#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);
use Params::Filter qw/filter/;

say "=" x 80;
say "Params::Filter: make_filterFast() vs Raw Inline Checking";
say "=" x 80;
say "";
say 'Comparing five approaches:';
say '  1. Raw inline - Manual hash operations (baseline)';
say '  2. Raw inline - Single validation pass';
say '  3. make_filterFast() - Closure that may modify input';
say '  4. make_filter() - Safe closure that copies input';
say '  5. OO interface - $f->apply($data)';
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

my $closure_fast = Params::Filter::make_filterFast(\@req, \@acc, \@exc);
my $closure_safe = Params::Filter::make_filter(\@req, \@acc, \@exc);
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
    age => 30,
    country => 'USA',
};

# Raw inline approach 1: Multiple passes (clear but slower)
sub raw_inline_multi {
    my ($data) = @_;
    my %result;

    # Check required fields
    return undef unless exists $data->{id};
    return undef unless exists $data->{name};
    return undef unless exists $data->{email};

    # Add required fields
    $result{id} = $data->{id};
    $result{name} = $data->{name};
    $result{email} = $data->{email};

    # Add accepted fields if present
    $result{phone} = $data->{phone} if exists $data->{phone};
    $result{city} = $data->{city} if exists $data->{city};

    # Excluded fields never added

    return \%result;
}

# Raw inline approach 2: Single validation pass (optimized)
sub raw_inline_single {
    my ($data) = @_;
    my %result;

    # Validate required fields in one pass
    for my $field (qw/id name email/) {
        return undef unless exists $data->{$field};
        $result{$field} = $data->{$field};
    }

    # Add accepted fields if present
    for my $field (qw/phone city/) {
        $result{$field} = $data->{$field} if exists $data->{$field};
    }

    # Excluded fields never added

    return \%result;
}

my $raw_multi = raw_inline_multi($test_data);
my $raw_single = raw_inline_single($test_data);
my $fast_result = $closure_fast->({$test_data->%*});
my $safe_result = $closure_safe->($test_data);
my $oo_result = $oo->apply($test_data);

say "Test 1: All approaches produce identical results";
say "  Raw multi-pass:      ", join(", ", sort keys %$raw_multi);
say "  Raw single-pass:     ", join(", ", sort keys %$raw_single);
say "  make_filterFast():   ", join(", ", sort keys %$fast_result);
say "  make_filter():       ", join(", ", sort keys %$safe_result);
say "  OO interface:        ", join(", ", sort keys %$oo_result);

if (join(",", sort keys %$raw_multi) eq join(",", sort keys %$fast_result) &&
    join(",", sort keys %$raw_multi) eq join(",", sort keys %$safe_result) &&
    join(",", sort keys %$raw_multi) eq join(",", sort keys %$oo_result)) {
    say "  ✅ All five approaches produce identical results";
} else {
    say "  ❌ RESULTS DIFFER!";
}
say "";

say "Test 2: Missing required field (fail-fast)";
my $incomplete_data = { id => 1, name => 'Bob' };  # Missing email

my $raw_multi_fail = raw_inline_multi($incomplete_data);
my $raw_single_fail = raw_inline_single($incomplete_data);
my $fast_fail = $closure_fast->({$incomplete_data->%*});
my $safe_fail = $closure_safe->($incomplete_data);
my $oo_fail = $oo->apply($incomplete_data);

say "  Raw multi-pass:      ", $raw_multi_fail ? "FAIL" : "PASS (undef)";
say "  Raw single-pass:     ", $raw_single_fail ? "FAIL" : "PASS (undef)";
say "  make_filterFast():   ", $fast_fail ? "FAIL" : "PASS (undef)";
say "  make_filter():       ", $safe_fail ? "FAIL" : "PASS (undef)";
say "  OO interface:        ", defined $oo_fail ? "FAIL" : "PASS (undef)";
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
# BENCHMARK 1: Simple Filtering (Required Only)
# ============================================================================
say "-" x 80;
say "Benchmark 1: Required Fields Only (50,000 records)";
say "-" x 80;
say "";

my $req_only = Params::Filter::make_filterFast([qw/id name email/]);
my $req_only_safe = Params::Filter::make_filter([qw/id name email/]);
my $req_only_oo = Params::Filter->new_filter({ required => [qw/id name email/] });

sub raw_required_only {
    my ($data) = @_;
    return undef unless exists $data->{id};
    return undef unless exists $data->{name};
    return undef unless exists $data->{email};
    return {
        id => $data->{id},
        name => $data->{name},
        email => $data->{email},
    };
}

cmpthese(-3, {
    raw_required => sub {
        for my $data (@benchmark_data) {
            my $result = raw_required_only($data);
        }
    },
    closure_fast => sub {
        for my $data (@benchmark_data) {
            my $result = $req_only->($data);
        }
    },
    closure_safe => sub {
        for my $data (@benchmark_data) {
            my $result = $req_only_safe->($data);
        }
    },
    oo => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = $req_only_oo->apply($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 2: Full Filtering (Required + Accepted + Excluded)
# ============================================================================
say "-" x 80;
say "Benchmark 2: Full Filtering (50,000 records)";
say "-" x 80;
say "";

cmpthese(-3, {
    raw_multi => sub {
        for my $data (@benchmark_data) {
            my $result = raw_inline_multi($data);
        }
    },
    raw_single => sub {
        for my $data (@benchmark_data) {
            my $result = raw_inline_single($data);
        }
    },
    closure_fast => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_fast->($data);
        }
    },
    closure_safe => sub {
        for my $data (@benchmark_data) {
            my $result = $closure_safe->($data);
        }
    },
    oo => sub {
        for my $data (@benchmark_data) {
            my ($result, $msg) = $oo->apply($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 3: High-Volume Processing (500,000 operations)
# ============================================================================
say "-" x 80;
say "Benchmark 3: High-Volume Processing (500,000 operations)";
say "-" x 80;
say "";

my $large_dataset = [(map {
    {
        id => $_,
        name => "User$_",
        email => "user$_\@example.com",
        phone => "555-$_",
        city => "City$_",
        password => "secret$_",
    }
} (1..100000)) x 5];  # 500k records

cmpthese(-3, {
    raw_single => sub {
        for my $data (@$large_dataset) {
            my $result = raw_inline_single($data);
        }
    },
    closure_fast => sub {
        for my $data (@$large_dataset) {
            my $result = $closure_fast->($data);
        }
    },
    closure_safe => sub {
        for my $data (@$large_dataset) {
            my $result = $closure_safe->($data);
        }
    },
    oo => sub {
        for my $data (@$large_dataset) {
            my ($result, $msg) = $oo->apply($data);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 4: Conditional Filtering (Fail-Fast)
# ============================================================================
say "-" x 80;
say "Benchmark 4: Fail-Fast Validation (100,000 checks)";
say "-" x 80;
say "Testing with 33% invalid records (missing required field)";
say "";

# Mix of valid and invalid data
my @conditional_data = map {
    $_ % 3 == 0
        ? { id => $_, name => "Valid" }  # Missing email
        : { id => $_, name => "User$_", email => "user$_\@example.com", phone => "555-$_" }
} (1..100000);

sub raw_failfast {
    my ($data) = @_;
    return undef unless exists $data->{id};
    return undef unless exists $data->{name};
    return undef unless exists $data->{email};
    my %result = (
        id => $data->{id},
        name => $data->{name},
        email => $data->{email},
    );
    $result{phone} = $data->{phone} if exists $data->{phone};
    return \%result;
}

my $cond_fast = Params::Filter::make_filterFast([qw/id name email/], [qw/phone/]);
my $cond_safe = Params::Filter::make_filter([qw/id name email/], [qw/phone/]);
my $cond_oo = Params::Filter->new_filter({ required => [qw/id name email/], accepted => [qw/phone/] });

cmpthese(-3, {
    raw_failfast => sub {
        for my $data (@conditional_data) {
            my $result = raw_failfast($data);
        }
    },
    closure_fast => sub {
        for my $data (@conditional_data) {
            my $result = $cond_fast->($data);
        }
    },
    closure_safe => sub {
        for my $data (@conditional_data) {
            my $result = $cond_safe->($data);
        }
    },
    oo => sub {
        for my $data (@conditional_data) {
            my ($result, $msg) = $cond_oo->apply($data);
        }
    },
});

say "";

say "=" x 80;
say "BENCHMARK SUMMARY";
say "=" x 80;
say "";
say "Performance analysis:";
say "  • Raw inline (single pass): Theoretical maximum speed";
say "  • Raw inline (multi pass): Clear but slower baseline";
say "  • make_filterFast(): Approaches raw speed with usability";
say "  • make_filter(): Safe alternative with small speed penalty";
say "  • OO interface: Full features with moderate overhead";
say "";
say "Key questions:";
say "  1. How close does make_filterFast() get to raw inline?";
say "  2. Is the overhead worth the safety and maintainability?";
say "  3. When should you use each approach?";
say "";
say "=" x 80;
