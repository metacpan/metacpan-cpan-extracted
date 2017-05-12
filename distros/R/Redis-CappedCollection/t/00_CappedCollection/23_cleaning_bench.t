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
use Data::UUID;
use List::Util;
use POSIX;
use Time::HiRes ();

use Redis::CappedCollection qw(
    $DEFAULT_PORT
);
use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

#const my $IGNORE_PERSENTS   => 1;
const my $IGNORE_PERSENTS   => 0;

# -- Global variables
my $uuid = new Data::UUID;
my (
    $COLLECTION,
    $ERROR_MSG,
    $REDIS,
    $REDIS_SERVER,
    $port,
);

( $REDIS_SERVER, $ERROR_MSG, $port ) = verify_redis();

SKIP: {
    diag $ERROR_MSG if $ERROR_MSG;
    skip( $ERROR_MSG, 1 ) if $ERROR_MSG;

    if ( $ENV{AUTHOR_TESTS} ) {
        testing();
    }
}

sub testing {
    diag "NOTE: data is added to a single list";
    diag "NOTE: $IGNORE_PERSENTS percents of operations with max times are ignored for average and median calculation";

    my $maxmemory = 1_000_000;
#    my $maxmemory = 758382040;
    my $data_len = 1_000;
    my $stuff = '*' x $data_len;
    my $list_id_len = 20;
#    my $list_id_len = 30;
    my $list_id = '*' x $list_id_len;
    my @operation_times = ();
    my $inserts = 100_000;
#    my $inserts = 10_000_000;
    diag "maxmemory = $maxmemory, list_id length = $list_id_len, data length = $data_len, data_id length = ".length( Time::HiRes::time );

    foreach my $cleanup_bytes ( 0, 100, 10_000 ) {
        foreach my $cleanup_items ( 0, 100, 10_000 ) {
#    foreach my $cleanup_bytes ( 60 * 1024 ) {
#        foreach my $cleanup_items ( 200 ) {
            new_connection(
                undef,      # name
                $maxmemory,
                $cleanup_bytes,
                $cleanup_items,
            );

            diag "--------------------------------------------------";
            diag "cleanup_bytes = $cleanup_bytes, cleanup_items = $cleanup_items";
            my @cleanings_operations;
            for ( my $i = 1; $i <= $inserts; $i++ ) {
                my $start_time = Time::HiRes::time;
                my ( undef, $cleanings ) = $COLLECTION->insert( $list_id, $start_time, $stuff, $start_time );
                my $finish_time = Time::HiRes::time;

                if ( $cleanings ) {
                    push @cleanings_operations, {
                        cleanings       => $cleanings,
                        operation_time  =>  $finish_time - $start_time,
                    };
                }

                pass "inserts $i/$inserts" if $i % int( $inserts / 10 ) == 0;
            }
            diag scalar( @cleanings_operations )."/$inserts cleaning operations";
            print_result_times( \@cleanings_operations );

            $COLLECTION->drop_collection;
            $COLLECTION->quit;
        }
    }
}

sub new_connection {
    my ( $name, $maxmemory, $cleanup_bytes, $cleanup_items, $memory_reserve ) = @_;

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
        'older_allowed' => 1,
        $name           ? ( name            => $name )              : (),
        $cleanup_bytes  ? ( 'cleanup_bytes' => $cleanup_bytes )     : (),
        $cleanup_items  ? ( 'cleanup_items' => $cleanup_items )     : (),
        $memory_reserve ? ( memory_reserve  => $memory_reserve )    : (),
    );
    isa_ok( $COLLECTION, 'Redis::CappedCollection' );

    $REDIS = $COLLECTION->_redis;
    isa_ok( $REDIS, 'Redis' );
    $REDIS->config_set( maxmemory => $maxmemory );
    $REDIS->config_set( 'maxmemory-policy' => 'noeviction' );

    return;
}

sub median {
    return List::Util::sum( ( sort { $a <=> $b } @_ )[ int( $#_ / 2 ), POSIX::ceil( $#_ / 2 ) ] ) / 2;
}

sub print_result_times {
    my ( $cleanings_operations ) = @_;

    my %times;
    ++$times{ $_->{operation_time} } foreach @$cleanings_operations;
    my @unique_times = reverse sort keys %times;
    pass "total times = ".scalar( @$cleanings_operations ).", unique times = ".scalar( @unique_times );

    my (
        $min_cleanings,
        $max_cleanings,
        $total_cleanings,
        $average_cleanings,
        $median_cleanings,
        $min_time,
        $max_time,
        $total_time,
        $average_time,
        $median_time,
    );

    $min_cleanings      =
    $max_cleanings      =
    $min_time           =
    $max_time           =
        0;

    foreach my $operation ( @$cleanings_operations ) {
        my $operation_time = $operation->{operation_time};
        my $cleanings = $operation->{cleanings};
        $min_cleanings = $cleanings if !$min_cleanings || $cleanings < $min_cleanings;
        $max_cleanings = $cleanings if !$max_cleanings || $cleanings > $max_cleanings;
        $min_time = $operation_time if !$min_time || $operation_time < $min_time;
        $max_time = $operation_time if !$max_time || $operation_time > $max_time;
    }

    # ignore $IGNORE_PERSENTS operations with max times
    my $total_operations = scalar @$cleanings_operations;
    my $ignored_operations = int( $total_operations * $IGNORE_PERSENTS / 100 );
    my $accounted_operations = $total_operations - $ignored_operations;
    CLEAR_TIMES:
    foreach my $max_time ( @unique_times ) {
        foreach my $operation ( @$cleanings_operations ) {
            last CLEAR_TIMES unless $ignored_operations;

            if ( $operation->{operation_time} == $max_time ) {
                $operation->{operation_time} = 0;
                --$ignored_operations;
            }
        }
    }

    my ( @cleanings, @times );

    $total_cleanings    =
    $total_time         =
    $average_cleanings  =
    $median_cleanings   =
    $average_time       =
    $median_time        =
        0;

    foreach my $operation ( @$cleanings_operations ) {
        if ( my $operation_time = $operation->{operation_time} ) {
            my $cleanings = $operation->{cleanings};
            $total_cleanings += $cleanings;
            $total_time += $operation_time;

            push @cleanings, $cleanings;
            push @times, $operation_time;
        }
    }
    $average_cleanings = $total_cleanings / $accounted_operations;
    $average_time = $total_time / $accounted_operations;
    $median_cleanings = median( @cleanings );
    $median_time = median( @times );

    diag sprintf( 'cleanings: min = %d, max = %d, average = %d, median = %df', $min_cleanings, $max_cleanings, int( $average_cleanings ), int( $median_cleanings ) );
    diag sprintf( 'operation time (sec): min = %.3f, max = %.3f, average = %.3f, median = %.3f', $min_time, $max_time, $average_time, $median_time );
}