#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib', 't/tlib';

use Test::More;
plan "no_plan";

BEGIN {
    eval "use Test::Exception";                 ## no critic
    plan skip_all => "because Test::Exception required for testing" if $@;
}

BEGIN {
    eval "use Test::RedisServer";               ## no critic
    plan skip_all => "because Test::RedisServer required for testing" if $@;
}

BEGIN {
    eval "use Net::EmptyPort";                  ## no critic
    plan skip_all => "because Net::EmptyPort required for testing" if $@;
}

BEGIN {
    eval 'use Test::NoWarnings';                ## no critic
    plan skip_all => 'because Test::NoWarnings required for testing' if $@;
}

use bytes;
use Data::UUID;
use Redis::CappedCollection qw(
    $DEFAULT_SERVER
    $DEFAULT_PORT
    $DEFAULT_CONNECTION_TIMEOUT
    $DEFAULT_OPERATION_TIMEOUT
    $E_INCOMP_DATA_VERSION
    $E_NO_ERROR
    $NAMESPACE
    );

use Redis::CappedCollection::Test::Utils qw(
    clear_coll_data
    get_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [] )

my $redis;
my $skip_msg;
my $error;
my $redis_error = "Unable to create test Redis server";
my $port = Net::EmptyPort::empty_port( $DEFAULT_PORT );

my $redis_server = get_redis(
    conf    => {
        port                => $port,
        'maxmemory-policy'  => 'noeviction',
    },
    _redis  => 1,
);
$skip_msg = $redis_error unless $redis_server;
my $redis_addr = $DEFAULT_SERVER.":$port";
eval { $redis = Redis->new( server => $redis_addr ) };
$skip_msg = $redis_error unless $redis;
$skip_msg = "Redis server version 2.8 or higher is required" if ( !$skip_msg && !eval { return $redis->eval( 'return 1', 0 ) } );

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

isa_ok( $redis_server, 'Test::RedisServer' );
isa_ok( $redis, 'Redis' );

my $redis_server_info = $redis->info( 'server' );
my $redis_version = $redis_server_info->{redis_version};
diag "redis-server version: $redis_version";

my ( $coll, $name, $tmp, $status_key, $queue_key );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

# all default

# a class method
$coll = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str );
isa_ok( $coll, 'Redis::CappedCollection' );
is $coll->_server, $redis_addr, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;
is bytes::length( $coll->name ), bytes::length( '89116152-C5BD-11E1-931B-0A690A986783' ), $msg;
is $coll->max_datasize, $Redis::CappedCollection::MAX_DATASIZE, $msg;
is $coll->last_errorcode, $E_NO_ERROR, $msg;

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";
ok $coll->_call_redis( "HEXISTS", $status_key, 'cleanup_bytes' ), "status field created";
ok $coll->_call_redis( "HEXISTS", $status_key, 'cleanup_items' ), "status field created";
ok $coll->_call_redis( "HEXISTS", $status_key, 'memory_reserve' ), "status field created";
ok $coll->_call_redis( "HEXISTS", $status_key, 'lists' ), "status field created";
is $coll->_call_redis( "HGET", $status_key, 'cleanup_bytes' ), $coll->cleanup_bytes, "correct status value";
is $coll->_call_redis( "HGET", $status_key, 'cleanup_items' ), $coll->cleanup_items, "correct status value";
is $coll->_call_redis( "HGET", $status_key, 'memory_reserve' ), $coll->memory_reserve, "correct status value";
is $coll->_call_redis( "HGET", $status_key, 'lists' ), 0, "correct status value";

my $coll_1 = Redis::CappedCollection->create( redis => { server => $redis_addr }, name => $uuid->create_str );
my $coll_2 = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str );
ok $coll_1->name ne $coll_2->name, "new UUID";

my $open_coll1 = Redis::CappedCollection->open( redis => $coll_1->_redis, name => $coll_1->name );
ok $open_coll1->name eq $coll_1->name, "correct UUID";
ok !$open_coll1->reconnect_on_error, 'no reconnect_on_error';
is $open_coll1->connection_timeout, undef, $msg;
is $open_coll1->operation_timeout, undef, $msg;
$open_coll1 = Redis::CappedCollection->open( redis => { server => $coll_1->_server }, name => $coll_1->name );
ok $open_coll1->name eq $coll_1->name, "correct UUID";
ok !$open_coll1->reconnect_on_error, 'no reconnect_on_error';
is $open_coll1->connection_timeout, $DEFAULT_CONNECTION_TIMEOUT, 'set connection_timeout';
is $open_coll1->operation_timeout, $DEFAULT_OPERATION_TIMEOUT, 'set operation_timeout';
$open_coll1 = Redis::CappedCollection->open( redis => { server => $coll_1->_server }, name => $coll_1->name, reconnect_on_error => 1 );
ok $open_coll1->name eq $coll_1->name, "correct UUID";
ok $open_coll1->reconnect_on_error, 'reconnect_on_error';
$open_coll1 = Redis::CappedCollection->open( redis => { server => $coll_1->_server }, name => $coll_1->name, connection_timeout => $DEFAULT_CONNECTION_TIMEOUT );
ok $open_coll1->name eq $coll_1->name, "correct UUID";
$open_coll1 = Redis::CappedCollection->open( redis => { server => $coll_1->_server }, name => $coll_1->name, operation_timeout => $DEFAULT_OPERATION_TIMEOUT );
ok $open_coll1->name eq $coll_1->name, "correct UUID";
$open_coll1 = Redis::CappedCollection->open(
    redis               => { server => $coll_1->_server },
    name                => $coll_1->name,
    max_datasize        => 1_000,
    check_maxmemory     => 1,
    reconnect_on_error  => 1,
    connection_timeout  => 0.1,
    operation_timeout   => $DEFAULT_OPERATION_TIMEOUT
);
ok $open_coll1->name eq $coll_1->name, "correct UUID";
dies_ok { Redis::CappedCollection->open() } "expecting to die";

$coll_1->_call_redis( 'HDEL', $NAMESPACE.':S:'.$coll_1->name, 'data_version' );
eval { Redis::CappedCollection->open( redis => $coll_1->_redis, name => $coll_1->name ) };
my $error = $@;
ok $error, 'exception';
my $error_msg = $Redis::CappedCollection::ERROR{ $E_INCOMP_DATA_VERSION };
like( $error, qr/$error_msg/, 'E_INCOMP_DATA_VERSION' );
note '$@: ', $error;

$coll = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str );
isa_ok( $coll, 'Redis::CappedCollection' );
$coll = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str, reconnect_on_error => 1 );
isa_ok( $coll, 'Redis::CappedCollection' );
$coll = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str, connection_timeout => $DEFAULT_CONNECTION_TIMEOUT );
isa_ok( $coll, 'Redis::CappedCollection' );
$coll = Redis::CappedCollection->create( redis => $redis, name => $uuid->create_str, operation_timeout => $DEFAULT_OPERATION_TIMEOUT );
isa_ok( $coll, 'Redis::CappedCollection' );
is $coll->_server, $redis_addr, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

clear_coll_data( $coll );
$coll->quit;

# each argument separately
foreach my $additional ( [ no_auto_connect_on_new => 1 ], [] )
{
    $redis = Redis->new(
        server => $redis_addr,
        @$additional,
    );

    $coll = Redis::CappedCollection->create(
        redis   => $redis,
        name    => $uuid->create_str,
    );
    isa_ok( $coll, 'Redis::CappedCollection' );
    is $coll->_server, $redis_addr, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;
}

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
is $coll->_server, $redis_addr, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$coll = Redis::CappedCollection->create(
    name    => $msg,
    redis   => $redis,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
is $coll->name, $msg, $msg;
clear_coll_data( $coll );

$coll = Redis::CappedCollection->create(
    name => $uuid->create_str,
    max_datasize => 98765,
    redis => $redis,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
is $coll->max_datasize, 98765, $msg;
clear_coll_data( $coll );

# errors in the arguments
$tmp = $coll.'';
foreach my $arg ( ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        $arg,
        ) } "expecting to die";
}
is $coll.'', $tmp, "value has not changed";

$tmp = $coll.'';
foreach my $arg ( ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        redis   => $arg,
        name    => $uuid->create_str,
        ) } "expecting to die";
}
is $coll.'', $tmp, "value has not changed";

$tmp = $coll.'';
foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        redis   => $redis,
        name    => $arg,
        ) } "expecting to die: ".( $arg || '' );
}
is $coll.'', $tmp, "value has not changed";

$coll = Redis::CappedCollection->create(
    name    => $uuid->create_str,
    redis   => $redis,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
$status_key  = $NAMESPACE.':S:'.$coll->name;
$name = $coll->name;
$coll->quit;
$tmp = $coll.'';
dies_ok {
    $coll = Redis::CappedCollection->create(
        redis   => $redis,
        name    => $name,
    ) } "expecting to die";
is $coll.'', $tmp, "value has not changed";

$redis = Redis->new(
    server => $redis_addr,
    );

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$tmp = $coll.'';
foreach my $arg ( ( undef, 0.5, -1, -3, "", "0.5", \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        redis           => $redis,
        max_datasize    => $arg,
        ) } "expecting to die: ".( $arg || '' );
    is $coll.'', $tmp, "value has not changed";
}

}
