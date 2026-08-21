#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;
use PQSpawn;

plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

# The scheduler's one guarantee: at-most-once per cron occurrence, no
# matter how many schedulers believe they are leader. Two layers enforce
# it - the optimistic `WHERE next_run = ?` advance and the per-occurrence
# unique key - and this file attacks each with real processes.

# ---- forced double leadership ----------------------------------------------
#
# Skip the election entirely: fork eight processes that ALL run the tick
# at once on the same due cron. Every one of them acts as a leader; the
# occurrence must still fire exactly once. This is the harder guarantee -
# the election above it only reduces contention.

{
    my ($q, $file) = make_queue();
    $q->upsert_cron({ name => 'contested', expr => '* * * * *',
                      task => 'contested.task' });
    # the last minute boundary: due, fresh, and - because the NEXT
    # boundary is still ahead - exactly one occurrence to fire. Step
    # over the boundary first if it is about to move under us.
    sleep 61 - time % 60 if time % 60 > 55;
    my $occ = int(time / 60) * 60;
    $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                undef, $occ, 'contested');

    my $n = 8;
    my %pipes;
    for my $i (1 .. $n) {
        pipe my $r, my $w or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $r;
            require Punk::Queue;
            my $c = Punk::Queue->new(dsn => "dbi:SQLite:dbname=$file");
            my $fired = eval { $c->backend->_cron_tick } // 0;
            print {$w} "$fired\n";
            close $w;
            require POSIX;
            POSIX::_exit(0);
        }
        close $w;
        $pipes{$pid} = $r;
    }
    my $total = 0;
    for my $pid (keys %pipes) {
        my $fh = $pipes{$pid};
        my $line = <$fh> // '';
        chomp $line;
        $total += $line || 0;
        close $pipes{$pid};
        waitpid $pid, 0;
    }

    is($total, 1, 'eight simultaneous leaders fired exactly one job');
    is($q->list_jobs(0, 0, { task => 'contested.task' })->{total}, 1,
       'and exactly one job row exists');
    my $c = $q->cron_info('contested');
    is($c->{last_run}, $occ, 'the occurrence is recorded once');
    ok($c->{next_run} > time, 'and the schedule moved on');
}

# ---- the election, with real supervisors ------------------------------------
#
# Two supervisor pools against one database: one wins the pq.cron.leader
# lease, one stands by. The scheduler ticks on 10s wall boundaries, so
# each phase below allows a generous window.

sub wait_for {
    my ($check, $timeout) = @_;
    my $deadline = time + ($timeout // 30);
    while (time < $deadline) {
        my $got = $check->();
        return $got if $got;
        select undef, undef, undef, 0.25;
    }
    return undef;
}

SKIP: {
    skip 'set PUNK_QUEUE_SLOW=1 to run the supervisor election (about 40s)', 9
        unless $ENV{PUNK_QUEUE_SLOW} || $ENV{AUTOMATED_TESTING};

    my ($q, $file) = make_queue();
    my $dsn = "dbi:SQLite:dbname=$file";
    my $app = task_app($dsn, <<'EOF');
$q->task('cron.mark' => sub { 'marked' });
EOF
    $q->upsert_cron({ name => 'mark', expr => '* * * * *',
                      task => 'cron.mark' });
    $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                undef, int(time) - 10, 'mark');

    my $a = pq_start(['worker', '--app', $app, '-j', 1,
                      '--interval', '0.2']);
    my $b = pq_start(['worker', '--app', $app, '-j', 1,
                      '--interval', '0.2']);

    # one of them wins the lease and fires the due occurrence
    ok(wait_for(sub {
        $q->list_jobs(0, 0, { task => 'cron.mark' })->{total} >= 1;
    }), 'a leader emerged and fired the due occurrence');
    is($q->list_jobs(0, 0, { task => 'cron.mark' })->{total}, 1,
       'exactly once, with two pools running');

    my $lock = wait_for(sub {
        my $l = $q->list_locks(0, 0, { name => 'pq.cron.leader' });
        $l->{total} == 1 ? $l->{locks}[0] : undef;
    });
    ok($lock, 'exactly one leader lease exists');
    my $first_owner = $lock->{owner};
    ok($first_owner, 'and it names its owner');

    # the owner is one of the two supervisor rows; kill that process
    my %sup;  # supervisor worker id -> process handle
    for my $h ($a, $b) {
        my $got = wait_for(sub {
            my $ws = $q->list_workers(0, 0, { role => 'supervisor' });
            for my $w (@{ $ws->{workers} }) {
                $sup{$w->{id}} = $w->{pid} if $w->{pid};
            }
            scalar(keys %sup) >= 2;
        });
        last if $got;
    }
    my $leader_pid = $sup{$first_owner};
    ok($leader_pid, 'the lease owner is a registered supervisor');
    my ($leader, $standby) =
        $leader_pid == $a->{pid} ? ($a, $b) : ($b, $a);

    my ($code) = pq_finish($leader, 'TERM');
    is($code, 0, 'the leader shut down cleanly');

    # a graceful leader hands the lease back; the standby picks it up on
    # its next aligned tick and fires the next due occurrence
    $q->dbh->do('UPDATE pq_crons SET next_run = ? WHERE name = ?',
                undef, int(time) - 5, 'mark');
    # the handback makes this quick, but it is an optimisation, not the
    # guarantee: if the departing leader never got to release, the standby
    # waits out the 30s lease and then its own aligned pass. Budget for
    # the slow path, or the test only passes on the fast one.
    ok(wait_for(sub {
        $q->list_jobs(0, 0, { task => 'cron.mark' })->{total} >= 2;
    }, 90), 'the standby took over and fired the next occurrence');

    my $l2 = $q->list_locks(0, 0, { name => 'pq.cron.leader' });
    is($l2->{total}, 1, 'one lease again');
    isnt($l2->{locks}[0]{owner}, $first_owner, 'held by the survivor');

    pq_finish($standby, 'TERM');
    unlink $app;
}

done_testing();
