use strict;
use warnings;

use Test2::V0;
use POSIX ();

use Parallel::Subs;

# Note: we use eval{} + $@ instead of dies{} because dies{} from Test2
# interferes with Parallel::ForkManager's exit() in child processes.

subtest 'single job failure reports error message' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    $p->add( sub { die "something went wrong\n" } );

    eval { $p->wait_for_all() };
    my $err = $@;
    like $err, qr/Job failures:/, "dies with Job failures header";
    like $err, qr/something went wrong/, "includes the original die message";
    like $err, qr/job 1/, "includes job ID";
    like $err, qr/pid \d+/, "includes PID";
};

subtest 'multiple failures collected before reporting' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { die "error A\n" } );
    $p->add( sub { die "error B\n" } );
    $p->add( sub { 42 } );

    eval { $p->wait_for_all() };
    my $err = $@;
    like $err, qr/Job failures:/, "dies with Job failures header";
    like $err, qr/error A/, "includes first error message";
    like $err, qr/error B/, "includes second error message";
};

subtest 'successful jobs run despite sibling failure' => sub {
    my $p = Parallel::Subs->new( max_process => 4 );
    $p->add( sub { 'ok1' } );
    $p->add( sub { die "fail\n" } );
    $p->add( sub { 'ok2' } );
    $p->add( sub { 'ok3' } );

    eval { $p->run() };
    my $err = $@;
    like $err, qr/fail/, "failure is reported";
    # Successful results are collected even when some jobs fail
    is $p->{result}{1}, 'ok1', "job 1 result preserved";
    is $p->{result}{3}, 'ok2', "job 3 result preserved";
    is $p->{result}{4}, 'ok3', "job 4 result preserved";
};

subtest 'job dying with complex error' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    $p->add( sub { die "multiline\nerror\nmessage\n" } );

    eval { $p->wait_for_all() };
    my $err = $@;
    like $err, qr/multiline/, "captures multiline die message";
};

subtest 'job exit via POSIX::_exit detected as failure' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    $p->add( sub { POSIX::_exit(1) } );

    eval { $p->wait_for_all() };
    my $err = $@;
    like $err, qr/Job failures:/, "non-zero _exit detected as failure";
    like $err, qr/exit=1/, "exit code is 1";
};

subtest 'all jobs succeed — no error' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { 'a' } );
    $p->add( sub { 'b' } );
    $p->add( sub { 'c' } );

    eval { $p->wait_for_all() };
    is $@, '', "no error when all jobs succeed";
    is $p->results(), [ 'a', 'b', 'c' ], "results are correct";
};

subtest 'wait_for_all_optimized preserves results' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    for my $i ( 1 .. 6 ) {
        $p->add( sub { $i * 10 } );
    }

    $p->wait_for_all_optimized();
    is $p->results(), [ 10, 20, 30, 40, 50, 60 ],
      "optimized mode preserves individual job results";
};

subtest 'wait_for_all_optimized with fewer jobs than CPUs preserves results' => sub {
    my $p = Parallel::Subs->new( max_process => 8 );
    $p->add( sub { 'x' } );
    $p->add( sub { 'y' } );

    $p->wait_for_all_optimized();
    is $p->results(), [ 'x', 'y' ],
      "results preserved when jobs < CPUs";
};

done_testing;
