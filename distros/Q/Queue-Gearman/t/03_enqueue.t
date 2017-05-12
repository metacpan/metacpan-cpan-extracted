use strict;
use Test::More 0.98;

use t::Util;
use Queue::Gearman;

plan skip_all => 'cannot find gearmand.' unless has_gearmand();

my $gearmand = setup_gearmand();
my $server   = sprintf 'localhost:%d', $gearmand->port;

my $queue = Queue::Gearman->new(
    servers            => [$server],
    serialize_method   => sub { join ',', @{$_[0]} },
    deserialize_method => sub { [split /,/, $_[0]] },
);
isa_ok $queue, 'Queue::Gearman';
$queue->can_do('add');

subtest 'dequeue: no job' => sub {
    my $job = $queue->dequeue();
    is $job, undef, 'no job';
};

subtest 'enqueue_forground: complete' => sub {
    my $task1 = $queue->enqueue_forground(add => [1, 2]);
    isa_ok $task1, 'Queue::Gearman::Task';

    my $task2 = $queue->enqueue_forground(add => [3, 4]);
    isa_ok $task2, 'Queue::Gearman::Task';

    ok !$task1->is_finished, 'task1 is not finished yet';
    ok !$task2->is_finished, 'task2 is not finished yet';

    my $job1 = $queue->dequeue();
    isa_ok $job1, 'Queue::Gearman::Job';
    is $job1->func, 'add', 'func: add';
    is_deeply $job1->arg, [1, 2], 'arg: 1,2';
    $job1->complete([3]);

    $task1->wait();
    $task2->wait();

    ok $task1->is_finished, 'task1 is finished';
    ok !$task1->fail, 'task1 is not failed';
    is_deeply $task1->result, [3], 'task1 has result: 3';
    ok !$task2->is_finished, 'task2 is not finished yet';

    my $job2 = $queue->dequeue();
    isa_ok $job2, 'Queue::Gearman::Job';
    is $job2->func, 'add', 'func: add';
    is_deeply $job2->arg, [3, 4], 'arg: 3,4';
    $job2->complete([7]);

    $task2->wait();

    ok $task2->is_finished, 'task2 is finished';
    ok !$task2->fail, 'task2 is not failed';
    is_deeply $task2->result, [7], 'task2 has result: 7';

    my $job3 = $queue->dequeue();
    is $job3, undef, 'empty';
};

subtest 'enqueue_forground: fail' => sub {
    my $task1 = $queue->enqueue_forground(add => [1, 2]);
    isa_ok $task1, 'Queue::Gearman::Task';

    my $task2 = $queue->enqueue_forground(add => [3, 4]);
    isa_ok $task2, 'Queue::Gearman::Task';

    ok !$task1->is_finished, 'task1 is not finished yet';
    ok !$task2->is_finished, 'task2 is not finished yet';

    my $job1 = $queue->dequeue();
    isa_ok $job1, 'Queue::Gearman::Job';
    is $job1->func, 'add', 'func: add';
    is_deeply $job1->arg, [1, 2], 'arg: 1,2';
    $job1->fail();

    $task1->wait();
    $task2->wait();

    ok $task1->is_finished, 'task1 is finished';
    ok $task1->fail, 'task1 is failed';
    ok !$task2->is_finished, 'task2 is not finished yet';

    my $job2 = $queue->dequeue();
    isa_ok $job2, 'Queue::Gearman::Job';
    is $job2->func, 'add', 'func: add';
    is_deeply $job2->arg, [3, 4], 'arg: 3,4';
    $job2->fail();

    $task2->wait();

    ok $task2->is_finished, 'task2 is finished';
    ok $task2->fail, 'task2 is failed';

    my $job3 = $queue->dequeue();
    is $job3, undef, 'empty';
};

subtest 'enqueue_background' => sub {
    my $task1 = $queue->enqueue_background(add => [1, 2]);
    isa_ok $task1, 'Queue::Gearman::Task';

    my $task2 = $queue->enqueue_background(add => [3, 4]);
    isa_ok $task2, 'Queue::Gearman::Task';

    my $job1 = $queue->dequeue();
    isa_ok $job1, 'Queue::Gearman::Job';
    is $job1->func, 'add', 'func: add';
    is_deeply $job1->arg, [1, 2], 'arg: 1,2';
    $job1->complete([]);

    my $job2 = $queue->dequeue();
    isa_ok $job2, 'Queue::Gearman::Job';
    is $job2->func, 'add', 'func: add';
    is_deeply $job2->arg, [3, 4], 'arg: 3,4';
    $job2->complete([]);

    my $job3 = $queue->dequeue();
    is $job3, undef, 'empty';
};

done_testing;
