# Test error handling in API retrieval

use strict;
use warnings;

use Test::More tests => 13;

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

my $want = "Can't download API declaration: 404";
our $have;

my $cv = AnyEvent->condvar;

my $client = eval {
    $cclass->new(
        api_path => '/nonexistent',
        host     => $host,
        port     => $port,
        cv       => $cv,
        api_cb   => sub {
            my ($self, $success, $error) = @_;

            $have = $error;

            ok !$success,     "API retrieval unsuccessful";
            is $error, $want, "Got 404 error";

            my $r_api = $self->get_api('remoting');
            my $p_api = $self->get_api('polling');

            is $r_api, undef, "Remoting API not set";
            is $p_api, undef, "Polling API not set";
        },
    )
};

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Client';

# This call should go through and not die, but callback will get
# the exception instead of actual result
eval {
    $client->call_async(
        action => 'test',
        method => 'ordered', # method exists
        arg    => [1,2,3],   # arguments are right
        cb     => sub {
            my ($result, $success, $error) = @_;
            
            ok !$success,        "Got exception in cb";
            is $error,    $want, "Got 404 error in cb";
            is $result,   undef, "Got undef result in cb";
        }
    )
};

is $@, '', "call_async didn't die";

$cv->recv;

my $ex = $client->exception;

is $ex, $have, "Exception set";

