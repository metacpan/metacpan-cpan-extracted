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
use Time::HiRes     qw( gettimeofday );
use Redis::CappedCollection qw(
    $DEFAULT_SERVER
    $DEFAULT_PORT
    $NAMESPACE
    );

use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [] )

my $redis_error = "Unable to create test Redis server";
my ( $redis, $skip_msg, $port ) = verify_redis();

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

    {
        no warnings;
        $Redis::CappedCollection::WAIT_USED_MEMORY = 1;
    }

# For Test::RedisServer
isa_ok( $redis, 'Test::RedisServer' );

my ( $coll, $name, $tmp, $status_key, $queue_key, $cleanup_bytes, $maxmemory, @arr );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

sub new_connect {
    # For Test::RedisServer
    $redis->stop if $redis;
    $port = Net::EmptyPort::empty_port( $port );
    $redis = get_redis( conf =>
        {
            port                => $port,
            maxmemory           => $maxmemory,
#            "vm-enabled"        => 'no',
            "maxmemory-policy"  => 'noeviction',
            "maxmemory-samples" => 100,
        } );
    skip( $redis_error, 1 ) unless $redis;
    isa_ok( $redis, 'Test::RedisServer' );

    $coll->quit if $coll;
    $coll = Redis::CappedCollection->create(
        redis   => $redis,
        name    => $uuid->create_str,
        $cleanup_bytes ? ( 'cleanup_bytes' => $cleanup_bytes ) : (),
        );
    isa_ok( $coll, 'Redis::CappedCollection' );

    ok ref( $coll->_redis ) =~ /Redis/, $msg;

    $status_key  = $NAMESPACE.':S:'.$coll->name;
    $queue_key   = $NAMESPACE.':Q:'.$coll->name;
    ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
    ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";
}

$cleanup_bytes = 0;
$maxmemory = 0;
new_connect();
is $coll->cleanup_bytes, 0, $msg;
$coll->drop_collection;

$cleanup_bytes = 50_000;
new_connect();
is $coll->cleanup_bytes, $cleanup_bytes, $msg;

my $data_id = 0;

$coll->insert( 'List id', $data_id++, '*' x 10_000 ) for 1..10;
$name = 'TEST';
$tmp = $data_id;
$coll->insert( $name, $data_id++, '*' );
$coll->insert( $name, $data_id++, '*' x 10_000 );

$coll->update( $name, $tmp, '*' x 10_000 );

$coll->insert( $name, $data_id++, '*' x 10_000 ) for 1..4;

dies_ok { $coll->cleanup_bytes( -1 ) } "expecting to die: cleanup_bytes is negative";

$coll->drop_collection;

$cleanup_bytes = 0;
new_connect();
$tmp = 'A';
$data_id = 0;
$coll->insert( $name, $data_id++, $tmp++, gettimeofday + 0 ) for 1..10;
@arr = $coll->receive( $name );
is "@arr", "A B C D E F G H I J", "correct value";
$coll->insert( $name, $data_id++, $tmp++, gettimeofday + 0 );
@arr = $coll->receive( $name );
is "@arr", "A B C D E F G H I J K", "correct value";

foreach my $arg ( ( undef, 0.5, -1, -3, "", "0.5", \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        redis           => $redis,
        name            => $uuid->create_str,
        cleanup_bytes   => $arg,
        ) } "expecting to die: ".( $arg || '' );
}

foreach my $arg ( ( undef, 0.04, 0.6, -1, -3, "", "0.6", \"scalar", [], $uuid ) )
{
    dies_ok { $coll = Redis::CappedCollection->create(
        redis           => $redis,
        name            => $uuid->create_str,
        memory_reserve  => $arg,
        ) } "expecting to die: ".( $arg || '' );
}

}
