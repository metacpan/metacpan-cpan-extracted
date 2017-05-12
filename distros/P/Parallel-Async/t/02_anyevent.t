use strict;
use warnings;

use Test::More;
use Test::Requires qw/AnyEvent/;

use Parallel::Async;

sub new_task {
    return async {
        note $$;
        return $$;
    };
}

subtest 'as_anyevent_child' => sub {
    my $task = new_task();

    my $cv = AnyEvent->condvar;
    my $w; $w = $task->as_anyevent_child(sub {
        undef $w;
        $cv->send(@_);
    });

    my ($pid, $status, @result) = $cv->recv;
    is $result[0], $pid;
    is $result[0], $task->child_pid();
};

done_testing;

