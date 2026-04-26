use strict;
use warnings;

use Test2::V0;

use Parallel::Subs;

subtest 'total_jobs tracks added jobs' => sub {
    my $p = Parallel::Subs->new();
    is $p->total_jobs(), 0, "no jobs initially";

    $p->add( sub { 1 } );
    is $p->total_jobs(), 1, "one job after add";

    $p->add( sub { 2 } );
    is $p->total_jobs(), 2, "two jobs after second add";
};

subtest 'run with no jobs returns undef' => sub {
    my $p = Parallel::Subs->new();
    my $result = $p->run();
    ok !defined $result, "run() with no jobs returns undef";
};

subtest 'add with non-CODE croaks' => sub {
    my $p = Parallel::Subs->new();

    like dies { $p->add("not a coderef") },
        qr/add\(\) requires a CODE reference/,
        "add() with string croaks";

    like dies { $p->add(undef) },
        qr/add\(\) requires a CODE reference/,
        "add() with undef croaks";

    is $p->total_jobs(), 0, "no jobs were actually added";
};

subtest 'results ordering matches job order' => sub {
    my $p = Parallel::Subs->new( max_process => 1 );
    for my $i ( 1 .. 10 ) {
        $p->add( sub { $i } );
    }
    $p->run();
    is $p->results(), [ 1 .. 10 ], "results preserve insertion order";
};

subtest 'wait_for_all_optimized runs all jobs and preserves results' => sub {
    my $p = Parallel::Subs->new();
    for my $i ( 1 .. 8 ) {
        $p->add( sub { $i } );
    }
    my $ret = $p->wait_for_all_optimized();
    isa_ok $ret, 'Parallel::Subs';
    is $ret->results(), [ 1 .. 8 ],
        "optimized mode preserves all return values in order";
};

subtest 'wait_for_all_optimized with fewer jobs than CPUs' => sub {
    # Force many CPUs but add only 2 jobs — should not fork unnecessary processes
    my $p = Parallel::Subs->new( max_process => 8 );
    $p->add( sub { 'a' } );
    $p->add( sub { 'b' } );
    my $ret = $p->wait_for_all_optimized();
    isa_ok $ret, 'Parallel::Subs';

    my $results = $ret->results();
    is scalar @$results, 2, "only 2 results, not 8 (no empty fork results)";
    is $results, [ 'a', 'b' ], "results preserve values when jobs < CPUs";
};

subtest 'max_process limits concurrency' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    for my $i ( 1 .. 4 ) {
        $p->add( sub { $i * 10 } );
    }
    $p->run();
    is $p->results(), [ 10, 20, 30, 40 ], "results correct with max_process=2";
};

subtest 'max_memory warns on non-Linux platforms' => sub {
    my $has_memstats = eval { require Sys::Statistics::Linux::MemStats; 1 };

    if ($has_memstats) {
        pass "Sys::Statistics::Linux::MemStats available — skipping warning test";
        return;
    }

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $p = Parallel::Subs->new( max_memory => 128 );
    isa_ok $p, 'Parallel::Subs';

    is scalar @warnings, 1, "exactly one warning emitted";
    like $warnings[0], qr/max_memory.*falling back/,
        "warning mentions max_memory fallback";
};

subtest 'constructor rejects negative max_process' => sub {
    like dies { Parallel::Subs->new( max_process => -1 ) },
        qr/max_process must be a positive number/,
        "max_process => -1 croaks";

    like dies { Parallel::Subs->new( max_process => 0 ) },
        qr/max_process must be a positive number/,
        "max_process => 0 croaks";
};

subtest 'constructor rejects negative max_process_per_cpu' => sub {
    like dies { Parallel::Subs->new( max_process_per_cpu => -2 ) },
        qr/max_process_per_cpu must be a positive number/,
        "max_process_per_cpu => -2 croaks";

    like dies { Parallel::Subs->new( max_process_per_cpu => 0 ) },
        qr/max_process_per_cpu must be a positive number/,
        "max_process_per_cpu => 0 croaks";
};

subtest 'constructor rejects negative max_memory' => sub {
    like dies { Parallel::Subs->new( max_memory => -100 ) },
        qr/max_memory must be a positive number/,
        "max_memory => -100 croaks";

    like dies { Parallel::Subs->new( max_memory => 0 ) },
        qr/max_memory must be a positive number/,
        "max_memory => 0 croaks";
};

subtest 'add with non-CODE callback croaks' => sub {
    my $p = Parallel::Subs->new();

    like dies { $p->add( sub { 1 }, "not a coderef" ) },
        qr/callback must be a CODE reference/,
        "string callback croaks";

    like dies { $p->add( sub { 1 }, [1, 2, 3] ) },
        qr/callback must be a CODE reference/,
        "arrayref callback croaks";

    like dies { $p->add( sub { 1 }, { a => 1 } ) },
        qr/callback must be a CODE reference/,
        "hashref callback croaks";

    is $p->total_jobs(), 0, "no jobs were added after bad callbacks";
};

subtest 'add with undef callback is allowed' => sub {
    my $p = Parallel::Subs->new();
    ok $p->add( sub { 1 }, undef ), "undef callback accepted";
    is $p->total_jobs(), 1, "job was added";
};

subtest 'wait_for_all_optimized preserves complex return types' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { { key => 'value' } } );
    $p->add( sub { [ 1, 2, 3 ] } );
    $p->add( sub { 'scalar' } );
    $p->add( sub { 42 } );

    $p->wait_for_all_optimized();
    my $results = $p->results();

    is $results->[0], { key => 'value' }, "hashref result preserved";
    is $results->[1], [ 1, 2, 3 ],        "arrayref result preserved";
    is $results->[2], 'scalar',            "string result preserved";
    is $results->[3], 42,                  "numeric result preserved";
};

subtest 'wait_for_all_optimized warns about callbacks' => sub {
    my $p = Parallel::Subs->new( max_process => 2 );
    $p->add( sub { 1 }, sub { } );
    $p->add( sub { 2 }, sub { } );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $p->wait_for_all_optimized();

    ok scalar @warnings >= 1, "at least one warning emitted";
    like $warnings[0], qr/Callback not supported/,
        "warning mentions callback not supported";
};

subtest 'wait_for_all with no jobs returns self' => sub {
    my $p = Parallel::Subs->new();
    my $ret = $p->wait_for_all();
    is $ret, exact_ref($p), "wait_for_all with no jobs returns \$self";
};

subtest 'wait_for_all_optimized with no jobs returns self' => sub {
    my $p = Parallel::Subs->new();
    my $ret = $p->wait_for_all_optimized();
    is $ret, exact_ref($p), "wait_for_all_optimized with no jobs returns \$self";
};

done_testing;
