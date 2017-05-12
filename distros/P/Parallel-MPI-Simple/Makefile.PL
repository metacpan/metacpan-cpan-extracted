use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Make sure people aren't being stupid... it's been known to happen.

print <<ENDOFMESSAGE;
I'm about to build the Makefile for Parallel::MPI::Simple.

If you have mpicc installed, I will attempt to use the arguements
it suggests to compile and link the module.  You will also have to
have already started mpd for the tests to work.

If you find you cannot build this module, or that the tests fail, you
may be on an odd system where you need to do more than pass -lmpi to
your C compiler to build MPI applications.  If this is the case, rerun
perl Makefile.PL with appropriate LDFLAGS= and CCFLAGS= arguments.

ENDOFMESSAGE

my $mpirun = "";
my ($libs, $ccflags) = ("", "");

if ($ENV{FORCE_MPIRUN}) {
    $mpirun = $ENV{FORCE_MPIRUN};
}
else {
    foreach my $mpi_try (qw(mpiexec mpirun)) {
	my $test = join("",`$mpi_try -n 1 echo test`);
	$mpirun = $mpi_try unless $! =~ /No such file or directory/;
	last if $mpirun;
    }
    
    if (!$mpirun) {
	print STDERR "Failed to run `$mpirun -n 1 echo test`: $!\n";
	print STDERR "It looks like you don't have mpi installed, re-run build with env: FORCE_MPIRUN=1 to ignore\n";
	exit(0);
    }
}

# try to get this information from mpicc, should quietly fail if not
if ($^O !~ /MSWin32/) {
    my @lines = `mpicc -help`;
    foreach my $line (@lines) {
	if ($line =~ /-link-info/) {
	    my $linkinfo = `mpicc -link-info`;
	    my @entries = split (/\s+/, $linkinfo);
	    $libs = join(" ", grep {/^-[Ll]/} @entries);
	}
	if ($line =~ /-compile-info/) {
	    my $compileinfo = `mpicc -compile-info`;
	    my @entries = split (/\s+/, $compileinfo);
	    $ccflags = join(" ", grep {/^-[ILl]/} @entries);
	}
    }
    if ($libs || $ccflags) {
	print STDERR "guessing values for\n LIBS:$libs\n CCFLAGS:$ccflags\n";
    }
    else {
	print STDERR "Could not determine options for mpicc, using defaults\n";
    }
}
else { # windows, look for mpich2
  my @potential = map {"C:\\$_\\MPICH2"}
    'Program Files',
      'Program Files (x86)';
  foreach my $try (@potential) {
    if (-f "$try\\bin\\mpiexec.exe") {
      $mpirun = "$try\\bin\\mpiexec.exe";
      $libs = qq{"-L$try\\lib" -lmpi};
      $ccflags = qq{"-I$try\\include" "-L$try\\lib" -lmpi};
    }
  }
}

# Check that people have tried to define linking and compiling options...
WriteMakefile(
    'NAME'	=> 'Parallel::MPI::Simple',
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
    'PREREQ_PM' => {Storable => 0},
    'LIBS' => $libs || "-lmpi",
    'CCFLAGS' => $ccflags || "",
);
