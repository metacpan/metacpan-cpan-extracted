package PPM::Make::Bundle;

use strict;
use warnings;
use Cwd;
use File::Spec::Functions qw(:ALL);
use File::Copy;
use File::Path;
use PPM::Make;
use PPM::Make::Util qw(:all);
use PPM::Make::Config qw(:all);
use PPM::Make::Search;

our $VERSION = '0.9904';

sub new {
  my ($class, %opts) = @_;

  my $bundle_name = delete $opts{bundle_name};
  if ($bundle_name) {
    $bundle_name =~ s{$PPM::Make::Util::ext$}{} if $bundle_name;
    $bundle_name .= '.zip';
  }

  my $clean = delete $opts{clean};

  my ($arch, $os) = arch_and_os($opts{arch}, $opts{os}, $opts{noas});
  my $has = what_have_you($opts{program}, $arch, $os);

  die "\nInvalid option specification" unless check_opts(%opts);
  my %cfg;
  unless ($opts{no_cfg}) {
    if (my $file = get_cfg_file()) {
      %cfg = read_cfg($file, $arch) or die "\nError reading config file";
    }
  }
  my $opts = %cfg ? merge_opts(\%cfg, \%opts) : \%opts;
  my $search = PPM::Make::Search->new(
    no_remote_lookup => $opts->{no_remote_lookup},
  );

  my $cwd = cwd;
  my $build_dir = catdir(tmpdir, "ppm_make-$$");
  mkdir $build_dir or die qq{Cannot mkdir $build_dir: $!};
  my $self = {cwd => $cwd, opts => $opts, files => {}, name => '',
              build_dir => $build_dir, has => $has, zipdist => $bundle_name,
              clean => $clean, arch => $arch, os => $os,
              search => $search,
              };
  bless $self, $class;
}

sub make_bundle {
  my $self = shift;
  $self->make_package($self->{opts}->{dist}) or return;
  $self->make_zip() or return;
  if ($self->{opts}->{upload}) {
    $self->upload_zip() or return;
  }
  my $cwd = $self->{cwd};
  chdir($cwd) or die qq{Cannot chdir to $cwd: $!};
  if ($self->{clean}) {
    chdir($self->{cwd}) or die qq{Cannot chdir to $self->{cwd}: $!};
    my $build_dir = $self->{build_dir};
    if (-d $build_dir) {
      rmtree($build_dir, 1, 1) or warn qq{Cannot rmtree $build_dir: $!};
    }
  }
  return 1;
}

sub make_package {
  my ($self, $dist, $info) = @_;

  my ($dist_name, $cpan_file);
  if ($dist and $dist !~ /$PPM::Make::Util::ext$/) {
    return 1 if (defined $self->{files}->{$dist} or is_ap_core($dist));
    $info = $self->get_info($dist) unless ($info and (ref($info) eq 'HASH'));
    $dist_name = $info->{dist_name};
    $cpan_file = $info->{cpan_file};
  }
  my $name;
 TRY: {
    (not $dist and (-e 'Makefile.PL' || -e 'Build.PL')) and do {
      last TRY if ($name = $self->from_cpan());
    };
    ($dist =~ /$PPM::Make::Util::ext$/) and do {
      last TRY if ($name = $self->from_cpan($dist));
    };
    ($dist_name) and do {
      last TRY if ($name = $self->from_repository($dist_name));
    };
    ($cpan_file) and do {
      my @cpan_mirrors = url_list();
      my $url = $cpan_mirrors[0] . '/authors/id/' . $cpan_file;
      last TRY if ($name = $self->from_cpan($url));
    };
    last TRY if ($name = $self->from_cpan($dist));
    die qq{Cannot build "$dist"};
  }
  $self->{name} ||= $name;
  my $prereqs = $self->{files}->{$name}->{prereqs};
  if ($prereqs and (ref($prereqs) eq 'ARRAY')) {
    foreach my $item(@$prereqs) {
      $self->make_package($item->{dist_name}, $item);
    }
  }
  return 1;
}

sub get_info {
  my ($self, $dist) = @_;
  return if (-f $dist or $dist =~ /^$PPM::Make::Util::protocol/ or $dist =~ /$PPM::Make::Util::ext$/);
  my $search = $self->{search};
  $dist =~ s{::}{-}g;
  {
    if ($search->search($dist, mode => 'dist')) {
      my $results = $search->{dist_results}->{$dist};
      my $cpan_file = cpan_file($results->{cpanid}, $results->{dist_file});
      my $info = {cpan_file => $cpan_file, dist_name => $results->{dist_name}};
      return $info;
    }
    else {
      $search->search_error(qq{Cannot obtain information on '$dist'});
    }
  }
  return;
}

sub from_cpan {
  my ($self, $pack) = @_;
  my $ppm = PPM::Make->new(%{$self->{opts}}, dist => $pack, no_cfg => 1);
  $ppm->make_ppm();
  my $name;
  if (defined $ppm->{ppd} and defined $ppm->{codebase}) {
    ($name = $ppm->{ppd}) =~ s{\.ppd$}{};
    (my $ar = $ppm->{codebase}) =~ s{.*/([^/]+)$}{$1};
    $self->{files}->{$name} = {cwd => $ppm->{cwd},
                               ppd => $ppm->{ppd},
                               ar => $ar};
  }
  else {
    return;
  }
  my @full_prereqs = keys %{$ppm->{args}->{PREREQ_PM}};
  return $name unless (scalar @full_prereqs > 0);
  my @prereqs = ();
  foreach my $mod(@full_prereqs) {
    push @prereqs, $mod unless ($mod eq 'perl' or is_core($mod));
  }
  my $search = $self->{search};
  {
    if (scalar @prereqs > 0) {
      my $matches = $search->search(\@prereqs, mode => 'mod');
      if ($matches and (ref($matches) eq 'HASH')) {
        foreach my $mod (keys %$matches) {
              my $item = $matches->{$mod};
              my $dist_name = $item->{dist_name};
              next if is_ap_core($dist_name);
              my $cpan_file = cpan_file($item->{cpanid}, $item->{dist_file});
              push @{$self->{files}->{$name}->{prereqs}}, 
                {dist_name => $dist_name,
                cpan_file => $cpan_file};
        }
      }
    }
  }
  return $name;
}

sub from_repository {
  my ($self, $pack) = @_;
  return if (-f $pack or $pack =~ /^$PPM::Make::Util::protocol/ or $pack =~ /$PPM::Make::Util::ext$/);
  my $cwd = $self->{build_dir};
  $pack =~ s/::/-/g;
  my $reps = $self->{opts}->{reps};
  return unless $reps;
  my @reps = ref($reps) eq 'ARRAY' ? @$reps : ($reps);
  chdir($cwd) or die qq{Cannot chdir to $cwd: $!};

  my $dist_name = $pack;
  my $ppd_local = $dist_name . '.ppd';
  my $arch = $self->{arch};
  my ($url, $ppd_remote, $info);
  foreach my $item (@reps) {
    if ($item !~ /^$PPM::Make::Util::protocol/) {
      $ppd_remote = catfile($item, $ppd_local);
      if (-f $ppd_remote) {
        copy($ppd_remote, $ppd_local) or do {
          warn qq{Cannot copy "$ppd_remote" to "$ppd_local": $!};
          return;
        };
        $info = parse_ppd(catfile($cwd, $ppd_local), $arch);
        next unless ($info and (ref($info) eq 'HASH'));
        my $info_arch = $info->{ARCHITECTURE}->{NAME};
        if ($info_arch  and ($info_arch eq $arch)) {
          $url = $item;
          print qq{\nUsing $ppd_local from $url\n};
          last;
        }
      }
    }
    else {
      $item .= '/' unless $item =~ m{/$};
      my $ppd_remote = $item . $ppd_local;
      if (head($ppd_remote)) {
        if (mirror($ppd_remote, $ppd_local)) {
          $info = parse_ppd(catfile($cwd, $ppd_local), $arch);
          next unless ($info and (ref($info) eq 'HASH'));
          my $info_arch = $info->{ARCHITECTURE}->{NAME};
          if ($info_arch  and ($info_arch eq $arch)) {
            $url = $item;
            print qq{\nUsing $ppd_local from $url\n};
            last;
          }
        }
      }
    }
  }
  return unless (-f $ppd_local);
  return unless ($info and (ref($info) eq 'HASH'));

  my $codebase = $info->{CODEBASE}->{HREF};
  (my $ar_local = $codebase) =~ s{.*?/([^/]+)$}{$1};
  if ($codebase =~ /^$PPM::Make::Util::protocol/) {
    my $ar_remote = $codebase;
    return unless mirror($ar_remote, $ar_local);
  }
  elsif ($url !~ /^$PPM::Make::Util::protocol/) {
    my $ar_remote = catfile($url, $codebase);
    if (-f $ar_remote) {
      copy($ar_remote, $ar_local) or do {
        warn qq{Cannot copy "$ar_remote" to "$ar_local": $!};
        return;
      };
    }
  }
  else {
    my $ar_remote = $url . $codebase;
    return unless mirror($ar_remote, $ar_local);
  }
  unless (-f $ar_local) {
    warn qq{Cannot get "$ar_local"};
    return;
  }
  (my $name = $ppd_local) =~ s{\.ppd$}{};
  $self->{files}->{$name} = {cwd => $cwd,
                             ppd => $ppd_local,
                             ar => $ar_local};

  my $deps = $info->{DEPENDENCY};
  return 1 unless ($deps and (ref($deps) eq 'ARRAY'));
  foreach my $item (@$deps) {
    my $dist_name = $item->{NAME};
    next if is_ap_core($dist_name);
    push @{$self->{files}->{$name}->{prereqs}}, {dist_name => $dist_name};
  }
  return $name;
}

sub fetch_prereqs {
  my ($self, $ppm) = @_;
  die qq{Please supply a PPM::Make object} 
    unless ($ppm and (ref($ppm) eq 'PPM::Make'));
  
  my @full_prereqs = keys %{$ppm->{args}->{PREREQ_PM}};
  my @prereqs = ();
  foreach my $mod(@full_prereqs) {
    push @prereqs, $mod unless ($mod eq 'perl' or is_core($mod));
  }
  my $search = $self->{search};
  {
    if (scalar @prereqs > 0) {
      my $matches = $search->search(\@prereqs, mode => 'mod');
      if ($matches and (ref($matches) eq 'HASH')) {
        my @cpan_mirrors = url_list();
        foreach my $mod(keys %$matches) {
            next if is_ap_core($matches->{$mod}->{dist_name});
            print qq{\nFetching prerequisite "$mod"\n};
            my $download = $cpan_mirrors[0] . '/authors/id/' . 
              $matches->{$mod}->{download};
            my $ppm = PPM::Make->new(%{$self->{opts}},
                                         no_cfg => 1, dist => $download);
            $ppm->make_ppm();
            (my $name = $ppm->{ppd}) =~ s{\.ppd$}{};
            $self->{files}->{$name} = {cwd => $ppm->{cwd},
                                           ppd => $ppm->{ppd},
                                           ar => $ppm->{codebase}};
            $self->fetch_prereqs($ppm);
        }
      }
    }
  }
}

sub make_zip {
  my $self = shift;
  my $cwd = $self->{build_dir};
  chdir($cwd) or die qq{Cannot chdir to $cwd: $!};
  my $files = $self->{files};
  my $bundle_name = $self->{name};
  foreach my $name(keys %$files) {
    my $item = $self->{files}->{$name};
    my $item_cwd = $item->{cwd};
    next if ($item_cwd eq $cwd);
    my $ppd = $item->{ppd};
    my $ar = $item->{ar};
    copy(catfile($item_cwd, $ppd), $ppd)
      or die qq{Cannot copy $ppd from $item_cwd: $!};
    copy(catfile($item_cwd, $ar), $ar)
      or die qq{Cannot copy $ar from $item_cwd: $!};
  }
  my $ppd_master = $self->{files}->{$bundle_name}->{ppd};
  my $zipdist = $self->{zipdist} ||
    ($bundle_name =~ /^(Bundle|Task)/ ?
     $bundle_name : ('Bundle-' . $bundle_name)) . '.zip';
  if (-f $zipdist) {
    unlink $zipdist or warn "Could not unlink $zipdist: $!";
  }
  my $readme = 'README';
  open(my $fh, '>', $readme) or die "Cannot open $readme: $!";
  print $fh <<"END";
To install this ppm package, run the following command
in the current directory:

   ppm rep add temp_repository file://C:/Path/to/current/directory
   ppm install $ppd_master
   ppm rep del temp_repository_id_number

END
  close $fh;

  my %contents = ($readme => 'README');
  foreach my $name(keys %$files) {
    my $item = $self->{files}->{$name};
    my $item_cwd = $item->{cwd};
    my $ppd = $item->{ppd};
    my $ar = $item->{ar};
    my $ppd_orig = $ppd . '.orig';
    rename($ppd, $ppd_orig) or die "Cannot rename $ppd to $ppd_orig: $!";
    open(my $rfh, '<', $ppd_orig) or die "Cannot open $ppd_orig: $!";
    open(my $wfh, '>', $ppd) or die "Cannot open $ppd: $!";
    while (my $line = <$rfh>) {
      $line =~ s{HREF=\".*/([^/]+)\"}{HREF="$1"};
      print $wfh $line;
    }
    close($rfh);
    close($wfh);
    $contents{$ar} = $ar;
    $contents{$ppd} = $ppd;
  }

  my $zip = $self->{has}->{zip};
  print qq{\nCreating $zipdist ...\n};
  if ($zip eq 'Archive::Zip') {
    my $arc = Archive::Zip->new();
    foreach (sort keys %contents) {
      print "Adding $contents{$_}\n";
      unless ($arc->addFile($_, $contents{$_})) {
        die "Failed to add $_";
      }
    }
    die "Writing to $zipdist failed" 
      unless $arc->writeToFileNamed($zipdist) == Archive::Zip::AZ_OK();
  }
  else {
    my @args = ($zip, $zipdist, keys %contents);
    print "@args\n";
    system(@args) == 0 or die "@args failed: $?";
  }
  unless ($self->{opts}->{upload}) {
    my $cwd = $self->{cwd};
    copy($zipdist, $cwd) or warn qq{Cannot copy $zipdist to $cwd: $!};
    print qq{\nCopying $zipdist to $cwd.\n};
  }
  $self->{zipdist} = $zipdist;
  return 1;
}

sub upload_zip {
  my $self = shift;
  my $upload = $self->{opts}->{upload};
  my $bundle_loc = $upload->{bundle};
  my $zipdist = $self->{zipdist};
  my $cwd = $self->{build_dir};
  chdir($cwd) or die qq{Cannot chdir to $cwd: $!};

  if (my $host = $upload->{host}) {
    print qq{\nUploading $zipdist to $host ...\n};
    my ($user, $passwd) = ($upload->{user}, $upload->{passwd});
    die "Must specify a username and password to log into $host"
      unless ($user and $passwd);
    my $ftp = Net::FTP->new($host)
      or die "Cannot connect to $host: $@";
    $ftp->login($user, $passwd)
      or die "Login for user $user failed: ", $ftp->message;
    $ftp->cwd($bundle_loc) or die
      "cwd to $bundle_loc failed: ", $ftp->message;
    $ftp->binary;
    $ftp->put($zipdist)
      or die "Cannot upload $zipdist: ", $ftp->message;
    $ftp->quit;
  }
  else {
    print qq{\nCopying $zipdist to $bundle_loc\n};
    copy($zipdist, "$bundle_loc/$zipdist") 
      or die "Cannot copy $zipdist to $bundle_loc: $!";
  }
  print qq{Done!\n};
  return 1;
}

1;

__END__

=head1 NAME

PPM::Make::Bundle - make a bundle of ppm packages

=head1 SYNOPSIS

  my $bundle = PPM::Make::Bundle->new(%opts);
  $bundle->make_bundle();

=head1 DESCRIPTION

C<PPM::Make::Bundle> is used to build a bundled zip file of a
package and all of it's required prerequisites. It will
first search through a list of specified repositories to
see if a required package is present there, and if not,
will use C<PPM::Make> to build one.
See L<PPM::Make> for a discussion of details on
how the ppm package is built, as well as the available
options. The bundled zip file will be placed in the
current directory from where it is invoked, unless
a C<bundle> key to C<upload> of C<PPM::Make> specifies
where to upload bundled files.

The options accepted for C<PPM::Make::Bundle> include
those of L<PPM::Make>. If a C<dist> option is not given,
it will be assumed that one is in a valid CPAN distribution
directory, and attempt to build a zipped bundle file based
on that distribution. Additional options specific
to C<PPM::Make::Bundle> are

=over

=item bundle_name =E<gt> $bundle_name

This options specifes the name of the zip file containing
all of the bundled ppm packages. If this is not specified,
a default of C<Bundle-dist_name.zip> will be used, where
C<dist_name> is the name of the main distribution being
built.

=item no_upload =E<gt> 1

By default, if a required package is built by C<PPM::Make>,
and if the configuration file specifies that such ppm
packages are to be uploaded to a repository, this upload
will take place. The C<no_upload> option specifies that
such individual package uploads not take place, although
the bundled zip file will still be uploaded, if specified.

=item reps =E<gt> \@repositories

This specifies a list of repositories to search for
needed ppm packages.

=item clean =E<gt> 1

The ppm packages are placed in a temporary directory
for eventual inclusion in the zipped bundle file.
The C<clean> option specifies that this temporary
directory be removed after the bundle file is built.

=back

=head1 BUGS

The needed prerequisites will be followed recursively;
however, for packages built with C<PPM::Make>,
the tests will be run before this has taken place,
which probably will result in build failures. Future
versions will address this problem. In the meantime,
you may want to use the C<ignore> option, to ignore
failing tests, or the C<skip> option, to skip running
the tests.

=head1 COPYRIGHT

This program is copyright 2006 by 
Randy Kobes <r.kobes@uwinnipeg.ca>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM::Make> and L<PPM>.

=cut
