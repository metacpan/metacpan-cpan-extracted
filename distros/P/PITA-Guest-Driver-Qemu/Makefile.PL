use strict;
use inc::Module::Install;

name                  'PITA-Guest-Driver-Qemu';
all_from              'lib/PITA/Guest/Driver/Qemu.pm';
requires              'Carp'             => 0;
requires              'File::Temp'       => '0.15';
requires              'File::Which'      => '0.05';
requires              'File::Remove'     => '0.34';
requires              'Params::Util'     => '0.10';
requires              'PITA'             => '0.40';
requires              'Filesys::MakeISO' => 0;
requires_external_bin 'qemu'             => 0;
build_requires        'File::Spec'       => '0.80';
build_requires        'Test::More'       => '0.47';

# What osname's do we know that mkisofs runs on
my @mkisofs_platforms = qw{
	aix beos cygwin darwin freebsd hpux irix linux netbsd
	openbsd os390 sco solaris sunos
};

# Make sure we install at least one mkisofs driver
if ( can_run('mkisofs') or grep { $^O eq $_ } @mkisofs_platforms ) {
	requires              'Filesys::MakeISO::Driver::Mkisofs';
	requires_external_bin 'mkisofs'; # Temporary

} elsif ( $^O eq 'MSWin32' ) {
	requires              'Filesys::MakeISO::Driver::MagicISO';

} else {
	print "Unable to determine a Filesys::MakeISO to use for your OS.\n";
	print "If you can install mkisofs it will be auto-detected.\n";
	print STDERR "NA: No MakeISO driver available, not applicable on this platform.\n";
	exit(255);
}

# Are we going to need the test image
if ( $ENV{AUTOMATED_TESTING} ) {
	# Always install the test image during automated testing
	build_requires        'PITA::Test::Image::Qemu';
}

WriteAll;
