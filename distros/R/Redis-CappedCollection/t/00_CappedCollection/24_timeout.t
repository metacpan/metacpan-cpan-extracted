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
    eval 'use Net::EmptyPort qw()';             ## no critic
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
use Time::HiRes ();

use Redis::CappedCollection qw(
    $DEFAULT_CONNECTION_TIMEOUT
    $DEFAULT_OPERATION_TIMEOUT
    $DEFAULT_PORT
);
use Redis::CappedCollection::Test::Utils qw(
    get_redis
    verify_redis
);

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

    testing();
}

sub testing {
    new_connection();

    #-- connection_timeout
    ok !defined( $COLLECTION->connection_timeout ), 'connection_timeout is not set';
    ok !defined( $REDIS->{sock}->timeout), 'socket timeout is not set';
    work();

    $COLLECTION->connection_timeout( $DEFAULT_CONNECTION_TIMEOUT );
    is $COLLECTION->connection_timeout, $DEFAULT_CONNECTION_TIMEOUT, 'connection_timeout is set';
    is $REDIS->{sock}->timeout, $DEFAULT_CONNECTION_TIMEOUT, 'socket timeout is set';
    work();

    $COLLECTION->connection_timeout( undef );
    ok !$COLLECTION->connection_timeout, 'connection_timeout is unset';
    ok !$REDIS->{sock}->timeout, 'socket timeout is unset';
    work();

    #-- operation_timeout
    ok !defined( $COLLECTION->operation_timeout ), 'operation_timeout is not set';
    dies_ok { $REDIS->{sock}->read_timeout } 'socket read_timeout is not set';
    dies_ok { $REDIS->{sock}->write_timeout } 'socket write_timeout is not set';
    work();

    $COLLECTION->operation_timeout( $DEFAULT_OPERATION_TIMEOUT );
    is $COLLECTION->operation_timeout, $DEFAULT_OPERATION_TIMEOUT, 'operation_timeout is set';
    is $REDIS->{sock}->read_timeout, $DEFAULT_OPERATION_TIMEOUT, 'socket read_timeout is set';
    is $REDIS->{sock}->write_timeout, $DEFAULT_OPERATION_TIMEOUT, 'socket write_timeout is set';
    ok $REDIS->{sock}->timeout_enabled, 'socket read/write enabled';
    work();

    $COLLECTION->operation_timeout( undef );
    is $COLLECTION->operation_timeout, undef, 'operation_timeout is unset';
    ok !$REDIS->{sock}->read_timeout, 'socket read_timeout is unset';
    ok !$REDIS->{sock}->write_timeout, 'socket write_timeout is unset';
    ok !$REDIS->{sock}->timeout_enabled, 'socket read/write timeout disabled';
    work();

    $COLLECTION->drop_collection;
    $COLLECTION->quit;
}

sub new_connection {
    if ( $REDIS_SERVER ) {
        $REDIS_SERVER->stop;
        undef $REDIS_SERVER;
    }

    $port = Net::EmptyPort::empty_port( $port );
    ( $REDIS_SERVER, $ERROR_MSG ) = get_redis(
        conf => {
            port                => $port,
            'maxmemory-policy'  => 'noeviction',
            maxmemory           => 1_000_000,
        },
    );
    skip( $ERROR_MSG, 1 ) unless $REDIS_SERVER;
    isa_ok( $REDIS_SERVER, 'Test::RedisServer' );

    $COLLECTION = Redis::CappedCollection->create(
        redis                   => $REDIS_SERVER,
        name                    => $uuid->create_str,
    );
    isa_ok( $COLLECTION, 'Redis::CappedCollection' );

    $REDIS = $COLLECTION->_redis;
    isa_ok( $REDIS, 'Redis' );

    return;
}

sub work {
    my $list_id = 'List id';
    for ( my $i = 0; $i < 1_000; $i++ ) {
        my $tm = Time::HiRes::time;
        is $COLLECTION->insert( $list_id, $tm, 'Stuff', $tm ), $list_id, 'operation OK';
    }
}