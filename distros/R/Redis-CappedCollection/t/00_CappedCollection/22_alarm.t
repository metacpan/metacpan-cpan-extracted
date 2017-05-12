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

use Const::Fast;
use Data::UUID;
use Redis::CappedCollection qw(
    $E_NO_ERROR
);
use Sys::SigAction qw(
    set_sig_handler
);
use Time::HiRes;
use Try::Tiny;

use Redis::CappedCollection::Test::Utils qw(
    clear_coll_data
    verify_redis
);

STDOUT->autoflush;

my ( $redis, $skip_msg, $port ) = verify_redis();

my $uuid = new Data::UUID;
my ( $coll, $coll_redis );

const my $BUSY_ERROR            => 'BUSY Redis is busy running a script. You can only call SCRIPT KILL or SHUTDOWN NOSAVE.';
const my $NOT_CONNECTED_ERROR   => 'Not connected to any server';
const my $MAX_ATTEMPTS          => 35;
const my $HIRES_DELAY           => 0.1; # secs
const my $MAX_HIRES_ATTEMPTS    => int( $MAX_ATTEMPTS / $HIRES_DELAY );

SKIP: {
    diag $skip_msg if $skip_msg;
    skip( $skip_msg, 1 ) if $skip_msg;

    # For Test::RedisServer
    isa_ok( $redis, 'Test::RedisServer' );

    if ( $ENV{AUTHOR_TESTS} ) {
        test_alrm();
        test_timeout();
    }
}

sub test_timeout {
    pass '>> test_timeout started';
    my $server_conf = $redis->conf;
    $server_conf->{server} = '127.0.0.1:'.$server_conf->{port} unless exists $server_conf->{server};
    my $redis_client;
    foreach my $add_client_parameters (
            [],

            #--- The Redis client will wait at most that number of seconds (can be fractional) before giving up

            # connecting to a server
            [ cnx_timeout   => 0.1 ],
            [ cnx_timeout   => 1 ],
            [ cnx_timeout   => 5 ],

            # when reading from the server
            [ read_timeout  => 0.1 ],
            [ read_timeout  => 1 ],
            [ read_timeout  => 5 ],

            # when reading (writing ?!) from the server
            # NOTE: 'reading' in documentation
            [ write_timeout => 0.1 ],
            [ write_timeout => 1 ],
            [ write_timeout => 5 ],
        ) {
        undef $redis_client;

        pass "add_client_parameters: @$add_client_parameters";
        $redis_client = Redis->new(
            server                  => $server_conf->{server},
#            debug                   => 1,
            @$add_client_parameters,
        );
        isa_ok( $redis_client, 'Redis' );
        pass 'The collection was created for '.create_new_collection( $redis_client, 1 ).' secs';

        $coll->reconnect_on_error( 1 );
        my ( $ret, $error, $last_error, $destructive_runtime ) = destructive_alarm( 1 );
        ok !$coll->ping, 'The collection is not connected';
        ok !$coll->_redis->ping, 'The redis client is not connected';
        pass "destructive_runtime = $destructive_runtime";

        my $attempt = 0;
        my $start_time = Time::HiRes::time();
        for ( ; $attempt < $MAX_HIRES_ATTEMPTS; $attempt++ ) {
            if ( $redis_client->ping ) {
                ok $redis_client->ping, 'The redis client is connected';
                last;
            }

            Time::HiRes::sleep( $HIRES_DELAY );
            $redis_client->connect;
        }
        BAIL_OUT( 'Cannot create new collection' ) if $attempt >= $MAX_HIRES_ATTEMPTS;
        my $finish_time = Time::HiRes::time();
        ok $coll->ping, 'The collection is connected';
        diag 'Connection was reestablished for '.( $finish_time - $start_time)." secs (add_client_parameters: @$add_client_parameters)";
    }

    pass '<< test_timeout finished';
}

sub test_alrm {
    pass '>> test_alarm started';

    create_new_collection( $redis );
    $coll->reconnect_on_error( 0 );

    my ( $ret, $error, $last_error, $start_time, $finish_time );

    my $list_id = 'List_id';
    my $data_id = 0;
    my $data    = 'Data';

    $ret = $coll->insert( $list_id, $data_id++, $data, Time::HiRes::time() );
    is $ret, $list_id, 'simple insert';
    undef $ret;

    my $timeout = 1;

    $start_time     = time;
    $ret            = $coll->_long_term_operation;
    $finish_time    = time;
    ok( ( ref( $ret ) eq 'ARRAY' and $ret->[0] == $E_NO_ERROR and $ret->[1] == 1 ), '_long_term_operation without ALRM' );
    ok( ( $finish_time - $start_time > $timeout + 1 ), 'runtime gt timeout' );
    undef $ret;

    $ret = $coll->insert( $list_id, $data_id++, $data, Time::HiRes::time() );
    is $ret, $list_id, 'insert after _long_term_operation without ALRM';
    undef $ret;

    foreach my $reconnect_on_error ( 0, 1 ) # ATTENTION: not use ( 1,0 )
    {
        my $max_iterations = 2;
        for ( my $i = 1; $i <= $max_iterations; $i++ )
        {
            $coll->reconnect_on_error( $reconnect_on_error );

            pass "try $i/$max_iterations";
            pass 'reconnect_on_error = '.$coll->reconnect_on_error;
            $start_time = time;
            ( $ret, $error, $last_error ) = destructive_alarm( $timeout );
            $finish_time = time;
            ok( ( $finish_time - $start_time <= $timeout + 1 ), 'runtime matches timeout' );
            undef $ret;

            # PROBLEM:

            # Must be:
#            lives_ok {
#                $ret = $coll->insert( $list_id, $data_id++, $data, Time::HiRes::time() );
#            } 'expecting to live';
#            is $ret, $list_id, 'insert after _long_term_operation with ALRM';
            # But have:
            my $expected_error = $coll->reconnect_on_error
                ? $BUSY_ERROR
                : "Unknown error: \\[$E_NO_ERROR,1,'_long_term_operation'\\]" # because _long_term_operation
            ;
            throws_ok {
                $ret = $coll->insert( $list_id, $data_id, $data, Time::HiRes::time() );
            } qr/$expected_error/, 'We can not normal continue because previous operation has not completed';
            ok !defined( $ret ), 'ret not initialized becase insert died';
# Because _reconnect in _call_redis added
#            ok( !$coll->ping, 'connection is not still alive' );
            my $received_data;
#            unless ( $coll->reconnect_on_error ) {
#                $received_data = $coll->receive( $list_id, $data_id );
#                ok defined( $received_data ) && $received_data ne $data, "fake data 'received' without error";
#            }
            ++$data_id;
            undef $received_data;

            # Try to fix the problem
            $coll_redis->connect;   # Used into Redis::CappedCollection->_reconnect

            if ( $coll->reconnect_on_error ) {
                # The problem is not fixed
# Because _reconnect in _call_redis added
#                ok( !$coll->ping, 'connection is not alive' );
#                throws_ok {
#                    $ret = $coll->insert( $list_id, $data_id++, $data, Time::HiRes::time() );
#                } qr/$NOT_CONNECTED_ERROR/, $NOT_CONNECTED_ERROR;

                # Fix the problem
                create_new_collection( $redis );
                next;
            } else {
                # The problem is fixed
                ok( $coll->ping, 'connection is alive' );

                lives_ok {
                    $ret = $coll->insert( $list_id, $data_id, $data, Time::HiRes::time() );
                } 'expecting to live';
                is $ret, $list_id, 'insert after _long_term_operation with ALRM';
                $received_data = $coll->receive( $list_id, $data_id );
#                ok defined( $received_data ) && $received_data ne $data, "fake data 'received' without error";
                is $received_data, $data, 'new data received without error';
                ++$data_id;
                undef $ret;
                undef $received_data;

                # TROUBLE: not registered error (regardless of the $coll->reconnect_on_error)
                destructive_alarm( $timeout, 1 );
                $start_time = time;
                $ret = $coll->insert( $list_id, $data_id, $data, Time::HiRes::time() );
                $finish_time = time;
                ok( ( $finish_time - $start_time > 1 ), 'TROUBLE: too long wait' );
                is $ret, $list_id, 'TROUBLE: like a successful insert after _long_term_operation with ALRM';
                ok( !$coll->ping, 'TROUBLE: connection is not still alive' );
                $received_data = $coll->receive( $list_id, $data_id );
                ok defined( $received_data ) && $received_data ne $data, "fake data 'received' without error";

                ++$data_id;
            }

            undef $ret;
            $coll_redis->connect;
        }
    }

    $coll->quit;

    pass '<< test_alarm finished';
}

sub create_new_collection {
    my ( $redis ) = @_;

    undef $coll;

    my $attempt = 1;
    my $start_time = Time::HiRes::time();
    for ( ; $attempt <= $MAX_HIRES_ATTEMPTS; $attempt++ ) {
        my $error;
        if ( $coll ) {
            $coll->drop_collection;
            $coll->quit;
        }
        try {
            $coll = Redis::CappedCollection->create(
                redis   => $redis,
                name    => $uuid->create_str,
            );
        } catch {
            $error = $_;
        };

        last unless $error;

#        like( $error, qr/$BUSY_ERROR/, "Attempt $attempt/$MAX_HIRES_ATTEMPTS: $BUSY_ERROR" );
        Time::HiRes::sleep( $HIRES_DELAY );
    }
    BAIL_OUT( 'Cannot create new collection' ) unless $coll;
    my $finish_time = Time::HiRes::time();

    isa_ok( $coll, 'Redis::CappedCollection' );
    $coll_redis = $coll->_redis;
    isa_ok( $coll_redis, 'Redis' );

    return $finish_time - $start_time;
}

sub destructive_alarm
{
    my $timeout             = shift;
    my $return_as_insert    = shift;

    pass '>>>> destructive_alarm started';

    my ( $ret, $error, $last_error );
    my $start_time = Time::HiRes::time();
    eval {
        # trailing \n is important: without it, {die $error} allocates memory to add script location,
        # and this causes deadlocks if signal happens to be in another malloc
        my $h = set_sig_handler( 'ALRM', sub { die "ALRM\n"; }, {
                mask => [ 'ALRM' ],
                safe => 0, # perl 5.8+ uses safe signal delivery so we need unsafe signal for timeout to work
            }
        );
        eval {
            alarm( $timeout );
            $ret = $coll->_long_term_operation( $return_as_insert );
        };
        alarm( 0 ); # cancel alarm (if code ran fast)
        $error = $@;
        undef $h;   # remove handler
        die "$error\n" if $error;
    };
    $last_error = $@;
    my $finish_time = Time::HiRes::time();

    ok !defined( $ret ), 'the result is not set because of the interruption of operation';
    ok $error, 'interrupted by the ALRM signal';
    ok $last_error, 'interrupted by us';

    pass '<<<< destructive_alarm finished';

    return( $ret, $error, $last_error, $finish_time - $start_time );
}
