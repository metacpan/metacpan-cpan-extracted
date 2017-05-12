# Test asynchronous Ext.Direct API retrieval

use strict;
use warnings;

use Test::More tests => 8;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Client::Async::Test::Util;

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cclass = 'RPC::ExtDirect::Client::Async';
my $apicls = 'RPC::ExtDirect::Client::API';

# Successful retrieval
my $cv = AnyEvent->condvar;

my $client = eval {
    $cclass->new(
        host   => $host,
        port   => $port,
        cv     => $cv,
        api_cb => sub {
            my ($self, $success, $error) = @_;

            ok $success,        "API retrieval success";
            is $error,   undef, "Error is empty";

            my $api = $self->get_api('remoting');

            ref_ok $api, $apicls, "Remoting API";

            $api = $self->get_api('polling');

            ref_ok $api, $apicls, "Polling API";
        },
    )
};

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Client';

# Block until all tests finish
$cv->recv;

