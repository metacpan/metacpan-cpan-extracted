use strict;
use warnings;

use Test::More;

use Parallel::Async;

my $task = async {
    note $$;
    return (@_, $$);
};

subtest 'single task' => sub {
    my @res = $task->recv(1, 2, 3);
    is_deeply \@res, [1, 2, 3, $task->child_pid];

    @res = $task->reset->recv(4, 5, 6);
    is_deeply \@res, [4, 5, 6, $task->child_pid];
};

subtest 'multi task' => sub {
    my @tasks = map { $task->clone } 1..3;
    my $chain = $tasks[0]->join(@tasks[1, 2]);

    my @res = $chain->recv(1, 2, 3);
    is_deeply \@res, [
        [1, 2, 3, $tasks[0]->child_pid],
        [1, 2, 3, $tasks[1]->child_pid],
        [1, 2, 3, $tasks[2]->child_pid],
    ];

    @res = $chain->reset->recv(4, 5, 6);
    is_deeply \@res, [
        [4, 5, 6, $tasks[0]->child_pid],
        [4, 5, 6, $tasks[1]->child_pid],
        [4, 5, 6, $tasks[2]->child_pid],
    ];
};

done_testing;

