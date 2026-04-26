use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'sparse callbacks - only some jobs have callbacks' => sub {
    my @called;
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { 'first' },  sub { push @called, shift } );
    $p->add( sub { 'second' } );    # no callback
    $p->add( sub { 'third' },  sub { push @called, shift } );
    $p->wait_for_all();

    is scalar @called, 2, "exactly two callbacks fired";
    is [ sort @called ], [ 'first', 'third' ],
        "only defined callbacks are invoked with correct values";
};

subtest 'callback receives undef when job returns undef' => sub {
    my $called = 0;
    my $got    = 'sentinel';
    my $p      = Parallel::Subs->new( max_process => 1 );
    $p->add(
        sub { return undef },
        sub { $got = shift; $called = 1 }
    );
    $p->wait_for_all();

    ok $called, "callback was invoked";
    ok !defined $got, "callback received undef from job that returned undef";
};

subtest 'callbacks receive results in job insertion order' => sub {
    my @order;
    my $p = Parallel::Subs->new( max_process => 1 );
    for my $i ( 1 .. 5 ) {
        $p->add(
            sub { $i * 100 },
            sub { push @order, shift }
        );
    }
    $p->wait_for_all();

    is \@order, [ 100, 200, 300, 400, 500 ],
        "callbacks invoked in insertion order with correct values";
};

subtest 'complex return types survive fork serialization' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { { nested => { deep => [ 1, 2, 3 ] } } } );
    $p->add( sub { [qw(a b c)] } );
    $p->add( sub { 42 } );
    $p->run();

    my $results = $p->results();
    is $results->[0], { nested => { deep => [ 1, 2, 3 ] } },
        "nested hash survives fork";
    is $results->[1], [qw(a b c)],
        "array ref survives fork";
    is $results->[2], 42,
        "scalar survives fork";
};

subtest 'wait_for_all returns self for chaining with jobs' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { 1 } );
    $p->add( sub { 2 } );
    my $ret = $p->wait_for_all();

    is $ret, exact_ref($p), "wait_for_all returns \$self when jobs exist";
};

subtest 'results before run returns empty list' => sub {
    my $p = Parallel::Subs->new();
    $p->add( sub { 1 } );
    my $results = $p->results();

    is $results, [], "results() before run() returns empty arrayref";
};

subtest 'many jobs with callbacks' => sub {
    my @collected;
    my $n = 20;
    my $p = Parallel::Subs->new( max_process => 4 );
    for my $i ( 1 .. $n ) {
        $p->add(
            sub { $i },
            sub { push @collected, shift }
        );
    }
    $p->wait_for_all();

    is scalar @collected, $n, "$n callbacks fired";
    is [ sort { $a <=> $b } @collected ], [ 1 .. $n ],
        "all $n jobs produced correct results via callbacks";
};

subtest 'callbacks fire as jobs complete (real-time)' => sub {
    # With max_process=1, jobs run sequentially.
    # Verify callbacks fire during run(), not after all jobs finish.
    my @log;
    my $p = Parallel::Subs->new( max_process => 1 );
    $p->add(
        sub { 'a' },
        sub { push @log, "cb:" . shift }
    );
    $p->add(
        sub { 'b' },
        sub { push @log, "cb:" . shift }
    );
    $p->wait_for_all();

    is \@log, [ 'cb:a', 'cb:b' ],
        "callbacks fired in completion order during execution";
    is $p->results(), [ 'a', 'b' ],
        "results are still available after callbacks";
};

subtest 'callback sum pattern works with real-time invocation' => sub {
    # Classic sum pattern from the SYNOPSIS
    my $sum = 0;
    my $p   = Parallel::Subs->new( max_process => 2 );
    for my $i ( 1 .. 10 ) {
        $p->add(
            sub { $i },
            sub { $sum += shift }
        );
    }
    $p->wait_for_all();

    is $sum, 55, "sum of 1..10 via callbacks equals 55";
};

done_testing;
