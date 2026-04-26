use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'jobs complete within timeout' => sub {
    my $p = Parallel::Subs->new( max_process => 2, timeout => 10 );
    $p->add( sub { return 42 } );
    $p->add( sub { return 84 } );
    $p->wait_for_all();
    is $p->results(), [ 42, 84 ], "fast jobs return correct results with timeout";
};

subtest 'timeout terminates hung child' => sub {
    my $p = Parallel::Subs->new( max_process => 1, timeout => 1 );
    $p->add( sub { sleep 100; return 'never' } );

    my $start = time;
    eval { $p->wait_for_all() };
    my $elapsed = time - $start;

    ok $elapsed < 10, "hung job terminated within timeout (${elapsed}s elapsed)";
    ok $@, "failure detected from timed-out job";
};

subtest 'timeout does not affect fast jobs alongside slow ones' => sub {
    # Run a fast job and a hung job in parallel
    my $p = Parallel::Subs->new( max_process => 2, timeout => 2 );
    $p->add( sub { return 'fast' } );
    $p->add( sub { sleep 100; return 'never' } );

    my $start = time;
    eval { $p->wait_for_all() };
    my $elapsed = time - $start;

    ok $elapsed < 10, "did not hang (${elapsed}s elapsed)";
    # The fast job's result should still be collected
    ok exists $p->{result}{1}, "fast job result was collected";
    is $p->{result}{1}, 'fast', "fast job returned correct value";
};

subtest 'timeout with wait_for_all_optimized' => sub {
    my $p = Parallel::Subs->new( max_process => 2, timeout => 5 );
    for my $i ( 1 .. 4 ) {
        $p->add( sub { $i } );
    }
    $p->wait_for_all_optimized();
    # Just verify it completes without hanging
    pass "optimized mode completes within timeout";
};

subtest 'timeout with callbacks' => sub {
    my $collected = 0;
    my $p = Parallel::Subs->new( timeout => 5 );
    $p->add(
        sub { return 10 },
        sub { $collected += shift }
    );
    $p->add(
        sub { return 20 },
        sub { $collected += shift }
    );
    $p->wait_for_all();
    is $collected, 30, "callbacks fire normally with timeout set";
};

subtest 'constructor rejects invalid timeout' => sub {
    like dies { Parallel::Subs->new( timeout => -1 ) },
        qr/timeout must be a positive number/,
        "negative timeout croaks";

    like dies { Parallel::Subs->new( timeout => 0 ) },
        qr/timeout must be a positive number/,
        "zero timeout croaks";
};

subtest 'alarm is cleared after successful job' => sub {
    # Run jobs sequentially to verify alarm is properly reset between jobs
    my $p = Parallel::Subs->new( max_process => 1, timeout => 2 );
    $p->add( sub { return 'a' } );
    $p->add( sub { return 'b' } );
    $p->add( sub { return 'c' } );
    $p->wait_for_all();
    is $p->results(), [ 'a', 'b', 'c' ], "sequential jobs all complete with timeout";
};

done_testing;
