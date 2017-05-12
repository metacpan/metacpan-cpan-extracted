#!/usr/bin/perl

use lib qw(./lib);
use strict;
use warnings;

use Module::Find;

use SRS::SetupLogger qw(setup_logger);

setup_logger(debug => 1);


my @mods = usesub 'Probe::MachineInfo';

foreach my $mod (@mods) {
	next if $mod =~ /Metric/;

	my ($name) = $mod =~ m/^.*::([^:]+)$/;
	my $class = $mod->new();
	print "$name: $class\n";
}
