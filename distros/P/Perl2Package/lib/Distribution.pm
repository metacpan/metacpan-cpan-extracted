package Distribution;
use Symbol;

$Distribution::TMP_DIR = '/tmp';
foreach my $dir (qw(/var/tmp /tmp C:/Windows/temp D:/Windows/temp)) {
    if (-d $dir) {
	$Distribution::TMP_DIR = $dir;
	last;
    }
}

#$Distribution::COPYRIGHT = "Artistic or GNU General Public License,"
#    . " as specified by the Perl README";
$Distribution::COPYRIGHT = "Probably the same terms as perl.  Check.";

sub new {
    my $proto = shift;
    my $self = { @_ };
    bless($self, ref($proto) || $proto);

    if ($self->{'source'}  &&
	$self->{'source'} =~ /(.*(?:\/|\\))?(.*)-(.+)
                              (\.(tar\.gz|tgz|zip))$/x) {
	$self->{'package-name'} ||= $2;
	$self->{'package-version'} ||= $3;
    }

    $self->{'name'} = $self->{'package-name'}
      or die "Missing package name";
    $self->{'version'} = $self->{'package-version'}
      or die "Missing package version";

    # this used to be File::Spec->curdir() - I don't understand why.  Michael
    # cwd() seems useful since it lets us use the directory we start in.
    $self->{'source_dirs'} ||= [ Cwd::cwd() ];
    $self->{'default_setup_dir'} = "$self->{'name'}-$self->{'version'}";
    $self->{'setup-dir'} ||= $self->{'default_setup_dir'};
    $self->{'build_dir'} = File::Spec->curdir();
    $self->{'make'} ||= $Config::Config{'make'};
    $self->{'build-root'} ||= File::Spec->catdir($Distribution::TMP_DIR,
						 $self->{'setup-dir'});
    $self->{'copyright'} ||= $Distribution::COPYRIGHT;
    $self->{'summary'} ||= "The Perl package $self->{'name'}";

    if (!defined($self->{'start_perl'} = $self->{'perl-path'})) {
	$self->{'start_perl'} = substr($Config::Config{'startperl'}, 2)
	  if defined $Config::Config{'startperl'};
    }
    $self->{'start_perl'} = undef
      if defined($self->{'start_perl'}) && $self->{'start_perl'} eq 'undef';

    $self;
}


sub MakeDirFor {
    my($self, $file) = @_;
    my $dir = File::Basename::dirname($file);
    if (! -d $dir) {
	print STDERR "Making directory $dir\n" if $self->{'verbose'};
        File::Path::mkpath($dir, 0, 0755)  ||
	    die "Failed to create directory $dir: $!";
    }
}

# Extract - unpack the distribution so we can examine it.  Also initialise
# the variable saying the filename of the source.


sub Extract {
    my $self = shift;  my $dir = shift || File::Spec->curdir();
    print STDERR "Extract files in $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";

    # Look for the source file - this logic should really go somewhere else e.g. new

    my $source = $self->{'source'} || die "Missing source definition";
    if (! -f $source) {
	foreach my $dir (@{$self->{'source_dirs'}}) {
	    print STDERR "Looking for $source in $dir\n" if $self->{'debug'};
	    my $s = File::Spec->catfile($dir, $source);
	    if (-f $s) {
		print STDERR "Found $source in $dir\n" if $self->{'debug'};
		$source = $s;
		$self->{source_path}=$s;
		last;
	    } elsif ( -e $s ) {
		warn "Ignoring non plain file $source in $dir\n";
	    }
	}
    } else {
	$self->{source_path}=$source;
    }

    $self->{source_base} = File::Basename::basename($source);

    -e $source or do {
	print STDERR "Source file doesn't exist in any sourcedir; pwd ",
	  `pwd`, "\n", join ( " ", @{$self->{'source_dirs'}} ), "\n";
	die "no source file $source";
    };

    $dir = $self->{'setup-dir'};
    if (-d $dir) {
	print STDERR "Removing directory $dir" if $self->{'verbose'};
	File::Path::rmtree($dir, 0, 0) unless $self->{'debug'};
	-e $dir && die "failed to delete directory " .
	  ( File::Spec->file_name_is_absolute($dir)
	    ? ($dir) : File::Spec->catdir( (File::Spec->curdir() , "$dir") ));
    }

    print STDERR "Extracting $source\n" if $self->{'verbose'};
    my $fallback = 0;
    eval { require Archive::Tar; require Compress::Zlib; };
    if ($@) {
	$fallback = 1;
    } else {
	if (Archive::Tar->can("extract_archive")) {
	    if (not defined(Archive::Tar->extract_archive($source))) {
		# Failed to extract: wonder why?
		for (Archive::Tar->error()) {
		    if (/Compression not available/) {
			# SuSE's Archive::Tar does this, even though
			# Compress::Zlib is installed.  Oh well.
			# 
			$fallback = 1;
		    } else {
			die "Failed to extract archive $source: $_";
		    }
		}
	    }
	} else {
	    my $tar = Archive::Tar->new();
	    my $compressed = $source =~ /\.(?:tgz|gz|z|zip)$/i;
	    my $numFiles = $tar->read($source, $compressed);
	    die("Failed to read archive $source")
	      unless $numFiles;
	    die("Failed to store contents of archive $source: ", $tar->error())
	      if $tar->extract($tar->list_files());
	}
    }

    if ($fallback) {
	# Archive::Tar is not available; fallback to tar and gzip
	my $command = $^O eq "MSWin32" ?
	  "tar xzf $source" :
	    "gzip -cd $source | tar xf - 2>&1";
	my $output = `$command`;
	die "Archive::Tar and Compress::Zlib are not available\n"
	  . " and using tar and gzip failed.\n"
	    . " Command was: $command\n"
	      . " Output was: $output\n"
		if $output;
    }
}

#RMFiles removes files which match a given regexp and fixes the
#Manifest file to reflect these changes..  Needless to say, if this
#feature is used then we have to hope the user knows why this is a
#good idea :-)

sub RMFiles {
    my $self = shift;
    my $dir = shift || ( $self->{'built-dir'} );

    my $old_dir = Cwd::cwd();
    eval {
	print STDERR "Removing unwanted files in $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	my $fh = Symbol::gensym();
	open ($fh, "<MANIFEST") || die "Failed to open MANIFEST: $!";
	my @manifest=<$fh>;
	close $fh;
	my $re = $self->{'rm-files'};
	print STDERR "Removing files matching ".$self->{'rm-files'}." in $dir\n"
	  if $self->{'verbose'};
	for (my $i=$#manifest; $i > -1 ; $i--) {
	    chomp $manifest[$i];
	    print STDERR "checking", $manifest[$i],"\n" if $self->{'verbose'};
	    $manifest[$i] =~ m/$re/o or next;
	    print STDERR "Removing ", $manifest[$i],"\n" if $self->{'verbose'};
	    unlink $manifest[$i] 
	      || die "Failed to unlink " . $manifest[$i] . " " . $!;
	    splice (@manifest,$i,1);
	}
	open ($fh, ">MANIFEST") || die "Failed to open MANIFEST: $!";
	print $fh join ("\n", @manifest); #newlinse still included
	close $fh;
    };
    my $status = $@;
    print STDERR "Returning directory to $old_dir\n" if $self->{'verbose'};
    chdir $old_dir;
    die $@ if $status;
}

sub Modes {
    my $self = shift; my $dir = shift || File::Spec->curdir();

    return if $^O eq "MSWin32";

    print STDERR "Fixing file permissions in $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";
    my $handler = sub {
	my($dev, $ino, $mode, $nlink, $uid, $gid) = stat;
	my $new_mode = 0444;
	$new_mode |= 0200 if $mode & 0200;
	$new_mode |= 0111 if $mode & 0100;
	chmod $new_mode, $_
	  or die "Failed to change mode of $File::Find::name: $!";
	if ($self->{chown}) {
	    chown 0, 0, $_
	      or die "Try --nochown; failed chown of $File::Find::name: $!";
	}
    };

    #    $dir = File::Spec->curdir();
    $dir = Cwd::cwd();
    print STDERR "Returning to directory  $dir\n" if $self->{'verbose'};
    File::Find::find($handler, $dir);
}

sub Prep {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Running Prep in $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	if (-d $self->{'setup-dir'}) {
	    print STDERR "Removing directory: $self->{'setup-dir'}\n"
	      if $self->{'verbose'};
	    #give an absolute path for better error messages.
	    File::Path::rmtree(Cwd::cwd() . '/' . $self->{'setup-dir'}, 0, 0);
	    -e $self->{'setup-dir'} && die "failed to delete directory " .
	      ( File::Spec->file_name_is_absolute($self->{'setup-dir'})
		? ($self->{'setup-dir'})
		: File::Spec->catdir( (Cwd::cwd() ,
				       $self->{'setup-dir'}) ) );
	}
	$self->Extract();
	$self->RMFiles() if $self->{'rm-files'};
	$self->Modes($self->{'setup-dir'});
    };
    my $status = $@;
    print STDERR "Returning to directory $old_dir\n" if $self->{'verbose'};
    chdir $old_dir;
    die $@ if $status;
}

sub PerlMakefilePL {
    my $self = shift; my $dir = shift || File::Spec->curdir();
    print STDERR "PerlMakeFile in drectory $dir\n" if $self->{'verbose'};
    chdir $dir || die "Failed to chdir to $dir: $!";

    #note Makefile.PL can return undef (no reason not to) which means that 
    #we can't use the return value from do to trap errors; also $! can be set 
    #by any error which occurs inside the Makefile.PL and so we can't tell the 
    #difference between an internal error and an external one using do

# fails in the case of Makefile.PL returns undef
#   my @command = ($^X, @{$self->{'makeperlopts'}}, 
#		   "-e",  "do 'Makefile.PL' or die $@;", 
#		   @{$self->{'makemakeropts'}});

# fails in the case of IO error inside do
#   my @command = ($^X, @{$self->{'makeperlopts'}}, 
#		   "-e",  "do 'Makefile.PL'; " . 'die $! if $!; die $@ if $@; ', 
#		    @{$self->{'makemakeropts'}});

    #this workaround from Ed Avis should deal with all that

    my @command =
      ($^X, @{$self->{'makeperlopts'}}, "-e",
       '$f = "Makefile.PL"; open FH, $f or die "$f: $!"; { local $/; $code = <FH> } eval $code; die $@ if $@',
       @{$self->{'makemakeropts'}});

    # but, FIXME - find a simpler form or fix perl :-)

    print STDERR "Creating Makefile: ". join ("| |",@command) ." \n" 
      if $self->{'verbose'};
    exit 1 if system @command;
}

sub Make {
    my $self = shift;
    if (my $dir = shift) {
	print STDERR "Calling Make in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
    }
    my $command = "$self->{'make'} " . ($self->{'makeopts'} || '');
    print STDERR "Running Make: $command\n";
    exit 1 if system $command;

    if ($self->{'runtests'}) {
	$command .= " test";
	print STDERR "Running Make Test: $command\n";
	exit 1 if system $command;
    }
}

sub ReadLocations {
    my %vars;
    my $fh = Symbol::gensym();
    open($fh, "<Makefile") || die "Failed to open Makefile: $!";
    while (my $line = <$fh>) {
	# Skip comments and/or empty lines
	next if $line =~ /^\s*\#/ or $line =~ /^\s*$/;
	if ($line =~ /^\s*(\w+)\s*\=\s*(.*)\s*$/) {
	    # Variable definition
	    my $var = $1;
	    my $val = $2;
	    $val =~ s/\$(\w)/defined($vars{$1})?$vars{$1}:''/gse;
	    $val =~ s/\$\((\w+)\)/defined($vars{$1})?$vars{$1}:''/gse;
	    $val =~ s/\$\{(\w+)\}/defined($vars{$1})?$vars{$1}:''/gse;
            $vars{$var} = $val;
	}
    }
    \%vars;
}

#FIXME: Makewrite and UnMakewrite
#
#These two functions make a file temporarily writeable and then reverse
#the changes so that we can make fixes but still have the correct permissions
#in the rpm

sub Makewrite {
    my $filename=shift;
    -w $filename and return undef;
    my @stat=stat($filename);
    chmod 0700, $filename or die "couldn't make file writable $filename";
    return \@stat;
}

sub UnMakewrite {
    my $filename=shift;
    my $oldperm=shift;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,
	$ctime,$blksize,$blocks) = @$oldperm;
    return chmod $mode & 07777, $filename;
}

sub AdjustPaths {
    my $self = shift; my $build_root = shift;
    my $adjustPathsSub = sub {
	my $f = $_;
	return unless -f $f && ! -z _;
	my $fh = Symbol::gensym();
	my $origstate=Makewrite($f);
 	open($fh, "+<$f")
 	  or ((chmod(0644, $f) || die "Failed to chmod $File::Find::name: $!")
 	      && open($fh, "+<$f"))
 	    or die "Failed to open $File::Find::name: $!";
	local $/ = undef;
	my $contents;
	die "Failed to read $File::Find::name: $!"
	  unless defined($contents = <$fh>);
	my $modified;
	if ($self->{'start_perl'}) {
	    $contents =~ s/^\#\!(\S*perl\S*)/\#\!$self->{'start_perl'}/si;
	    $modified = 1;
	}
	if ($contents =~ s/\Q$build_root\E//gs) {
	    $modified = 1;
	}
	if ($modified) {
	    seek($fh, 0, 0) or die "Failed to seek in $File::Find::name: $!";
	    (print $fh $contents)
	      or die "Failed to write $File::Find::name: $!";
	    truncate $fh, length($contents)
	      or die "Failed to truncate $File::Find::name: $!";
	}
	close($fh) or die "Failed to close $File::Find::name: $!";
	defined $origstate && UnMakewrite($f,$origstate);
    };
    File::Find::find($adjustPathsSub, $self->{'build-root'});
}


sub MakeInstall {
    my $self = shift;
    if (my $dir = shift) {
	print STDERR "Running MakeInstall in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
    }

    my $locations = ReadLocations();

    my $command = "$self->{'make'} " . ($self->{'makeopts'} || '')
      . " install";
    foreach my $key (qw(INSTALLPRIVLIB INSTALLARCHLIB INSTALLSITELIB
                        INSTALLSITEARCH INSTALLBIN INSTALLSCRIPT
			INSTALLMAN1DIR INSTALLMAN3DIR)) {
	my $d = File::Spec->canonpath(File::Spec->catdir($self->{'build-root'},
							 $locations->{$key}));
	$command .= " $key=$d";
    }
    print STDERR "Running Make Install: $command\n" if $self->{'verbose'};
    exit 1 if !$self->{'debug'} and system $command;

    print STDERR "Adjusting Paths in $self->{'build-root'}\n";
    $self->AdjustPaths($self->{'build-root'});

    my($files, $dirs) = $self->Files($self->{'build-root'});
    my $fileList = '';
    foreach my $dir (sort keys %$dirs) {
	next if $dirs->{$dir};
	$fileList .= "%dir $dir\n";
    }

    if ($self->{compress_manpages}) {
	foreach my $file (sort keys %$files) {
	    #FIXME: this regexp is not guaranteed.  (Maybe matching
	    #'/man/man\d/' would be better?)
	    ($file =~ m,/usr/(.*/|)man/, ) and ($file .= ".gz");
	    $fileList .= "$file\n";
	}
    } else {
	foreach my $file (sort keys %$files) {
	    $fileList .= "$file\n";
	}
    }

    my($filelist_path, $specs_path) = $self->FileListPath();
    if ($filelist_path) {
	my $fh = Symbol::gensym();
	(open($fh, ">$filelist_path")  and  (print $fh $fileList)
	 and  close($fh))
	  or  die "Failed to create list of files in $filelist_path: $!";
    }
    $specs_path;
}

# Build -
#
#Fully builds the perl module so that we can extract full information
#from it. This is not to be used for actual building in the final RPM
#any more.
#

sub Build {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Running Build() in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	$self->PerlMakefilePL($self->{'setup-dir'});
	$self->Make();
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    $self->{"built-dir"}=$self->{'build_dir'} . '/' . $self->{'setup-dir'};
}

sub CleanBuildRoot {
    my $self = shift; my $dir = shift || die "Missing directory name";
    print STDERR "Cleaning build root $dir\n" if $self->{'verbose'};
    File::Path::rmtree($dir, 0, 0) unless $self->{'debug'};
    -e $dir && die "failed to delete directory " .
      ( File::Spec->file_name_is_absolute($dir)
	? ($dir) : File::Spec->catdir( (Cwd::cwd() , "$dir") ));
}

sub Install {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $filelist;
    eval {
	my $dir = $self->{'build_dir'};
	print STDERR "Running Install() in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	#originally we deleted all files.  This is now done at the start of
	#%install meaning that the user can add files to the RPM
	# $self->CleanBuildRoot($self->{'build-root'});
	$filelist = $self->MakeInstall($self->{'setup-dir'});
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    $filelist;
}

1;
