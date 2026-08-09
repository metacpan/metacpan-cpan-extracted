#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;
use PQConform;

# The exact same battery t/10 runs against SQLite. Nothing Pg-specific may
# appear here - if PostgreSQL needs its own assertion for a behaviour, the
# contract has diverged and that is the bug.

plan skip_all => 'set PUNK_QUEUE_PG_DSN (and install DBD::Pg) to run'
    unless has_pg();

conformance(\&make_pg_queue, 'pg');

done_testing();
