#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# The one thing FOR UPDATE SKIP LOCKED is for: N processes hammering one
# queue, every job claimed exactly once, none lost, none doubled. Everything
# else about the Pg backend is covered by the conformance battery; this is
# the test that cannot be written in one process.

plan skip_all => 'set PUNK_QUEUE_PG_DSN (and install DBD::Pg) to run'
    unless has_pg();

my $WORKERS = 4;
my $JOBS    = 200;

my $q = make_pg_queue();
$q->enqueue('grab', [$_]) for 1 .. $JOBS;

# Each child claims as fast as it can, recording ids to a pipe. The child
# builds its own queue object post-fork; the pool's pid check hands it a
# fresh connection rather than the parent's.
my %pipes;
for my $w (1 .. $WORKERS) {
    pipe my $r, my $wr or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r;
        require Punk::Queue;
        my $cq = Punk::Queue->new(dsn => pg_dsn());
        while (my $job = $cq->dequeue(worker => $w)) {
            print {$wr} $job->id, "\n";
        }
        close $wr;
        exit 0;
    }
    close $wr;
    $pipes{$pid} = $r;
}

my (%claimed, %dupes, %per_worker);
for my $pid (keys %pipes) {
    my $r = $pipes{$pid};
    while (my $line = <$r>) {
        chomp $line;
        $dupes{$line}++ if $claimed{$line}++;
        $per_worker{$pid}++;
    }
    close $r;
    waitpid $pid, 0;
    is($? >> 8, 0, "claimer $pid exited 0");
}

is(scalar keys %claimed, $JOBS, "all $JOBS jobs were claimed");
is(scalar keys %dupes, 0, 'no job was claimed twice')
    or diag 'doubled ids: ' . join(', ', sort keys %dupes);

# Not a fairness assertion - SKIP LOCKED promises none - just visibility.
diag "claims per worker: " . join(', ', map { $per_worker{$_} // 0 }
                                        sort keys %pipes);

# And the table agrees: everything is active, stamped, nothing inactive.
my ($active) = $q->dbh->selectrow_array(
    "SELECT count(*) FROM pq_jobs WHERE state = 'active'");
my ($inactive) = $q->dbh->selectrow_array(
    "SELECT count(*) FROM pq_jobs WHERE state = 'inactive'");
is($active,   $JOBS, 'every row is active');
is($inactive, 0,     'none left behind');

done_testing();
