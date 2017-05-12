#!/usr/bin/perl
#
# DESCRIPTION:
#	Test failures caught by tunnelling via SSH
#
# COPYRIGHT:
#	Copyright (C) 2010 Opsera Limited
#
# LICENCE:
#	GNU GPLv2

use lib 't';

use strict;
use NSCATest;
use Test::More;

plan 'no_plan';

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
	['x' x 1000, 0, 'Host check with big hostname'],
	['x' x 1000, 'service OK', 0, 'Service check with big hostname'],
	['long_svc_name', 'x' x 1000, 0, 'Service check with big service name'],
	];

# From a different server, run:
#  ssh -n -N -T -2 -o TCPKeepAlive=yes -o ServerAliveCountMax=3 -o ServerAliveInterval=10 -R 7669:1.0.0.1:6669 {thisserver}
# And make sure nothing listening on port 6669 on other server

foreach my $i (1..100) {
	my $nsca = NSCATest->new( config => "plain" );

	#$nsca->start($type);
	my $rc = $nsca->send($data);
	#sleep 1;		# Need to wait for --daemon to finish processing

	is( $rc, undef, "Get error from send, as expected" );
	#my $output = $nsca->read_cmd;
	#is_deeply($data, $output, "Got all data as expected");

	#$nsca->stop;
}
