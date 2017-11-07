use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Exception;

plan tests => 1 + 2;

use HTTP::Request ();

use Net::WebSocket::Constants ();
use Net::WebSocket::Handshake::Client ();
use Net::WebSocket::Handshake::Server ();

my $client = Net::WebSocket::Handshake::Client->new(
    uri => 'ws://nada.tld',
);

my ($key) = $client->to_string =~ m<-Key:\s+(\S+)> or die 'where key?';

my $server = Net::WebSocket::Handshake::Server->new();

lives_ok(
    sub {
        $server->consume_headers(
            'sec-websocket-version' => Net::WebSocket::Constants::PROTOCOL_VERSION(),
            'sec-websocket-key' => $key,
            'connection' => 'upgrade',
            'upgrade' => 'websocket',
        );
    },
    'Server consume_headers',
);

#----------------------------------------------------------------------

$server->to_string() =~ m<-Accept:\s+(\S+)> or die 'where Accept?';
my $accept = $1;

lives_ok(
    sub {
        $client->consume_headers(
            'connection' => 'upgrade',
            'upgrade' => 'websocket',
            'sec-websocket-accept' => $accept,
        );
    },
    'Client consume headers',
);
