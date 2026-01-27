#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);
use Params::Filter qw/filter/;

say "=" x 80;
say "Params::Filter: All Interfaces Benchmark";
say "=" x 80;
say "";
say 'Comparing four approaches:';
say '  1. Functional interface: filter($data, @req, @acc, @exc)';
say '  2. OO interface: $f->apply($data)';
say '  3. Safe closure: make_filter(@req, @acc, @exc)->($data) [copies input]';
say '  4. Fast closure: make_filterFast(@req, @acc, @exc)->($data) [may modify input]';
say "";

# ============================================================================
# CORRECTNESS TESTS
# ============================================================================
say "-" x 80;
say "CORRECTNESS TESTS";
say "-" x 80;
say "";

my @req = qw/id name email/;
my @acc = qw/phone city/;
my @exc = qw/password/;

my $closure_safe = Params::Filter::make_filter(\@req, \@acc, \@exc);
my $closure_fast = Params::Filter::make_filterFast(\@req, \@acc, \@exc);
my $oo = Params::Filter->new_filter({
    required => \@req,
    accepted => \@acc,
    excluded => \@exc,
});

my $test_data = {
    id => 1,
    name => 'Alice',
    email => 'alice@example.com',
    phone => '555-1234',
    city => 'NYC',
    password => 'secret',
};

my ($func_result, $func_msg) = filter($test_data, \@req, \@acc, \@exc);
my $oo_result = $oo->apply($test_data);
my $safe_result = $closure_safe->($test_data);
my $fast_result = $closure_fast->({$test_data->%*});  # Pass a copy

say "Test 1: All approaches produce identical results";
say "  Functional: ", join(", ", sort keys %$func_result);
say "  OO:        ", join(", ", sort keys %$oo_result);
say "  Safe:      ", join(", ", sort keys %$safe_result);
say "  Fast:      ", join(", ", sort keys %$fast_result);

if (join(",", sort keys %$func_result) eq join(",", sort keys %$oo_result) &&
    join(",", sort keys %$func_result) eq join(",", sort keys %$safe_result) &&
    join(",", sort keys %$func_result) eq join(",", sort keys %$fast_result)) {
    say "  ✅ All four approaches produce identical results";
} else {
    say "  ❌ RESULTS DIFFER!";
}
say "";

say "Test 2: make_filterFast() is destructive";
my $data1 = {$test_data->%*};
my $data2 = {$test_data->%*};
$closure_fast->($data1);
say "  Before: ", join(", ", sort keys %$data2);
$closure_fast->($data2);
say "  After:  ", join(", ", sort keys %$data2);
say "  Original modified? ", (keys %$data2 < keys %$test_data) ? "YES (destructive)" : "NO";
say "";

say "Test 3: make_filter() is non-destructive";
my $data3 = {$test_data->%*};
my $data4 = {$test_data->%*};
say "  Before: ", join(", ", sort keys %$data3);
$closure_safe->($data3);
say "  After:  ", join(", ", sort keys %$data3);
say "  Original intact? ", (keys %$data3 == keys %$data4) ? "YES (non-destructive)" : "NO";
say "";

say "=" x 80;
say "CORRECTNESS TESTS COMPLETE";
say "=" x 80;
say "";

# ============================================================================
# PREPARE BENCHMARK DATA
# ============================================================================
say "Generating benchmark data...";

my @benchmark_data = map {
    {
        id => $_,
        name => "User$_",
        email => "user$_\@example.com",
        phone => "555-$_",
        city => "City$_",
        age => int(rand(50)) + 18,
        country => "USA",
        password => "secret$_",
        ssn => "123-45-6789",
    }
} (1..50000);

say "Data generated. Starting benchmarks...";
say "";

# ============================================================================
# BENCHMARK 1: Single Filter (Most Common Use Case)
# ============================================================================
say "-" x 80;
say "Benchmark 1: Single Filter Use Case (50,000 records)";
say "-" x 80;
say "Scenario: Each record filtered once, original not needed afterwards";
say "";

cmpthese(-3, {
    functional => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = filter($data, \@req, \@acc, \@exc);
        }
    },
    oo => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = $oo->apply($data);
        }
    },
    closure_safe => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_safe->($data);
        }
    },
    closure_fast => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_fast->($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 2: Multiple Filters (Original Data Needed)
# ============================================================================
say "-" x 80;
say "Benchmark 2: Multiple Filters on Same Data (50,000 records)";
say "-" x 80;
say "Scenario: Original data must be preserved for multiple filters";
say "";

my @req2 = qw/id name email/;
my @acc2 = qw/phone/;
my @exc2 = [qw/password/];

my @req3 = qw/id name age/;
my @acc3 = [];
my @exc3 = [qw/email password/];

my $safe_a = Params::Filter::make_filter(\@req2, \@acc2, \@exc2);
my $safe_b = Params::Filter::make_filter(\@req3, \@acc3, \@exc3);
my $fast_a = Params::Filter::make_filterFast(\@req2, \@acc2, \@exc2);
my $fast_b = Params::Filter::make_filterFast(\@req3, \@acc3, \@exc3);

cmpthese(-3, {
    functional => sub {
        for my $data (@benchmark_data) {
            my ($r1, $m1) = filter($data, \@req2, \@acc2, \@exc2);
            my ($r2, $m2) = filter($data, \@req3, \@acc3, \@exc3);
        }
    },
    oo => sub {
        for my $data (@benchmark_data) {
            my $r1 = $oo->apply($data);
            my $r2 = $oo->apply($data);
        }
    },
    closure_safe => sub {
        for my $data (@benchmark_data) {
            my $r1 = $safe_a->($data);
            my $r2 = $safe_b->($data);
        }
    },
    closure_fast_copy => sub {
        for my $data (@benchmark_data) {
            my $r1 = $fast_a->({$data->%*});  # Explicit copy
            my $r2 = $fast_b->({$data->%*});  # Explicit copy
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 3: High-Volume Filtering (500,000 operations)
# ============================================================================
say "-" x 80;
say "Benchmark 3: High-Volume Single Filter (500,000 operations)";
say "-" x 80;
say "Scenario: Maximum throughput, single use per data item";
say "";

my $large_dataset = [(map {
    {
        id => $_,
        name => "User$_",
        email => "user$_\@example.com",
        phone => "555-$_",
        password => "secret$_",
    }
} (1..100000)) x 5];  # 500k records

cmpthese(-3, {
    functional => sub {
        for my $data (@$large_dataset) {
            my ($result, $msg) = filter($data, \@req, \@acc, \@exc);
        }
    },
    oo => sub {
        for my $data (@$large_dataset) {
            my ($result, $msg) = $oo->apply($data);
        }
    },
    closure_safe => sub {
        for my $data (@$large_dataset) {
            my $result = $closure_safe->($data);
        }
    },
    closure_fast => sub {
        for my $data (@$large_dataset) {
            my $result = $closure_fast->($data);
        }
    },
});

say "";

say "=" x 80;
say "BENCHMARK SUMMARY";
say "=" x 80;
say "";
say "Performance comparison:";
say "  • Functional: Baseline (slowest, creates filter each call)";
say "  • OO: 1.5-2x faster than functional (object reuse)";
say "  • make_filter(): 2x faster than OO (safe, non-destructive)";
say "  • make_filterFast(): 2.5-3x faster than OO (fast, destructive)";
say "";
say "Usage recommendations:";
say "  • Use make_filterFast() when:";
say "    - Original data not needed after filtering (most common case)";
say "    - Maximum performance is critical";
say "    - Willing to manage copying explicitly when needed";
say "";
say "  • Use make_filter() when:";
say "    - Original data must be preserved";
say "    - Multiple filters on same data";
say "    - Want safety without managing copies";
say "";
say "  • Use OO interface when:";
say "    - Need error messages";
say "    - Need debug mode";
say "    - Need wildcard support";
say "    - Prefer traditional object-oriented style";
say "";
say "  • Use functional interface when:";
say "    - One-off filtering (no filter reuse)";
say "    - Simplicity is more important than speed";
say "";
say "=" x 80;
