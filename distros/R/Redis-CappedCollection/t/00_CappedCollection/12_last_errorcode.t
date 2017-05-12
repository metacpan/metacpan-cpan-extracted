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
use Params::Util qw(
    _NUMBER
);
use Redis::CappedCollection qw(
    $DEFAULT_PORT
    $NAMESPACE

    $E_NO_ERROR
    $E_MISMATCH_ARG
    $E_DATA_TOO_LARGE
    $E_NETWORK
    $E_MAXMEMORY_LIMIT
    $E_COLLECTION_DELETED
    $E_REDIS
    $E_DATA_ID_EXISTS
    $E_OLDER_THAN_ALLOWED
    );
use Time::HiRes;

use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [], $uuid )

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

my ( $coll, $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr, $len, $maxmemory, $policy, $older_allowed, $info );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

sub check_redis_config {
    if ( $policy eq 'noeviction' ) {
        ok Redis::CappedCollection::_maxmemory_policy_ok( redis => $coll->_redis ), 'check maxmemory-policy correct';
        ok $coll->_maxmemory_policy_ok, 'check maxmemory-policy correct';
        ok Redis::CappedCollection::redis_config_ok( redis => $coll->_redis ), 'redis config correct';
        ok $coll->redis_config_ok, 'redis config correct';
    } else {
        ok !Redis::CappedCollection::_maxmemory_policy_ok( redis => $coll->_redis ), 'check maxmemory-policy correct';
        ok !$coll->_maxmemory_policy_ok, 'check maxmemory-policy correct';
        ok !Redis::CappedCollection::redis_config_ok( redis => $coll->_redis ), 'redis config not correct';
        ok !$coll->redis_config_ok, 'redis config not correct';
    }
}

sub new_connect {
    # For Test::RedisServer
    $redis->stop if $redis;
    $port = Net::EmptyPort::empty_port( $DEFAULT_PORT );
    $redis = get_redis( conf =>
        {
            port                => $port,
            maxmemory           => $maxmemory,
#            "vm-enabled"        => 'no',
            "maxmemory-policy"  => $policy,
            "maxmemory-samples" => 100,
        } );
    skip( $redis_error, 1 ) unless $redis;
    isa_ok( $redis, 'Test::RedisServer' );

    $coll->quit if $coll;
    $coll = Redis::CappedCollection->create(
        redis           => { $redis->connect_info },
        name            => $uuid->create_str,
        older_allowed   => $older_allowed,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );

    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;
    check_redis_config();

    $status_key  = $NAMESPACE.':S:'.$coll->name;
    $queue_key   = $NAMESPACE.':Q:'.$coll->name;
    ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
    ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";
}

$maxmemory = 0;
$policy = "noeviction";
$older_allowed = 1;
new_connect();

my $data_id = 0;

#-- all correct

# some inserts
$len = 0;
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    ( $coll->insert( $i, $data_id++, $_ ), $tmp += bytes::length( $_.'' ), ++$len ) for $i..10;
}
$info = $coll->collection_info;
is $info->{lists},  10,     "OK lists - $info->{lists}";
is $info->{items},  $len,   "OK queue length - $info->{items}";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

#-- E_NO_ERROR

is $coll->last_errorcode, $E_NO_ERROR, "E_NO_ERROR";
note '$@: ', $@;

#-- E_MISMATCH_ARG

eval { $coll->insert() };
is $coll->last_errorcode, $E_MISMATCH_ARG, "E_MISMATCH_ARG";
note '$@: ', $@;

#-- E_DATA_TOO_LARGE

my $prev_max_datasize = $coll->max_datasize;
my $max_datasize = 100;
$coll->max_datasize( $max_datasize );
is $coll->max_datasize, $max_datasize, $msg;

eval { $id = $coll->insert( 'List id', $data_id++, '*' x ( $max_datasize + 1 ) ) };
is $coll->last_errorcode, $E_DATA_TOO_LARGE, "E_DATA_TOO_LARGE";
note '$@: ', $@;
$coll->max_datasize( $prev_max_datasize );

#-- E_NETWORK

$coll->quit;    # see $coll->_use_external_connection

eval { $info = $coll->collection_info };
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
is $coll->last_errorcode, $E_NO_ERROR, "E_NO_ERROR";
note '$@: ', $@;
ok $coll->_redis->ping, "server is not available";

new_connect();

#-- E_MAXMEMORY_LIMIT

    $maxmemory = 1024 * 1024;
    new_connect();
    ( undef, $max_datasize ) = $coll->_call_redis( 'CONFIG', 'GET', 'maxmemory' );
    is $max_datasize, $maxmemory, "value is set correctly";

    $tmp = '*' x 1024;
    for ( my $i = 0; $i < 2 * 1024; ++$i )
    {
        eval { $id = $coll->insert( $i.'', $data_id++, $tmp ) };
        if ( $@ )
        {
            is $coll->last_errorcode, $E_MAXMEMORY_LIMIT, "E_MAXMEMORY_LIMIT";
            note "($i)", '$@: ', $@;
            last;
        }
    }

    $coll->drop_collection;

#-- E_MAXMEMORY_POLICY

    foreach my $test_policy (
            'volatile-lru',         # -> remove the key with an expire set using an LRU algorithm
            'allkeys-lru',          # -> remove any key accordingly to the LRU algorithm
            'volatile-random',      # -> remove a random key with an expire set
            'allkeys-random',       # -> remove a random key, any key
            'volatile-ttl',         # -> remove the key with the nearest expire time (minor TTL)
#            'noeviction',           # -> don't expire at all, just return an error on write operations
        ) {
        $policy = $test_policy;
        dies_ok { new_connect() } "expecting to die: E_MAXMEMORY_POLICY";
    }

#-- E_COLLECTION_DELETED

#    $policy = "volatile-lru";       # -> remove the key with an expire set using an LRU algorithm
#    $policy = "allkeys-lru";        # -> remove any key accordingly to the LRU algorithm
#    $policy = "volatile-random";    # -> remove a random key with an expire set
#    $policy = "allkeys-random";     # -> remove a random key, any key
#    $policy = "volatile-ttl";       # -> remove the key with the nearest expire time (minor TTL)
    $policy = "noeviction";         # -> don't expire at all, just return an error on write operations

    $maxmemory = 2 * 1024 * 1024;
    $older_allowed = 1;
    new_connect();
    $status_key  = $NAMESPACE.':S:'.$coll->name;

    $id = $coll->insert( 'Other List id', $data_id++, '*' x 1024, Time::HiRes::time );
    $coll->_call_redis( 'DEL', $status_key );
    eval { $id = $coll->insert( 'Next List id', $data_id++, '*' x 1024, Time::HiRes::time ) };
    ok $@, "exception";
    is $coll->last_errorcode, $E_COLLECTION_DELETED, "E_COLLECTION_DELETED";
    note '$@: ', $@;
    $coll->drop_collection;

#-- E_REDIS

eval { $coll->_call_redis( "BADTHING", "Anything" ) };
is $coll->last_errorcode, $E_REDIS, "E_REDIS";
note '$@: ', $@;

#-- E_DATA_ID_EXISTS

new_connect();
$id = $coll->insert( "Some id", 123, '*' x 1024 );
eval { $id = $coll->insert( "Some id", 123, '*' x 1024 ) };
is $coll->last_errorcode, $E_DATA_ID_EXISTS, "E_DATA_ID_EXISTS";
note '$@: ', $@;

#-- E_OLDER_THAN_ALLOWED

new_connect();

$list_key = $NAMESPACE.':D:*';
foreach my $i ( 1..( 10 ) )
{
    $id = $coll->insert( "Some id", $i, $i, $i );
}
eval { $id = $coll->insert( "Some id", 123, '*', 1 ) };
is $coll->last_errorcode, $E_NO_ERROR, "E_NO_ERROR";
note '$@: ', $@;

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$older_allowed = 0;
new_connect();

$list_key = $NAMESPACE.':D:*';
foreach my $i ( 3..12 )
{
    $id = $coll->insert( "Some id", $i, $i, $i );
}
eval { $id = $coll->insert( "Some id", 123, '*', 2 ) };
is $coll->last_errorcode, $E_NO_ERROR, "E_NO_ERROR";
$coll->pop_oldest;
eval { $id = $coll->insert( "Some id", 234, '*', 1 ) };
is $coll->last_errorcode, $E_OLDER_THAN_ALLOWED, "E_OLDER_THAN_ALLOWED";
note '$@: ', $@;

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

}
