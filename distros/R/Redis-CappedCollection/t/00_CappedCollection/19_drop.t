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
use Redis;
use Redis::CappedCollection qw(
    $DEFAULT_SERVER
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

my ( $coll, $name, $tmp, $id, $list_key, @arr, $len, $info );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

my $data_id = 0;

for my $big_data_threshold ( ( 0, 20 ) )
{

    $coll = Redis::CappedCollection->create(
        redis               => $redis,
        name                => "Some name",
        big_data_threshold  => $big_data_threshold,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;

    is $coll->name, "Some name", "correct collection name";

#-- all correct

# some inserts
    $len = 0;
    $tmp = 0;

    for ( my $i = 1; $i <= 10; ++$i )
    {
        $data_id = 0;
        ( $coll->insert( $i, $data_id++, $_ ), $tmp += bytes::length( $_.'' ), ++$len ) for 1..10;
    }
    $info = $coll->collection_info;
    ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
    is $info->{lists},  10,     "OK lists";
    is $info->{items},  $len,   "OK items";

    for ( my $i = 1; $i <= 10; ++$i )
    {
        $coll->drop_list( $i );
        $info = $coll->collection_info;
        is $info->{lists},  10 - $i,    "OK lists";
        is $info->{items},  $len -= 10,  "OK items";
        ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
    }

    dies_ok { $coll->drop_list() } "expecting to die - no args";

    foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
    {
        dies_ok { $coll->drop_list(
            $arg,
            ) } "expecting to die: ".( $arg || '' );
    }

    $coll->drop_collection;
    dies_ok { Redis::CappedCollection->open( redis => $coll->_redis, name => $coll->name ) } "expecting to die";
    dies_ok { Redis::CappedCollection->collection_info( redis => $coll->_redis, name => $coll->name ) } "expecting to die";

}

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->collection_exists, 'collection exists';
Redis::CappedCollection->drop_collection( redis => $coll->_redis, name => $coll->name );
ok !$coll->collection_exists, 'collection not exists';

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->collection_exists, 'collection exists';
Redis::CappedCollection::drop_collection( redis => $coll->_redis, name => $coll->name );
ok !$coll->collection_exists, 'collection not exists';

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->collection_exists, 'collection exists';
dies_ok { Redis::CappedCollection->drop_collection() } "expecting to die";
ok $coll->collection_exists, 'collection exists';

my $redis_addr = $DEFAULT_SERVER.":$port";
foreach my $additional ( [ no_auto_connect_on_new => 1 ], [] )
{
    my $redis = Redis->new(
        server => $redis_addr,
        @$additional,
    );

    $coll = Redis::CappedCollection->create(
        redis   => $redis,
        name    => $uuid->create_str,
    );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->collection_exists, 'collection exists';
    dies_ok { Redis::CappedCollection->drop_collection() } "expecting to die";
    ok $coll->collection_exists, 'collection exists';
}

}
