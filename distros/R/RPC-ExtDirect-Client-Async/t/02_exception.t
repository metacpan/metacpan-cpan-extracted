# Test exceptions and server failure handling

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Client::Async::Test::Util;
use RPC::ExtDirect::Test::Pkg::Meta;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

plan tests => 11 + (8 * @$tests);

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cv = AnyEvent->condvar;

my $cclass = 'RPC::ExtDirect::Client::Async';
my $client = eval {
    $cclass->new( host => $host, port => $port, cv => $cv, )
};

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Right object, too,';

# This should die despite API not being ready
eval {
    $client->call_async(
        action => 'test',
        method => 'ordered', #exists
        arg    => [],
    )
};

like $@, qr{^Callback subroutine is required},
         "Died at no callback provided before ready";

# These calls should NOT die but pass the error to callback instead
run_batch($client, 'before API ready', $tests);

# Block until we got API
$cv->recv;

# Sanity checks
is $client->api_ready, 1,     "Got API ready";
is $client->exception, undef, "No exception set";

# This should also die the same way as before API is ready
eval {
    $client->call_async(
        action => 'test',
        method => 'ordered', #exists
        arg    => [],
    )
};

like $@, qr{^Callback subroutine is required},
         "Died at no callback provided after ready";

# This should treat the cv as callback and pass the error on to it
my $cv2 = AnyEvent->condvar;

eval {
    $client->call_async(
        action => 'test',
        method => 'nonexistent',
        arg    => [],
        cb     => $cv2,
    )
};

is $@, '', "CV as callback eval $@";

my $want = [
    undef, '', 'Method nonexistent is not found in Action test'
];

# Block, but briefly
my $have = $cv2->recv;
my @have = $cv2->recv;

is       $have, undef, "CV as callback result scalar context";
is_deep \@have, $want, "CV as callback result list context";

# These calls should behave the same way as before API is ready,
# i.e. not die but pass the error to the callback
run_batch($client, 'after API ready', $tests);

sub run_batch {
    my ($client, $phase, $tests) = @_;
    
    TEST:
    for my $test ( @$tests ) {
        my $name   = $test->{name};
        my $type   = $test->{type} || 'call';
        my $err_re = $test->{error};
        
        my $msg      = "($phase) $name";
        my $sub_name = "${type}_async";
        
        eval {
            $client->$sub_name(
                action   => $test->{action},
                method   => $test->{method},
                arg      => $test->{arg},
                metadata => $test->{meta},
                upload   => $test->{upload},
                cb       => sub {
                    my ($result, $success, $error) = @_;
                    
                    is    $result,  undef,   "$msg result";
                    ok   !$success,          "$msg success";
                    like  $error,   $err_re, "$msg error";
                },
            );
        };
        
        is $@, '', "$msg didn't die";
    }
}

__DATA__
#line 139
# These tests are literally copied from the corresponding t/02_exceptions.t
# in RPC::ExtDirect::Client. Both test sets should always be in sync!
[{
    name   => 'Nonexistent Action',
    action => 'nonexistent',
    method => 'ordered',
    error  => qr/^Action nonexistent is not found/,
}, {
    name   => 'Existing Action, nonexistent Method',
    action => 'test',
    method => 'nonexistent',
    error  => qr/^Method nonexistent is not found in Action test/,
}, {
    name   => 'Ordered Method, not enough arguments',
    action => 'test',
    method => 'ordered',
    arg    => [ 42 ],
    error  => qr/requires 3 argument\(s\) but only 1 are provided/,
}, {
    name   => 'Ordered Method, wrong argument type',
    action => 'test',
    method => 'ordered',
    arg    => {},
    error  => qr/expects ordered arguments in arrayref/,
}, {
    name   => 'Named Method strict, not enough arguments',
    action => 'test',
    method => 'named',
    arg    => { arg1 => 'foo', arg2 => 'bar', },
    error  => qr/parameters: 'arg1, arg2, arg3'; these are missing: 'arg3'/,
}, {
    name   => 'Named Method !strict, not enough arguments',
    action => 'test',
    method => 'named_no_strict',
    arg    => { arg1 => 'baz', },
    error  => qr/parameters: 'arg1, arg2'; these are missing: 'arg2'/,
}, {
    name   => 'Named Method, wrong argument type',
    action => 'test',
    method => 'named',
    arg    => [],
    error  => qr/expects named arguments in hashref/,
}, {
    name   => 'formHandler, wrong argument type',
    action => 'test',
    method => 'form',
    arg    => [],
    error  => qr/expects named arguments in hashref/,
}, {
    name   => 'formhandler, nonexistent upload',
    type   => 'upload',
    action => 'test',
    method => 'form',
    arg    => {},
    upload => ['nonexistent_file_with_a_long_name'],
    error  => qr{Upload entry 'nonexistent_file_with_a_long_name' is not readable},
}, {
    name   => 'Invalid ordered metadata 1',
    action => 'Meta',
    method => 'arg0',
    arg    => [],
    meta   => {},
    error  => qr/Meta\.arg0 expects metadata in arrayref/,
}, {
    name   => 'Invalid ordered metadata 2',
    action => 'Meta',
    method => 'arg0',
    arg    => [],
    meta   => [],
    error  => qr/Meta\.arg0 requires 2 metadata.*?but only 0/,
}, {
    name   => 'Invalid ordered metadata 3',
    action => 'Meta',
    method => 'arg0',
    arg    => [],
    meta   => [42],
    error  => qr/Meta\.arg0 requires 2 metadata.*?but only 1/,
}, {
    name   => 'Invalid named metadata 1',
    action => 'Meta',
    method => 'named_strict',
    arg    => {},
    meta   => [],
    error  => qr/Meta\.named_strict expects metadata key\/value/,
}, {
    name   => 'Invalid named metadata 2',
    action => 'Meta',
    method => 'named_strict',
    arg    => {},
    meta   => {},
    error  => qr/Meta\.named_strict requires.*?keys: 'foo'.*?missing: 'foo'/,
}];
