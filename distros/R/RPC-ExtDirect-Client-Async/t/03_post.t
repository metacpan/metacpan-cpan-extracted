# Test asynchronous Ext.Direct Method calls via POST

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use RPC::ExtDirect::Test::Pkg::Meta;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Client::Async::Test::Util;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

plan tests => 5 + (4 * @$tests);

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cv = AnyEvent->condvar;

my $cclass = 'RPC::ExtDirect::Client::Async';
my $client = eval {
    $cclass->new(
        host   => $host,
        port   => $port,
        cv     => $cv,
    )
};

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Right object, too,';

# maybe_start_server will leave arguments it doesn't know about
my %run_only = map { $_ => 1 } @ARGV;

TEST:
for my $test ( @$tests ) {
    my $name   = $test->{name};
    my $action = $test->{action};
    my $method = $test->{method};
    my $arg    = $test->{arg};
    my $meta   = $test->{meta};
    my $want   = $test->{want};
    my $err_re = $test->{error};
    
    next TEST if %run_only && !$run_only{$name};
    
    eval {
        $client->call_async(
            action   => $action,
            method   => $method,
            arg      => $arg,
            metadata => $meta,
            cv       => $cv,
            cb       => sub {
                my ($result, $success, $error) = @_;
                
                my $ref = ref $result;
                
                # $success is *transport* success; when we're testing
                # methods returning exceptions, the mere fact that we
                # did receive the response already means successful
                # invocation. So in fact we should have *no* unsuccessful
                # calls at all in this test suite.
                ok $success, "$name: successful";
                
                if ( $err_re ) {
                    my $msg = $result->message;
                    like $ref, qr/Exception/, "$name: exception";
                    like $msg, $err_re,       "$name: error message";
                }
                else {
                    unlike  $ref,    qr/Exception/, "$name: no exception";
                    is_deep $result, $want,         "$name: result data";
                }
            },
        );
    };
    
    is $@, '', "$name didn't die";
}

# Block until all tests above finish
$cv->recv;

# Test cv as the callback
$cv = AnyEvent->condvar;

$client->call_async(
    action => 'test',
    method => 'ordered',
    arg    => [41, 42, 43],
    cb     => $cv,
);

# This should block
my $have = $cv->recv;

is_deep $have, [41, 42, 43], "cv as callback data matches";

__DATA__
#line 116
# These tests are literally copied from the corresponding t/03_post.t
# in RPC::ExtDirect::Client. Both test sets should always be in sync!
[{
    name   => 'Ordered arguments',
    action => 'test',
    method => 'ordered',
    arg    => [ qw(foo bar qux mumble splurge) ],
    want   => [ qw(foo bar qux) ],
}, {
    name   => 'Named arguments',
    action => 'test',
    method => 'named',
    arg    => {
        arg1 => 'foo', arg2 => 'bar',
        arg3 => 'qux', arg4 => 'mumble',
    },
    want   => { arg1 => 'foo', arg2 => 'bar', arg3 => 'qux', },
}, {
    name   => 'Named arguments !strict',
    action => 'test',
    method => 'named_no_strict',
    arg    => {
        arg1 => 'foo', arg2 => 'bar',
        arg3 => 'qux', arg4 => 'mumble',
    },
    want   => {
        arg1 => 'foo', arg2 => 'bar',
        arg3 => 'qux', arg4 => 'mumble',
    },
}, {
    name   => 'Method dies',
    action => 'test',
    method => 'dies',
    arg    => [],
    error  => qr/Whoa/,
}, {
    name   => 'Ordered metadata 1',
    action => 'Meta',
    method => 'arg0',
    arg    => [],
    meta   => [42, 'foo'],
    want   => { meta => [42, 'foo'], },
}, {
    name   => 'Ordered metadata 2',
    action => 'Meta',
    method => 'arg1_last',
    arg    => ['foo'],
    meta   => [42],
    want   => { arg1 => 'foo', meta => [42], },
}, {
    name   => 'Ordered metadata 3',
    action => 'Meta',
    method => 'arg1_first',
    arg    => ['foo'],
    meta   => [42, 43],
    want   => { arg1 => 'foo', meta => [42, 43], },
}, {
    name   => 'Ordered metadata 4',
    action => 'Meta',
    method => 'arg2_last',
    arg    => [42, 43],
    meta   => ['foo', 'bar'],
    want   => { arg1 => 42, arg2 => 43, meta => ['foo'], },
}, {
    name   => 'Ordered metadata 5',
    action => 'Meta',
    method => 'arg2_middle',
    arg    => [44, 45],
    meta   => [qw/ fred bonzo qux /],
    want   => { arg1 => 44, arg2 => 45, meta => ['fred', 'bonzo'], },
}, {
    name   => 'Ordered metadata 6',
    action => 'Meta',
    method => 'named_default',
    arg    => { foo => 'bar', fred => 'bonzo' },
    meta   => ['throbbe'],
    want   => { foo => 'bar', fred => 'bonzo', meta => ['throbbe'], },
}, {
    name   => 'Ordered metadata 7',
    action => 'Meta',
    method => 'named_arg',
    arg    => { qux => 'frob', },
    meta   => ['sploosh!'],
    want   => { meta => ['sploosh!'], qux => 'frob', },
}, {
    name   => 'Ordered metadata 8',
    action => 'Meta',
    method => 'named_arg',
    arg    => { foo => 'bar' },
    meta   => ['guzzard'],
    want   => { meta => ['guzzard'], },
}, {
    name   => 'Named metadata 1',
    action => 'Meta',
    method => 'named_strict',
    arg    => { frob => 'dux', frogg => 'bonzo' },
    meta   => { foo => { bar => { baz => 42 } } },
    want   => {
        frob => 'dux', frogg => 'bonzo',
        meta => { foo => { bar => { baz => 42 } } },
    },
}, {
    name   => 'Named metadata 2',
    action => 'Meta',
    method => 'named_unstrict',
    arg    => { qux => undef },
    meta   => {},
    want   => { meta => {}, qux => undef, },
}];
