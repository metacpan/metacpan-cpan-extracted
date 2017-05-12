#!/usr/bin/perl -w
#TODO: to develop tests
# - memory errors (working with ROLLBACK)
# - with maxmemory = 0
# - $E_NONEXISTENT_DATA_ID error

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
use File::Spec ();
use JSON::XS ();
use Params::Util qw(
    _NUMBER
);
use Time::HiRes ();

use Redis::CappedCollection qw(
    $DEFAULT_PORT
    $DEFAULT_SERVER
    $E_MAXMEMORY_LIMIT
    $E_NONEXISTENT_DATA_ID
    $E_REDIS
    $MIN_MEMORY_RESERVE
    $NAMESPACE
);
use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

# -- Global variables
my $uuid = new Data::UUID;
my (
    $CLEANUP_BYTES,
    $CLEANUP_ITEMS,
    $COLLECTION,
    $COLLECTION_NAME,
    $ERROR_MSG,
    $JSON,
    $LAST_REDIS_USED_MEMORY,
    $MAXMEMORY,
    $MEMORY_RESERVE,
    $MEMORY_RESERVE_COEFFICIENT,
    $REDIS,
    $REDIS_LOG,
    $REDIS_SERVER,
    $STATUS_KEY,
    $QUEUE_KEY,
    $cleanings_performed,
    $debug_records,
    $inserts,
    $list_id,
    @operation_times,
    $stuff,
    $port,
);

( $REDIS_SERVER, $ERROR_MSG, $port ) = verify_redis();

SKIP: {
    diag $ERROR_MSG if $ERROR_MSG;
    skip( $ERROR_MSG, 1 ) if $ERROR_MSG;

    {
        no warnings;
        $Redis::CappedCollection::WAIT_USED_MEMORY = 1;
    }

    $MEMORY_RESERVE_COEFFICIENT = 1 + $MIN_MEMORY_RESERVE;

sub new_connection {
    my ( $name, $maxmemory, $cleanup_bytes, $cleanup_items, $memory_reserve ) = @_;

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
    $REDIS_LOG = File::Spec->catfile( $REDIS_SERVER->tmpdir, 'redis-server.log' );

    $COLLECTION = Redis::CappedCollection->create(
        redis           => $REDIS_SERVER,
        name            => $uuid->create_str,
        'older_allowed' => 1,
        $name           ? ( name            => $name )              : (),
        $cleanup_bytes  ? ( 'cleanup_bytes' => $cleanup_bytes )     : (),
        $cleanup_items  ? ( 'cleanup_items' => $cleanup_items   )   : (),
        $memory_reserve ? ( memory_reserve  => $memory_reserve )    : (),
    );
    isa_ok( $COLLECTION, 'Redis::CappedCollection' );
    $COLLECTION_NAME    = $COLLECTION->name;
    $CLEANUP_BYTES      = $COLLECTION->cleanup_bytes;
    $CLEANUP_ITEMS      = $COLLECTION->cleanup_items;
    $MEMORY_RESERVE     = $COLLECTION->memory_reserve;
    $MAXMEMORY          = $maxmemory;

    $REDIS = $COLLECTION->_redis;
    isa_ok( $REDIS, 'Redis' );
    $REDIS->config_set( maxmemory => $maxmemory );
    $REDIS->config_set( 'maxmemory-policy' => 'noeviction' );

    $STATUS_KEY = "$NAMESPACE:S:$COLLECTION_NAME";
    $QUEUE_KEY  = "$NAMESPACE:Q:$COLLECTION_NAME";
    ok $COLLECTION->_call_redis( 'EXISTS', $STATUS_KEY ), 'status hash created';
    ok !$COLLECTION->_call_redis( 'EXISTS', $QUEUE_KEY ), 'queue list not created';

    $JSON = JSON::XS->new;

    return;
}

sub read_log {
    my ( $line, %debug_records );

    open( my $redis_log_fh, '<', $REDIS_LOG ) or die "cannot open < $REDIS_LOG: $!";
    while ( $line = <$redis_log_fh>) {
        chomp $line;
        if ( my ( $func_name, $json_text ) = $line =~ /[^*]+\*\s+(\w+):\s+(.+)/ ) {
            my $result = $JSON->decode( $json_text );
            my $debug_id = delete $result->{_DEBUG_ID};
            $debug_records{ $func_name }->{ $debug_id } = []
                unless exists $debug_records{ $func_name }->{ $debug_id } ;
            my $debug_measurements = $debug_records{ $func_name }->{ $debug_id };
            push @$debug_measurements, $result;
        }
    }
    close $redis_log_fh;

    return \%debug_records;
}

sub verifying {
    my ( $tested_function ) = @_;

    $debug_records = read_log();
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;
#say STDERR '# DUMP: ', Data::Dumper->Dump( [ $debug_records ], [ 'debug_records' ] );

    $cleanings_performed = 0;
    foreach my $operation_id ( sort keys %{ $debug_records->{ $tested_function } } ) {
        my (
            $calculated_cleaning_needed,
            $cleaning_performed,
            $enough_memory_cleaning_needed,
            $exists_before_cleanings,
            $items_deleted,
        );

        foreach my $step ( @{ $debug_records->{ $tested_function }->{ $operation_id } } ) {
            if ( $step->{_STEP} eq 'Before cleanings' ) {
                $exists_before_cleanings = 1;
                $calculated_cleaning_needed =
                       $step->{coll_items} > 0
                    && (
                           $step->{cleanup_items} > 0
                        || $step->{cleanup_bytes} > 0
                        || (
                               $step->{cleanup_items} == 0
                            && $step->{cleanup_bytes} == 0
                        )
                    )
                ;
                ok $exists_before_cleanings && $calculated_cleaning_needed, 'Before cleanings';
            } elsif ( $step->{_STEP} eq 'Before real cleaning' ) {
                ok $step->{to_delete_data_id} eq shift( @operation_times ), 'to_delete data time OK';
            } elsif ( $step->{_STEP} eq 'After real cleaning' ) {
                ok !$COLLECTION->_call_redis( 'HEXISTS', $step->{to_delete_data_key}, $step->{to_delete_data_id} ), 'to_delete data deleted';
                $cleaning_performed = 1;
                ++$cleanings_performed;
                ++$items_deleted;
            } elsif ( $step->{_STEP} eq 'Cleaning finished' ) {
                ok $step->{items_deleted} == $items_deleted,            'items deleted OK';
                ok $step->{bytes_deleted} > $step->{cleanup_bytes}, 'bytes deleted OK';
            }

            $LAST_REDIS_USED_MEMORY     = $step->{REDIS_USED_MEMORY};
        }

        if ( $cleaning_performed ) {
            ok $exists_before_cleanings,        'exists before cleanings';
            ok $calculated_cleaning_needed,     'cleaning needed';
        } else {
            ok !$exists_before_cleanings || !$calculated_cleaning_needed, 'not exists before cleanings';
        }
    }
    if ( $tested_function eq 'insert') {
        ok $cleanings_performed, 'cleanings performed';
    } else {
        diag 'cleanings on update present' if $cleanings_performed;
    }
    pass sprintf( 'expected: %.2f * %.2f (%.2f) < %.2f', $LAST_REDIS_USED_MEMORY, $MEMORY_RESERVE_COEFFICIENT, $LAST_REDIS_USED_MEMORY * $MEMORY_RESERVE_COEFFICIENT, $MAXMEMORY );
# NOTE: $LAST_REDIS_USED_MEMORY * $MEMORY_RESERVE_COEFFICIENT near by $MAXMEMORY according cleanup_bytes and cleanup_items';
#    ok $LAST_REDIS_USED_MEMORY * $MEMORY_RESERVE_COEFFICIENT > $MAXMEMORY, 'cleaning OK';
}

#-- Insert ---------------------------------------------------------------------

my $prev_time = 0;
my $time_grows = 0;
foreach my $current_cleanup_bytes ( 0, 100, 10_000 ) {
    foreach my $current_cleanup_items ( 0, 100, 10_000 ) {
        new_connection(
            undef,      # name
#TODO:
#            0,          # maxmemory
            1_000_000,  # maxmemory
            $current_cleanup_bytes,
            $current_cleanup_items,
        );

        $stuff = '*' x 1_000;
        $list_id = 'Some list_id';
        @operation_times = ();
        $inserts = 1_000;
        my $last_removed_time = $COLLECTION->collection_info->{last_removed_time};
        ok defined( _NUMBER( $last_removed_time ) ) && $last_removed_time == 0, 'OK last_removed_time before';
        for ( 1 .. $inserts ) {
            my $data_time = Time::HiRes::time;
            my $data_id = $data_time;
            push @operation_times, $data_time;
            $COLLECTION->_DEBUG( $data_time );
            $COLLECTION->insert( $list_id, $data_id, $stuff, $data_time );
        }
        my $last_cleanup_bytes = $COLLECTION->_call_redis( "HGET", $STATUS_KEY, 'last_cleanup_bytes'  );
        ok $last_cleanup_bytes, "last_cleanup_bytes calculated ($last_cleanup_bytes)";
        $last_removed_time = $COLLECTION->collection_info->{last_removed_time};
        ok $last_removed_time > 0, 'OK last_removed_time after';
        ok $last_removed_time >= $prev_time, 'OK last_removed_time';
        ++$time_grows if $last_removed_time > $prev_time;
        $prev_time = $last_removed_time;
        verifying( 'insert' );
    }
}
ok $time_grows, 'last_removed_time grows';

#-- Update ---------------------------------------------------------------------

$MAXMEMORY = 2_000_000;
foreach my $current_cleanup_bytes ( 0, 100 ) {
    foreach my $current_cleanup_items ( 0, 100, 10_000 ) {
        new_connection(
            undef,      # name
#TODO:
#            0,          # maxmemory
            $MAXMEMORY, # maxmemory
            $current_cleanup_bytes,
            $current_cleanup_items,
        );

        @operation_times = ();
        my %data_lists;
        my $inserted_data_size = 0;
        while ( $inserted_data_size < $MAXMEMORY ) {
            my $data_time = Time::HiRes::time;
            my $data_id = $data_time;
            push @operation_times, $data_time;
            $COLLECTION->_DEBUG( $data_time );
            $stuff = '*' x ( int( rand( 1_000 ) ) + 2 );
            $inserted_data_size += length( $stuff );
            $list_id = int( rand( 1_000 ) ) + 1;
            $data_lists{ $data_id } = $list_id;
            $COLLECTION->_DEBUG( Time::HiRes::time );
            $COLLECTION->insert( $list_id, $data_id, $stuff, $data_time );
        }
        verifying( 'insert' );
        my $last_cleanup_bytes = $COLLECTION->_call_redis( "HGET", $STATUS_KEY, 'last_cleanup_bytes'  );
        ( $last_cleanup_bytes ) = $last_cleanup_bytes =~ /(\d+)\]$/;
        ok $last_cleanup_bytes, "last_cleanup_bytes calculated ($last_cleanup_bytes)";

        $COLLECTION->_DEBUG( Time::HiRes::time );
        my $data_id  = $operation_times[ -100 ];    # cause $data_id == $data_time
        $list_id = $data_lists{ $data_id };
        $stuff = '@' x int( $last_cleanup_bytes / 2 );
        $COLLECTION->update( $list_id, $data_id, $stuff );
        my $new_last_cleanup_bytes = $COLLECTION->_call_redis( "HGET", $STATUS_KEY, 'last_cleanup_bytes'  );
        ( $new_last_cleanup_bytes ) = $new_last_cleanup_bytes =~ /(\d+)\]$/;
        ok $new_last_cleanup_bytes, "last_cleanup_bytes calculated ($new_last_cleanup_bytes)";
        verifying( 'update' );

        #-- cleaning himself
        for ( my $i = 0; $i < scalar( @operation_times ); $i++ ) {
            $data_id = $operation_times[ $i ];
            $list_id = $data_lists{ $data_id };
            unless ( defined $COLLECTION->receive( $list_id, $data_id ) ) {
                $COLLECTION->_DEBUG( Time::HiRes::time );
                eval { $COLLECTION->update( $list_id, $data_id, $stuff ) };
                my $error = $@;
                ok !$error, 'no exception';
                break;
            }
        }

        #-- $E_NONEXISTENT_DATA_ID
        $data_id = 99999999;
        $COLLECTION->_DEBUG( Time::HiRes::time );
        ok !$COLLECTION->update( $list_id, $data_id, $stuff ), 'data not exists';
#TODO:
# - When DATA_KEY not exists
# - When data cleaned
    }
}

#-- ROLLBACK ---------------------------------------------------------------------
#$MAXMEMORY = 2_000_000;
#new_connection(
#    undef,      # name
##TODO:
##    0,          # maxmemory
#    $MAXMEMORY, # maxmemory
#);
#
#@operation_times = ();
#my %data_lists;
#my $inserted_data_size = 0;
#while ( $inserted_data_size < $MAXMEMORY ) {
#    my $data_time = Time::HiRes::time;
#    my $data_id = $data_time;
#    push @operation_times, $data_time;
#    $COLLECTION->_DEBUG( $data_time );
#    $stuff = '*' x ( int( rand( 1_000 ) ) + 2 );
#    $inserted_data_size += length( $stuff );
#    $list_id = int( rand( 1_000 ) ) + 1;
#    $data_lists{ $data_id } = $list_id;
#    $COLLECTION->insert( $list_id, $data_id, $stuff, $data_time );
#}
#verifying( 'insert' );
#
#$COLLECTION->_DEBUG( Time::HiRes::time );
#my $data_id  = $operation_times[ -100 ];    # cause $data_id == $data_time
#$list_id = $data_lists{ $data_id };
##TODO:
## - how to achieve the desired error?
##   - in _DEBUG mode to cause error?
## - incorrect or unclear we are working with 'maxmemory-policy noeviction'
#$stuff = '@' x ( int( $MAXMEMORY / $MEMORY_RESERVE_COEFFICIENT ) - 1 );
#$COLLECTION->update( $list_id, $data_id, $stuff );
#verifying( 'update' );

}