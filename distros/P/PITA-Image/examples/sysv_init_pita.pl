#!/usr/bin/perl

# This script checks for the config file in the root of
# the injector drive.
# If found, runs the PITA::Image launcher, then shuts down.
# If not found, does nothing, allowing maintainers to login.
# This is an example only to demonstrate the desired behaviour.
# It would need to be tweaked for each machine.

use strict;
use IPC::Run3;
use PITA::Image;

my $injector = '/mnt/hdb1';
my $rootconf = "$injector/image.conf";

# If the drive is NOT mounted, exit normally and allow sysvinit
# to continue on to a normal user login.
unless ( -f $rootconf ) {
	print "pita: Did testing payload at $rootconf\n";
	print "pita: Continuing to normal login.\n";
	exit(0);
}

# Wrap the main actions in an eval to catch errors
eval {
	# Configure the image manager
	my $manager = PITA::Image->new(
		injector => $injector,
		workarea => '/tmp',
	);
	$manager->add_platform(
		scheme => 'perl5',
		path   => '', # Default system Perl context
	);
	$manager->add_platform(
		scheme => 'perl5',
		path   => '/opt/perl5-6-1/bin/perl'
	);

	# Run the tasks
	$manager->run;

	# Report the results
	$manager->report;
};

# Shut down the computer immediately on completion or failure.
# The user will never see a login in this case.
run3( [ 'shutdown', '-h', '0' ], \undef );

exit(0);
