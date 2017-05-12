# Test creating the Client with local API instance

use strict;
use warnings;

use Test::More tests => 11;

use AnyEvent; # for condvar
use RPC::ExtDirect;
use RPC::ExtDirect::Client::Async;

use lib 't/lib';
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client::Async::Test::Util;
use test::class;

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my $cclass = 'RPC::ExtDirect::Client::Async';
my $aclass = 'RPC::ExtDirect::Client::API';

my $api = RPC::ExtDirect->get_api();

our $api_cb_run;

my $cv = AnyEvent->condvar;

my $client = eval {
    $cclass->new(
        host   => 'localhost', # should be enough
        cv     => $cv,
        api    => $api,
        api_cb => sub {
            $api_cb_run = \@_;
        }
    )
};

is     $@,      '',      "Constructor eval $@";
ok     $client,          "Got client object";
ref_ok $client, $cclass, "Client";

ok $cv->ready, "cv signaled";
is_deep $api_cb_run, [$client, 1], "api_cb run";

ok $client->api_ready, "API ready";

my $remoting_api = $client->get_api('remoting');

ref_ok $remoting_api, $aclass, "Remoting API object";

my $polling_api = $client->get_api('polling');

ref_ok $polling_api, $aclass, "Polling API object";

# Finally start the server
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

$client->port($port);

$cv = AnyEvent->condvar;

# Not exactly cool at this point, but who cares
eval {
    $client->call_async(
        action => 'test',
        method => 'ping',
        arg    => [],
        cb     => sub {
            my $have = shift;
            my $want = JSON::true;
            
            cmp_ok $have, '==', $want, "Call data matches"
                or diag explain "Have:", $have, "Want:", $want;
        },
    )
};

eval {
    $client->poll_async(
        cv => $cv,
        cb => sub {
            my $have = shift;

            my $want = [{ name => 'foo', data => 'foo' }];

            is_deep $have, $want, "Poll data matches";
        },
    )
};

# Block until all tests are finished
$cv->recv;

