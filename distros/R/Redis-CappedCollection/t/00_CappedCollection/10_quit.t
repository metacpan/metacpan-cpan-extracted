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

my ( $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr, $len, $info );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

my $coll_1 = Redis::CappedCollection->create(
    redis   => $redis,
    name    => "Some name",
    );
isa_ok( $coll_1, 'Redis::CappedCollection' );
ok $coll_1->_server =~ /.+:$port$/, $msg;
ok ref( $coll_1->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll_1->name;
$queue_key   = $NAMESPACE.':Q:'.$coll_1->name;
ok $coll_1->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll_1->_call_redis( "EXISTS", $queue_key ), "queue list not created";

is $coll_1->name, "Some name",    "correct collection name";

my $data_id = 0;

# some inserts
$len = 0;
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    ( $coll_1->insert( $i, $data_id++, $_ ), $tmp += bytes::length( $_.'' ), ++$len ) for $i..10;
}
$info = $coll_1->collection_info;
is $info->{lists},  10,     "OK lists - $info->{lists}";
is $info->{items},  $len,   "OK queue length - $info->{items}";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

#-- all correct

ok $coll_1->_redis->ping, "server is available";
$coll_1->quit;
ok $coll_1->_redis->ping, "server OK";

$coll_1 = Redis::CappedCollection->open(
    redis   => { $redis->connect_info },
    name    => "Some name",
    );
isa_ok( $coll_1, 'Redis::CappedCollection' );
ok !$coll_1->reconnect_on_error, 'reconnect_on_error FALSE';

ok $coll_1->_redis->ping, "server is available";
$coll_1->quit;
ok !$coll_1->_redis->ping, "no server";

#-- reconnect
$coll_1 = Redis::CappedCollection->open(
    redis               => { $redis->connect_info },
    name                => "Some name",
    reconnect_on_error  => 1,
);
isa_ok( $coll_1, 'Redis::CappedCollection' );
ok $coll_1->reconnect_on_error, 'reconnect_on_error TRUE';
ok $coll_1->_redis->ping, "server is available";
$coll_1->quit;
ok !$coll_1->_redis->ping, "no server";
$info = $coll_1->collection_info;
ok $coll_1->_redis->ping, "server reconnected";

my $coll_2 = Redis::CappedCollection->create(
    redis   => $redis,
    name    => "Some new name",
    );
isa_ok( $coll_2, 'Redis::CappedCollection' );
ok $coll_2->_server =~ /.+:$port$/, $msg;
ok ref( $coll_2->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll_2->name;
$queue_key   = $NAMESPACE.':Q:'.$coll_2->name;
ok $coll_2->_call_redis( "EXISTS", $status_key ), "status hash exists";
ok !$coll_2->_call_redis( "EXISTS", $queue_key ), "queue list exists";

is $coll_2->name, "Some new name", "correct collection name";

$info = $coll_2->collection_info;
is $info->{lists},  0, "OK lists - $info->{lists}";
is $info->{items},  0, "OK queue length - $info->{items}";
ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';

#-- ping

my $coll_3 = Redis::CappedCollection->create(
    redis   => { $redis->connect_info },
    name    => "Some next name",
    );
isa_ok( $coll_3, 'Redis::CappedCollection' );

ok $coll_3->ping, "server is available";
$coll_3->quit;
ok !$coll_3->ping, "no server";

}
