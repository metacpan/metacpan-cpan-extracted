#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);
use Params::Filter qw/filter/;

say "=" x 70;
say "Micro-Benchmark: Comparing Optimization Impact";
say "=" x 70;
say "";

# Test data - typical use case
my @test_data = map {
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
} (1..50000);

my @required = qw/id name email/;
my @accepted = qw/phone city/;
my @excluded = qw/extra1 extra2 extra3/;

say "Test: 50,000 hashref operations";
say "  Required: id, name, email (3 fields)";
say "  Accepted: phone, city (2 fields)";
say "  Excluded: extra1, extra2, extra3 (3 fields)";
say "  Total input: 8 fields";
say "";

# Test 1: Functional interface
cmpthese(-3, {
    functional => sub {
        for my $data (@test_data) {
            my ($filtered, $msg) = filter($data, \@required, \@accepted, \@excluded);
        }
    },
});

say "";

# Test 2: OO interface (should use cached hashes)
cmpthese(-3, {
    oo_interface => sub {
        my $filter = Params::Filter->new_filter({
            required => \@required,
            accepted => \@accepted,
            excluded => \@excluded,
        });
        for my $data (@test_data) {
            my ($filtered, $msg) = $filter->apply($data);
        }
    },
});

say "";

# Test 3: Compare side-by-side
cmpthese(-3, {
    functional => sub {
        for my $data (@test_data) {
            my ($filtered, $msg) = filter($data, \@required, \@accepted, \@excluded);
        }
    },
    oo_cached => sub {
        my $filter = Params::Filter->new_filter({
            required => \@required,
            accepted => \@accepted,
            excluded => \@excluded,
        });
        for my $data (@test_data) {
            my ($filtered, $msg) = $filter->apply($data);
        }
    },
});

say "";
say "=" x 70;
say "Note: OO interface should be faster due to cached hash lookups";
say "=" x 70;
