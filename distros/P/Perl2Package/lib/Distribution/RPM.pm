package Distribution::RPM;

use File::Copy;

@Distribution::RPM::ISA = qw(Distribution);

{
    my($source_dir, $build_dir, $specs_dir, $topdir);

    sub Init {
	my $self = shift; my $fatal = shift;
	die "Self must be a reference" unless (ref $self);
	die "Self must be a hash reference" unless ($self =~ m/HASH/);
	my $rpm_version;

	my $last_rpm=4;		#latest version of RPM we have seen
	my $next_rpm=$last_rpm+1; #latest version of RPM we have seen

	if (defined $self->{"rpm-version"}) {
	    $rpm_version = $self->{"rpm-version"};
	} else {
	    my $rpm_version_string = `rpm --version`;
	    if ($rpm_version_string =~ /rpm\s+version\s+([2-$last_rpm])\.+/i) {
		$rpm_version=$1;
	    } elsif ($rpm_version_string =~ /rpm\s+version\s+[10]\.+/i) {
		die "Cannot handle RPM before version 2: " .
		  ($rpm_version_string || "");
	    } elsif ($rpm_version_string
		     =~ /rpm\s+version\s+([$next_rpm-9]|\d\d+)/i) {
		$rpm_version=$last_rpm;
		warn "Your RPM is a new version.  I'm going to pretend it's "
		  . "rpm $last_rpm";
	    } elsif ($rpm_version_string =~ /rpm\s+version\s/i) {
		$rpm_version=$last_rpm;
		warn "RPM version unkown.  I'm going to pretend it's $last_rpm";
	    } else {
		die "RPM --version option didn't work as expected..";
	    }
	}
	$self->{"rpm-version"}=$rpm_version;

      CASE: {
	    $rpm_version == 2 && do { $self->handle_rpm_version_2() ; last CASE;};
	    $rpm_version == 3 && do { $self->handle_rpm_version_3() ; last CASE;};
	    $rpm_version == 4 && do { $self->handle_rpm_version_4() ; last CASE;};
	    die "RPM version should be between 2 and $last_rpm";
	}

	return init_directories();
    }

    sub init_directories {
	if (!$source_dir) {
	    $source_dir = $ENV{'RPM_SOURCE_DIR'} if $ENV{'RPM_SOURCE_DIR'};
	    $build_dir = $ENV{'RPM_BUILD_DIR'} if $ENV{'RPM_BUILD_DIR'};

	    $source_dir=`rpm --eval '%_sourcedir'` unless $source_dir;
	    chomp $source_dir;
	    die "Failed to work out source_dir from rpm" unless $source_dir;
	    $specs_dir=`rpm --eval '%_specdir'` unless $specs_dir;
	    chomp $specs_dir;
	    die "Failed to work out specs_dir from rpm" unless $specs_dir;
	    $build_dir=`rpm --eval '%_builddir'` unless $build_dir;
	    chomp $build_dir;
	    die "Failed to work out build_dir from rpm" unless $build_dir;
	}
	if (!$topdir) {
	    #if using "OpenLinux", please upgrade to RedHat or Fedora
	    #(or SUSE).  That distribution is no longer supported and
	    #never will be again.
	    foreach my $dir ("redhat", "packages") {
		if (-d "/usr/src/$dir") {
		    $topdir = "/usr/src/$dir";
		    last;
		}
	    }
	    die "Unable to determine RPM topdir" unless $topdir;
	}
	$source_dir ||= "$topdir/SOURCES";
	$specs_dir ||= "$topdir/SPECS";
	$build_dir ||= "$topdir/BUILD";
	return ($source_dir, $build_dir, $specs_dir);
    }

    sub handle_rpm_version_2 {
	my $self=shift;
	my $rpm_output = `rpm --showrc`;
	foreach my $ref (['topdir', \$topdir],
			 ['specdir', \$specs_dir],
			 ['sourcedir', \$source_dir],
			 ['builddir', \$build_dir]) {
	    my $var = $ref->[0];
	    if ($rpm_output =~ /^$var\s+\S+\s+(.*)/m) {
		${$ref->[1]} ||= $1;
	    }
	}
    }

    sub handle_rpm_version_3 {
	my $self=shift;
	my $rpm_output = `rpm --showrc`;
	my $varfunc;
	$varfunc = sub {
	    my $var = shift;
	    my $val;
	    if ($rpm_output =~ /^\S+\s+$var\s+(.*)/m) {
		$val = $1;
		while ($val =~ /\%\{(\S+)\}/) {
		    my $vr = $1;
		    my $vl = &$varfunc($vr);
		    if (defined($vl)) {
			$val =~ s/^\%\{\Q$vr\E\}/$vl/gs;
		    } else {
			return undef;
		    }
		}
		return $val;
	    }
	    return undef;
	};

	sub handle_rpm_version_4 {
	    my $self=$_[0];
	    my $ret=handle_rpm_version_3(@_);
	    $self->{compress_manpages}=1;
	    $self->{'find-requires'}=1 unless defined $self->{'find-requires'};
	    return $ret;
	}

	foreach my $ref (['_topdir', \$topdir],
			 ['_specdir', \$specs_dir],
			 ['_sourcedir', \$source_dir],
			 ['_builddir', \$build_dir]) {
	    ${$ref->[1]} ||= &$varfunc($ref->[0]);
	}
    }

}

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    ($self->{'rpm-source-dir'}, $self->{'rpm-build-dir'},
     $self->{'rpm-specs-dir'}) = $self->Init(1);
    # rpm-data-dir is a directory for perl authors to put RPM related
    # info into.  The name is important since it must be common
    # across all perl modules and must not be used for reasons other
    # than setting up RPM builds.  For this reason it should be agreed
    # with the rest of the perl community.
    $self->{'rpm-data-dir'} = 'pkg-data-rpm';
    if ($self->{'data-dir'}) {
	my $dir=$self->{'data-dir'}/$self->{'package-name'} ;
	if (-d $dir) {
	    $self->{'user-data-dir'} = $dir;
	    #FIXME: if we do bulk building then this would be a
	    #normal case.
	    warn "Data dir $dir found\n" if $self->{'verbose'};
	} else {
	    print STDERR "Didn't find data dir $dir\n" if $self->{'verbose'};
	}
    }
    $self->{'rpm-group'} ||= 'Development/Languages/Perl';
    push(@{$self->{'source_dirs'}}, $self->{'rpm-source-dir'});
    $self->{'build_dir'} = $self->{'rpm-build-dir'};
    $self;
}

#FIXME: Files should also differentiate
#  configuration files, at least any in /etc
#  documentation??

#this function returns four hashes
#%d - directories in the build
#%f - files in the build
#%dirs - the same as %d but with full path
#%files - the same as %f but with full path
# the keys give the name.
#
# the value will be 1 for files
# for directories 0 means a directory to be included.  1 means a directory
# that should be skipped

# given that makerpm dynamically builds the file list during the build
# process, this function is mainly

sub Files {
    my $self = shift;  my $buildRoot = shift;
    if (not -d $buildRoot) {
	warn "directory $buildRoot does not exist please report and/or investigate\n";
	return ({}, {}, {}, {});
    }
    my(%files, %dirs);
    my $findSub = sub {
	#FIXME: better handling of perllocal.pod might be desirable (why???).
	#For example, we could store its contents in $self and then output it
	#into the specfile in the postinst script.  This could then add it
	#to the live systems perllocal.pod.

	if (-d $_) {
	    $dirs{$File::Find::name} ||= 0;
	    $dirs{$File::Find::dir} = 1;
	} elsif (-f _) {
	    $dirs{$File::Find::dir} = 1;
	    $File::Find::name =~ m,/usr/lib/perl\d+/.*/perllocal.pod, and return;
	    $files{$File::Find::name} = 1;
	} else {
	    die "Unknown file type: $File::Find::name";
	}
    };
    File::Find::find($findSub, $buildRoot);

    # Remove the trailing buildRoot
    my(%f, %d);
    while (my($key, $val) = each %files) {
	$key =~ s/^\Q$buildRoot\E//;
	$f{$key} = $val
    }
    while (my($key, $val) = each %dirs) {
	$key =~ s/^\Q$buildRoot\E//;
	$d{$key} = $val
    }
    (\%f, \%d, \%files, \%dirs);
}

sub FileListPath {
    my $self = shift;
    my $fl = $self->{'setup-dir'} . ".rpmfilelist";
    ($fl, File::Spec->catdir($self->{'setup-dir'}, $fl));
}

sub CheckDocFileForDesc {
    my $self=shift;
    my $filename=shift;
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if $self->{'verbose'};
    open($fh, "<$filename") || die "Failed to open $filename: $!";
    my $desc;
    my $linecount=1;
  LINE: while ( my $line=<$fh> ) {
	$desc .= $line;
	$linecount++;
	$linecount > 25 && last LINE;
    }
    close($fh) or die "Failed to close $filename $!";
    #FIXME: quality check
    $linecount > 2 or return undef;
    return $desc if ( $desc );
}

# sub CheckPerlProgForDesc

# given a valid perl program see if there is a valid description in it.

sub CheckPerlProgForDesc {
    my $self=shift;
    my $filename=shift;
    my $desc;
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if $self->{'verbose'};
    open($fh, $filename) || die "Failed to open $filename: $!";;

    my $linecount=1;
  LINE: while (my $line=<$fh>){
	($line =~ m/^=head1[\t ]+DESCRIPTION/) and do {
	    while ( $line=<$fh> ) {
		($line =~ m/^=(head1)|(cut)/) and last LINE;
		$desc .= $line;
		$linecount++;
		$linecount > 30 && last LINE;
	    }
	};
	#tests to see if the descripiton is good enough
	#FIXME: mentions package name?
    }
    close($fh) or die "Failed to close $filename $!";
    ( $desc =~ m/(....\n.*){3}/m ) and do {
	#Often descriptions don't say the name of the module and
	#furthermore they always assume that we know they are a perl
	#module so put in a little header.
	$desc =~ s/^\s*\n//;
	$desc="This package contains the perl extension " .
	  $self->{"package-name"} . ".\n\n" . $desc 
	    unless $desc =~ m/perl/ and $desc =~ m/module/;
	print STDERR "Found description in $filename\n" if $self->{'verbose'};
	return $desc;
    };
    print STDERR "No description found in $filename\n" if $self->{'verbose'};
    return undef;
}

# sub ProcessFileNames
# looks through a list of candidate files names and orders them
# according to desirability then cuts off those that look likely
# to do more harm than good.

# N.B. function call to here is done a bit wierdly...

sub ProcessFileNames {
    my ($self, $doclist) = @_;
    die "function miscall" unless (ref $self && (ref $doclist eq "ARRAY"));

    print STDERR "Sorting different perl file possibilities\n"
      if $self->{'verbose'};

    local $::simplename=$self->{"package-name"};
    local ($::A, $::B);
    $::simplename =~ s,[-/ ],_,g;
    $::simplename =~ tr/[A-Z]/[a-z]/;

    #Ordering Heuristic
    #
    #best: the description in the module named the same as the package
    #
    #next: documentation files
    #
    #next: files named as package
    #finally: prefer .pod to .pm to .pl
    #
    #N.B. sort high to low not low to high

    my @sort_list = sort {
	local $::res=0;
	$::A = $a;
	$::B = $b;
	$::A =~ s,[-/ ],_,g;
	$::A =~ tr/[A-Z]/[a-z]/;
	$::B =~ s,[-/ ],_,g;
	$::B =~ tr/[A-Z]/[a-z]/;

	#bundles seem a bad place to look from our limited experience
	#this might be better as an exception on the next rule??
	return $::res
	  if ( $::res = - (($::B =~ m/(^|_)bundle_/ )
			   <=> ($::A =~ m/(^|_)bundle_/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/$::simplename.(pm|pod|pod)/ )
			 <=> ($::A =~ m/$::simplename.(pm|pod|pod)/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/^readme/ )
			 <=> ($::A =~ m/^readme/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/.pod$/ )
			 <=> ($::A =~ m/.pod$/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/.pm$/ )
			 <=> ($::A =~ m/.pm$/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/.pl$/ )
			 <=> ($::A =~ m/.pl$/ )) ) ;
	return $::res
	  if ( $::res = (($::B =~ m/$::simplename/ )
			 <=> ($::A =~ m/$::simplename/ )) ) ;
	return length $::B <=> length $::A;
    } @$doclist;

    print STDERR "Checking which fies could really be used\n"
      if $self->{'verbose'};
    my $useful=0;		#assume first always good
  CASE: {
	$#sort_list == 1 && do {
	    $useful=1;
	    last CASE;
	};
	while (1) {
	    $useful==$#sort_list and last CASE;
	    #non perl files in the list must be there for some reason
	    ($sort_list[$useful+1] =~ m/\.p(od|m|l)$/) or do {$useful++; next};
	    my $cmp_name=$sort_list[$useful+1];
	    $cmp_name =~ s,[-/ ],_,g;
	    $cmp_name =~ tr/[A-Z]/[a-z]/;
	    #perl files should look something like the package name???
	    ($cmp_name =~ m/$::simplename/) && do {$useful++; next};
	    last CASE;
	}
    }
    $#sort_list = $useful;

    print STDERR "Description file list is as follows:\n  " ,
      join ("\n  ", @sort_list), "\n" if $self->{'verbose'};

    #FIXME: ref return would be more efficient
    return \@sort_list;
}

# sub CheckFilesForDesc

# runs through a list of files to see if they are there and reads in a
# description if one of them is.

sub CheckFilesForDesc {

    my $doc_list=&ProcessFileNames;

    my $self = shift;
    my $desc;

  FILE: foreach my $filename ( @$doc_list ){
	-e $filename or 
	  do {print STDERR "no $filename file" if $self->{'verbose'};
	      next FILE};
	$filename =~ m/\.p(od|m|l)$/ && do  {
	    $desc=$self->CheckPerlProgForDesc($filename);
	    $desc && last FILE;
	    next FILE;
	};
	$desc=$self->CheckDocFileForDesc($filename);
	last FILE if $desc;
    }
    return $desc;
}

#Autodesc : run after Build to try to automatically guess a
#description using files in the perl archive.
#
#run this after a build.  Assumes that it's in the package's
#build directory after a setup.

sub AutoDesc {
    my $self = shift;
    my $desc = "";
    print STDERR "Hunting for files in distribution\n" if $self->{'verbose'};

    #Files for use for a description.  Names are relative to package
    #base.  Are there more names which work good?  BLURB?  INTRO?

    my (@doc_list) = ( "README", "DESCRIPTION" );

    my $dirpref =Cwd::cwd();

    my $handler=sub {
	m/\.p(od|m|l)$/ or return;
	my $name=$File::Find::name;
	$name =~ s/^$dirpref//;
	push @doc_list, $name;
    };
    &File::Find::find($handler, '.');

    $desc=$self->CheckFilesForDesc(\@doc_list);

    unless ( $desc ) {
	warn "Failed to generate any descripiton for"
	  . $self->{'package-name'} . ".\n";
	return undef;
    }

    #FIXME: what's the best way to clean up whitespace?  Is it needed at all?
    #bear in mind that both perl descriptions and rpm special case
    #indentation with white space to mean something like \verbatim

    $desc=~s/^[\t ]*//mg;	#space at the start of lines
    $desc=~s/[\t ]*$//mg;	#space at the end of lines
    $desc=~s/^[_\W]*//s; #blank / punctuation lines at the start  
      $desc=~s/\s*$//;		#blank lines at the end.

    #Simple cleanup of PODisms
    $desc=~s/(^|\s)[A-Z]<([^>]+)>/$1$2/g;

    $self->{"description"}=$desc;
    return 1;
}

#AutoDocs is a method which reads through the package and generates a
#documentation list.

sub AutoDocs() {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my @docs = ();
    my $return="";
    eval {
	my $dir =  $self->{'build_dir'} . '/' . $self->{'setup-dir'};
	print STDERR "Running AutoDocs() in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	opendir (BASEDIR , ".") || die "can't open package main directory $!";
	my @files=readdir (BASEDIR);
	@docs= grep {m/(^README)|(^COPYING$)|(^doc(s|u.*)?)/i} @files;
	print STDERR "Found the following documentation files\n" ,
	  join ("  " , @docs ), "\n" if $self->{'verbose'};
	foreach my $doc (@docs) {
	    #      $return .= "\%doc " . $self->{'setup-dir'} . '/' . $doc . "\n";
	    $return .= "\%doc " . $doc . "\n";
	}
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    return $return;
}


# CheckRPMDataVersion
#
#reads information in the rpm data directory.  This is a minimum shot.
#Should design a full modular system, but it's always neat to have a
#minimal implementation anyway...
#
#assume we are in the build directory
#
#
#function holds a result cache so that it can be called repeatedly
#from different places without them needing to communicate and still
#be efficient

{
    my $verbose=1;		# we should really objectify this.. 
    my %CheckRPMDataVersionResult=();
    sub CheckRPMDataVersion ($) {
	my $RPMDataVersion=0.001; #the minimum version???
	my $dir=shift;
	($dir =~ m,^/,) or ($dir= Cwd::cwd() . '/' . $dir);
	print STDERR "checking RPM Data Version in $dir\n" if $verbose;
	return $CheckRPMDataVersionResult{$dir}
	  if defined $CheckRPMDataVersionResult{$dir};
	#only called if there is?
	-d $dir or warn "No RPM data dir";
	my $vfile=$dir . '/VERSION';
	if ( -e $vfile ) {
	    my $fh = Symbol::gensym();
	    open ($fh, $vfile ) || die "Failed to open rpm data version file " .
	      $vfile . ": $!";
	    my ($suggest, $require);
	    while (<$fh>) {
		( ($require) = m/^REQUIRES:\s*(\S+)/ ) && do {
		    die "Required version found but not positive number"
		      unless $require =~ m/^\d+\.?\d*$/ ;
		    if ($require > $RPMDataVersion) {
			print STDERR <<END ;
Required version in $vfile is $require, makerpm data version is $RPMDataVersion.
END
			die "RPM data dir is too new.  You must upgrade makerpm.";
		    }
		};
		( ($suggest) = m/^SUGGESTS:\s*(\S*)/ ) && do {
		    die "Suggested version found but not positive number"
		      unless $suggest =~ m/^\d+\.?\d*$/ ;
		    warn "RPM data dir is newer than makerpm. Try to upgrade if you can"
		      if $suggest > $RPMDataVersion;
		};
		#	    ( $compatible = m/^COMPATIBLE:\s*(\S*)/ ) && do {};
	    }
	    $require = 0 unless defined $require ;
	    print STDERR "RPM data version $require; we have $RPMDataVersion; okay\n";
	    close($fh) or die "Failed to close " . $vfile .  ": $!";
	    return $CheckRPMDataVersionResult{$dir}=$RPMDataVersion;
	} else { 
	    print STDERR "no version file found; continue happily\n" if $verbose;
	}
    }
}

sub ReadFile {
    my $self=shift;
    my $filepath=shift;
    my $fh = Symbol::gensym();
    open ($fh, $filepath) || die "Failed to open file " .
      $filepath . ": $!";
    print STDERR "Reading ". $filepath ."\n"
      if $self->{'verbose'};
    my $returnme="";
    while (<$fh>) {
	$returnme .= $_;
    }
    close($fh) or die "Failed to close " . $filepath .  ": $!";
    return $returnme;
}

#Description - drive the hunt for description information
#
#expects build to have already been done.

sub ReadDescription {
    my $self=shift;
    my $descfile=shift;
    my $fh = Symbol::gensym();
    open ($fh, $descfile )
      || die "Failed to open description file " .
	$descfile . ": $!";
    print STDERR "Reading description from ". $descfile ."\n"
      if $self->{'verbose'};
    $self->{"description"}="";
    while (<$fh>) {
	$self->{"description"} .= $_;
    }
    close($fh) or die "Failed to close " . $descfile .  ": $!";
}

#Description -  drive the hunt for description information
#
#expects build to have already been done.  Anything else would be an
#internal error.
#

sub Description {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $desc = "";
    my $descfilename = "description";
    die "package not yet built when looking for description"
      unless $self->{"built-dir"};
    eval {
	my $dir =  $self->{"built-dir"};
	print STDERR "Running Description() in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
      CASE: {
	    my $pkg_own_desc = $self->{"rpm-data-dir"} . "/" . $descfilename;

	    #case 1 - a file explicitly provided by the user
	    $self->{"desc-file"} && do {
		my $descfile = $self->{"desc-file"};
		-e $descfile or die "File " . $descfile . " doesn't exist";
		-e $pkg_own_desc
		  and warn "Overriding " . $self->{"package-name"}
		    . "packages own description.  Maybe new?";
		$self->ReadDescription($descfile);
		last CASE;
	    };

	    #case 2 - a file provided in the data-dir by the user
	    $self->{"user-data-dir"} && do {
		CheckRPMDataVersion($self->{"user-data-dir"});
		print STDERR "Checking for desc file in given data directory\n"
		  if $self->{'verbose'};
		my $descfile = $self->{'user-data-dir'} . '/'
		  . $self->{"package-name"} . '/' . $descfilename;
		-e $descfile && do {
		    -e $pkg_own_desc
		      and warn "Overriding " . $self->{"package-name"}
			. "packages own description.  Maybe new?";
		    my $fh = Symbol::gensym();
		    $self->ReadDescription($descfile);
		    last CASE;
		};
		print STDERR "No description file in data-dir\n"
		  if $self->{'verbose'};
	    };

	    #case 3 - a file provided by the package author
	    -e $pkg_own_desc && do {
		CheckRPMDataVersion($self->{"rpm-data-dir"});
		print STDERR "Checking for desc file in rpm's data directory\n"
		  if $self->{'verbose'};
		$self->ReadDescription($pkg_own_desc);
		last CASE;
	    };

	    #case 4 - try to build a description automatically
	    $self->{"auto-desc"} && do {
		$self->AutoDesc() and last CASE;
	    };

	    warn "failed to find description for " . $self->{"package-name"};
	}
    };
    my $status = $@;
    chdir $old_dir;
    die if $status;
}

sub ReadRequires {
    my $self=shift;
    my $reqfile=shift;
    my $fh = Symbol::gensym();
    open ($fh, $reqfile )
      || die "Failed to open description file " .
	$reqfile . ": $!";
    print STDERR "Reading description from ". $reqfile ."\n"
      if $self->{'verbose'};
    while (<$fh>) {
	s/(^|\s)#.*//; 		#delete comments
	foreach my $req (m/(?:(\S+)\s)/g) {
	    push @{$self->{'require'}}, $req;
	}
    }
    close($fh) or die "Failed to close " . $reqfile .  ": $!";
}

#Requires -  drive the hunt for requires information
#
#expects build to have already been done.
#

sub Requires {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    my $desc = "";

    my $reqfilename = "requires";

    eval {
	my $dir =  $self->{'built-dir'};
	print STDERR "Running Requires in directory $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
      CASE: {
	    my $pkg_own_req = $self->{"rpm-data-dir"} . "/" . $reqfilename;

	    #case 1 does not exist
	    #requires provided on the command line are additive.

	    #case 2 - a file provided in the data-dir by the user
	    $self->{"user-data-dir"} && do {
		CheckRPMDataVersion($self->{"user-data-dir"});
		print STDERR "Checking for requires file in given data directory\n"
		  if $self->{'verbose'};
		my $reqfile = $self->{'user-data-dir'} . '/'
		  . $self->{"package-name"} . '/' . $reqfilename;
		-e $reqfile && do {
		    -e $pkg_own_req
		      and warn "Overriding " . $self->{"package-name"}
			. "packages own requires list.  Maybe new?";
		    my $fh = Symbol::gensym();
		    $self->ReadRequires($reqfile);
		    last CASE;
		};
		print STDERR "No description file in data-dir\n"
		  if $self->{'verbose'};
	    };

	    #case 3 - a file provided by the package author
	    -e $pkg_own_req && do {
		CheckRPMDataVersion($self->{"rpm-data-dir"});
		print STDERR "Checking for requires file in rpm's data directory\n"
		  if $self->{'verbose'};
		$self->ReadRequires($pkg_own_req);
		last CASE;
	    };

	    #case 4 - try to build requires automatically
	    #also doesn't exist.  This is the job of RPM.

	}
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
}

#ReadConfigFile
#
#This function takes a filename and returns the entire contents of
#that file from the override directory or the module directory.
#

sub ReadConfigFile {
    my $self=shift;
    my $filename=shift;
    my $old_dir = Cwd::cwd();
    my $returnme=undef;
    eval {
	my $dir =  $self->{'built-dir'};
	print STDERR "ReadConfigFile in $dir\n" if $self->{'verbose'};
	chdir $dir || die "Failed to chdir to $dir: $!";
	my $pkg_own_file = $self->{"rpm-data-dir"} . "/" . $filename;

	#a file provided in the data-dir by the user
	$self->{"user-data-dir"} && do {
	    CheckRPMDataVersion($self->{"user-data-dir"});
	    print STDERR "Checking for $filename in given data directory\n"
	      if $self->{'verbose'};
	    my $user_file = $self->{'user-data-dir'} . '/'
	      . $self->{"package-name"} . '/' . $filename;
	    -e $user_file && do {
		-e $pkg_own_file
		  and warn "Overriding " . $self->{"package-name"}
		    . "packages own file $pkg_own_file.  Maybe new?";
		$returnme = $self->ReadFile($user_file);
	    };
	    print STDERR "No override file in data-dir\n"
	      if ($self->{'verbose'} and not defined $returnme);
	};
	#a file provided by the package author
	if (-e $pkg_own_file and not defined $returnme) {
	    CheckRPMDataVersion($self->{"rpm-data-dir"});
	    print STDERR "Checking for file $pkg_own_file in rpm's data directory\n"
	      if $self->{'verbose'};
	    $returnme = $self->ReadFile($pkg_own_file);
	}
	print STDERR "Didn't find file matching $filename.\n"
	  if ( $self->{'verbose'} and not defined $returnme );
    };
    my $status = $@;
    chdir $old_dir;
    die $@ if $status;
    $returnme = "" unless defined $returnme;
    return $returnme;
}

sub Specs {
    my $self = shift;
    my $old_dir = Cwd::cwd();
    eval {

	# We want to do a build so that the package author has the
	# chance to create any dynamic data he wants us to be able to be
	# able to see such as platform specific scripts or text
	# format documentation derived from something else.


	unless ( $self->{"built-dir"} ) {
	    $self->Prep();
	    $self->Build();
	}


	$self->Description();
	$self->Requires();

	#FIXME check what side effects install has... hmm get rid of them
	#if they are important.
	my $filelist;
	#where is this file going anyway???
	$filelist = $self->{'name'}.$self->{'version'} . '.filelist'
	  unless defined $filelist;

	#not used, apparently
	#	my($files, $dirs) = $self->Files($self->{'build-root'});

	my $specs = <<"EOF";
#Spec file created by makerpm 
#   
%define packagename $self->{'name'}
%define packageversion $self->{'version'}
%define release 1
EOF
	my $mo = $self->{'makeopts'} || '';
	$mo =~ s/\n\t/ /sg;
	$specs .= sprintf("%%define makeopts \"%s\"\n",
			  ($mo ? sprintf("--makeopts=%s",
					 quotemeta($mo)) : ""));
	foreach my $opttype ("makemakeropts", "makeperlopts") {
	    my @mmo=();
	  CASE:{ 
		($#{$self->{"$opttype"}} > -1) and do {
		    foreach my $opt (@{$self->{"$opttype"}}) {
			# $mmo =~ s/\n\t/ /sg; #allow through newlines???
			$opt=quotemeta(quotemeta $opt);
			$opt= "--$opttype=" . $opt ;
			push @mmo, $opt;
		    }
		    $specs .= "%define $opttype ".join (" ",@mmo). " \n";
		    last;
		};
		$specs .= "%define $opttype \"\"\n";
	    }
	}

	my $setup_dir = $self->{'setup-dir'} eq $self->{'default_setup_dir'} ?
	  "" : " --setup-dir=$self->{'setup-dir'}";

	my $makerpm_path = File::Spec->catdir('$RPM_SOURCE_DIR', 'makerpm.pl');
	$makerpm_path = File::Spec->canonpath($makerpm_path) . $setup_dir .
	  " --source=$self->{'source'}";

	$self->{"description"} = $self->{'summary'}
	  unless $self->{'description'};

	my $prefix='';
	$prefix="perl-" if ($self->{'name-prefix'});

	$specs .= <<"EOF";

Name:      $prefix%{packagename}
Version:   %{packageversion}
Release:   %{release}
Group:     $self->{'rpm-group'}
Source:    $self->{'source'}
License: $self->{'copyright'}
BuildRoot: $self->{'build-root'}
Provides:  $prefix%{packagename}
Summary:   $self->{'summary'}
EOF

	#this is something added to mirror the RedHat generated spec files..
	#I think it makes sense, though maybe the version number is too
	#strict?? - Michael

	$specs .= <<"EOF" if $self->{"rpm-version"} > 4;
BuildRequires: perl >= 5.6
Requires: perl >= 5.6
EOF

	if (my $req = $self->{'require'}) {
	    $specs .= "Requires: " . join(" ", @$req) . "\n";
	}

	my $runtests = $self->{'runtests'} ? " --runtests" : "";

	#Normally files should be owned by root.  If we are non root
	#then we can't do chowns (on any civilised operating system
	#;-) so we have to fix the ownership with a command.

	# This is a warning because there might be modules which might
	# install their own userid for security reasons or set files
	# to other ownership's deliberately.  It is the responsibility
	# of the packager to be aware of this.

	my $defattr;
	if ($self->{'defattr'}) {
	    $defattr="";
	} else {
	    warn "using Defattr to force all files to root ownership\n";
	    $defattr = "%defattr(-,root,root)";
	}

	use vars qw/$prep_script $build_script $install_script
		    $clean_script $pre_script $post_script
		    $preun_script $postun_script $verify_script/;
	my @scripts = ("prep", "build", "install", "clean", "pre",
		       "post","preun", "postun", "verify" );
	foreach my $script ( @scripts ) {
	    no strict "refs";	#makes for an easier life..
	    my $var = $script . "_script";
	    $$var = $self->ReadConfigFile($script . ".sh") ;
	}

	my $doclist = $self->ReadConfigFile("docfiles") ;
	$doclist = $self->AutoDocs() unless $doclist ;
	$doclist = "" unless $doclist;

	$specs .= <<"EOF";

%description
$self->{'description'}
EOF

	$specs .= <<"EOF" if $self->{'find-requires'};
# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

EOF

	$specs .= <<"EOF";
%prep
EOF

	$specs .= <<"EOF" ;
%setup -q -n $self->{'setup-dir'}
EOF
	#FIXME we haven't actually checked that a file would be removed
	#so this might give an error at prep time?
	$specs .= <<"EOF" if $self->{'rm-files'};
find $self->{'setup-dir'} -regex '$self->{'rm-files'} ' -print0 | xargs -0 rm
EOF
	$specs .= <<"EOF" ;

$prep_script

%build
EOF

	#we put LANG=C becuase perl 5.8.0 on RH 9 doesn't create makefiles otherwise.  
	#this should be made conditional in the case where perl starts working with 
	#unicode languages..
	$specs .= "export LANG=C\n";
	$specs .= 'CFLAGS="$RPM_OPT_FLAGS" perl ';
	$specs .= '%{makeperlopts} ' if @{$self->{'makeperlopts'}};
	$specs .= ' Makefile.PL PREFIX=$RPM_BUILD_ROOT/usr ';
	$specs .= '%{makemakeropts}' if @{$self->{'makemakeropts'}};
	$specs .= "\nmake";
	$specs .= '%{makeopts}' if $self->{'makeopts'};
	$specs .= "\n";

	$specs .= <<"EOF" ;

$build_script

%install
rm -rf \$RPM_BUILD_ROOT

$install_script

#run install script first so we can pick up all of the files

eval `perl '-V:installarchlib'`
mkdir -p \$RPM_BUILD_ROOT/\$installarchlib
make install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

#we don't include the packing list and perllocal.pod files since their
#functions are superceeded by rpm.  we have to actually delete them
#since if we don't rpm complains about unpackaged installed files.

find \$RPM_BUILD_ROOT/usr -type f \\( -name 'perllocal.pod' \\\
	-o -name '.packlist' \\) -print | xargs rm
find \$RPM_BUILD_ROOT/usr -type f -print | 
	sed "s\@^\$RPM_BUILD_ROOT\@\@g" > $filelist

if [ "\$(cat $filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi
EOF

	my ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire)
	  = getpwent;
	#fixme: external calls not really needed
	#fixme more: date works in the local locale, but will RPM
	#then be able to hack it?!?!
	my $date=`date +'%a %b %d %Y %T'`; chomp $date;
	my $host=`hostname`; chomp $host;

	$specs .= <<"EOF" ;

%clean

$clean_script

rm -rf \$RPM_BUILD_ROOT

%pre

$pre_script

%post

$post_script

%preun

$preun_script

%postun

$postun_script

%verifyscript

$verify_script

%files -f $filelist
$defattr
$doclist

%changelog
* $date autogenerated
- by $comment <$name\@$host>
- using MakeRPM:
- $::VERSION
- $::ID
EOF

	my $specs_name = "$self->{'name'}-$self->{'version'}.spec";
	my $specs_file = File::Spec->catfile($self->{'rpm-specs-dir'},
					     $specs_name);
	$specs_file = File::Spec->canonpath($specs_file);
	print STDERR "Creating SPECS file $specs_file\n";
	print STDERR $specs if $self->{'verbose'};
	unless ($self->{'debug'}) {
	    my $fh = Symbol::gensym();
	    open($fh, ">$specs_file") or die "Failed to open $specs_file: $!";
	    (print $fh $specs) or die "Failed to write to $specs_file: $!";
	    close($fh) or die "Failed to close $specs_file: $!";
	}
	$self->{specs_file}=$specs_file;
    };
    my $status = $@;
    chdir $old_dir;
    die if $status;
}

#
# tell the user how to build an rpm using the spec file
#

sub TellBuild {
    my $self=shift;
    if ( ! -e $self->{'rpm-source-dir'} . "/" . $self->{'source'} ) {
	print STDERR "copy source file " . $self->{'source'} . " to " . 
	  $self->{'rpm-source-dir'} . "\n";
	print STDERR "then ";
    } else {
	print STDERR "now ";
    }
    print STDERR "run `rpmbuild -ba $self->{specs_file}' to create an rpm\n";
}

#
# build an rpm using the spec file
#

# relies on Extract having been run to initialise facts about the
# source file.

sub DoBuild {
    my $self=shift;
    defined $self->{'source_path'} and defined $self->{'rpm-source-dir'} 
      and defined $self->{'source_base'} or 
	die "Source file variables not defined";
    my $rpm_sfile = $self->{'rpm-source-dir'} . "/" . $self->{'source'};
    unless ( -e  $rpm_sfile ) {
	copy $self->{'source_path'}, 
	  $self->{'rpm-source-dir'} ."/". $self->{'source_base'} or die $!;
    } 
    my @command=("rpmbuild", "-ba", $self->{specs_file});
    print STDERR join " ", "running", @command;
    exit 1 if system @command;
}

1;
