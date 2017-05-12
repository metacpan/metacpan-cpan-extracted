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

use Const::Fast;
use Params::Util qw(
    _NUMBER
);
use Time::HiRes qw();
use Try::Tiny;

use Redis::CappedCollection qw(
    $DEFAULT_PORT
);
use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

const my $FILLER                => '#';

#-- Collection settings
const my $COLLECTION_NAME       => $FILLER x 40;
const my $CLEANUP_BYTES         => 1 * 1024;
const my $CLEANUP_ITEMS         => 10;
const my $MAX_DATASIZE          => 4 * 1024;    # 4k
const my $OLDER_ALLOWED         => 0;
const my $CHECK_MAXMEMORY       => 1;
const my $MEMORY_RESERVE        => 0.05;

#TODO:
# - pick up for ROLLBACK and verify it
# - pick up and comment out the combination for long-term testing
const my $MAXMEMORY             => 1 * 1024 * 1024;
const my $MAX_LISTS             => 20;
const my $LIST_NAME_LEN         => 20;
const my $DATA_ID_LEN           => 20;
const my $MIN_DATA_LEN          => 2_000;   # must be > than length( "$data_id.$FILLER.$list_id.$FILLER.$data_len.$FILLER" )
const my $MAX_DATA_LEN          => 2_200;   # must be >= $MIN_DATA_LEN
const my $DURATION              => 20;      # secs
const my $REPORT_ABOUT_RECS     => 100;

# -- Global variables
my (
    $REDIS_SERVER,
    $REDIS,
    $COLLECTION,
    $ERROR_MSG,
    $port,
);

my $CURRENT_LIST_ID = 0;
my $CURRENT_DATA_ID = 1;

sub get_collection {

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
            maxmemory           => $MAXMEMORY,
        },
    );
    skip( $ERROR_MSG, 1 ) unless $REDIS_SERVER;
    isa_ok( $REDIS_SERVER, 'Test::RedisServer' );

    $COLLECTION = Redis::CappedCollection->create(
        redis           => $REDIS_SERVER,
        name            => $COLLECTION_NAME,
        'older_allowed' => $OLDER_ALLOWED,
        'cleanup_bytes' => $CLEANUP_BYTES,
        'cleanup_items' => $CLEANUP_ITEMS,
        memory_reserve  => $MEMORY_RESERVE,
    );
    isa_ok( $COLLECTION, 'Redis::CappedCollection' );

    $REDIS = $COLLECTION->_redis;
    isa_ok( $REDIS, 'Redis' );

    return;
}

sub get_string {
    my $value   = shift;
    my $min_len = shift;
    my $max_len = shift || $min_len;

    my $delta = $max_len - $min_len;
    my $len = $delta ? int( rand( $delta + 1 ) ) + $min_len : $min_len;
    $value = "$value";

    return $value.( $FILLER x ( $len - length( $value ) ) );
}

sub get_naked_id {
    my $filled_id = shift;

    my $pos = index( $filled_id, $FILLER );
    my $naked_id = $pos == -1 ? $filled_id : substr( $filled_id, 0, $pos );

    return $naked_id;
}

sub get_status {
    my ( $start_tm, $inserts, $total ) = @_;

    my $info = $COLLECTION->collection_info;
    my $items = $info->{items};
    my $lists = $info->{lists};
    fail 'last_removed_time not exists' unless defined( _NUMBER( $info->{last_removed_time} ) ) && $info->{last_removed_time} >= 0;
    my $info_memory = $COLLECTION->_call_redis( 'INFO', 'memory' );
    my ( $used_memory ) = $info_memory =~ /used_memory:(\d+)/;
    my $duration = time - $start_tm;

    pass "inserts = $inserts, duration = $duration/$DURATION, lists = $lists/$MAX_LISTS, items = $items, used_memory = $used_memory/$MAXMEMORY"
        if $inserts % $REPORT_ABOUT_RECS == 0 || $total;

    return( $lists, $items );
}

( $REDIS_SERVER, $ERROR_MSG ) = verify_redis();

SKIP: {
    diag $ERROR_MSG if $ERROR_MSG;
    skip( $ERROR_MSG, 1 ) if $ERROR_MSG;

    {
        no warnings;
        $Redis::CappedCollection::WAIT_USED_MEMORY = 1;
    }

    get_collection();

#-- Insert ---------------------------------------------------------------------

    my $start_tm = time();
    my $previous_items = 0;
    my $last_items = -1;
    my $last_lists = 0;
    my $inserts = 0;
    my @existing_lists;

    while ( 1 ) {
        last if time - $start_tm > $DURATION && $last_items <= $previous_items;
        $previous_items = $previous_items >= $last_items ? $previous_items : $last_items;

        my $list_id;
        if ( $last_lists < $MAX_LISTS ) {
            $list_id = $CURRENT_LIST_ID++;
        } else {
            $list_id = $existing_lists[ int( rand( scalar @existing_lists ) ) ];
            ( $list_id ) = $list_id =~ /^(\d+)$FILLER+$/;
        }

        my $data_id = $CURRENT_DATA_ID++;
        my $data_time = $data_id;
        my $data_template = get_string( '', $MIN_DATA_LEN, $MAX_DATA_LEN );
        my $data_len = length $data_template;
        my $data = $data_id.$FILLER.$list_id.$FILLER.$data_len.$FILLER;
        $data .= $FILLER x ( $data_len - length( $data ) );
        $data_id = get_string( $data_id, $DATA_ID_LEN );
        $list_id = get_string( $list_id, $LIST_NAME_LEN );
        try {
            $COLLECTION->insert( $list_id, $data_id, $data, $data_time );
            ++$inserts;
        } catch {
            my $error = $_;
            fail "Error adding data: $error";
            last;
        };

        ( $last_lists, $last_items ) = get_status( $start_tm, $inserts );

        @existing_lists = $COLLECTION->lists;
        unless ( $last_lists == scalar( @existing_lists ) ) {
            fail 'BAD existing lists';
        }

        my %data_ids;
        foreach my $existing_list_id ( @existing_lists ) {
            my $naked_list_id = get_naked_id( $existing_list_id );
            my %existing_list = $COLLECTION->receive( $existing_list_id, '' );   # data_id1 => data1, ...
            while ( my ( $existing_data_id, $existing_data ) = each %existing_list ) {
                my $naked_data_id = get_naked_id( $existing_data_id );
                if ( exists $data_ids{ $naked_data_id } ) {
                    fail 'data_id duplicated';
                } else {
                    ++$data_ids{ $naked_data_id };
                }

                my ( $included_data_id, $included_list_id, $included_data_len ) = $existing_data =~ /^(\d+)$FILLER(\d+)$FILLER(\d+)$FILLER+$/;
                unless ( length( $existing_data ) == $included_data_len ) {
                    fail 'data has wrong length';
                }
                unless ( $naked_list_id == $included_list_id && $naked_data_id == $included_data_id ) {
                    fail 'data in the wrong place';
                }
            }
        }
        unless ( $last_items == scalar( keys %data_ids ) ){
            fail 'BAD existing data';
        }

        foreach my $sequence_data_id ( ( $CURRENT_DATA_ID - $last_items ) .. ( $CURRENT_DATA_ID - 1 ) ) {
            unless ( exists $data_ids{ $sequence_data_id } ) {
                fail 'data does not remove sequentially';
            }
        }
    }

    get_status( $start_tm, $inserts, 1 );

#-- Update ---------------------------------------------------------------------
#TODO: update test
}
