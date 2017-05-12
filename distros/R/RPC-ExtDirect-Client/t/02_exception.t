# Test Ext.Direct exception handling

use strict;
use warnings;

use Test::More;

use RPC::ExtDirect::Client;

use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Test::Pkg::Meta;

use lib 't/lib';
use test::class;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Client::Test::Util;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

plan tests => 4 + @$tests;

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# Host/port in @ARGV means there's server listening elsewhere
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cclass = 'RPC::ExtDirect::Client';
my $client = eval { $cclass->new( host => $host, port => $port, timeout => 1, ) };

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
    my $type   = $test->{type} || 'call';
    my $arg    = $test->{arg};
    my $meta   = $test->{meta};
    my $upload = $test->{upload};
    my $error  = $test->{error};
    
    next TEST if %run_only && !$run_only{ $name };
    
    # All tests should die so checking return value is unnecessary
    eval {
        $client->$type(
            action   => $action,
            method   => $method,
            arg      => $arg,
            metadata => $meta,
            upload   => $upload,
        );
    };
    
    like $@, $error, "$name: exception matches";
}

__DATA__
#line 67
# This data should be always kept synchronized with the corresponding
# section in RPC::ExtDirect::Client::Async t/02_exception.t
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
