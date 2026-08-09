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

# A live child obeys a broadcast stop: the command rides the inbox, is
# drained on the heartbeat, and the child exits cleanly - which the
# supervisor answers with a respawn, because a commanded stop is recycling,
# not shutdown.
{
    my ($q, $file) = make_queue();
    my $app = task_app("dbi:SQLite:dbname=$file");

    # fast heartbeat so the inbox drains quickly
    my $h = pq_start(['worker', '--app', $app, '-j', '1'],
                     env => { PUNK_QUEUE_NO_HM_ABI => 1 });

    my $deadline = time + 15;
    my @child;
    while (time < $deadline) {
        @child = grep { $_->{role} eq 'child' }
                 @{ $q->list_workers->{workers} };
        last if @child == 1;
        select undef, undef, undef, 0.1;
    }
    is(scalar @child, 1, 'one child registered');
    my $old_row = $child[0]{id};

    is($q->broadcast('stop', [], [$old_row]), 1, 'stop sent to its inbox');

    # the child drains on its heartbeat (10s default) - but also on the
    # first idle pass after any claim; nudge it with a job so the drain
    # happens promptly rather than at the heartbeat interval
    $q->enqueue(add => [1, 1]);

    $deadline = time + 30;
    my @after;
    while (time < $deadline) {
        @after = grep { $_->{role} eq 'child' }
                 @{ $q->list_workers->{workers} };
        last if @after == 1 && $after[0]{id} != $old_row;
        select undef, undef, undef, 0.2;
    }
    is(scalar @after, 1, 'a child is running again');
    isnt($after[0]{id}, $old_row,
         'and it is a fresh registration - the old one obeyed the stop');

    my ($code) = pq_finish($h, 'TERM');
    is($code, 0, 'clean shutdown');
    unlink $app;
}

done_testing();
