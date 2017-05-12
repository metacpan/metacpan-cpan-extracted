#!/usr/bin/perl

# Launch script for PITA::Scheme.
# Needs to be tailored for each image.
# Most of the time needs to be run by root

use PITA::Scheme;

my $injector = '/mnt/injector';
my $workarea = '/tmp';





#####################################################################
# Mount the injector directory

my $rv = system("mount -t vfat /dev/hdb1 $injector");
if ( $rv ) {
	die "Error while mounting injector";
}
unless ( -f "$injector/scheme.conf" ) {
	die "Injector does not contain scheme.conf";
}





#####################################################################
# Create the PITA::Scheme

my $scheme = PITA::Scheme->new(
	injector => $injector,
	workarea => $workarea,
	);
$scheme->prepare_all;
$scheme->execute_all;
$scheme->put_report;

sleep 10;

system('shutdown -h 0');

exit(0);

