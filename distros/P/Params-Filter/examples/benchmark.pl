#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(cmpthese timethis);
use Params::Filter qw/filter/;

# Benchmark: Params::Filter Performance Comparison
# Tests both internal performance (OO vs functional) and external benefits
# (with filter vs without filter)

say "=" x 70;
say "Params::Filter Benchmark Suite";
say "=" x 70;
say "";

# ============================================================================
# BENCHMARK 1: OO Interface vs Functional Interface (Scenario 3)
# Purpose: Validate framework, compare internal performance
# ============================================================================
say "-" x 70;
say "Benchmark 1: OO vs Functional Interface (10,000 records)";
say "-" x 70;

# Prepare test data
my @records = map {
    {
        id          => $_,
        name        => "User_$_",
        email       => 'user' . $_ . '@example.com',
        phone       => "555-$_",
        city        => "City_$_",
        state       => "ST",
        zip         => "12345",
        extra1      => "data1",
        extra2      => "data2",
        extra3      => "data3",
    }
} (1..10000);

my $filter_rules = {
    required => ['id', 'name', 'email'],
    accepted => ['phone', 'city', 'state', 'zip'],
    excluded => ['extra1', 'extra2', 'extra3'],
};

say "Processing 10,000 records with 9 fields (6 kept, 3 excluded)...";
say "";

cmpthese(-5, {
    'functional' => sub {
        for my $record (@records) {
            my ($filtered, $msg) = filter(
                $record,
                $filter_rules->{required},
                $filter_rules->{accepted},
                $filter_rules->{excluded},
            );
        }
    },
    'oo_interface' => sub {
        my $filter = Params::Filter->new_filter($filter_rules);
        for my $record (@records) {
            my ($filtered, $msg) = $filter->apply($record);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 2: Conditional Gatekeeper (Scenario 2)
# Purpose: Compare filter as conditional vs manual existence checks
# ============================================================================
say "-" x 70;
say "Benchmark 2: Conditional Gatekeeper (100,000 iterations)";
say "-" x 70;

# Test data with varying completeness
my @test_cases = (
    { name => 'Alice', email => 'alice@example.com', age => 30 },
    { name => 'Bob', email => 'bob@example.com' },
    { name => 'Charlie' },  # Missing required email
    { name => 'Diana', email => 'diana@example.com', city => 'NYC' },
);

my @required_fields = qw/name email/;

say "Checking if records have required fields (name, email)...";
say "";

cmpthese(-5, {
    'manual_checks' => sub {
        for (1..100000) {
            my $data = $test_cases[$_ % @test_cases];
            # Manual existence checks
            my $has_required = 1;
            for my $field (@required_fields) {
                $has_required &&= exists $data->{$field};
            }
            if ($has_required) {
                # Would process data here
                my $name = $data->{name};
                my $email = $data->{email};
            }
        }
    },
    'with_filter' => sub {
        my $filter = Params::Filter->new_filter({
            required => \@required_fields,
            accepted => [],
        });
        for (1..100000) {
            my $data = $test_cases[$_ % @test_cases];
            my ($filtered, $msg) = $filter->apply($data);
            if ($filtered) {
                # Would process data here
                my $name = $filtered->{name};
                my $email = $filtered->{email};
            }
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 3: Field Extraction - Filter vs Manual Hash Slice
# Purpose: Compare extracting subset of fields from larger hash
# ============================================================================
say "-" x 70;
say "Benchmark 3: Field Extraction (50,000 records)";
say "-" x 70;

# Records with many fields
my @large_records = map {
    {
        id         => $_,
        username   => "user$_",
        email      => 'user' . $_ . '@example.com',
        field1     => "data1_$_",
        field2     => "data2_$_",
        field3     => "data3_$_",
        field4     => "data4_$_",
        field5     => "data5_$_",
        field6     => "data6_$_",
        field7     => "data7_$_",
        field8     => "data8_$_",
        field9     => "data9_$_",
        field10    => "data10_$_",
    }
} (1..50000);

my @needed_fields = qw/id username email/;

say "Extracting 3 fields from records with 13 fields...";
say "";

cmpthese(-5, {
    'manual_slice' => sub {
        for my $record (@large_records) {
            my $extracted = {
                map { $_ => $record->{$_} } @needed_fields
            };
        }
    },
    'with_filter' => sub {
        my $filter = Params::Filter->new_filter({
            required => \@needed_fields,
            accepted => [],
        });
        for my $record (@large_records) {
            my ($filtered, $msg) = $filter->apply($record);
        }
    },
});

say "";

# ============================================================================
# BENCHMARK 4: Input Reduction Before Expensive Operation
# Purpose: Show benefit of filtering early before complex validation
# ============================================================================
say "-" x 70;
say "Benchmark 4: Early Reduction Before Expensive Validation (10,000 records)";
say "-" x 70;

# Simulated expensive validation function
sub expensive_validation {
    my ($data) = @_;
    # Simulate expensive type checking, DB lookups, etc.
    my $result = 1;
    for my $key (keys %$data) {
        $result += length($data->{$key});
    }
    return $result > 0;
}

my @api_requests = map {
    {
        user_id     => $_,
        username    => "user$_",
        email       => 'user' . $_ . '@example.com',
        password    => "secret$_",      # Sensitive, should be excluded
        ssn         => "123-$_",        # Sensitive, should be excluded
        bio         => "Bio $_",
        metadata    => "metadata_$_",   # Not needed
        timestamp   => time,
        extra       => "extra_$_",
    }
} (1..10000);

say "Processing API requests with 9 fields, need to validate 3...";
say "";

cmpthese(-5, {
    'validate_all' => sub {
        for my $req (@api_requests) {
            # Validate ALL fields before processing
            if (expensive_validation($req)) {
                # Then extract what we need
                my $user_id = $req->{user_id};
                my $username = $req->{username};
                my $email = $req->{email};
            }
        }
    },
    'filter_first' => sub {
        my $filter = Params::Filter->new_filter({
            required => ['user_id'],
            accepted => ['username', 'email'],
            excluded => ['password', 'ssn'],
        });
        for my $req (@api_requests) {
            # Filter first, then validate only what's needed
            my ($filtered, $msg) = $filter->apply($req);
            if ($filtered && expensive_validation($filtered)) {
                # Process filtered data
                my $user_id = $filtered->{user_id};
                my $username = $filtered->{username};
                my $email = $filtered->{email};
            }
        }
    },
});

say "";
say "=" x 70;
say "Benchmark Complete";
say "=" x 70;
say "";
say "Interpretation:";
say "  - Rate: operations per second (higher is better)";
say "  - Comparisons show relative performance between approaches";
say "  - Negative % indicates how much slower than baseline";
say "";
