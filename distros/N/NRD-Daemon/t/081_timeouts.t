#!/usr/bin/perl
#
# DESCRIPTION:
#	Test sending garbage to nrd 
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
use IO::Socket::INET;

use NRD::Serialize;
use NRD::Packet;

# 6 (2 x 3 servers) plain serializer tests
# 9 (2 x 3 servers) encrypt serializer tests
plan tests => 15;

my $host = 'localhost';
my $port = 7669;

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

# When the NRD server cuts a connection we get a SIG_PIPE. Perls default is to die...
$SIG{'PIPE'} = 'IGNORE';

my $config = 'plain';
foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
	my $nsca = NSCATest->new( config => $config );

	$nsca->start($type);

	#TODO: read data from urandom, spit it into NRD and let it run for a while...
        my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                    PeerPort => $port,
                                    Proto    => 'tcp',
                                 ) || die "Can't connect [$!]";
        sleep 8;

        # Seems like the 
        print $sock ("XXXXXXXXXX" x 1000) or ok($! eq 'Broken pipe', "Stale socket errored out");
        close $sock;
        $@ = undef;

	#The important thing, in the end is that the results we send now get to the server intact.
	$nsca->send($data);
	sleep 1;		# Need to wait for --daemon to finish processing

	my $output = $nsca->read_cmd;
	is_deeply($data, $output, "Got all data as expected");

	$nsca->stop;
}

$config = 'encrypt';
foreach my $type ('--server_type=Single', '--server_type=Fork', '--server_type=PreFork') {
        my $nsca = NSCATest->new( config => $config );

        $nsca->start($type);

        #TODO: read data from urandom, spit it into NRD and let it run for a while...
        my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                    PeerPort => $port,
                                    Proto    => 'tcp',
                                 ) || die "Can't connect [$!]";
        sleep 8;

        print $sock ("XXXXXXXXXX" x 1000) or ok($! eq 'Broken pipe', "Stale socket errored out before helo");
        close $sock;
        $@ = undef;

        #TODO: read data from urandom, spit it into NRD and let it run for a while...
        $sock = IO::Socket::INET->new(PeerAddr => $host,
                                    PeerPort => $port,
                                    Proto    => 'tcp',
                                 ) || die "Can't connect [$!]";

        my $serializer = NRD::Serialize->instance_of('crypt',
          {encrypt_type => 'Blowfish', encrypt_key => 'dekjr+34lkr' }
        );
        my $packer = NRD::Packet->new();
        # Send the helo
        print $sock $packer->pack($serializer->helo);
        sleep 8;
        print $sock ("XXXXXXXXXX" x 1000);
        is( $!, 'Broken pipe', "Stale socket errored out after helo" );
        close $sock;
        $@ = undef;


        #The important thing, in the end is that the results we send now get to the server intact.
        $nsca->send($data);
        sleep 1;                # Need to wait for --daemon to finish processing

        my $output = $nsca->read_cmd;
        is_deeply($data, $output, "Got all data as expected");

        $nsca->stop;
}

