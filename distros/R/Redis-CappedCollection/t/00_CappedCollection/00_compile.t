#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More;
plan "no_plan";

BEGIN {
    eval 'use Test::NoWarnings';    ## no critic
    plan skip_all => 'because Test::NoWarnings required for testing' if $@;
}

BEGIN { use_ok 'Redis::CappedCollection' }

can_ok( 'Redis::CappedCollection', $_ ) foreach qw(
    new
    create
    insert
    update
    upsert
    receive
    collection_exists
    collection_info
    list_info
    oldest_time
    open
    pop_oldest
    redis_config_ok
    resize
    list_exists
    lists
    drop_collection
    clear_collection
    drop_list
    ping
    quit

    cleanup_bytes
    cleanup_items
    connection_timeout
    last_errorcode
    max_datasize
    name
    older_allowed
    operation_timeout
    reconnect_on_error
    redis
    );

my $val;
ok( $val = $Redis::CappedCollection::MAX_DATASIZE, "import OK: $val" );
