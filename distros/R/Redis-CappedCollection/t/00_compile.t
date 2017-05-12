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

BEGIN { use_ok 'Redis::CappedCollection', qw(
    $DATA_VERSION
    $DEFAULT_CONNECTION_TIMEOUT
    $DEFAULT_OPERATION_TIMEOUT
    $DEFAULT_SERVER
    $DEFAULT_PORT
    $NAMESPACE
    $MIN_MEMORY_RESERVE
    $MAX_MEMORY_RESERVE
    $DEFAULT_CLEANUP_ITEMS

    $E_NO_ERROR
    $E_MISMATCH_ARG
    $E_DATA_TOO_LARGE
    $E_NETWORK
    $E_MAXMEMORY_LIMIT
    $E_MAXMEMORY_POLICY
    $E_COLLECTION_DELETED
    $E_REDIS
    $E_DATA_ID_EXISTS
    $E_OLDER_THAN_ALLOWED
    $E_NONEXISTENT_DATA_ID
    $E_INCOMP_DATA_VERSION
    $E_REDIS_DID_NOT_RETURN_DATA
    $E_UNKNOWN_ERROR
    ) }

my $val;

ok( defined( $_ ), "import OK: $_" ) foreach qw(
    $DATA_VERSION
    $DEFAULT_SERVER
    $DEFAULT_PORT
    $NAMESPACE
    $MIN_MEMORY_RESERVE
    $MAX_MEMORY_RESERVE

    $E_NO_ERROR
    $E_INCOMP_DATA_VERSION
    $E_MISMATCH_ARG
    $E_DATA_TOO_LARGE
    $E_NETWORK
    $E_MAXMEMORY_LIMIT
    $E_MAXMEMORY_POLICY
    $E_COLLECTION_DELETED
    $E_REDIS
    $E_DATA_ID_EXISTS
    $E_OLDER_THAN_ALLOWED
    $E_NONEXISTENT_DATA_ID
    $E_NOSCRIPT
    );
