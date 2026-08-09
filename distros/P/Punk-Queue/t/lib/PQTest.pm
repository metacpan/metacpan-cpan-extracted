package PQTest;

# Test helper: a throwaway SQLite queue, and a drain loop.
#
# File-backed rather than :memory:, because the whole point of a queue is
# that more than one process can see it, and an in-memory database is
# invisible even to a second handle in the same process. The temp file goes
# away with the object.

use 5.010;
use strict;
use warnings;
use Exporter 'import';
use File::Temp ();
use File::Spec ();

our @EXPORT_OK = qw(queue_file make_queue drain has_dbd
                    pg_dsn has_pg make_pg_queue);
our @EXPORT    = @EXPORT_OK;

my @KEEP;   # File::Temp::Dir objects live as long as the test does

sub has_dbd {
    return eval { require DBI; require DBD::SQLite; 1 } ? 1 : 0;
}

# A path in a fresh temp directory. The directory (not just the file) so
# SQLite's -wal and -shm siblings are cleaned up too.
sub queue_file {
    my $dir = File::Temp->newdir(TEMPLATE => 'punkq-XXXXXX', TMPDIR => 1);
    push @KEEP, $dir;
    return File::Spec->catfile("$dir", 'queue.db');
}

# A migrated queue on a fresh database.
sub make_queue {
    my (%opts) = @_;
    require Punk::Queue;
    my $file = delete $opts{file} || queue_file();
    my $q = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file", %opts);
    $q->migrate unless delete $opts{no_migrate};
    return wantarray ? ($q, $file) : $q;
}

# ---- PostgreSQL ------------------------------------------------------------
#
# Gated on PUNK_QUEUE_PG_DSN, e.g.
#     PUNK_QUEUE_PG_DSN=dbi:Pg:dbname=punk_queue_test prove -b t/
#
# Unlike SQLite there is no throwaway file, so a fresh queue means dropping
# the pq_* tables and re-migrating. That makes the Pg tests destructive on
# their database by design - the DSN is opt-in precisely so nobody points it
# at anything they care about.

sub pg_dsn { $ENV{PUNK_QUEUE_PG_DSN} }

sub has_pg {
    return 0 unless pg_dsn();
    return eval { require DBI; require DBD::Pg; 1 } ? 1 : 0;
}

sub _pg_wipe {
    my ($dsn) = @_;
    my $dbh = DBI->connect($dsn, '', '',
                           { RaiseError => 1, PrintError => 0 });
    $dbh->do("SET client_min_messages = WARNING");   # silence the IF EXISTS notices
    $dbh->do("DROP VIEW IF EXISTS pq_jobs_human");
    $dbh->do("DROP TABLE IF EXISTS $_ CASCADE")
        for qw(pq_job_logs pq_job_deps pq_jobs pq_workers pq_locks
               pq_crons pq_migrations);
    $dbh->disconnect;
}

# A migrated queue on a wiped Pg database. The connection pool is keyed on
# dsn and pid, so the wipe happens on its own handle and the queue gets a
# pooled one afterwards.
sub make_pg_queue {
    my (%opts) = @_;
    require Punk::Queue;
    my $dsn = pg_dsn() or die 'make_pg_queue without PUNK_QUEUE_PG_DSN';
    _pg_wipe($dsn);
    my $q = Punk::Queue->new(dsn => $dsn, %opts);
    $q->migrate unless delete $opts{no_migrate};
    return $q;
}

# Claim and run until the queue is empty. Returns the number of jobs run.
# The cap is a guard against a task that enqueues itself: a test that hangs
# is much worse to debug than one that fails.
sub drain {
    my ($q, %opts) = @_;
    my $max = delete $opts{max};
    $max = 1000 unless defined $max;
    my @pass;
    for my $k (qw(queues tasks worker)) {
        push @pass, $k, $opts{$k} if exists $opts{$k};
    }
    my $n = 0;
    while ($n < $max) {
        my $job = $q->dequeue(@pass) or last;
        $q->perform($job);
        $n++;
    }
    return $n;
}

1;
