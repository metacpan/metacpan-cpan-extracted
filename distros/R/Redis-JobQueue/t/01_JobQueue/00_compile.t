#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More tests => 30;
use Test::NoWarnings;

BEGIN { use_ok 'Redis::JobQueue', qw(
    DEFAULT_SERVER
    DEFAULT_PORT
    DEFAULT_TIMEOUT
    DEFAULT_CONNECTION_TIMEOUT
    DEFAULT_OPERATION_TIMEOUT

    E_NO_ERROR
    E_MISMATCH_ARG
    E_DATA_TOO_LARGE
    E_NETWORK
    E_MAX_MEMORY_LIMIT
    E_JOB_DELETED
    E_REDIS
    ) }

can_ok( 'Redis::JobQueue', 'new' );
can_ok( 'Redis::JobQueue', 'add_job' );
can_ok( 'Redis::JobQueue', 'get_job_data' );
can_ok( 'Redis::JobQueue', 'get_job_meta_fields' );
can_ok( 'Redis::JobQueue', 'load_job' );
can_ok( 'Redis::JobQueue', 'get_next_job' );
can_ok( 'Redis::JobQueue', 'get_next_job_id' );
can_ok( 'Redis::JobQueue', 'update_job' );
can_ok( 'Redis::JobQueue', 'delete_job' );
can_ok( 'Redis::JobQueue', 'get_job_ids' );
can_ok( 'Redis::JobQueue', 'ping' );
can_ok( 'Redis::JobQueue', 'quit' );

can_ok( 'Redis::JobQueue', 'timeout' );
can_ok( 'Redis::JobQueue', 'max_datasize' );
can_ok( 'Redis::JobQueue', 'last_errorcode' );

my $val;
ok( $val = DEFAULT_SERVER(),    "import OK: $val" );
ok( $val = DEFAULT_PORT(),      "import OK: $val" );
ok( $val = DEFAULT_CONNECTION_TIMEOUT(),    "import OK: $val" );
ok( $val = DEFAULT_OPERATION_TIMEOUT(),     "import OK: $val" );
$val = undef;
ok( defined ( $val = DEFAULT_TIMEOUT() ),   "import OK: $val" );

ok( ( $val = E_NO_ERROR() ) == 0, "import OK: $val" );
ok( $val = E_MISMATCH_ARG(),      "import OK: $val" );
ok( $val = E_DATA_TOO_LARGE(),    "import OK: $val" );
ok( $val = E_NETWORK(),           "import OK: $val" );
ok( $val = E_MAX_MEMORY_LIMIT(),  "import OK: $val" );
ok( $val = E_JOB_DELETED(),       "import OK: $val" );
ok( $val = E_REDIS(),             "import OK: $val" );

ok( $val = Redis::JobQueue::MAX_DATASIZE(), "import OK: $val" );
