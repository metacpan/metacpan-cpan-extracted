use strict;
use warnings;

use Test::More;
use Time::HiRes qw/sleep/;

use Parallel::Async;

sub new_task {
    return async {
        sleep 0.1 * (1 + int rand 3);
        note $$;
        return (@_, $$);
    };
}

my $task1 = new_task();
my $task2 = new_task();
my $task3 = new_task();

my $chain = $task1->join($task2)->join($task3);

subtest 'recv' => sub {
    my @res = $chain->recv;
    is_deeply \@res, [
        [ $task1->child_pid ],
        [ $task2->child_pid ],
        [ $task3->child_pid ],
    ];
};

subtest 'run' => sub {
    my @pids = $chain->reset->run;

    is_deeply \@pids, [
        $task1->child_pid,
        $task2->child_pid,
        $task3->child_pid,
    ];

    wait for @pids;
};

subtest 'clone' => sub {
    my $chain2 = $chain->clone;
    my @res = $chain2->recv;
    is_deeply \@res, [
        [ $chain2->{tasks}->[0]->child_pid ],
        [ $chain2->{tasks}->[1]->child_pid ],
        [ $chain2->{tasks}->[2]->child_pid ],
    ];

    isnt $chain2->{tasks}->[0]->child_pid, $task1->child_pid;
    isnt $chain2->{tasks}->[1]->child_pid, $task2->child_pid;
    isnt $chain2->{tasks}->[2]->child_pid, $task3->child_pid;
};

subtest 'nest' => sub {
    my $chain2 = $chain->clone;
    my @res = $chain->reset->join($chain2)->recv($$);
    is_deeply \@res, [
        [ $$, $task1->child_pid ],
        [ $$, $task2->child_pid ],
        [ $$, $task3->child_pid ],
        [ $$, $chain2->{tasks}->[0]->child_pid ],
        [ $$, $chain2->{tasks}->[1]->child_pid ],
        [ $$, $chain2->{tasks}->[2]->child_pid ],
    ];
};

done_testing;

