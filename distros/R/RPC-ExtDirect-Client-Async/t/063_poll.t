# Test multiple events per response

package test::class;

use strict;

use RPC::ExtDirect Action => 'test';
use RPC::ExtDirect::Event;

our $EVENTS = [{
    name => 'foo', data => 'bar',
}, {
    name => 'bar', data => { fred => 'frob' },
}, {
    name => 'qux', data => [qw/ blerg blarg blurg /],
}];

sub handle_poll : ExtDirect(pollHandler) {
    return map { RPC::ExtDirect::Event->new($_) } @$EVENTS;
}

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
    host => $host,
    port => $port,
    cv   => $cv,
);

ok $client, 'Got client object';

my $want = $test::class::EVENTS;

$client->poll_async(
    cv => $cv,
    cb => sub {
        is_deep shift, $want, "Multiple events data";
    },
);

# Block until all tests finish
$cv->recv;

