# Test cookie handling w/ asynchronous calls

use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

eval {
    require AnyEvent::HTTP;
};

if ( $@ ) {
    plan skip_all => "AnyEvent::HTTP not present";
}
else {
    eval "use RPC::ExtDirect::Client::Async";

    plan tests => 7;
};

use lib 't/lib';
use test::class::cookies;
use RPC::ExtDirect::Client::Async::Test::Util;

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my %client_params = (
    host    => $host,
    port    => $port,
    timeout => 100000,
);

my $tests = eval do { local $/; <DATA>; }       ## no critic
    or die "Can't eval DATA: '$@'";

run_tests(%$_) for @$tests;

sub run_tests {
    my %params = @_;
    
    my $client_params  = $params{client_params};
    my $cookie_jar     = $params{cookie_jar};
    my $desc           = $params{desc};
    my $expected_data  = $params{expected_data};
    my $expected_event = { name => 'cookies', data => $expected_data };
    
    my $api_cv = AnyEvent->condvar;
    
    my $client = RPC::ExtDirect::Client::Async->new(
        @$client_params,
        cv => $api_cv,
    );
    
    $api_cv->recv;
    
    my $cv = AnyEvent->condvar;
    
    $client->call_async(
        $cookie_jar ? (cookies => $cookie_jar) : (),
        action  => 'test',
        method  => 'ordered',
        arg     => [],
        cv      => $cv,
        cb      => sub {
            my $have = shift;
            
            is_deep $have, $expected_data, "Ordered with $desc";
        },
    );
    
    $client->submit_async(
        $cookie_jar ? (cookies => $cookie_jar) : (),
        action  => 'test',
        method  => 'form',
        arg     => {},
        cv      => $cv,
        cb      => sub {
            my $data = shift;
            
            is_deep $data, $expected_data, "Form handler with $desc";
        },
    );
    
    $client->poll_async(
        $cookie_jar ? (cookies => $cookie_jar) : (),
        cv => $cv,
        cb => sub {
            my $event = shift;

            is_deep $event, [$expected_event], "Poll handler with $desc";
        },
    );

    $cv->recv;
}

__DATA__

[
    {
        desc           => 'raw cookies w/ new',
        expected_data  => { foo => 'bar', bar => 'baz', },
        client_params  => [
            %client_params,
            cookies => { foo => 'bar', bar => 'baz', },
        ],
    },
   {
        desc           => 'raw cookies w/ call',
        cookie_jar     => {
            bar => 'foo',
            baz => 'bar',
        },
        expected_data  => {
            bar => 'foo',
            baz => 'bar',
        },
        client_params  => [ %client_params ],
    },
]
