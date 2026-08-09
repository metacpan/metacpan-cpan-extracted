#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

require Punk::Queue;

# A fresh database migrates from nothing.
{
    my $file = queue_file();
    my $q = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");

    is($q->schema_version, 0, 'a fresh database reports version 0');

    my $v = $q->migrate;
    ok($v > 0, "migrate applied up to version $v");
    is($q->schema_version, $v, 'and the database agrees');
    is($q->backend->latest_version, $v,
       'which is the latest version this build knows');
}

# Migrating twice is a no-op, not an error. Every worker calls this at boot.
{
    my ($q) = make_queue();
    my $v = $q->schema_version;

    is($q->migrate, $v, 're-running migrate returns the same version');
    is($q->migrate, $v, 'and again');
    is($q->schema_version, $v, 'the schema did not move');
}

# The tables and indexes the rest of the dist depends on.
{
    my ($q) = make_queue();
    my $dbh = $q->dbh;

    my $tables = $dbh->selectcol_arrayref(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name");
    my %have = map { $_ => 1 } @$tables;

    for my $t (qw(pq_jobs pq_job_deps pq_workers pq_locks pq_crons
                  pq_migrations)) {
        ok($have{$t}, "table $t exists");
    }

    my $idx = $dbh->selectcol_arrayref(
        "SELECT name FROM sqlite_master WHERE type = 'index' ORDER BY name");
    my %hidx = map { $_ => 1 } @$idx;

    # pq_jobs_ready is the dequeue hot path; the rest matter later, but a
    # missing one is much cheaper to notice here than in phase 5.
    for my $i (qw(pq_jobs_ready pq_jobs_delayed pq_jobs_gc pq_jobs_expires
                  pq_jobs_worker pq_jobs_task pq_jobs_lock_key
                  pq_deps_parent pq_locks_name pq_locks_expires
                  pq_crons_due)) {
        ok($hidx{$i}, "index $i exists");
    }
}

# WAL is mandatory for a file-backed queue: a reader must not block the
# claim transaction. It is applied at connect, and migrate refuses without
# it - this asserts the connect half took.
{
    my ($q) = make_queue();
    my ($mode) = $q->dbh->selectrow_array('PRAGMA journal_mode');
    is(lc $mode, 'wal', 'journal_mode is WAL on a file-backed queue');

    my ($fk) = $q->dbh->selectrow_array('PRAGMA foreign_keys');
    ok($fk, 'foreign_keys is on, so the dependency cascade works');
}

# The clock delta: probed once per connection, and small against a local
# SQLite (its now() and ours are the same clock).
{
    my ($q) = make_queue();
    my $delta = $q->backend->clock_delta;
    ok(abs($delta) < 5, "clock delta is small for a local database ($delta)");

    my $now = $q->backend->now;
    ok(abs($now - time()) < 5, 'now() is close to wall clock');
}

# Partial migration: asking for a version we already have changes nothing.
{
    my ($q) = make_queue();
    my $v = $q->schema_version;
    is($q->migrate(1), $v, 'migrate(1) against a current schema is a no-op');
}

# Auto-migration: on by default, and it fires on the first job operation
# rather than in new() - Punk::Queue->new(...)->schema_version must be able
# to report 0 for an unmigrated database, which is exactly what a deploy
# check asks.
{
    my $file = queue_file();
    my $q = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");
    is($q->schema_version, 0, 'new() does not migrate');

    my $id = $q->enqueue('t');
    ok($id, 'the first enqueue works on an unmigrated database');
    ok($q->schema_version > 0, 'because it migrated first');
}

# auto_migrate => 0 turns it off, and then the operation fails rather than
# silently creating a schema behind a deploy process's back.
{
    my $file = queue_file();
    my $q = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file",
                             auto_migrate => 0);
    eval { $q->enqueue('t') };
    ok($@, 'auto_migrate => 0 leaves the database alone');
    is($q->schema_version, 0, 'and the schema was not created');
}

done_testing();
