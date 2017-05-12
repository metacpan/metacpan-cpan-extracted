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

my ( $coll, $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr, $len, $info, $tm );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

my $data_id = 0;

for my $big_data_threshold ( ( 0, 10 ) )
{

    $coll = Redis::CappedCollection->create(
        redis               => $redis,
        name                => $uuid->create_str,
        big_data_threshold  => $big_data_threshold,
        'older_allowed'     => 1,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;

    $status_key  = $NAMESPACE.':S:'.$coll->name;
    $queue_key   = $NAMESPACE.':Q:'.$coll->name;
    ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
    ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

#-- all correct

    $info = $coll->list_info( 'Some list id' );
    is $info->{items},              undef, "OK items";
    is $info->{oldest_time},        undef, "OK oldest_time";

# some inserts
    $len = 0;
    $tmp = 0;
    $tm = gettimeofday;
    $coll->insert( 'Some list id', $data_id++, 1, $tm );
    $info = $coll->list_info( 'Some list id' );
    is $info->{items}, 1, "OK items";
    ok abs( $tm - $info->{oldest_time} <= 0.00009 ), "OK oldest_time";
    for ( my $i = 2; $i <= 10; ++$i )
    {
        $coll->insert( 'Some list id', $data_id++, $i, gettimeofday + 0 );
        $info = $coll->list_info( 'Some list id' );
        is $info->{items}, $i, "OK items";
        ok abs( $tm - $info->{oldest_time} <= 0.00009 ), "OK oldest_time";
    }

    $coll->drop_collection;

# Remove old data (insert)
    $coll = Redis::CappedCollection->create(
        redis               => $redis,
        name                => $uuid->create_str,
        big_data_threshold  => $big_data_threshold,
        'older_allowed'     => 1,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;

    @arr = ();
    foreach my $i ( 1..5 )
    {
        $tm = gettimeofday;
        push @arr, $tm;
        $id = $coll->insert( 'Some list id', $data_id++, '*', $tm );
        $info = $coll->collection_info;
        ok defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0, 'last_removed_time OK';
    }
    $id = $coll->insert( 'Some list id', $data_id++, '*', $tm );

    $info = $coll->list_info( 'Some list id' );
    is $info->{items}, 6, "OK items";
#    ok abs( $arr[1] - $info->{oldest_time} ) <= 0.00009, "OK oldest_time";
    ok abs( $arr[0] - $info->{oldest_time} ) <= 0.0009, "OK oldest_time";
#    is $arr[0], $info->{oldest_time}, "OK oldest_time";

    dies_ok { $coll->list_info() } "expecting to die - no args";

    foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
    {
        dies_ok { $coll->list_info(
            $arg,
            ) } "expecting to die: ".( $arg || '' );
    }

    $coll->drop_collection;

#----------
    $coll = Redis::CappedCollection->create(
        redis               => $redis,
        name                => $uuid->create_str,
        big_data_threshold  => $big_data_threshold,
        'older_allowed'     => 1,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;

# some inserts
    $len = 0;
    $tmp = 0;
    $tm = time;
    for ( my $i = 1; $i <= 10; ++$i )
    {
        $coll->insert( 'Some list id', $data_id++, $i, $tm );
        $info = $coll->list_info( 'Some list id' );
        is $info->{items}, $i, "OK items";
        is $info->{oldest_time}, $tm, "OK oldest_time";
    }

    $coll->drop_collection;

# Remove old data (insert)
    $coll = Redis::CappedCollection->create(
        redis               => $redis,
        name                => $uuid->create_str,
        big_data_threshold  => $big_data_threshold,
        'older_allowed'     => 1,
        );
    isa_ok( $coll, 'Redis::CappedCollection' );
    ok $coll->_server =~ /.+:$port$/, $msg;
    ok ref( $coll->_redis ) =~ /Redis/, $msg;

    @arr = ();
    $tm = time;
    foreach my $i ( 1..5 )
    {
        push @arr, $tm;
        $id = $coll->insert( 'Some list id', $data_id++, '*', $tm );
    }
    $id = $coll->insert( 'Some list id', $data_id++, '*', $tm );

    $info = $coll->list_info( 'Some list id' );
    is $info->{items}, 6, "OK items";
    is $info->{oldest_time}, $tm, "OK oldest_time";

    $coll->drop_collection;

}

}
