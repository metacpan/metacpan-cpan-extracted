#!/usr/bin/perl
#
# DESCRIPTION:
#	Test sending basic passive results to nrd 
#
# COPYRIGHT:
#	Copyright (C) 2007 Altinity Limited
#	Copyright is freely given to Ethan Galstad if included in the NSCA distribution
#
# LICENCE:
#	GNU GPLv2

use lib 't';

use strict;
use NSCATest;
use Test::More;

plan tests => (3 * 3);

my $data = [ 
	["hostname", "0", "Plugin output"],
	["long_output", 0, 'x' x 10240 ],
	["hostname-with-other-bits", "1", "More data to be read"],
	["hostname.here", "2", "Check that ; are okay to receive"],
	["host", "service", 0, "A good result here"],
	["host54", "service with spaces", 1, "Warning! My flies are undone!"],
	["host-robin", "service with a :)", 2, "Critical? Alert! Alert!"],
	["host-batman", "another service", 3, "Unknown - the only way to travel"],
	["long_output", "service1", 0, 'x' x 10240 ], #10K of plugin output
	];
my $last_check = [['last_check', '0', 'LastCheckOutput']];

SKIP: {
skip "Spooling not implemented yet", 9;

foreach my $config ('plain', 'encrypt', 'digest'){
  foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
	my $nsca = NSCATest->new( config => $config );

        # all this data is sent with daemon stopped
	$nsca->send($data);
	sleep 5;		# Need to wait for --daemon to finish processing

        # now we start the daemon
	$nsca->start($type);

        $nsca->send($last_check);

        my $output = $nsca->read_cmd;

	is_deeply([ @{$data}, @{$last_check} ], $output, "Got all data as expected");

	$nsca->stop;
   }
}

}
