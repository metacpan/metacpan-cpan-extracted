#!/usr/bin/perl
#
# DESCRIPTION:
#	Test client for memory leaks
#
# LICENCE:
#	GNU GPLv2

use lib 't';

use strict;
use NSCATest;
use Test::More;
use Net::Server::Fork;
use Test::Memory::Cycle;

plan tests => 2;

my $host = 'localhost';
my $port = 7669;


my $nsca = NSCATest->new( config => "plain" );
$nsca->start("--server_type=Single");

sleep 1;

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

use NRD::Client;

my $client;
eval { 
    $client = NRD::Client->new( { timeout => 5, serializer => "plain" } );
    $client->connect( PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp" );
    foreach my $d ( @$data ) {
        $client->send_result( { 
            command => "result", 
            data => { 
                time => time(), 
                %{ $client->{serializer}->from_line( join("\t", @$d) ) },
            },
        } );
    }
    $client->end;
};
is( $@, '', "No errors" );
memory_cycle_ok( $client, "No memory cycles for client" );

$nsca->stop;

