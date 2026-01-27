#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);
use Params::Filter qw/filter/;

say "=" x 80;
say "Params::Filter: make_filter() Benchmark";
say "=" x 80;
say "";
say 'Comparing three approaches:';
say '  1. Functional interface: filter($data, @req, @acc, @exc)';
say '  2. OO interface: $f->apply($data)';
say '  3. Closure interface: make_filter(@req, @acc, @exc)->($data)';
say "";

# ============================================================================
# CORRECTNESS TESTS
# ============================================================================
say "-" x 80;
say "CORRECTNESS TESTS";
say "-" x 80;
say "";

# Test 1: Basic required fields
my @req1 = qw/name email/;
my @acc1 = qw/phone/;
my @exc1 = qw/password/;

my $closure1 = Params::Filter::make_filter(\@req1, \@acc1, \@exc1);
my $oo1 = Params::Filter->new_filter({
    required => \@req1,
    accepted => \@acc1,
    excluded => \@exc1,
});

my $test_data1 = {
    name => 'Alice',
    email => 'alice@example.com',
    phone => '555-1234',
    password => 'secret',
};

my ($func_result1, $func_msg1) = filter($test_data1, \@req1, \@acc1, \@exc1);
my $oo_result1 = $oo1->apply($test_data1);
my $closure_result1 = $closure1->($test_data1);

say "Test 1: Required + Accepted + Excluded";
say "  Input: ", join(", ", keys %$test_data1);
say "  Functional: ", join(", ", sort keys %$func_result1) // "undef";
say "  OO:        ", join(", ", sort keys %$oo_result1) // "undef";
say "  Closure:   ", join(", ", sort keys %$closure_result1) // "undef";

# Verify they match
if (join(",", sort keys %$func_result1) eq join(",", sort keys %$oo_result1) &&
    join(",", sort keys %$func_result1) eq join(",", sort keys %$closure_result1)) {
    say "  ✅ All three approaches produce identical results";
} else {
    say "  ❌ RESULTS DIFFER!";
}
say "";

# Test 2: Missing required field
my $test_data2 = {
    name => 'Bob',
    # email missing!
};

my ($func_result2, $func_msg2) = filter($test_data2, \@req1, \@acc1, \@exc1);
my $oo_result2 = $oo1->apply($test_data2);
my $closure_result2 = $closure1->($test_data2);

say "Test 2: Missing Required Field";
say "  Input: ", join(", ", keys %$test_data2);
say "  Functional: ", $func_result2 ? "FAIL" : "PASS (undef)";
say "  OO:        ", $oo_result2 ? "FAIL" : "PASS (undef)";
say "  Closure:   ", $closure_result2 ? "FAIL" : "PASS (undef)";
say "";

# Test 3: Multiple filters on same data
say "Test 3: Multiple Filters on Same Data";
my $test_data3 = {
    name => 'Charlie',
    email => 'charlie@example.com',
    phone => '555-5678',
    age => 30,
    password => 'secret',
};

my @req3a = qw/name email/;
my @acc3a = qw/phone/;
my @exc3a = [qw/password/];

my @req3b = qw/name age/;
my @acc3b = [];
my @exc3b = [qw/email password/];

my $closure3a = Params::Filter::make_filter(\@req3a, \@acc3a, \@exc3a);
my $closure3b = Params::Filter::make_filter(\@req3b, \@acc3b, \@exc3b);

my $result3a = $closure3a->($test_data3);
my $result3b = $closure3b->($test_data3);

say "  Original data: ", join(", ", sort keys %$test_data3);
say "  Filter A result: ", join(", ", sort keys %$result3a);
say "  Filter B result: ", join(", ", sort keys %$result3b);
say "  Original intact? ", join(", ", sort keys %$test_data3);
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

my @required = qw/id name email/;
my @accepted = qw/phone city age/;
my @excluded = qw/password ssn/;

say "Data generated. Starting benchmarks...";
say "";

# ============================================================================
# BENCHMARK 1: Simple Filtering (Required Only)
# ============================================================================
say "-" x 80;
say "Benchmark 1: Required Fields Only (50,000 records)";
say "-" x 80;
say "";

my $closure_simple = Params::Filter::make_filter([qw/id name email/]);
my $oo_simple = Params::Filter->new_filter({ required => [qw/id name email/] });

cmpthese(-3, {
    functional_simple => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = filter($data, [qw/id name email/]);
        }
    },
    oo_simple => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = $oo_simple->apply($data);
        }
    },
    closure_simple => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_simple->($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 2: Required + Accepted + Excluded
# ============================================================================
say "-" x 80;
say "Benchmark 2: Required + Accepted + Excluded (50,000 records)";
say "-" x 80;
say "";

my $closure_full = Params::Filter::make_filter(\@required, \@accepted, \@excluded);
my $oo_full = Params::Filter->new_filter({
    required => \@required,
    accepted => \@accepted,
    excluded => \@excluded,
});

cmpthese(-3, {
    functional_full => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = filter($data, \@required, \@accepted, \@excluded);
        }
    },
    oo_full => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = $oo_full->apply($data);
        }
    },
    closure_full => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_full->($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 3: Filter Reuse (Create Once, Use Many Times)
# ============================================================================
say "-" x 80;
say "Benchmark 3: Filter Reuse (500,000 operations)";
say "-" x 80;
say "Note: Filter objects created once, then reused";
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
    functional_reuse => sub {
        for my $data (@$large_dataset) {
            my ($result, $msg) = filter($data, \@required, \@accepted, \@excluded);
        }
    },
    oo_reuse => sub {
        for my $data (@$large_dataset) {
            my ($result, $msg) = $oo_full->apply($data);
        }
    },
    closure_reuse => sub {
        for my $data (@$large_dataset) {
            my $result = $closure_full->($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 4: Conditional Filtering (Fail-Fast Behavior)
# ============================================================================
say "-" x 80;
say "Benchmark 4: Conditional Filtering (100,000 checks)";
say "-" x 80;
say "Testing if required fields are present (fail-fast scenario)";
say "";

# Mix of valid and invalid data
my @conditional_data = map {
    $_ % 3 == 0
        ? { id => $_, name => "Valid" }  # Missing email
        : { id => $_, name => "User$_", email => "user$_\@example.com" }
} (1..100000);

my $closure_cond = Params::Filter::make_filter([qw/id name email/]);

cmpthese(-3, {
    functional_cond => sub {
        for my $data (@conditional_data) {
            my ($result, $msg) = filter($data, [qw/id name email/]);
        }
    },
    oo_cond => sub {
        for my $data (@conditional_data) {
            my ($result, $msg) = $oo_simple->apply($data);
        }
    },
    closure_cond => sub {
        for my $data (@conditional_data) {
            my $result = $closure_cond->($data);
        }
    },
});

say "";

say "=" x 80;
say "BENCHMARK SUMMARY";
say "=" x 80;
say "";
say "Key insights:";
say "  1. make_filter() closures should be fastest (no object overhead)";
say "  2. OO interface has method call overhead";
say "  3. Functional interface creates new filter each call (slowest)";
say "  4. Filter reuse is where closures and OO shine";
say "";
say "Trade-offs:";
say "  • make_filter: Fast but destructive (modifies input), no error messages";
say "  • OO: Moderate speed, non-destructive, with error messages";
say "  • Functional: Slowest, non-destructive, with error messages";
say "";
say "=" x 80;
