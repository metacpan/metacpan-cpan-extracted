package PPM::Make;
use strict;
use warnings;
use PPM::Make::Config qw(:all);
use PPM::Make::Util qw(:all);
use PPM::Make::Meta;
use PPM::Make::Search;
use Cwd;
use Pod::Find qw(pod_find contains_pod);
use File::Basename;
use File::Path;
use File::Find;
use File::Copy;
use File::Spec;
use Net::FTP;
use Pod::Html;
use XML::Writer;
use version;
use Parse::LocalDistribution;

our $VERSION = '0.9904';

sub new {
  my ($class, %opts) = @_;

  die "\nInvalid option specification" unless check_opts(%opts);
  
  $opts{zip_archive} = 1 if ($opts{binary} and $opts{binary} =~ /\.zip$/);

  my ($arch, $os) = arch_and_os($opts{arch}, $opts{os}, $opts{noas});
  my $has = what_have_you($opts{program}, $arch, $os);

  my %cfg;
#  $opts{no_cfg} = 1 if $opts{install};
  unless ($opts{no_cfg}) {
    if (my $file = get_cfg_file()) {
      %cfg = read_cfg($file, $arch) or die "\nError reading config file";
    }
  }
  my $opts = %cfg ? merge_opts(\%cfg, \%opts) : \%opts;

  my $search = PPM::Make::Search->new(
    no_remote_lookup => $opts->{no_remote_lookup},
  );
  my $self = {
              opts => $opts || {},
              cwd => '',
              has => $has,
              args => {},
              ppd => '',
              archive => '',
              zip => '',
              prereq_pm => {},
              file => '',
              version => '',
              use_mb => '',
              ARCHITECTURE => $arch,
              OS => $os,
              cpan_meta => $opts->{cpan_meta},
              search => $search,
              fetch_error => '',
             };
  bless $self, $class;
}

sub make_ppm {
  my $self = shift;
  die 'No software available to make a zip archive'
    if ( ($self->{opts}->{zip_archive} or $self->{opts}->{zipdist})
        and not $self->{has}->{zip});
  my $dist = $self->{opts}->{dist};
  $self->{org_dir} = my $org_dir = cwd;
  if ($dist) {
    my $build_dir = File::Spec->tmpdir;
    chdir $build_dir or die "Cannot chdir to $build_dir: $!";
    print "Working directory: $build_dir\n"; 

    my $local_dist = File::Spec->file_name_is_absolute($dist)
      ? $dist
      : File::Spec->catfile($org_dir, $dist);
    if (-f $local_dist) {
      print "Found a local distribution: $local_dist\n";
      my $basename = basename($local_dist);
      copy($local_dist, File::Spec->catfile($build_dir, $basename));
      $self->{search}->{no_remote_lookup} = 0;
    }

    die $self->{fetch_error} 
      unless ($dist = $self->fetch_file($dist, no_case => $self->{opts}{no_case}));
#      if ($dist =~ m!$PPM::Make::Util::protocol! 
#          or $dist =~ m!^\w/\w\w/! or $dist !~ m!$PPM::Make::Util::ext!);
    print "Extracting files from $dist ....\n";
    my $name = $self->extract_dist($dist, $build_dir);
    chdir $name or die "Cannot chdir to $name: $!";
    $self->{file} = $dist;
  }
  die "Need a Makefile.PL or Build.PL to build"
    unless (-f 'Makefile.PL' or -f 'Build.PL');
  my $force = $self->{opts}->{force};
  $self->{cwd} = cwd;
  print "Working directory: $self->{cwd}\n";
  my $mb = -e 'Build.PL';
  $self->{mb} = $mb;
  die "This distribution requires Module::Build to build" 
    if ($mb and not HAS_MB);
  $self->check_script() if $self->{opts}->{script};
  $self->check_files() if $self->{opts}->{add};
  $self->adjust_binary() if $self->{opts}->{arch_sub};
  $self->build_dist()
    unless (-d 'blib' and 
            (-f 'Makefile' or ($mb and -f 'Build' and -d '_build')) 
            and not $force);

  my $meta = PPM::Make::Meta->new(dir => $self->{cwd},
                                  search => $self->{search},
                                  );
  die qq{Creating PPM::Make::Meta object failed}
    unless ($meta and (ref($meta) eq 'PPM::Make::Meta'));
  $meta->meta();
  foreach my $key( keys %{$meta->{info}}) {
    next unless defined $meta->{info}->{$key};
    $self->{args}->{$key} ||= $meta->{info}->{$key};
  }

  if ($self->{version} = $self->{args}->{VERSION}) {
    my $version = version->new($self->{version});
    $self->{version} = $version;
    $self->{version} =~ s/^v//x;
  } 
  else {
    warn "Could not extract version information";
  }
  unless ($self->{opts}->{no_html}) {
    $self->make_html() unless (-d 'blib/html' and not $force);
  }
  $dist = $self->make_dist();
  $self->make_ppd($dist);
#  if ($self->{opts}->{install}) {
#    die 'Must have the ppm utility to install' unless HAS_PPM;
#    $self->ppm_install();
#  }
  $self->make_cpan() if $self->{opts}->{cpan};
  $self->make_zipdist($dist) 
    if ($self->{opts}->{zipdist} and not $self->{opts}->{no_upload});
  if (defined $self->{opts}->{upload} and not $self->{opts}->{no_upload}) {
    die 'Please specify the location to place the ppd file'
      unless $self->{opts}->{upload}->{ppd}; 
    $self->upload_ppm();
  }

  if ($org_dir ne $self->{cwd}) {
    for (qw/archive ppd zip/) {
      copy(File::Spec->catfile($self->{cwd}, $self->{$_}), $org_dir) if $self->{$_};
    }
  }

  return 1;
}

sub check_script {
  my $self = shift;
  my $script = $self->{opts}->{script};
  return if ($script =~ m!$PPM::Make::Util::protocol!);
  my ($name, $path, $suffix) = fileparse($script, '\..*');
  my $file = $name . $suffix;
  $self->{opts}->{script} = $file;
  return if (-e $file);
  copy($script, $file) or die "Copying $script to $self->{cwd} failed: $!";
}

sub check_files {
  my $self = shift;
  my @entries = ();
  foreach my $file (@{$self->{opts}->{add}}) {
    my ($name, $path, $suffix) = fileparse($file, '\..*');
    my $entry = $name . $suffix;
    push @entries, $entry;
    next if (-e $entry);
    copy($file, $entry) or die "Copying $file to $self->{cwd} failed: $!";
  }
  $self->{opts}->{add} = \@entries if @entries;
}

sub extract_dist {
  my ($self, $file, $build_dir) = @_;

  my $has = $self->{has};
  my ($tar, $gzip, $unzip) = @$has{qw(tar gzip unzip)};

  my ($name, $path, $suffix) = fileparse($file, $PPM::Make::Util::ext);
  if (-d "$build_dir/$name") {
      rmtree("$build_dir/$name", 1, 0) 
          or die "rmtree of $name failed: $!";
  }
  EXTRACT: {
    if ($suffix eq '.zip') {
      ($unzip eq 'Archive::Zip') && do {
        my $arc = Archive::Zip->new();
        die "Read of $file failed" 
          unless $arc->read($file) == Archive::Zip::AZ_OK();
        $arc->extractTree();
        last EXTRACT;
      };
      ($unzip) && do {
        my @args = ($unzip, $file);
        print "@args\n";
        system(@args) == 0 or die "@args failed: $?";
        last EXTRACT;
      };

    }
    else {
      ($tar eq 'Archive::Tar') && do {
        my $arc = Archive::Tar->new($file, 1);
        $arc->extract($arc->list_files);
        last EXTRACT;
      };
      ($tar and $gzip and $suffix !~ /bz2$/) && do {
        my @args = ($gzip, '-dc', $file, '|', $tar, 'xvf', '-');
        print "@args\n";
        system(@args) == 0 or die "@args failed: $?";
        last EXTRACT;
      };
      ($tar) && do {
        my @args = ($tar, 'xvf', $file);
        print "@args\n";
        system(@args) == 0 or die "@args failed: $?";
        last EXTRACT;
      };
    }
    die "Cannot extract $file";
  }
  return $name;
}

sub adjust_binary {
  my $self = shift;
  my $binary = $self->{opts}->{binary};
  my $archname = $self->{ARCHITECTURE};
  return unless $archname;
  if ($binary) {
    if ($binary =~ m!$PPM::Make::Util::ext!) {
      if ($binary =~ m!/!) {
        $binary =~ s!(.*?)([\w\-]+)$PPM::Make::Util::ext!$1$archname/$2$3!;
      }
      else {
        $binary = $archname . '/' . $binary;
      }
    }
    else {
      $binary =~ s!/$!!;
      $binary .= '/' . $archname . '/';        
    }
  }
  else {
    $binary = $archname . '/';
  }
  $self->{opts}->{binary} = $binary;
}

sub build_dist {
  my $self = shift;
  my $binary = $self->{opts}->{binary};
  my $script = $self->{opts}->{script};
  my $exec = $self->{opts}->{exec};

  my $has = $self->{has};
  my ($make, $perl) = @$has{qw(make perl)};
  my $mb = $self->{mb};

  my $makepl = $mb ? 'Build.PL' : 'Makefile.PL';
  my @args = ($perl, $makepl);
  if (not $mb and my $makepl_arg = $CPAN::Config->{makepl_arg}) {
    push @args, (split ' ', $makepl_arg);
  }
  print "@args\n";
  system(@args) == 0 or die qq{@args failed: $?};

#  if ($mb) {
#    my $file = 'Build.PL';
#    unless (my $r = do $file) {
#      die "Can't parse $file: $@" if $@;
#      die "Can't do $file: $!" unless defined $r;
#      die "Can't run $file" unless $r;
#    }
#  }
#  else {
#    $self->write_makefile();
#  }

  my $build = 'Build';
  @args = $mb ? ($perl, $build) : ($make);
  if (not $mb and my $make_arg = $CPAN::Config->{make_arg}) {
    push @args, (split ' ', $make_arg);
  }
  print "@args\n";
  system(@args) == 0 or die "@args failed: $?";

  unless ($self->{opts}->{skip}) {
    @args = $mb ? ($perl, $build, 'test') : ($make, 'test');
    print "@args\n";
    unless (system(@args) == 0) {
      die "@args failed: $?" unless $self->{opts}->{ignore};
      warn "@args failed: $?";
    }
  }
  return 1;
}

sub make_html {
  my $self = shift;
  my $args = $self->{args};
  my $cwd = $self->{cwd};
  my $html = 'blib/html';
  unless (-d $html) {
    mkpath($html, 1, 0755) or die "Couldn't mkdir $html: $!";
  }
  my %pods = pod_find({-verbose => 1}, "$cwd/blib/");
  if (-d "$cwd/blib/script/") {
    finddepth( sub {
                $pods{$File::Find::name} = 
                  "script::" . basename($File::Find::name) 
                    if (-f $_ and not /\.bat$/ and contains_pod($_));
              }, "$cwd/blib/script");
  }

  foreach my $pod (keys %pods){
    my @dirs = split /::/, $pods{$pod};
    my $isbin = shift @dirs eq 'script';

    (my $infile = File::Spec->abs2rel($pod)) =~ s!^\w+:!!;
    $infile =~ s!\\!/!g;
    my $outfile = (pop @dirs) . '.html';

    my @rootdirs  = $isbin? ('bin') : ('site', 'lib');
    (my $path2root = "../" x (@rootdirs+@dirs)) =~ s|/$||;
    
    (my $fulldir = File::Spec->catfile($html, @rootdirs, @dirs)) =~ s!\\!/!g;
    unless (-d $fulldir){
      mkpath($fulldir, 1, 0755) 
        or die "Couldn't mkdir $fulldir: $!";  
    }
    ($outfile = File::Spec->catfile($fulldir, $outfile)) =~ s!\\!/!g;

    my $htmlroot = "$path2root/site/lib";
    my $podroot = "$cwd/blib";
    my $podpath = join ":" => map { $podroot . '/' . $_ }
      ($isbin ? qw(bin lib) : qw(lib));
    (my $package = $pods{$pod}) =~ s!^(lib|script)::!!;
    my $abstract = parse_abstract($package, $infile);
    my $title =  $abstract ? "$package - $abstract" : $package;
    my @opts = (
                '--header',
                "--title=$title",
                "--infile=$infile",
                "--outfile=$outfile",
                "--podroot=$podroot",
                "--htmlroot=$htmlroot",
                "--css=$path2root/Active.css",
               );
    print "pod2html @opts\n";
    pod2html(@opts);# or warn "pod2html @opts failed: $!";
  }
  ###################################
}

sub make_dist {
  my $self = shift;
  my $args = $self->{args};
  my $has = $self->{has};
  my ($tar, $gzip, $zip) = @$has{qw(tar gzip zip)};
  my $force_zip = $self->{opts}->{zip_archive};
  my $binary = $self->{opts}->{binary};
  my $name;
  if ($binary and $binary =~ /$PPM::Make::Util::ext/) {
    ($name = $binary) =~ s!.*/(.*)$PPM::Make::Util::ext!$1!;
  }
  else {
    $name = $args->{DISTNAME} || $args->{NAME};
    $name  =~ s!::!-!g;
  }

  $name .= "-$self->{version}" 
    if ( ($self->{opts}->{vs} or $self->{opts}->{vsr}) and $self->{version});

  my $is_Win32 = (not $self->{OS} or $self->{OS} =~ /Win32/i 
                  or not $self->{ARCHITECTURE} or
                  $self->{ARCHITECTURE} =~ /Win32/i);

  my $script = $self->{opts}->{script};
  my $script_is_external = $script ? ($script =~ /$PPM::Make::Util::protocol/) : '';
  my @files;
  if ($self->{opts}->{add}) {
    @files = @{$self->{opts}->{add}};
  }

  my $arc = $force_zip ? ($name . '.zip') : ($name . '.tar.gz');
#  unless ($self->{opts}->{force}) {
#    return $arc if (-f $arc);
#  }
  unlink $arc if (-e $arc);

  DIST: {
    ($tar eq 'Archive::Tar' and not $force_zip) && do {
      $name .= '.tar.gz';
      my @f;
      my $arc = Archive::Tar->new();
      if ($is_Win32) {
        finddepth(sub { push @f, $File::Find::name
                          unless $File::Find::name =~ m!blib/man\d!;
                        print $File::Find::name,"\n"}, 'blib');
      }
      else {
        finddepth(sub { push @f, $File::Find::name; 
                        print $File::Find::name,"\n"}, 'blib');
      }
      if ($script and not $script_is_external) {
        push @f, $script;
        print "$script\n";
      }
      if (@files) {
        push @f, @files;
        print join "\n", @files;
      }
      $arc->add_files(@f);
      $arc->write($name, 1);
      last DIST;
    };
    ($tar and $gzip and not $force_zip) && do {
      $name .= '.tar';
      my @args = ($tar, 'cvf', $name);

      if ($is_Win32) {
        my @f;
        finddepth(sub {
                        push @f, $File::Find::name
                          if $File::Find::name =~ m!blib/man\d!;},
                             'blib');
        for (@f) {
          push @args, "--exclude", $_;
        }
      }

      push @args, 'blib';

      if ($script and not $script_is_external) {
        push @args, $script;
      }
      if (@files) {
        push @args, @files;
      }
      print "@args\n";
      system(@args) == 0 or die "@args failed: $?";
      @args = ($gzip, $name);
      print "@args\n";
      system(@args) == 0 or die "@args failed: $?";
      $name .= '.gz';
      last DIST;
    };
    ($zip eq 'Archive::Zip') && do {
      $name .= '.zip';
      my $arc = Archive::Zip->new();
      if ($is_Win32) {
        die "zip of blib failed" unless $arc->addTree('blib', 'blib',
                     sub{$_ !~ m!blib/man\d/! 
                           && print "$_\n";}) == Archive::Zip::AZ_OK();
      }
      else {
        die "zip of blib failed" unless $arc->addTree('blib', 'blib', 
                              sub{print "$_\n";}) == Archive::Zip::AZ_OK();
      }
      if ($script and not $script_is_external) {
        die "zip of $script failed"
          unless $arc->addFile($script, $script);
        print "$script\n";
      }
      if (@files) {
        for (@files) {
          die "zip of $_ failed" unless $arc->addFile($_, $_);
          print "$_\n";
        }
      }
      die "Writing to $name failed" 
        unless $arc->writeToFileNamed($name) == Archive::Zip::AZ_OK();
      last DIST;
    };
    ($zip) && do {
      $name .= '.zip';
      my @args = ($zip, '-r', $name, 'blib');
      if ($script and not $script_is_external) {
        push @args, $script;
        print "$script\n";
      }
      if (@files) {
        push @args, @files;
        print join "\n", @files;
      }
      if ($is_Win32) {
        my @f;
        finddepth(sub {
                        push @f, $File::Find::name
                          unless $File::Find::name =~ m!blib/man\d!;},
                             'blib');
        for (@f) {
          push @args, "-x", $_;
        }
      }

      print "@args\n";
      system(@args) == 0 or die "@args failed: $?";
      last DIST;
    };
    die "Cannot make archive for $name";
  }
  return $name;
}

sub make_ppd {
  my ($self, $dist) = @_;
  my $has = $self->{has};
  my ($make, $perl) = @$has{qw(make perl)};
  my $binary = $self->{opts}->{binary};
  if ($binary) {
    unless ($binary =~ /$PPM::Make::Util::ext/) {
      $binary =~ s!/$!!;
      $binary .= '/' . $dist;
    }
  }

  (my $name = $dist) =~ s!$PPM::Make::Util::ext!!;
  if ($self->{opts}->{vsr} and not $self->{opts}->{vsp}) {
     $name =~ s/-$self->{version}// if $self->{version};
  }
  if ($self->{opts}->{vsp} and $name !~ m/-$self->{version}/) {
     $name .= "-$self->{version}";
  }
  my $ppd = $name . '.ppd';
  my $args = $self->{args};
  my $os = $self->{OS};
  my $arch = $self->{ARCHITECTURE};
  my $d;

  $d->{SOFTPKG}->{NAME} = $d->{TITLE} = $name;
  $d->{SOFTPKG}->{VERSION} = cpan2ppd_version($self->{version} || 0);
  $d->{OS}->{NAME} = $os if $os;
  $d->{ARCHITECTURE}->{NAME} = $arch if $arch;
  $d->{ABSTRACT} = $args->{ABSTRACT};
  $d->{AUTHOR} = (ref($args->{AUTHOR}) eq 'ARRAY') ?
    (join ', ', @{$args->{AUTHOR}}) : $args->{AUTHOR};
  $d->{CODEBASE}->{HREF} = $self->{opts}->{no_upload} ? $dist : 
    ($binary || $dist);
  ($self->{archive} = $d->{CODEBASE}->{HREF}) =~ s!.*/(.*)!$1!;

  if ( my $script = $self->{opts}->{script}) {
    if (my $exec = $self->{opts}->{exec}) {
      $d->{INSTALL}->{EXEC} = $exec;
    }
    if ($script =~ m!$PPM::Make::Util::protocol!) {
      $d->{INSTALL}->{HREF} = $script;
      (my $name = $script) =~ s!.*/(.*)!$1!;
      $d->{INSTALL}->{SCRIPT} = $name;
    }
    else {
      $d->{INSTALL}->{SCRIPT} = $script;
    }
  }

  my $search = $self->{search};

  my $parser = Parse::LocalDistribution->new({ALLOW_DEV_VERSION => 1});
  my $provides = $parser->parse('.');
  for my $package (keys %{$provides || {}}) {
    my $name = $package;
    if ($] < 5.10 and $name !~ /::/) {
      $name .= '::';
    }
    my $version = $provides->{$package}{version};
    $version = undef if defined $version and $version eq 'undef';
    if ($version) {
      push @{$d->{PROVIDE}}, {NAME => $name, VERSION => $version};
    } else {
      push @{$d->{PROVIDE}}, {NAME => $name};
    }
  }
  my $mod_ref;
  foreach my $dp (keys %{$args->{PREREQ_PM}}) {
    next if ($dp eq 'perl' or is_core($dp));
    $dp =~ s{-}{::}g;
    $d->{REQUIRE}->{$dp} = $args->{PREREQ_PM}->{$dp} || 0;
    push @$mod_ref, $dp;
  }
  my %deps = map {$_ => 1} @$mod_ref;
  {
    if ($mod_ref and ref($mod_ref) eq 'ARRAY') {
      if ($search->search($mod_ref, mode => 'mod')) {
        my $matches = $search->{mod_results};
        if ($matches and ref($matches) eq 'HASH') {
          foreach my $dp(keys %$matches) {
            next unless $deps{$dp};
            my $results = $matches->{$dp};
            next unless (defined $results and defined $results->{mod_name});
            my $dist = $results->{dist_name};
            next if (not $dist or $dist =~ m!^perl$!
                      or $dist =~ m!^Test! or is_ap_core($dist));
            $self->{prereq_pm}->{$dist} = 
              $d->{DEPENDENCY}->{$dist} = 
                cpan2ppd_version($args->{PREREQ_PM}->{$dp} || 0);
          }
        }
        else {
          $search->search_error(qq{Cannot find information on prerequisites for '$name'});
        }
      }
    }
  }
  foreach (qw(OS ARCHITECTURE)) {
    delete $d->{$_}->{NAME} unless $self->{$_};
  }
  $self->print_ppd($d, $ppd);
  $self->{ppd} = $ppd;
}

sub print_ppd {
  my ($self, $d, $fn) = @_;
  open (my $fh, '>', $fn) or die "Couldn't write to $fn: $!";
  my $writer = XML::Writer->new(OUTPUT => $fh, DATA_INDENT => 2);
  $writer->xmlDecl('UTF-8');
  # weird hack to eliminate an empty line after the XML declaration
  $writer->startTag('SOFTPKG', NAME => $d->{SOFTPKG}->{NAME}, VERSION => $d->{SOFTPKG}->{VERSION});
  $writer->setDataMode(1);
  $writer->dataElement(TITLE => encode_non_ascii_chars($d->{TITLE}));
  $writer->dataElement(ABSTRACT => encode_non_ascii_chars($d->{ABSTRACT}));
  $writer->dataElement(AUTHOR => encode_non_ascii_chars($d->{AUTHOR}));
  $writer->startTag('IMPLEMENTATION');

  foreach (sort keys %{$d->{DEPENDENCY}}) {
    $writer->emptyTag('DEPENDENCY' => NAME => $_, VERSION => $d->{DEPENDENCY}->{$_});
  }
  if ($] > 5.008) {
    foreach (sort keys %{$d->{REQUIRE}}) {
      $writer->emptyTag('REQUIRE' => NAME => $_, VERSION => $d->{REQUIRE}->{$_});
    }
  }
  foreach (qw(OS ARCHITECTURE)) {
    next unless $d->{$_}->{NAME};
    $writer->emptyTag($_ => NAME => $d->{$_}->{NAME});
  }

  if (my $script = $d->{INSTALL}->{SCRIPT}) {
    my %attr;
    for (qw/EXEC HREF/) {
      next unless $d->{INSTALL}->{$_};
      $attr{$_} = $d->{INSTALL}->{$_};
    }
    $writer->dataElement('INSTALL', $script, %attr);
  }

  $writer->emptyTag('CODEBASE' => HREF => $d->{CODEBASE}->{HREF});

  my $provide = $d->{PROVIDE};
  unless ($self->{opts}->{no_ppm4}) {
    if ($provide and (ref($provide) eq 'ARRAY')) {
      foreach my $mod(@$provide) {
        my %attr;
        if ($mod->{VERSION}) {
          $attr{VERSION} = $mod->{VERSION};
        }
        $writer->emptyTag('PROVIDE' => NAME => $mod->{NAME}, %attr);
      }
    }
  }
  $writer->endTag('IMPLEMENTATION');
  $writer->endTag('SOFTPKG');
  $writer->end;
  $fh->close;
  $self->{codebase} = $d->{CODEBASE}->{HREF};
}

sub make_zipdist {
  my ($self, $dist) = @_;
  my $ppd = $self->{ppd};
  (my $zipdist = $ppd) =~ s!\.ppd$!.zip!;
  if (-f $zipdist) {
      unlink $zipdist or warn "Could not unlink $zipdist: $!";
  }
  my $cb = $self->{codebase};
  my ($path, $archive, $local);
  if ($cb =~ m!/!) {
    ($path, $archive) = $cb =~ m!(.*)/(.*)!;
    $local = ($path !~ m!(http|ftp)://! 
              and not File::Spec->file_name_is_absolute($path) ) ? 1 : 0;
  }
  else {
    $archive = $cb;
  }
  my $readme = 'README.ppm';
  open(my $fh, '>', $readme) or die "Cannot open $readme: $!";
  print $fh <<"END";
To install this ppm package, run the following command
in the current directory:

   ppm install $ppd

END
  close $fh;

  my $ppd_zip = $ppd . '.copy';
  open(my $rfh, '<', $ppd) or die "Cannot open $ppd: $!";
  open(my $wfh, '>', $ppd_zip) or die "Cannot open $ppd_zip: $!";
  while (my $line = <$rfh>) {
    $line =~ s{HREF=\"(http|ftp)://.*/([^/]+)\"}{HREF="$2"};
    print $wfh $line;
  }
  close($rfh);
  close($wfh);

  my $zip = $self->{has}->{zip};
  my $copy = $local ? File::Spec::Unix->catfile($path, $archive) : $archive;
  print qq{\nCreating $zipdist ...\n};
  if ($zip eq 'Archive::Zip') {
    my %contents = ($ppd_zip => $ppd,
                    $archive => $copy,
                    $readme => 'README');
    my $arc = Archive::Zip->new();
    foreach (keys %contents) {
      print "Adding $_ as $contents{$_}\n";
      unless ($arc->addFile($_, $contents{$_})) {
        die "Failed to add $_";
      }
    }
    die "Writing to $zipdist failed" 
      unless $arc->writeToFileNamed($zipdist) == Archive::Zip::AZ_OK();
  }
  else {
    if ($path and $local) {
      unless (-d $path) {
        mkpath($path, 1, 0777) or die "Cannot mkpath $path: $!";
      }
      copy($archive, $copy) or die "Cannot cp $archive to $copy: $!";
    }
    rename($ppd, "$ppd.tmp") or die "Cannnot rename $ppd to $ppd.tmp: $!";
    rename($ppd_zip, $ppd) or die "Cannnot rename $ppd_zip to $ppd: $!";

    my @args = ($zip, $zipdist, $ppd, $copy, $readme);
    print "@args\n";
    system(@args) == 0 or die "@args failed: $?";
    rename($ppd, $ppd_zip) or die "Cannnot rename $ppd to $ppd_zip: $!";
    rename("$ppd.tmp", $ppd) or die "Cannnot rename $ppd.tmp to $ppd: $!";
    if ($path and $local and -d $path) {
      rmtree($path, 1, 1) or warn "Cannot rmtree $path: $!";
    }
  }
  $self->{zip} = $zipdist;
  unlink $readme;
  unlink $ppd_zip;
}

sub make_cpan {
  my $self = shift;
  my ($ppd, $archive) = ($self->{ppd}, $self->{archive});
  my %seen;
  my $man = 'MANIFEST';
  my $copy = $man . '.orig';
  unless (-e $copy) {
    rename($man, $copy) or die "Cannot rename $man: $!";
  }
  open(my $orig, '<', $copy) or die "Cannot read $copy: $!";
  open(my $new, '>', $man) or die "Cannot open $man for writing: $!";
  while (<$orig>) {
    $seen{ppd}++ if $_ =~ /$ppd/;
    $seen{archive}++ if $_ =~ /$archive/;
    print $new $_;
  }
  close $orig;
  print $new "\n$ppd\n" unless $seen{ppd};
  print $new "$archive\n" unless $seen{archive};
  close $new;
  my @args = ($self->{has}->{make}, 'dist');
  print "@args\n";
  system(@args) == 0 or die qq{system @args failed: $?};
  return;
}

sub upload_ppm {
  my $self = shift;
  my ($ppd, $archive, $zip) = ($self->{ppd}, $self->{archive}, $self->{zip});
  my $upload = $self->{opts}->{upload};
  my $ppd_loc = $upload->{ppd};
  my $zip_loc = $upload->{zip};
  my $ar_loc = $self->{opts}->{arch_sub} ?
    $self->{ARCHITECTURE} : $upload->{ar} || $ppd_loc;
  if (defined $ar_loc) {
    if (not File::Spec->file_name_is_absolute($ar_loc)) {
      ($ar_loc = File::Spec->catdir($ppd_loc, $ar_loc)) =~ s!\\!/!g;
    }
  }
  if (defined $zip_loc) {
    if (not File::Spec->file_name_is_absolute($zip_loc)) {
      ($zip_loc = File::Spec->catdir($ppd_loc, $zip_loc)) =~ s!\\!/!g;
    }
  }

  if (my $host = $upload->{host}) {
    print qq{\nUploading files to $host ...\n};
    my ($user, $passwd) = ($upload->{user}, $upload->{passwd});
    die "Must specify a username and password to log into $host"
      unless ($user and $passwd);
    my $ftp = Net::FTP->new($host)
      or die "Cannot connect to $host: $@";
    $ftp->login($user, $passwd)
      or die "Login for user $user failed: ", $ftp->message;
    $ftp->cwd($ppd_loc) or die
      "cwd to $ppd_loc failed: ", $ftp->message;
    if ($Net::FTP::VERSION eq '2.77') {
      $ftp->binary;
    }
    else {
      $ftp->ascii;
    }
    $ftp->put($ppd)
      or die "Cannot upload $ppd: ", $ftp->message;
    $ftp->cwd($ar_loc)
      or die "cwd to $ar_loc failed: ", $ftp->message;
    $ftp->binary;
    $ftp->put($archive)
      or die "Cannot upload $archive: ", $ftp->message;
    if ($self->{opts}->{zipdist} and -f $zip) {
      $ftp->cwd($zip_loc)
        or die "cwd to $zip_loc failed: ", $ftp->message;
      $ftp->put($zip)
        or die "Cannot upload $zip: ", $ftp->message;
    }
    $ftp->quit;
    print qq{Done!\n};
  }
  else {
    print qq{\nCopying files ....\n};
    copy($ppd, "$ppd_loc/$ppd") 
      or die "Cannot copy $ppd to $ppd_loc: $!";
    unless (-d $ar_loc) {
      mkdir $ar_loc or die "Cannot mkdir $ar_loc: $!";
    }
    copy($archive, "$ar_loc/$archive") 
      or die "Cannot copy $archive to $ar_loc: $!";
    if ($self->{opts}->{zipdist} and -f $zip) {
      unless (-d $zip_loc) {
        mkdir $zip_loc or die "Cannot mkdir $zip_loc: $!";
      }
      copy($zip, "$zip_loc/$zip") 
        or die "Cannot copy $zip to $zip_loc: $!";
    }
    print qq{Done!\n};
  }
}

sub fetch_file {
  my ($self, $dist, %args) = @_;
  my $no_case = $args{no_case};
  my $to;
  if (-f $dist) {
    $to = basename($dist, $PPM::Make::Util::ext);
    unless ($dist eq $to) {
      copy($dist, $to) or die "Cannot cp $dist to $to: $!";
    }
    return $to;
  }
  if ($dist =~ m!$PPM::Make::Util::protocol!) {
    ($to = $dist) =~ s!.*/(.*)!$1!;
    print "Fetching $dist ....\n";
    my $rc = mirror($dist, $to);
    unless ($rc) {
      $self->{fetch_error} = qq{Fetch of $dist failed.};
      return;
    }
    return $to;
  }
  my $search = $self->{search};
  my $results;
  unless ($dist =~ /$PPM::Make::Util::ext$/) {
    my $mod = $dist;
    $mod =~ s!-!::!g;
    if ($search->search($mod, mode => 'mod')) {
      $results = $search->{mod_results}->{$mod};
    }
    unless ($results) {
      $mod =~ s!::!-!g;
      if ($search->search($mod, mode => 'dist')) {
        $results = $search->{dist_results}->{$mod};
      }
    }
    unless ($results->{cpanid} and $results->{dist_file}) {
      $self->{fetch_error} = qq{Cannot get distribution name of '$mod'};
      return;
    }
    $dist = cpan_file($results->{cpanid}, $results->{dist_file});
  }
  my $id = dirname($dist);
  $to = basename($dist, $PPM::Make::Util::ext);
  my $src = HAS_CPAN ? 
    File::Spec->catdir($src_dir, 'authors/id', $id) : 
        $src_dir;
  my $CS = 'CHECKSUMS';
  my $get_cs = 0;
  for my $file( ($to, $CS)) {
    my $local = File::Spec->catfile($src, $file);
    if (-e $local and $src_dir ne $build_dir and not $get_cs) {
      copy($local, '.') or do {
        $self->{fetch_error} = "Cannot copy $local: $!";
        return;
      };
      next;
    }
    else {
      my $from;
      $get_cs = 1;
      foreach my $url(@url_list) {
        $url =~ s!/$!!;
        $from = $url . '/authors/id/' . $id . '/' . $file;
        print "Fetching $from ...\n";
        last if mirror($from, $file);
      }
      unless (-e $file) {
        $self->{fetch_error} = "Fetch of $file from $from failed";
        return;
      }
      if ($src_dir ne $build_dir) {
        unless (-d $src) {
          mkpath($src) or do {
            $self->{fetch_error} = "Cannot mkdir $src: $!";
            return;
          };
        }
        copy($file, $src) or warn "Cannot copy $to to $src: $!";
      }
    }
  }
  return $to unless $to =~ /$PPM::Make::Util::ext$/;
  my $cksum;
  unless ($cksum = load_cs($CS)) {
    $self->{fetch_error} = qq{Checksums check disabled - cannot load $CS file.};
    return;
  }
  unless (verifyMD5($cksum, $to) || verifySHA256($cksum, $to)) {
    $self->{fetch_error} =  qq{Checksums check for "$to" failed.};
    return;
  }
  unlink $CS or warn qq{Cannot unlink "$CS": $!\n};
  return $to;
}

1;

__END__

=head1 NAME

PPM::Make - Make a ppm package from a CPAN distribution

=head1 SYNOPSIS

  my $ppm = PPM::Make->new( [options] );
  $ppm->make_ppm();

=head1 DESCRIPTION

See the supplied C<make_ppm> script for a command-line interface.

This module automates somewhat some of the steps needed to make
a I<ppm> (Perl Package Manager) package from a CPAN distribution.
It attempts to fill in the I<ABSTRACT> and I<AUTHOR> attributes of 
F<Makefile.PL>, if these are not supplied, and also uses C<pod2html> 
to generate a set of html documentation. It also adjusts I<CODEBASE> 
of I<package.ppd> to reflect the generated I<package.tar.gz> 
or I<package.zip> archive. Such packages are suitable both for 
local installation via

  C:\.cpan\build\package_src> ppm install

and for distribution via a repository.

Options can be given as some combination of key/value
pairs passed to the I<new()> constructor (described below) 
and those specified in a configuration file.
This file can either be that given by the value of
the I<PPM_CFG> environment variable or, if not set,
a file called F<.ppmcfg> at the top-level
directory (on Win32) or under I<HOME> (on Unix).
If the I<no_cfg> argument is passed into C<new()>,
this file will be ignored.

The configuration file is of an INI type. If a section
I<default> is specified as

  [ default ]
  option1 = value1
  option2 = value2

these values will be used as the default. Architecture-specific
values may be specified within their own section:

  [ MSWin32-x86-multi-thread-5.8 ]
  option1 = new_value1
  option3 = value3

In this case, an architecture specified as
I<MSWin32-x86-multi-thread-5.8> within PPM::Make will
have I<option1 = new_value1>, I<option2 = value2>,
and I<option3 = value3>, while any other architecture
will have I<option1 = value1> and I<option2 = value2>.
Options that take multiple values, such as C<reps>,
can be specified as

    reps = <<END
  http://theoryx5.uwinnipeg.ca/ppms/
  http://ppm.activestate.com/PPMPackages/5.8-windows/
  END

Options specified within the configuration file
can be overridden by passing the option into
the I<new()> method of PPM::Make.

Valid options that may be specified within the 
configuration file are those of PPM::Make, described below. 
For the I<program> and I<upload> options (which take hash references),
the keys (make, zip, unzip, tar, gzip),
or (ppd, ar, zip, host, user, passwd), respectively,
should be specified. For binary options, a value
of I<yes|on> in the configuration file will be interpreted
as true, while I<no|off> will be interpreted as false.

=head2 OPTIONS

The available options accepted by the I<new> constructor are

=over

=item no_cfg =E<gt> 1

If specified, do not attempt to read a F<.ppmcfg> configuration
file.

=item no_html =E<gt> 1

If specified, do not build the html documentation.

=item no_ppm4 =E<gt> 1

If specified, do not add ppm4 extensions to the ppd file.

=item no_remote_lookup =E<gt> 1

If specified, do not consult remote databases nor CPAN.pm for information
not contained within the files of the distribution.

=item dist =E<gt> value

If I<dist> is not specified, it will be assumed that one
is working inside an already unpacked source directory,
and the ppm distribution will be built from there. A value 
for I<dist> will be interpreted either as a CPAN-like source
distribution to fetch and build, or as a module name,
in which case I<CPAN.pm> will be used to infer the
corresponding distribution to grab.

=item no_case =E<gt> boolean

If I<no_case> is specified, a case-insensitive search
of a module name will be performed.

=item binary =E<gt> value

The value of I<binary> is used in the I<BINARY_LOCATION>
attribute passed to C<perl Makefile.PL>, and arises in
setting the I<HREF> attribute of the I<CODEBASE> field
in the ppd file.

=item arch_sub =E<gt> boolean

Setting this option will insert the value of C<$Config{archname}>
(or the value of the I<arch> option, if given)
as a relative subdirectory in the I<HREF> attribute of the 
I<CODEBASE> field in the ppd file.

=item script =E<gt> value

The value of I<script> is used in the I<PPM_INSTALL_SCRIPT>
attribute passed to C<perl Makefile.PL>, and arises in
setting the value of the I<INSTALL> field in the ppd file.
If this begins with I<http://> or I<ftp://>, so that the
script is assumed external, this will be
used as the I<HREF> attribute for I<INSTALL>.

=item exec =E<gt> value

The value of I<exec> is used in the I<PPM_INSTALL_EXEC>
attribute passed to C<perl Makefile.PL>, and arises in
setting the I<EXEC> attribute of the I<INSTALL> field
in the ppd file. 

=item  add =E<gt> \@files

The specified array reference contains a list of files
outside of the F<blib> directory to be added to the archive. 

=item zip_archive =E<gt> boolean

By default, a I<.tar.gz> distribution will be built, if possible. 
Giving I<zip> a true value forces a I<.zip> distribution to be made.

=item force =E<gt> boolean

If a F<blib/> directory is detected, it will be assumed that
the distribution has already been made. Setting I<force> to
be a true value forces remaking the distribution.

=item ignore =E<gt> boolean

If when building and testing a distribution, failure of any
supplied tests will be treated as a fatal error. Setting
I<ignore> to a true value causes failed tests to just
issue a warning.

=item skip =E<gt> boolean

If this option is true, the tests when building a distribution
won't be run.

=item os =E<gt> value

If this option specified, the value, if present, will be used instead 
of the default for the I<NAME> attribute of the I<OS> field of the ppd 
file. If a value of an empty string is given, the I<OS> field will not 
be included in the  ppd file.

=item arch =E<gt> value

If this option is specified, the value, if present, will be used instead 
of the default for the I<NAME> attribute of the I<ARCHITECTURE> field of 
the ppd file. If a value of an empty string is given, the 
I<ARCHITECTURE> field will not be included in the ppd file.

=item remove =E<gt> boolean

If specified, the directory used to build the ppm distribution
(with the I<dist> option) will be removed after a successful install.

=item zipdist =E<gt> boolean

If enabled, this option will create a zip file C<archive.zip>
consisting of the C<archive.ppd> ppd file and the C<archive.tar.gz>
archive file, suitable for local installations. A short README
file giving the command for installation is also included.

=item cpan =E<gt> boolean

If specified, a distribution will be made using C<make dist>
which will include the I<ppd> and I<archive> file.

=item reps =E<gt> \@repositories

This specifies a list of repositories to search for when
making a bundle file with PPM::Make::Bundle.

=item program =E<gt> { p1 =E<gt> '/path/to/q1', p2 =E<gt> '/path/to/q2', ...}

This option specifies that C</path/to/q1> should be used
for program C<p1>, etc., rather than the ones PPM::Make finds. The
programs specified can be one of C<tar>, C<gzip>, C<zip>, C<unzip>,
or C<make>.

=item no_as =E<gt> boolean

Beginning with Perl-5.8, Activestate adds the Perl version number to
the NAME of the ARCHITECTURE tag in the ppd file. This option
will make a ppd file I<without> this practice.

=item vs =E<gt> boolean

This option, if enabled, will add a version string 
(based on the VERSION reported in the ppd file) to the 
ppd and archive filenames.

=item vsr =E<gt> boolean

This option, if enabled, will add a version string 
(based on the VERSION reported in the ppd file) to the 
archive filename.

=item vsp =E<gt> boolean

This option, if enabled, will add a version string 
(based on the VERSION reported in the ppd file) to the 
ppd filename.

=item upload =E<gt> {key1 =E<gt> val1, key2 =E<gt> val2, ...}

If given, this option will copy the ppd and archive files
to the specified locations. The available options are

=over

=item ppd =E<gt> $path_to_ppd_files

This is the location where the ppd file should be placed,
and must be given as an absolute pathname.

=item ar =E<gt> $path_to_archive_files

This is the location where the archive file should be placed.
This may either be an absolute pathname or a relative one,
in which case it is interpreted to be relative to that
specified by I<ppd>. If this is not given, and yet I<ppd>
is specified, then this defaults, first of all, to the
value of I<arch_sub>, if given, or else to the value
of I<ppd>.

=item zip =E<gt> $path_to_zip_file

This is the location where the zipped file created with the
I<--zipdist> options should be placed.
This may either be an absolute pathname or a relative one,
in which case it is interpreted to be relative to that
specified by I<ppd>. If this is not given, but I<ppd>
is specified, this will default to the value of I<ppd>.

=item bundle =E<gt> $path_to_bundles

This is the location where the bundle file created with
PPM::Make::Bundle should be placed.
This may either be an absolute pathname or a relative one,
in which case it is interpreted to be relative to that
specified by I<ppd>. If this is not given, but I<ppd>
is specified, this will default to the value of I<ppd>.

=item host =E<gt> $hostname

If specified, an ftp transfer to the specified host is
done, with I<ppd> and I<ar> as described above.

=item user =E<gt> $username

This specifies the user name to login as when transferring
via ftp.

=item passwd =E<gt> $passwd

This is the associated password to use for I<user>

=back

=item no_upload =E<gt> 1

This option instructs C<upload> to be ignored (used by PPM::Make::Bundle)

=back

=head2 STEPS

The steps to make the PPM distribution are as follows. 

=over

=item determine available programs

For building and making the distribution, certain
programs will be needed. For unpacking and making 
I<.tar.gz> files, either I<Archive::Tar> and I<Compress::Zlib>
must be installed, or a C<tar> and C<gzip> program must
be available. For unpacking and making I<.zip> archives,
either I<Archive::Zip> must be present, or a C<zip> and
C<unzip> program must be available. Finally, a C<make>
program must be present.

=item fetch and unpack the distribution

If I<dist> is specified, the corresponding file is
fetched (by I<LWP::Simple>, if a I<URL> is specified).
If I<dist> appears to be a module name, the associated
distribution is determined by I<CPAN.pm>. This is done
through the C<fetch_file> method, which
fetches a file, and if successful, returns the stored filename.
If the file is specified beginning with I<http://> or I<ftp://>:

  my $fetch = 'http://my.server/my_file.tar.gz';
  my $filename = $obj->fetch_file($fetch);

will grab this file directly. Otherwise, if the file is
specified with an absolute path name, has
an extension I<\.(tar\.gz|tgz|tar\.Z|zip)>, and if the file
exists locally, it will use that; otherwise, it will assume
this is a CPAN distribution and grab it from a CPAN mirror:

  my $dist = 'A/AB/ABC/file.tar.gz';
  my $filename = $obj->fetch_file($dist);

which assumes the file lives under I<$CPAN/authors/id/>. If
neither of the above are satisfied, it will assume this
is, first of all, a module name, and if not found, a distribution
name, and if found, will fetch the corresponding CPAN distribution.

  my $mod = 'Net::FTP';
  my $filename = $obj->fetch_file($mod);

Assuming this succeeds, the distribution is then unpacked.

=item build the distribution

If needed, or if specied by the I<force> option, the
distribution is built by the usual

  C:\.cpan\build\package_src> perl Makefile.PL
  C:\.cpan\build\package_src> nmake
  C:\.cpan\build\package_src> nmake test

procedure. A failure in any of the tests will be considered
fatal unless the I<ignore> option is used. Additional
arguments to these commands present in either I<CPAN::Config>
or present in the I<binary> option to specify I<BINARY_LOCATION>
in F<Makefile.PL> will be added.

=item parse Makefile.PL

Some information contained in the I<WriteMakefile> attributes
of F<Makefile.PL> is then extracted.

=item parse Makefile

If certain information in F<Makefile.PL> can't be extracted,
F<Makefile> is tried.

=item determining the ABSTRACT

If an I<ABSTRACT> or I<ABSTRACT_FROM> attribute in F<Makefile.PL> 
is not given, an attempt is made to extract an abstract from the 
pod documentation of likely files.

=item determining the AUTHOR

If an I<AUTHOR> attribute in F<Makefile.PL> is not given,
an attempt is made to get the author information using I<CPAN.pm>.

=item determining Bundle information

If the distribution is a Bundle, extract the prerequisites
from the associated module for insertion in the ppd file.

=item HTML documentation

C<pod2html> is used to generate a set of html documentation.
This is placed under the F<blib/html/site/lib/> subdirectory, 
which C<ppm install> will install into the user's html tree.

=item Make the PPM distribution

A distribution file based on the contents of the F<blib/> directory
is then made. If possible, this will be a I<.tar.gz> file,
unless suitable software isn't available or if the I<zip>
option is used, in which case a I<.zip> archive is made, if possible.

=item adjust the PPD file

The F<package_name.ppd> file generated by C<nmake ppd> will
be edited appropriately. This includes filling in the 
I<ABSTRACT> and I<AUTHOR> fields, if needed and possible,
and also filling in the I<CODEBASE> field with the 
name of the generated archive file. This will incorporate
a possible I<binary> option used to specify
the I<HREF> attribute of the I<CODEBASE> field. 
Two routines are used in doing this - C<parse_ppd>, for
parsing the ppd file, and C<print_ppd>, for generating
the modified file.

=item upload the ppm files

If the I<upload> option is specified, the ppd and archive
files will be copied to the given locations.

=back

=head1 REQUIREMENTS

As well as the needed software for unpacking and
making I<.tar.gz> and I<.zip> archives, and a C<make>
program, it is assumed in this that I<CPAN.pm> is 
available and already configured, either site-wide or
through a user's F<$HOME/.cpan/CPAN/MyConfig.pm>.

Although the examples given above had a Win32 flavour,
like I<PPM>, no assumptions on the operating system are
made in the module.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PPM::Make

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PPM-Make>

=item * CPAN::Forum: Discussion forum

L<http:///www.cpanforum.com/dist/PPM-Make>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PPM-Make>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PPM-Make>

=item * Search CPAN

L<http://search.cpan.org/dist/PPM-Make>

=item * UWinnipeg CPAN search

L<http://cpan.uwinnipeg.ca/dist/PPM-Make>

=back

=head1 COPYRIGHT

This program is copyright, 2003, 2006, 2008
by Randy Kobes E<lt>r.kobes@uwinnipeg.caE<gt>.
It is distributed under the same terms as Perl itself.

=head1 CURRENT MAINTAINER

Kenichi Ishigaki E<lt>ishigaki@cpan.orgE<gt>

=head1 SEE ALSO

L<make_ppm> for a command-line interface for making
ppm packages, L<ppm_install> for a command line interface
for installing CPAN packages via C<ppm>,
L<PPM::Make::Install>, and L<PPM>.

=cut

