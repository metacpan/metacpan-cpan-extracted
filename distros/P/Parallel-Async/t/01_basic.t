use strict;
use warnings;

use Test::More;

use Parallel::Async;

sub new_task {
    return async {
        note $$;
        return $$;
    };
}

subtest 'pid' => sub {
    my $task = new_task;
    is $task->parent_pid, $$;
    is $task->child_pid, undef;

    my $ret = $task->recv();
    is $task->parent_pid, $$;
    is $task->child_pid,  $ret;
};

subtest 'recv' => sub {
    my $task = new_task;
    my $ret  = $task->recv();
    is $ret, $task->child_pid;
};

subtest 'clone' => sub {
    my $task = new_task();
    my $ret = $task->recv();
    is $ret, $task->child_pid;

    $ret = eval { $task->recv() };
    like $@, qr/\A\Qthis task already run./msi;
    is $ret, undef;

    $task = $task->clone;
    $ret = $task->recv();
    is $ret, $task->child_pid;
};

subtest 'reset' => sub {
    my $task = new_task();
    my $ret = $task->recv();
    is $ret, $task->child_pid;

    $ret = eval { $task->recv() };
    like $@, qr/\A\Qthis task already run./msi;
    is $ret, undef;

    $task->reset;
    $ret = $task->recv();
    is $ret, $task->child_pid;
};

subtest 'run' => sub {
    my $task = new_task;
    my $pid = $task->run();
    is $pid, $task->child_pid;
};

done_testing;

