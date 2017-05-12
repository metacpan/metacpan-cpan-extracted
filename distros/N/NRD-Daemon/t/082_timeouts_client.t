#!/usr/bin/perl
#
# DESCRIPTION:
#	Test client timeouts
#
# LICENCE:
#	GNU GPLv2

package DummyServer;
use Net::Server::Single;
use base qw(Net::Server::Single);

use Data::Dumper;
# Limit rate of reading and replying to catch timeouts
sub process_request {
    my $self = shift;
    while( read(*STDIN, my $data, 1) ) {
        #print STDERR "->$data\n";
        print $data;
        sleep 1;
    }
}

1;

package main;

use lib 't';

use strict;
use NSCATest;
use Test::More;
use Net::Server::Fork;

plan tests => 1;

my $host = 'localhost';
my $port = 7669;

my $pid = fork();
if (! $pid) {
    DummyServer->run(port => $port, background => undef, setsid => 0);
    exit;
}
sleep 1;

END { if ($pid) { print "Killing $pid\n"; kill 'TERM', $pid } };

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

eval { 
    my $client = NRD::Client->new( { timeout => 5, serializer => "plain" } );
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
like( $@, qr/Timeout/, "Got timeout failure sending" );
