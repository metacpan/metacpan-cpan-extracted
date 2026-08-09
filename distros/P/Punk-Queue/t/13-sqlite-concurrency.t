#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# The same exactly-once promise t/12 makes for SKIP LOCKED, kept here by
# BEGIN IMMEDIATE + busy_timeout: contending writers serialise at BEGIN
# and SQLITE_BUSY becomes a wait, not an error surfacing to the claim.

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $WORKERS = 4;
my $JOBS    = 100;

my ($q, $file) = make_queue();
$q->enqueue('grab', [$_]) for 1 .. $JOBS;

my %pipes;
for my $w (1 .. $WORKERS) {
    pipe my $r, my $wr or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r;
        require Punk::Queue;
        my $cq = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");
        while (my $job = $cq->dequeue(worker => $w)) {
            print {$wr} $job->id, "\n";
        }
        close $wr;
        exit 0;
    }
    close $wr;
    $pipes{$pid} = $r;
}

my (%claimed, %dupes);
for my $pid (keys %pipes) {
    my $r = $pipes{$pid};
    while (my $line = <$r>) {
        chomp $line;
        $dupes{$line}++ if $claimed{$line}++;
    }
    close $r;
    waitpid $pid, 0;
    is($? >> 8, 0, "claimer $pid exited 0");
}

is(scalar keys %claimed, $JOBS, "all $JOBS jobs were claimed");
is(scalar keys %dupes, 0, 'no job was claimed twice')
    or diag 'doubled ids: ' . join(', ', sort keys %dupes);

my ($active) = $q->dbh->selectrow_array(
    "SELECT count(*) FROM pq_jobs WHERE state = 'active'");
is($active, $JOBS, 'every row is active');

done_testing();
