#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
use PQTest;
use PQSpawn;

# Kill the worker's LISTEN connection server-side and prove the wakeup
# recovers: re-connect, re-LISTEN, re-watch the NEW fd (the spike showed a
# reconnected handle gets a different socket). The failure shape this
# guards is specific and quiet - pg_notifies on a dead connection returns
# undef without dying and {Active} stays true, so a lazy implementation
# would sit deaf forever while looking healthy.

plan skip_all => 'set PUNK_QUEUE_PG_DSN (and install DBD::Pg) to run'
    unless has_pg();

my $has_hm = eval { require Hyperman; 1 };
my @paths = (['poll', { PUNK_QUEUE_NO_HM_ABI => 1 }]);
push @paths, ['loop', {}] if $has_hm;

for my $p (@paths) {
    my ($name, $env) = @$p;

    subtest "$name path: the wakeup survives pg_terminate_backend" => sub {
        my $q = make_pg_queue();
        my $app = task_app(pg_dsn());

        my $h = pq_start(['worker', '--app', $app, '--interval', '60'],
                         env => $env);

        my $deadline = time + 15;
        while (time < $deadline) {
            last if $q->list_workers->{total} > 0;
            select undef, undef, undef, 0.1;
        }
        select undef, undef, undef, 0.5;

        # prove the wakeup works before the cut
        my $id = $q->enqueue(add => [1, 1]);
        my $lim = Time::HiRes::time() + 10;
        1 while Time::HiRes::time() < $lim
            && $q->job_info($id)->{state} ne 'finished'
            && !select(undef, undef, undef, 0.01);
        is($q->job_info($id)->{state}, 'finished', 'wakeup works before');

        # cut the LISTEN connection from the server side
        my $killed = $q->dbh->selectcol_arrayref(q{
            SELECT pg_terminate_backend(pid) FROM pg_stat_activity
             WHERE pid <> pg_backend_pid() AND query LIKE 'LISTEN%'
        });
        ok(scalar @$killed, 'terminated the LISTEN backend(s)')
            or diag 'no LISTEN connection found to kill';

        # give the worker a beat to notice the EOF and reconnect
        select undef, undef, undef, 1.5;

        # the wakeup must still be NOTIFY-fast: the 60s interval means a
        # deaf worker would not pick this up inside the assertion window
        my $id2 = $q->enqueue(add => [2, 2]);
        my $t0 = Time::HiRes::time();
        $lim = $t0 + 15;
        while (Time::HiRes::time() < $lim) {
            last if $q->job_info($id2)->{state} eq 'finished';
            select undef, undef, undef, 0.01;
        }
        my $took = Time::HiRes::time() - $t0;
        is($q->job_info($id2)->{state}, 'finished',
           sprintf 'wakeup works after the cut (%.0fms)', $took * 1000);
        ok($took < 10, 'and NOTIFY-fast, not interval-slow');

        my ($code) = pq_finish($h, 'TERM');
        is($code, 0, 'clean shutdown');
        unlink $app;
    };
}

done_testing();
