# Test event poll handling for empty responses

package test::class;

use strict;

use RPC::ExtDirect;
use RPC::ExtDirect::Event;

sub handle_poll : ExtDirect(pollHandler) { return; }

package main;

use strict;
use warnings;

use Test::More tests => 3;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use lib 't/lib';
use RPC::ExtDirect::Client::Async::Test::Util;

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cv = AnyEvent->condvar;

my $client = RPC::ExtDirect::Client::Async->new(
    host   => $host,
    port   => $port,
    cv     => $cv,
);

ok $client, 'Got client object';

$client->poll_async(
    cv => $cv,
    cb => sub {
        is_deep shift, [], "Empty poll response";
    },
);

# Block until all tests finish
$cv->recv;

