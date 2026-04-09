#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use Test::More;
use Benchmark qw(:all);
use Params::Filter qw/filter/;

# Benchmark Tests for Params::Filter
# These tests measure performance characteristics
# Run with: prove -vb t/benchmark.t

eval "use Benchmark 0; 1;";
plan skip_all => "Benchmark.pm required for performance testing" if $@;

say "\n" . "=" x 70;
say "Params::Filter Performance Benchmarks";
say "=" x 70 . "\n";

# ========================================================================
# TEST 1: OO vs Functional Interface (Scenario 3)
# ========================================================================
subtest "OO vs Functional Interface" => sub {
    my @records = map {
        {
            id     => $_,
            name   => "User_$_",
            email  => 'user' . $_ . '@example.com',
            phone  => "555-$_",
            city   => "City_$_",
            extra1 => "data1",
            extra2 => "data2",
            extra3 => "data3",
        }
    } (1..5000);

    my $filter_rules = {
        required => ['id', 'name', 'email'],
        accepted => ['phone', 'city'],
        excluded => ['extra1', 'extra2', 'extra3'],
    };

    say "\nBenchmark 1: OO vs Functional (5,000 records)";

    my $results = cmpthese(-2, {
        functional => sub {
            for my $record (@records) {
                my ($filtered, $msg) = filter(
                    $record,
                    $filter_rules->{required},
                    $filter_rules->{accepted},
                    $filter_rules->{excluded},
                );
            }
        },
        oo_interface => sub {
            my $filter = Params::Filter->new_filter($filter_rules);
            for my $record (@records) {
                my ($filtered, $msg) = $filter->apply($record);
            }
        },
    }, 'none');

    ok(1, "Benchmark 1 completed");
};

# ========================================================================
# TEST 2: Manual vs Filter for Conditional Checks
# ========================================================================
subtest "Manual vs Filter for Conditional Checks" => sub {
    my @test_cases = (
        { name => 'Alice', email => 'alice@example.com', age => 30 },
        { name => 'Bob', email => 'bob@example.com' },
        { name => 'Charlie' },
        { name => 'Diana', email => 'diana@example.com', city => 'NYC' },
    );

    my @required_fields = qw/name email/;

    say "\nBenchmark 2: Conditional Gatekeeper (50,000 iterations)";

    cmpthese(-2, {
        manual_checks => sub {
            for (1..50000) {
                my $data = $test_cases[$_ % @test_cases];
                my $has_required = 1;
                for my $field (@required_fields) {
                    $has_required &&= exists $data->{$field};
                }
                if ($has_required) {
                    my $name = $data->{name};
                    my $email = $data->{email};
                }
            }
        },
        with_filter => sub {
            my $filter = Params::Filter->new_filter({
                required => \@required_fields,
                accepted => [],
            });
            for (1..50000) {
                my $data = $test_cases[$_ % @test_cases];
                my ($filtered, $msg) = $filter->apply($data);
                if ($filtered) {
                    my $name = $filtered->{name};
                    my $email = $filtered->{email};
                }
            }
        },
    }, 'none');

    ok(1, "Benchmark 2 completed");
};

# ========================================================================
# TEST 3: Field Extraction - Filter vs Manual Hash Slice
# ========================================================================
subtest "Field Extraction Performance" => sub {
    my @large_records = map {
        {
            id        => $_,
            username  => "user$_",
            email     => 'user' . $_ . '@example.com',
            field1    => "data1_$_",
            field2    => "data2_$_",
            field3    => "data3_$_",
            field4    => "data4_$_",
            field5    => "data5_$_",
            field6    => "data6_$_",
            field7    => "data7_$_",
            field8    => "data8_$_",
            field9    => "data9_$_",
            field10   => "data10_$_",
        }
    } (1..20000);

    my @needed_fields = qw/id username email/;

    say "\nBenchmark 3: Field Extraction (20,000 records)";

    cmpthese(-2, {
        manual_slice => sub {
            for my $record (@large_records) {
                my $extracted = {
                    map { $_ => $record->{$_} } @needed_fields
                };
            }
        },
        with_filter => sub {
            my $filter = Params::Filter->new_filter({
                required => \@needed_fields,
                accepted => [],
            });
            for my $record (@large_records) {
                my ($filtered, $msg) = $filter->apply($record);
            }
        },
    }, 'none');

    ok(1, "Benchmark 3 completed");
};

# ========================================================================
# TEST 4: Filter Reuse Benefit (OO Interface)
# ========================================================================
subtest "Filter Reuse Benefit" => sub {
    my @records = map {
        {
            id     => $_,
            name   => "User_$_",
            email  => 'user' . $_ . '@example.com',
            extra1 => "data1",
            extra2 => "data2",
        }
    } (1..10000);

    say "\nBenchmark 4: Filter Reuse vs Recreation (10,000 records)";

    cmpthese(-2, {
        recreate_filter => sub {
            for my $record (@records) {
                my $filter = Params::Filter->new_filter({
                    required => ['id', 'name'],
                    accepted => ['email'],
                    excluded => ['extra1', 'extra2'],
                });
                my ($filtered, $msg) = $filter->apply($record);
            }
        },
        reuse_filter => sub {
            my $filter = Params::Filter->new_filter({
                required => ['id', 'name'],
                accepted => ['email'],
                excluded => ['extra1', 'extra2'],
            });
            for my $record (@records) {
                my ($filtered, $msg) = $filter->apply($record);
            }
        },
    }, 'none');

    ok(1, "Benchmark 4 completed");
};

say "\n" . "=" x 70;
say "All benchmarks completed";
say "=" x 70 . "\n";

done_testing();
