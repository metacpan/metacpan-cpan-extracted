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
    $E_REDIS_DID_NOT_RETURN_DATA
    $NAMESPACE
    );

use Redis::CappedCollection::Test::Utils qw(
    verify_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [], $uuid )

my ( $redis, $skip_msg, $port ) = verify_redis();

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

# For Test::RedisServer
isa_ok( $redis, 'Test::RedisServer' );

my ( $coll, $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr, $len, $info );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => "Some name",
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

is $coll->name, "Some name",    "correct collection name";

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
is $info->{lists},  10,     "OK lists";
is $info->{items},  $len,   "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$coll->drop_collection;

$list_key = $NAMESPACE.':[DT]:*';
eval { $coll->_call_redis( "KEYS", $list_key ); };
is $coll->last_errorcode, $E_REDIS_DID_NOT_RETURN_DATA, "correct lists value";

ok !$coll->_call_redis( "EXISTS", $status_key ),    "status hash droped";
ok !$coll->_call_redis( "EXISTS", $queue_key ),     "queue list droped";

is $coll->name, undef, "correct collection name";

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => "Some name",
    );
isa_ok( $coll, 'Redis::CappedCollection' );

$coll->insert( 'list_id', $data_id++, 'Stuff' ) for 1..10;
$info = $coll->collection_info;
ok $info->{lists}, "OK lists";
ok $info->{items}, "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$coll->clear_collection;
$info = $coll->collection_info;
ok !$info->{lists}, "OK lists";
ok !$info->{items}, "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$list_key = $NAMESPACE.':[DT]:*';
eval { $coll->_call_redis( "KEYS", $list_key ); };
is $coll->last_errorcode, $E_REDIS_DID_NOT_RETURN_DATA, "correct lists value";

ok $coll->_call_redis( "EXISTS", $status_key ),    "status hash exists";
ok !$coll->_call_redis( "EXISTS", $queue_key ),     "queue list droped";

ok defined( $coll->name ), "correct collection name";

$id = $coll->insert( "Some id", ++$data_id, "Some stuff" );
is $id, "Some id", "correct result";

}
