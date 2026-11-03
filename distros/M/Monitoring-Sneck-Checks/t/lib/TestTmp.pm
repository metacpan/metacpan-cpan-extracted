package TestTmp;

# Scratch directories for tests, kept under t/tmp rather than the
# system temp directory. That keeps the fake binaries tests exec away
# from a noexec /tmp and leaves what a failed test made easy to find.

use strict;
use warnings;
use FindBin;
use File::Path qw(make_path);
use File::Temp ();

# Makes a new directory under t/tmp and returns its absolute path. It
# is removed at exit unless KEEP_TMP is set in the environment.
#
#     my $dir = TestTmp::dir();
sub dir {
	my $base = $FindBin::Bin . '/tmp';
	make_path($base);
	return File::Temp::tempdir( DIR => $base, CLEANUP => !$ENV{KEEP_TMP} );
}

1;
