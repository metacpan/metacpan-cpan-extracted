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

# The wakeup gate. The worker's interval is set to 60 seconds, so polling
# cannot explain a fast pickup: if these jobs start promptly, LISTEN/NOTIFY
# genuinely woke the worker. This test cannot pass by accident.
#
# Run over both paths: the Hyperman loop (io_watch on pg_socket) and the
# plain poll(2) path (the notify fd in the pollfd set).

plan skip_all => 'set PUNK_QUEUE_PG_DSN (and install DBD::Pg) to run'
    unless has_pg();

my $has_hm = eval { require Hyperman; 1 };
my @paths = (['poll', { PUNK_QUEUE_NO_HM_ABI => 1 }]);
push @paths, ['loop', {}] if $has_hm;

for my $p (@paths) {
    my ($name, $env) = @$p;

    subtest "$name path: NOTIFY wakes a 60s-interval worker" => sub {
        my $q = make_pg_queue();
        my $app = task_app(pg_dsn());

        my $h = pq_start(['worker', '--app', $app, '--interval', '60'],
                         env => $env);

        # let the worker boot, connect and LISTEN
        my $deadline = time + 15;
        while (time < $deadline) {
            last if $q->list_workers->{total} > 0;
            select undef, undef, undef, 0.1;
        }
        ok($q->list_workers->{total} > 0, 'the worker is up');
        select undef, undef, undef, 0.5;    # and listening

        my @took;
        for my $i (1 .. 5) {
            my $id = $q->enqueue(add => [$i, $i]);
            my $t0 = Time::HiRes::time();
            my $lim = $t0 + 10;
            while (Time::HiRes::time() < $lim) {
                last if $q->job_info($id)->{state} eq 'finished';
                select undef, undef, undef, 0.01;
            }
            my $took = Time::HiRes::time() - $t0;
            push @took, $took;
            is($q->job_info($id)->{state}, 'finished',
               sprintf 'job %d finished (%.0fms)', $i, $took * 1000);
        }

        my @sorted = sort { $a <=> $b } @took;
        diag sprintf '%s pickup: median %.0fms, worst %.0fms',
            $name, $sorted[2] * 1000, $sorted[-1] * 1000;
        ok($sorted[-1] < 5,
           'every pickup beat the 60s interval by an order of magnitude - '
         . 'only NOTIFY explains that');

        my ($code) = pq_finish($h, 'TERM');
        is($code, 0, 'clean shutdown');
        unlink $app;
    };
}

done_testing();
