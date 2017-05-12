# Test Ext.Direct API handling with local instance

package test::class;

use RPC::ExtDirect::Event;
use RPC::ExtDirect Action => 'test';

sub foo : ExtDirect(0) { 'foo' }

sub poll : ExtDirect(pollHandler) {
    return ( RPC::ExtDirect::Event->new('foo', 'bar') )
}

package main;

use strict;
use warnings;

use Test::More tests => 9;

use RPC::ExtDirect::Client;

use lib 't/lib';
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client::Test::Util;

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# Client gets created before server can respond; this way we make sure
# the API is indeed not retrieved remotely

my $cclass = 'RPC::ExtDirect::Client';
my $aclass = 'RPC::ExtDirect::Client::API';

my $api = RPC::ExtDirect->get_api();

my $client = eval {
    $cclass->new(
        host => 'localhost', # should work
        api  => $api,
        timeout => 1,
    )
};

is     $@,      '',      "Constructor eval $@";
ok     $client,          "Got object";
ref_ok $client, $cclass, "Client object";

my $remoting_api = $client->get_api('remoting');

ref_ok $remoting_api, $aclass, "Remoting API object";

my $polling_api = $client->get_api('polling');

ref_ok $polling_api, $aclass, "Polling API object";

# Finally start the server and run some calls
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');

$client->port($port);

my $data = eval {
    $client->call(
        action => 'test',
        method => 'foo',
        arg    => [],
    )
};

is $@,    '',    "call() didn't die";
is $data, 'foo', "call() result matches";

my @events = eval { $client->poll() };

my $want = [{
    name => 'foo',
    data => 'bar',
}];

is      $@,       '',    "poll() didn't die";
is_deep \@events, $want, "poll() data matches";

