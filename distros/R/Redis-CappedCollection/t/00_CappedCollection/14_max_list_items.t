#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib qw(
    lib
    t/tlib
);

use Test::More;
plan 'no_plan';

BEGIN {
    eval 'use Test::RedisServer';               ## no critic
    plan skip_all => 'because Test::RedisServer required for testing' if $@;
}

BEGIN {
    eval 'use Net::EmptyPort';                  ## no critic
    plan skip_all => 'because Net::EmptyPort required for testing' if $@;
}

BEGIN {
    eval 'use Test::Exception';                 ## no critic
    plan skip_all => 'because Test::Exception required for testing' if $@;
}

BEGIN {
    eval 'use Test::NoWarnings';                ## no critic
    plan skip_all => 'because Test::NoWarnings required for testing' if $@;
}

use Data::UUID;
use Params::Util qw(
    _NUMBER
);
use Time::HiRes ();

use Redis::CappedCollection qw(
    $NAMESPACE
);
use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

# -- Global variables
my $uuid = new Data::UUID;
my (
    $COLLECTION,
    $COLLECTION_NAME,
    $ERROR_MSG,
    $REDIS,
    $REDIS_SERVER,
    $STATUS_KEY,
    $QUEUE_KEY,
    $DATA_KEY,
    $TIME_KEY,
    $inserts,
    $list_id,
    $last_data_time,
    $collection_info,
    $stuff,
    $port,
);

( $REDIS_SERVER, $ERROR_MSG, $port ) = verify_redis();

SKIP: {
    diag $ERROR_MSG if $ERROR_MSG;
    skip( $ERROR_MSG, 1 ) if $ERROR_MSG;

$stuff          = '*' x 10;
$list_id        = 'list_id';

sub new_connection {
    my ( $name, $maxmemory, $older_allowed, $max_list_items ) = @_;

    if ( $COLLECTION ) {
        $COLLECTION->drop_collection;
        $COLLECTION->quit;
    }

    if ( $REDIS_SERVER ) {
        $REDIS_SERVER->stop;
        undef $REDIS_SERVER;
    }

    $port = Net::EmptyPort::empty_port( $port );
    ( $REDIS_SERVER, $ERROR_MSG ) = get_redis(
        conf => {
            port                => $port,
            'maxmemory-policy'  => 'noeviction',
            $maxmemory ? ( maxmemory => $maxmemory ) : ( maxmemory => 0 ),
        },
    );
    skip( $ERROR_MSG, 1 ) unless $REDIS_SERVER;
    isa_ok( $REDIS_SERVER, 'Test::RedisServer' );

    $COLLECTION = Redis::CappedCollection->create(
        redis           => $REDIS_SERVER,
        name            => $uuid->create_str,
        'older_allowed' => $older_allowed // 0,
        $name           ? ( name                => $name )              : (),
        $max_list_items ? ( 'max_list_items'    => $max_list_items )    : (),
    );
    isa_ok( $COLLECTION, 'Redis::CappedCollection' );
    $COLLECTION_NAME    = $COLLECTION->name;

    $REDIS = $COLLECTION->_redis;
    isa_ok( $REDIS, 'Redis' );
    $REDIS->config_set( maxmemory => $maxmemory );
    $REDIS->config_set( 'maxmemory-policy' => 'noeviction' );

    $STATUS_KEY = "$NAMESPACE:S:$COLLECTION_NAME";
    $QUEUE_KEY  = "$NAMESPACE:Q:$COLLECTION_NAME";
    $DATA_KEY   = "$NAMESPACE:T:$COLLECTION_NAME:$list_id";
    $TIME_KEY   = "$NAMESPACE:T:$COLLECTION_NAME:$list_id";
    ok $COLLECTION->_call_redis( 'EXISTS', $STATUS_KEY ), 'status hash created';
    ok !$COLLECTION->_call_redis( 'EXISTS', $QUEUE_KEY ), 'queue list not created';

    $last_data_time = undef;

    return;
}

my $data_id = 0;

sub insert_item {
    my $data_time   = Time::HiRes::time;
    $last_data_time //= $data_time;
    $COLLECTION->insert( $list_id, ++$data_id, $stuff, $data_time );
}

sub update_item {
    my $data_time   = Time::HiRes::time;
    $last_data_time //= $data_time;
    $COLLECTION->update( $list_id, ++$data_id, $stuff x 2, $data_time );
}

sub testing {
    my ( $mode, $older_allowed ) = @_;

    my $function = $mode eq 'insert' ? \&insert_item : \&update_item;
    new_connection(
        undef,          # name
        1_000_000,      # maxmemory
        $older_allowed, # older_allowed
    );

    $collection_info = $COLLECTION->collection_info;
    my $last_removed_time = $collection_info->{last_removed_time};
    ok defined( _NUMBER( $last_removed_time ) ) && $last_removed_time == 0, 'OK last_removed_time';
    is $collection_info->{max_list_items}, 0, 'max_list_items == 0';
    is $collection_info->{lists}, 0, 'lists == 0';
    is $collection_info->{items}, 0, 'items == 0';
    ok !$COLLECTION->_call_redis( 'EXISTS', $DATA_KEY ), 'data hash not created';
    ok !$COLLECTION->_call_redis( 'EXISTS', $TIME_KEY ), 'time hash not created';

    $inserts = 100;
    insert_item() for 1 .. $inserts;
    $collection_info = $COLLECTION->collection_info;
    is $collection_info->{lists}, 1, 'lists == 1';
    is $collection_info->{items}, $inserts, "items == $inserts";
    is $collection_info->{max_list_items}, 0, 'max_list_items == 0';
    is $collection_info->{last_removed_time}, 0, 'last_removed_time == 0';
    ok $COLLECTION->_call_redis( 'EXISTS', $DATA_KEY ), 'data hash created';
    ok $COLLECTION->_call_redis( 'EXISTS', $TIME_KEY ), 'time hash created';

    my $real_last_removed_time = $older_allowed ? 0 : $last_data_time;

    my $new_max_items = int( $inserts / 2 );
    $COLLECTION->resize( max_list_items => $new_max_items );
    $collection_info = $COLLECTION->collection_info;
    is $collection_info->{max_list_items}, $new_max_items, "max_list_items == $new_max_items";

    $function->();

    my $new_items = $mode eq 'insert' ? $new_max_items : $new_max_items - 1;
    $collection_info = $COLLECTION->collection_info;
    is $collection_info->{lists}, 1, 'lists == 1';
    is $collection_info->{items}, $new_items, "items == $new_items";
    is $collection_info->{max_list_items}, $new_max_items, "max_list_items == $new_max_items";
    ok sprintf( '%.5f', $collection_info->{last_removed_time} ) eq sprintf( '%.5f', $real_last_removed_time ), 'last_removed_time OK';
    ok $COLLECTION->_call_redis( 'EXISTS', $DATA_KEY ), 'data hash exists';
    ok $COLLECTION->_call_redis( 'EXISTS', $TIME_KEY ), 'time hash exists';

    $COLLECTION->resize( max_list_items => 1 );
    $collection_info = $COLLECTION->collection_info;
    is $collection_info->{max_list_items}, 1, 'max_list_items == 0';

    $function->();

    $new_items = $mode eq 'insert' ? 1 : 0;
    $collection_info = $COLLECTION->collection_info;
    is $collection_info->{lists}, $new_items, "lists == $new_items";
    is $collection_info->{items}, $new_items, "items == $new_items";
    is $collection_info->{max_list_items}, 1, 'max_list_items == 1';
    ok sprintf( '%.5f', $collection_info->{last_removed_time} ) eq sprintf( '%.5f', $real_last_removed_time ), 'last_removed_time OK';
    ok !$COLLECTION->_call_redis( 'EXISTS', $DATA_KEY ), 'data hash not exists';
    ok !$COLLECTION->_call_redis( 'EXISTS', $TIME_KEY ), 'time hash not exists';
}

foreach my $older_allowed ( 0, 1 ) {
    testing( 'insert', $older_allowed );
#    testing( 'update', $older_allowed );
}

}