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

my ( $coll, $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr, $len );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $uuid->create_str,
    );
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;
my $_redis = $coll->_redis;
ok( $coll->collection_exists( name => $coll->name ), "collection exists: ".$coll->name );
ok( Redis::CappedCollection::collection_exists( redis => $_redis, name => $coll->name ), "collection exists: ".$coll->name );
ok( Redis::CappedCollection::collection_exists( redis => $coll, name => $coll->name ), "collection exists: ".$coll->name );
ok( Redis::CappedCollection->collection_exists( redis => $_redis, name => $coll->name ), "collection exists: ".$coll->name );
dies_ok { Redis::CappedCollection->create( redis => $redis, name => $coll->name ) } 'expecting to die: collection '.$coll->name.' already exists';
dies_ok { Redis::CappedCollection->collection_exists() } 'expecting to die';

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

#-- all correct
ok( !$coll->list_exists( $_ ), "list not exist: $_" ) for 1..10;

my $data_id = 0;

# some inserts
$len = 0;
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    $coll->insert( $i, $data_id++, $_ ) for $i..10;
}

ok( $coll->list_exists( $_ ), "list exist: $_" ) for 1..10;
ok( $coll->collection_exists( name => $coll->name ), "collection exists: ".$coll->name );
ok( Redis::CappedCollection::collection_exists( redis => $_redis, name => $coll->name ), "collection exists: ".$coll->name );

# errors in the arguments

dies_ok { $coll->receive() } "expecting to die - no args";

foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
{
    dies_ok { $coll->receive( $arg ) } "expecting to die: ".( $arg || '' );
}

ok( $coll->list_exists( $_ ), "list exist: $_" ) for 1..10;
ok( $coll->collection_exists( name => $coll->name ), "collection exists: ".$coll->name );
ok( Redis::CappedCollection::collection_exists( redis => $_redis, name => $coll->name ), "collection exists: ".$coll->name );

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );
ok( !$coll->collection_exists( name => $coll->name ), "collection not exist: ".$coll->name );
ok( !Redis::CappedCollection::collection_exists( redis => $_redis, name => $coll->name ), "collection not exist: ".$coll->name );

}
