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

sub testing {
    my ( $method ) = @_;

    undef $redis;
    ( $redis, $skip_msg, $port ) = verify_redis();
    return unless $redis;   # it was not possible to re-start the redis server
    isa_ok( $redis, 'Test::RedisServer' );

my ( $coll, $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

$coll->quit if $coll;
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

my $data_id = 0;

#-- all correct

# some inserts
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    $coll->insert( $i, $data_id++, $_ ) for $i..10;
}

# verify
for ( my $i = 1; $i <= 10; ++$i )
{
    foreach my $type ( qw( D ) )
    {
        $list_key = $NAMESPACE.":$type:".$coll->name.':'.$i;
        ok $coll->_call_redis( "EXISTS", $list_key ), "data list created";
    }
    $list_key = $NAMESPACE.':D:'.$coll->name.':'.$i;
    is( $coll->_call_redis( "HGET", $list_key, $_ - $i ), $_, "correct inserted value ($i list)" ) for $i..10;
}

# reverse updates
for ( my $i = 1; $i <= 10; ++$i )
{
    for ( my $j = $i; $j <= 10; $j++ ) {
        $tmp = $coll->$method( $i, $j - $i, 10 - $j + $i );
        is $tmp, $method eq 'update' ? 1 : $i, 'correct update';
    }
}

# verify
for ( my $i = 1; $i <= 10; ++$i )
{
    $list_key = $NAMESPACE.':D:'.$coll->name.':'.$i;
    is( $coll->_call_redis( "HGET", $list_key, $_ - $i ), 10 - $_ + $i, "correct updated value ($i list)" ) for $i..10;
}

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

#-- resizing

$coll->quit if $coll;
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

# some inserts
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    $data_id = 0;
    ( $coll->insert( $i, $data_id++, $_ ), $tmp += bytes::length( $_."" ) ) for $i..10;
}

# updates with resizing
$tmp = 0;
for ( my $i = 1; $i <= 10; ++$i )
{
    ( $coll->$method( $i, $_ - $i, ( 10 - $_ + $i ).'*' ), $tmp += bytes::length( ( 10 - $_ + $i ).'*' ) ) for $i..10;
}

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$coll->quit if $coll;
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

$data_id = 0;
$coll->insert( "id", , $_, $data_id++ ) for 1..9;
$list_key = $NAMESPACE.':D:'.$coll->name.':id';
is $coll->_call_redis( "HLEN", $list_key ), 9, "correct list length";

$tmp = $coll->update( "bad_id", 0, '*' );
ok !$tmp, "not updated";
is $coll->_call_redis( "HLEN", $list_key ), 9, "correct list length";

$tmp = $coll->$method( "id", 3, '***' );
ok $tmp, "not updated";
is $coll->_call_redis( "HLEN", $list_key ), 9, "correct list length";

# errors in the arguments

dies_ok { $coll->$method() } "expecting to die - no args";

foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
{
    dies_ok { $coll->$method(
        $arg,
        0,
        '*',
        ) } "expecting to die: ".( $arg || '' );
}

foreach my $arg ( ( undef, \"scalar", [], $uuid ) )
{
    dies_ok { $coll->$method(
        'id',
        0,
        $arg,
        ) } "expecting to die: ".( $arg || '' );
}

foreach my $arg ( ( undef, "", \"scalar", [], $uuid ) )
{
    dies_ok { $coll->$method(
        'id',
        $arg,
        '*',
        ) } "expecting to die: ".( $arg || '' );
}

#-- new data time
$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

$name = 'Coll';
$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis   => $redis,
    name    => $name,
    );
isa_ok( $coll, 'Redis::CappedCollection' );

$queue_key   = $NAMESPACE.':Q:'.$name;

# some inserts
my $data = 'Stuff';
my $list_id = 'list_1';
$coll->insert( $list_id, 2, $data, 2 );
$list_id = 'list_2';
$coll->insert( $list_id, 6, $data, 6 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_2 6', 'Q OK';

$list_id = 'list_3';

# items == 1
$coll->insert( $list_id, 4, $data, 4 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 4 list_2 6', 'Q OK';

$coll->$method( $list_id, 4, $data, 4 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 4 list_2 6', 'Q OK';
$coll->update( $list_id, 4, $data, 3 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 3 list_2 6', 'Q OK';
$coll->update( $list_id, 4, $data, 1 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_3 1 list_1 2 list_2 6', 'Q OK';
$coll->update( $list_id, 4, $data, 7 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_2 6 list_3 7', 'Q OK';

$coll->update( $list_id, 4, $data, 4 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 4 list_2 6', 'Q OK';

# items > 1
my $time_key  = "$NAMESPACE:T:$name:$list_id";

$coll->insert( $list_id, 3, $data, 3 );
$coll->insert( $list_id, 5, $data, 5 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 3 list_2 6', 'Q OK';
@arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
is "@arr", '3 3 4 4 5 5', 'T OK';

$coll->$method( $list_id, 4, $data, 4 );
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 3 list_2 6', 'Q OK';
@arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
is "@arr", '3 3 4 4 5 5', 'T OK';
$coll->update( $list_id, 4, $data, 7 );
@arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
is "@arr", '3 3 5 5 4 7', 'T OK';
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_1 2 list_3 3 list_2 6', 'Q OK';
$coll->update( $list_id, 4, $data, 1 );
@arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
is "@arr", '4 1 3 3 5 5', 'T OK';
@arr = $coll->_call_redis( 'ZRANGE', $queue_key, 0, -1, 'WITHSCORES' );
is "@arr", 'list_3 1 list_1 2 list_2 6', 'Q OK';

if ( $method eq 'upsert' ) {
    $coll->$method( $list_id, 4, $data, 2 );    # update with $data_time
    @arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
    is "@arr", '4 2 3 3 5 5', 'T OK (data_time changed on update)';
    my $new_data = $coll->receive( $list_id, 4 );
    ok $new_data eq $data, 'data changed';

    $coll->$method( $list_id, 4, 'new data' );  # update without $data_time
    @arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
    is "@arr", '4 2 3 3 5 5', 'T OK (data_time not changed on update)';
    $new_data = $coll->receive( $list_id, 4 );
    ok $new_data eq 'new data', 'data changed';

    $coll->pop_oldest;
    # last_removed_time != 0
    sleep 1;
    $coll->$method( $list_id, 4, 'new data' );  # update without $data_time
    @arr = $coll->_call_redis( 'ZRANGE', $time_key, 0, -1, 'WITHSCORES' );
    is "@arr", '4 2 3 3 5 5', 'T OK (data_time not changed on update)';
    $new_data = $coll->receive( $list_id, 4 );
    ok $new_data eq 'new data', 'data changed';
}

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

}

foreach my $method ( qw( update upsert ) )
{
    testing( $method );
}

}
