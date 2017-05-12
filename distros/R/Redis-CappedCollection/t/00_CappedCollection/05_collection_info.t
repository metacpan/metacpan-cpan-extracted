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
use Time::HiRes     qw( gettimeofday );
use Redis::CappedCollection qw(
    $DATA_VERSION
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
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

#-- all correct

$info = Redis::CappedCollection::collection_info( redis => $coll->_redis, name => $coll->name );
is $info->{lists},              0,      "OK lists";
is $info->{items},              0,      "OK items";
is $info->{max_list_items},     0,      "OK max_list_items";
is $info->{older_allowed},      0,      "OK older_allowed";             # default
is $info->{oldest_time},        undef,  "OK oldest_time";
is $info->{data_version},       $DATA_VERSION, 'OK data_version';

$info = Redis::CappedCollection::collection_info( redis => { server => $coll->_server }, name => $coll->name );
is $info->{lists},              0,      "OK lists";
is $info->{items},              0,      "OK items";
is $info->{max_list_items},     0,      "OK max_list_items";
is $info->{older_allowed},      0,      "OK older_allowed";             # default
is $info->{oldest_time},        undef,  "OK oldest_time";
is $info->{data_version},       $DATA_VERSION, 'OK data_version';
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} == 0, 'last_removed_time OK';

$info = Redis::CappedCollection->collection_info( redis => $coll->_redis, name => $coll->name );
is $info->{lists},              0,      "OK lists";
is $info->{items},              0,      "OK items";
is $info->{max_list_items},     0,      "OK max_list_items";
is $info->{older_allowed},      0,      "OK older_allowed";             # default
is $info->{oldest_time},        undef,  "OK oldest_time";
is $info->{data_version},       $DATA_VERSION, 'OK data_version';
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} == 0, 'last_removed_time OK';

$info = $coll->collection_info;
is $info->{lists},              0,      "OK lists";
is $info->{items},              0,      "OK items";
is $info->{max_list_items},     0,      "OK max_list_items";
is $info->{older_allowed},      0,      "OK older_allowed";             # default
is $info->{oldest_time},        undef,  "OK oldest_time";
is $coll->oldest_time,          undef,  "OK oldest_time";
is $info->{data_version},       $DATA_VERSION, 'OK data_version';
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} == 0, 'last_removed_time OK';

dies_ok { Redis::CappedCollection->collection_info() } "expecting to die";

my $data_id = 0;

# some inserts
$len = 0;
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    ( $coll->insert( $i, $data_id++, $_ ), $tmp += bytes::length( $_.'' ), ++$len ) for $i..10;
    $info = $coll->collection_info;
    is $info->{lists},              $i,     "OK lists";
    is $info->{items},              $len,   "OK items";
    is $info->{older_allowed},      0,      "OK older_allowed";         # defaulf
    ok $info->{oldest_time}         > 0,    "OK oldest_time";
    is $coll->oldest_time,          $info->{oldest_time},   "OK oldest_time";
    ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
}

$coll->_call_redis( 'HDEL', $status_key, 'data_version' );
$info = $coll->collection_info;
is $info->{data_version}, '0', 'OK data_version';
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$coll->pop_oldest;
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} > 0, 'last_removed_time OK';

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

# Remove old data (insert)
$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;
$status_key  = $NAMESPACE.':S:'.$coll->name;

$list_key = $NAMESPACE.':D:*';
foreach my $i ( 1..10 )
{
    $data_id = 0;
    $id = $coll->insert( $i, $data_id++, '*' );
    $info = $coll->collection_info;
    is $info->{lists},  $i, "OK lists";
    is $info->{items},  $i, "OK items";
    is $info->{max_list_items}, 0, "OK max_list_items";
    ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
}

$data_id = 0;
$id = $coll->insert( 'List id', $data_id++, '*****' );
@arr = $coll->_call_redis( "KEYS", $list_key );
is scalar( @arr ), 11, "correct lists value";

$info = $coll->collection_info;
is $info->{lists},  11,              "OK lists";
is $info->{items},  11,              "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    max_list_items  => 1_000_000,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

$data_id = 0;
$coll->insert( "id", $data_id++, $_, gettimeofday + 0 ) for 1..9;
$list_key = $NAMESPACE.':D:'.$coll->name.':id';
is $coll->_call_redis( "HLEN", $list_key ), 9, "correct list length";

$info = $coll->collection_info;
is $info->{lists},  1, "OK lists";
is $info->{items},  9, "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
is $info->{max_list_items}, 1_000_000, "OK max_list_items";

$tmp = $coll->update( "bad_id", 0, '*' );
ok !$tmp, "not updated";
$info = $coll->collection_info;
is $info->{lists},  1,  "OK lists";
is $info->{items},  9,  "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$tmp = $coll->update( "id", 0, '***' );
ok $tmp, "not updated";
$info = $coll->collection_info;
is $info->{lists},  1,  "OK lists";
is $info->{items},  9,  "OK items";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

$info = $coll->collection_info;
is $info->{older_allowed},      0,      "OK older_allowed";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
ok $coll->resize( older_allowed => 1 ), 'resized';
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
ok $coll->resize( max_list_items => 10_000 ), 'resized';
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{max_list_items} ) ) && $info->{max_list_items} == 10_000, 'max_list_items OK';
ok $coll->resize( max_list_items => 0 ), 'resized';
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{max_list_items} ) ) && $info->{max_list_items} == 0, 'max_list_items OK';

is $info->{older_allowed},      1,      "OK older_allowed";
$coll->pop_oldest;
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} > 0, 'last_removed_time OK';
$coll->insert( "id", $data_id++, 'Stuff', 3 );
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} == 0, 'last_removed_time OK';
$coll->pop_oldest;
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} > 0, 'last_removed_time OK';
$coll->update( "id", 1, '***', 2 );
$info = $coll->collection_info;
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} == 0, 'last_removed_time OK';

dies_ok { $coll->resize() } "expecting to die";
ok( Redis::CappedCollection->resize( redis => $coll->_redis, name => $coll->name, older_allowed => 0 ), 'resized' );
ok( Redis::CappedCollection::resize( redis => $coll->_redis, name => $coll->name, older_allowed => 0 ), 'resized' );
ok( Redis::CappedCollection::resize( redis => $coll->_redis, name => $coll->name, max_list_items => 10 ), 'resized' );
ok( Redis::CappedCollection::resize( redis => $coll->_redis, name => $coll->name, max_list_items => 0 ), 'resized' );
dies_ok { $coll->resize() } "expecting to die";
dies_ok { Redis::CappedCollection->resize() } "expecting to die";

}
