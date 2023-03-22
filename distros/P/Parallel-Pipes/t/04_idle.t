use strict;
use warnings;
use Test::More;

use Parallel::Pipes;
use Parallel::Pipes::App;


subtest 'Parallel::Pipes' => sub {
    plan skip_all => 'skip on windows' if $^O eq 'MSWin32';
    my $idle_work_called = 0;
    my $pipes = Parallel::Pipes->new(5, sub { sleep 1; 1 }, {
        idle_tick => 0.4,
        idle_work => sub { $idle_work_called++ },
    });
    for my $r ($pipes->is_ready) {
        $r->write(1);
    }
    while (1) {
        my @written = $pipes->is_written;
        last if !@written;
        for my $r ($pipes->is_ready(@written)) {
            $r->read;
        }
    }
    $pipes->close;
    is $idle_work_called, 2;
};

subtest 'Parallel::Pipes::App' => sub {
    plan skip_all => 'skip on windows' if $^O eq 'MSWin32';
    my $init_work_called = 0;
    my $before_work_called = 0;
    my $after_work_called = 0;
    my $idle_work_called = 0;
    Parallel::Pipes::App->run(
        num => 5,
        tasks => [1..5],
        work => sub { sleep 1; 1 },
        init_work => sub {
            my $pipes = shift;
            ok $pipes->isa('Parallel::Pipes');
            $init_work_called++;
        },
        before_work => sub {
            my ($task, $pipe) = @_;
            ok $pipe->isa('Parallel::Pipes::Here');
            $before_work_called++;
        },
        after_work => sub {
            my ($result, $pipe) = @_;
            ok $pipe->isa('Parallel::Pipes::Here');
            $after_work_called++;
        },
        idle_tick => 0.4,
        idle_work => sub { $idle_work_called++ },
    );
    is $init_work_called, 1;
    is $before_work_called, 5;
    is $after_work_called, 5;
    is $idle_work_called, 2;
};

subtest 'Parallel::Pipes::App no fork' => sub {
    my $init_work_called = 0;
    my $before_work_called = 0;
    my $after_work_called = 0;
    my $idle_work_called = 0;
    Parallel::Pipes::App->run(
        num => 1,
        tasks => [1],
        work => sub { sleep 1; 1 },
        init_work => sub {
            my $pipes = shift;
            ok $pipes->isa('Parallel::Pipes');
            $init_work_called++;
        },
        before_work => sub {
            my ($task, $pipe) = @_;
            ok $pipe->isa('Parallel::Pipes::Impl::NoFork');
            $before_work_called++;
        },
        after_work => sub {
            my ($result, $pipe) = @_;
            ok $pipe->isa('Parallel::Pipes::Impl::NoFork');
            $after_work_called++;
        },
        idle_tick => 0.4,
        idle_work => sub { $idle_work_called++ },
    );
    is $init_work_called, 1;
    is $before_work_called, 1;
    is $after_work_called, 1;
    is $idle_work_called, 0;
};

done_testing;
