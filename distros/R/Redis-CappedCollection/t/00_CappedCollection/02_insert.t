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
use Params::Util    qw( _NONNEGINT );
use Redis::CappedCollection qw(
    $E_NETWORK
    $E_NO_ERROR
    $E_REDIS_DID_NOT_RETURN_DATA
    $NAMESPACE
    );

use Redis::CappedCollection::Test::Utils qw(
    clear_coll_data
    verify_redis
);

# options for testing arguments: ( undef, 0, 0.5, 1, -1, -3, "", "0", "0.5", "1", 9999999999999999, \"scalar", [], $uuid )

my ( $redis, $skip_msg, $port, $coll ) = verify_redis();

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

my ( $name, $tmp, $id, $status_key, $queue_key, $list_key, @arr );
my $uuid = new Data::UUID;
my $msg = "attribute is set correctly";

$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    cleanup_items   => 0,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

$status_key  = $NAMESPACE.':S:'.$coll->name;
$queue_key   = $NAMESPACE.':Q:'.$coll->name;
ok $coll->_call_redis( "EXISTS", $status_key ), "status hash created";
ok !$coll->_call_redis( "EXISTS", $queue_key ), "queue list not created";

my $data_id = -1;

# all correct
$id = controlled_call( $method, "Some id", ++$data_id, "Some stuff" );
is $id, "Some id", "correct result";
ok $coll->_call_redis( "EXISTS", $queue_key ), "queue list created";
$list_key = $NAMESPACE.":D:".$coll->name.':'.$id;
ok $coll->_call_redis( "EXISTS", $list_key ), "data list created";
$list_key = $NAMESPACE.":T:".$coll->name.':'.$id;
ok !$coll->_call_redis( "EXISTS", $list_key ), "data list created";
is $coll->_call_redis( "HGET", $status_key, 'lists'  ), 1, "correct status value";

$tmp = controlled_call( $method, "Some id", ++$data_id, "Some new stuff" );
is $tmp, $id, "correct result";
$list_key = $NAMESPACE.":T:".$coll->name.':'.$id;
ok $coll->_call_redis( "EXISTS", $list_key ), "data list created";
is $coll->_call_redis( "HGET", $status_key, 'lists'  ), 1, "correct status value";

$tmp = controlled_call( $method, "Some new id", ++$data_id, "Some another stuff" );
is $tmp, "Some new id", "correct result";
is $coll->_call_redis( "HGET", $status_key, 'lists'  ), 2, "correct status value";

#$id = controlled_call( $method, undef, ++$data_id, "Any stuff" );
#is bytes::length( $id ), bytes::length( '89116152-C5BD-11E1-931B-0A690A986783' ), $msg;

my $saved_name = $coll->name;
controlled_call( $method, "ID", ++$data_id, "Stuff" );
controlled_call( $method, "ID", ++$data_id, "Stuff" );
controlled_call( $method, "ID", ++$data_id, "Stuff" );

# errors in the arguments
$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    cleanup_items   => 0,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;

dies_ok { controlled_call( $method ) } "expecting to die - no args";

foreach my $arg ( ( undef, \"scalar", [], $uuid ) )
{
    dies_ok { controlled_call( $method,
        undef,
        ++$data_id,
        $arg,
        ) } "expecting to die: ".( $arg || '' );
}

foreach my $arg ( ( undef, "", "Some:id", \"scalar", [], $uuid ) )
{
    dies_ok { controlled_call( $method,
        $arg,
        ++$data_id,
        "Correct stuff",
        ) } "expecting to die: ".( $arg || '' );
}

foreach my $arg ( ( undef, '', \"scalar", [], $uuid ) )
{
    dies_ok { controlled_call( $method,
        "List id",
        $arg,
        "Correct stuff",
        ) } "expecting to die: ".( $arg || '' );
}

$tmp = 0;
foreach my $arg ( ( 0, -1, -3, "", "0", \"scalar", [], $uuid ) )
{
    dies_ok { controlled_call( $method,
        "List id",
        $tmp++,
        "Correct stuff",
        $arg,
        ) } "expecting to die: ".( $arg || '' );
}

# make sure that the data is saved and not destroyed
is $coll->_call_redis( "ZCOUNT", $queue_key, '-inf', '+inf' ), 3, "correct list number";
is $coll->_call_redis( "HGET", $status_key, 'lists' ), 3, "correct status value";

$list_key = $NAMESPACE.":D:".$saved_name.':ID';
is $coll->_call_redis( "HLEN", $list_key ), 3, "correct data number";

$list_key = $NAMESPACE.":T:".$saved_name.':ID';
is $coll->_call_redis( "ZCOUNT", $list_key, '-inf', '+inf' ), 3, "correct time number";

@arr = $coll->_call_redis( "KEYS", $NAMESPACE.":D:$saved_name:*" );
is( scalar( @arr ), 3, "correct number of lists created" );
@arr = $coll->_call_redis( "KEYS", $NAMESPACE.":T:$saved_name:*" );
is( scalar( @arr ), 2, "correct number of lists created" );

@arr = sort $coll->_call_redis( "ZRANGE", $queue_key, 0, -1 );
$tmp = "@arr";
@arr = sort ( "ID", "Some id", "Some new id" );
is $tmp, "@arr", "correct values set";

$list_key = $NAMESPACE.":D:".$saved_name.':Some id';
@arr = sort $coll->_call_redis( "HVALS", $list_key );
$tmp = "@arr";
@arr = ( "Some new stuff", "Some stuff" );
is $tmp, "@arr", "correct values set";

# destruction of status hash
$status_key  = $NAMESPACE.':S:'.$coll->name;
$coll->_call_redis( "DEL", $status_key );
dies_ok { $id = controlled_call( $method, "Some id", ++$data_id, "Some stuff" ) } "expecting to die";

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

# Remove old data
$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    cleanup_items   => 0,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;
$status_key  = $NAMESPACE.':S:'.$coll->name;

$list_key = $NAMESPACE.':D:*';
foreach my $i ( 1..10 )
{
    $id = controlled_call( $method, $i, ++$data_id, $i );
    @arr = $coll->_call_redis( "KEYS", $list_key );
    is scalar( @arr ), $i, "correct lists value: $i inserts ".scalar( @arr )." lists";
}
$list_key = $NAMESPACE.":T:*";
eval { $coll->_call_redis( "KEYS", $list_key ); };
is $coll->last_errorcode, $E_REDIS_DID_NOT_RETURN_DATA, "correct lists value";

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

#-------------------------------------------------------------------------------
$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    cleanup_items   => 0,
);
isa_ok( $coll, 'Redis::CappedCollection' );
ok $coll->_server =~ /.+:$port$/, $msg;
ok ref( $coll->_redis ) =~ /Redis/, $msg;
$status_key  = $NAMESPACE.':S:'.$coll->name;

$list_key = $NAMESPACE.':D:*';
foreach my $i ( 1..10 )
{
    $id = controlled_call( $method, $i, ++$data_id, $i, gettimeofday + 0 );
    $id = controlled_call( $method, $i, ++$data_id, $i, gettimeofday + 0 );
    @arr = $coll->_call_redis( "KEYS", $list_key );
    is scalar( @arr ), $i, "correct lists value: $i inserts ".scalar( @arr )." lists";
}
@arr = $coll->_call_redis( "KEYS", $list_key );
is scalar( @arr ), 10, "correct lists value";
$list_key = $NAMESPACE.":T:*";
@arr = $coll->_call_redis( "KEYS", $list_key );
is scalar( @arr ), 10, "correct lists value";

$id = controlled_call( $method, 'List id', ++$data_id, '*' x 5, gettimeofday + 0 );
@arr = $coll->_call_redis( "KEYS", $list_key );
is scalar( @arr ), 10, "correct lists value";

$coll->_call_redis( "DEL", $_ ) foreach $coll->_call_redis( "KEYS", $NAMESPACE.":*" );

#-------------------------------------------------------------------------------
$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis           => $redis,
    name            => $uuid->create_str,
    cleanup_items   => 0,
);
isa_ok( $coll, 'Redis::CappedCollection' );

my $memory_info = $coll->_redis->info( 'memory' );

my ( undef, $maxmemory ) = $coll->_call_redis( "CONFIG", 'GET', 'maxmemory' );
ok $maxmemory >= 0, 'maxmemory OK';

$maxmemory = $memory_info->{used_memory} + 1_000_000;
is $coll->_call_redis( "CONFIG", 'SET', 'maxmemory', $maxmemory ), 'OK', 'CONFIG SET OK';
( undef, $maxmemory ) = $coll->_call_redis( "CONFIG", 'GET', 'maxmemory' );
ok $maxmemory == $maxmemory, 'maxmemory OK';

$list_key = $NAMESPACE.":D:*";
my $lists = 0;
my $i = 1;
while ( 1 ) {
    controlled_call( $method, $i, $i, '@' x 10_000, gettimeofday );
    @arr = $coll->_call_redis( "KEYS", $list_key );
    $lists = scalar( @arr );
    last if $lists != $i;
    ++$i;
}
ok $lists <= $i - 1, sprintf( "data squeezed: lists < i - 1 ($lists < $i - 1)" );

$coll->quit;
lives_ok {
    controlled_call( $method, 'Other new list_id', 'Other new data_id', 'Some data', gettimeofday );
} "expecting to live: ";
is $coll->last_errorcode, $E_NO_ERROR, 'E_NO_ERROR';

$coll->quit if $coll;
$coll = Redis::CappedCollection->create(
    redis   => { $redis->connect_info },    # HashRef
    name    => $uuid->create_str,
);
isa_ok( $coll, 'Redis::CappedCollection' );

$coll->quit;    # see $coll->_use_external_connection

lives_ok {
    controlled_call( $method, 'Other new list_id', 'Other new data_id', 'Some data', gettimeofday );
} "expecting to die: method = $method";
is $coll->last_errorcode, $E_NO_ERROR, 'E_NO_ERROR';
}

my %statistics;

sub controlled_call {
    my ( $method, @args ) = @_;

    my $property = 'total_commands_processed';

    my $before = get_property_value( $property );
    my $ret = $coll->$method( @args );
    my $after = get_property_value( $property );

    ++$statistics{ $method }->{ $property }->{count};
    $statistics{ $method }->{ $property }->{sum} += $after - $before;

    return $ret;
}

sub get_property_value {
    my ( $property ) = @_;

    my $result_str = $coll->_call_redis( 'INFO', 'Stats' );
    my ( $value ) = $result_str =~ /$property:(\d+)/;

    return $value;
}

foreach my $method ( qw( insert upsert ) )
{
    testing( $method );
}

foreach my $method ( sort keys %statistics ) {
    my $method_info = $statistics{ $method };
    foreach my $property ( sort keys %$method_info ) {
        my $property_info = $method_info->{ $property };
        diag "$method:$property average = ", $property_info->{sum} / $property_info->{count};
    }
}

}
