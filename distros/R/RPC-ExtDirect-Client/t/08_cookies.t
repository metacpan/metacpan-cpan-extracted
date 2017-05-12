# Test cookie handling

package test::class;

use strict;

use RPC::ExtDirect  Action => 'test',
                    before => \&before_hook,
                    ;
use RPC::ExtDirect::Event;

our %cookies;

sub before_hook {
    my ($class, %params) = @_;

    my $env = $params{env};

    %cookies = map { $_ => $env->cookie($_) } $env->cookie;

    return 1;
}

sub ordered : ExtDirect(0) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub form : ExtDirect(formHandler) {
    my $ret  = { %cookies };
    %cookies = ();

    return $ret;
}

sub poll : ExtDirect(pollHandler) {
    return RPC::ExtDirect::Event->new(
        'cookies',
        { %cookies },
    );
}

package main;

use strict;
use warnings;

use Test::More tests => 13;

use lib 't/lib';
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client::Test::Util;
use RPC::ExtDirect::Client;

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# Host/port in @ARGV means there's server listening elsewhere
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $expected_data = {
    foo => 'bar',
    bar => 'baz',
};

my $expected_event = {
    name => 'cookies',
    data => $expected_data,
};

my $client = RPC::ExtDirect::Client->new(
    host    => $host,
    port    => $port,
    cookies => $expected_data,
    keep_alive => !1,
    timeout => 1,
);

run_tests(
    client         => $client,
    cookie_jar     => undef,
    desc           => 'raw cookies w/ new',
    expected_data  => $expected_data,
    expected_event => $expected_event,
);

$client = RPC::ExtDirect::Client->new(
    host        => 'localhost',
    port        => $port,
    keep_alive => !1,
    timeout => 1,
);

$expected_data = {
    bar => 'foo',
    baz => 'bar',
};

$expected_event = {
    name => 'cookies',
    data => $expected_data,
};

run_tests(
    client         => $client,
    cookie_jar     => $expected_data,
    desc           => 'raw cookies override',
    expected_data  => $expected_data,
    expected_event => $expected_event,
);

$expected_data = {
    qux   => 'frob',
    mymse => 'splurge',
};

$expected_event = {
    name => 'cookies',
    data => $expected_data,
};

run_tests(
    client         => $client,
    cookie_jar     => $expected_data,
    desc           => 'raw cookies per each call',
    expected_data  => $expected_data,
    expected_event => $expected_event,
);

SKIP: {
    skip "Need HTTP::Cookies", 3 unless eval "require HTTP::Cookies";

    my $cookie_jar = HTTP::Cookies->new;

    $cookie_jar->set_cookie(1, 'foo', 'bar', '/', '');
    $cookie_jar->set_cookie(1, 'bar', 'baz', '/', '');

    my $expected_data = {
        foo => 'bar',
        bar => 'baz',
    };

    my $expected_event = {
        name => 'cookies',
        data => $expected_data,
    };

    $client = RPC::ExtDirect::Client->new(
        host => $host,
        port => $port,
        keep_alive => !1,
        timeout => 1,
    );

    run_tests(
        client         => $client,
        cookie_jar     => $cookie_jar,
        desc           => 'HTTP::Cookies',
        expected_data  => $expected_data,
        expected_event => $expected_event,
    );
}

sub run_tests {
    my %params = @_;

    my $client         = $params{client};
    my $cookie_jar     = $params{cookie_jar};
    my $desc           = $params{desc};
    my $expected_data  = $params{expected_data};
    my $expected_event = $params{expected_event};
    
    my $data = $client->call(
        action  => 'test',
        method  => 'ordered',
        arg     => [],
        $cookie_jar ? (cookies => $cookie_jar) : (),
    );

    is_deep $data, $expected_data, "Ordered with $desc";

    $data = $client->submit(
        action  => 'test',
        method  => 'form',
        arg     => {},
        $cookie_jar ? (cookies => $cookie_jar) : (),
    );

    is_deep $data, $expected_data, "Form handler with $desc";

    my $event = $client->poll(
        $cookie_jar ? (cookies => $cookie_jar) : (),
    );

    is_deep $event, $expected_event, "Poll handler with $desc";
}
