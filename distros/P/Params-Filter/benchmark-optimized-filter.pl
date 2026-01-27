#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);

use Params::Filter qw/filter make_filter/;

say "=" x 80;
say "Benchmark: Optimized filter() vs make_filter() Closure";
say "=" x 80;
say "";
say "Testing if optimized functional approach matches closure performance";
say "";

# Test data
my $test_data = {
    id => 123,
    name => 'Alice',
    email => 'alice@example.com',
    phone => '555-1234',
    city => 'NYC',
    password => 'secret',
    extra => 'ignored',
};

# ============================================================================
# Scenario 1: Required-only (no accepted fields)
# ============================================================================
say "=" x 80;
say "SCENARIO 1: Required-only (no accepted fields)";
say "=" x 80;
say "Config: required=['id','name','email'], accepted=[], excluded=[]";
say "";

my @req1 = qw/id name email/;
my @ok1 = ();
my @no1 = ();

my $closure1 = make_filter(\@req1, \@ok1, \@no1);

cmpthese(-5, {
    'filter() functional' => sub {
        my $result = filter($test_data, \@req1, \@ok1, \@no1);
    },
    'make_filter() closure' => sub {
        my $result = $closure1->($test_data);
    },
});

say "";

# ============================================================================
# Scenario 2: Wildcard (accept all except exclusions)
# ============================================================================
say "=" x 80;
say "SCENARIO 2: Wildcard (accept all except exclusions)";
say "=" x 80;
say "Config: required=['id','name'], accepted=['*'], excluded=['password']";
say "";

my @req2 = qw/id name/;
my @ok2 = ('*');
my @no2 = qw/password extra/;

my $closure2 = make_filter(\@req2, \@ok2, \@no2);

cmpthese(-5, {
    'filter() functional' => sub {
        my $result = filter($test_data, \@req2, \@ok2, \@no2);
    },
    'make_filter() closure' => sub {
        my $result = $closure2->($test_data);
    },
});

say "";

# ============================================================================
# Scenario 3: Accepted-specific (normal case)
# ============================================================================
say "=" x 80;
say "SCENARIO 3: Accepted-specific (normal case)";
say "=" x 80;
say "Config: required=['id','name','email'], accepted=['phone','city'], excluded=['password']";
say "";

my @req3 = qw/id name email/;
my @ok3 = qw/phone city/;
my @no3 = qw/password/;

my $closure3 = make_filter(\@req3, \@ok3, \@no3);

cmpthese(-5, {
    'filter() functional' => sub {
        my $result = filter($test_data, \@req3, \@ok3, \@no3);
    },
    'make_filter() closure' => sub {
        my $result = $closure3->($test_data);
    },
});

say "";

# ============================================================================
# Scenario 4: Multiple filters (simulating high-volume processing)
# ============================================================================
say "=" x 80;
say "SCENARIO 4: High-volume processing (100K operations)";
say "=" x 80;
say "Applying 3 different filters to same data";
say "";

cmpthese(-5, {
    'filter() functional' => sub {
        my $r1 = filter($test_data, \@req1, \@ok1, \@no1);
        my $r2 = filter($test_data, \@req2, \@ok2, \@no2);
        my $r3 = filter($test_data, \@req3, \@ok3, \@no3);
    },
    'make_filter() closure' => sub {
        my $r1 = $closure1->($test_data);
        my $r2 = $closure2->($test_data);
        my $r3 = $closure3->($test_data);
    },
});

say "";

# ============================================================================
# Correctness verification
# ============================================================================
say "=" x 80;
say "CORRECTNESS VERIFICATION";
say "=" x 80;
say "";

my $f1 = filter($test_data, \@req1, \@ok1, \@no1);
my $c1 = $closure1->($test_data);

say "Scenario 1 (required-only):";
say "  filter():    ", join(", ", sort keys %$f1);
say "  make_filter(): ", join(", ", sort keys %$c1);
say "  Match: ", (join(" ", sort keys %$f1) eq join(" ", sort keys %$c1) ? "✅" : "❌");
say "";

my $f2 = filter($test_data, \@req2, \@ok2, \@no2);
my $c2 = $closure2->($test_data);

say "Scenario 2 (wildcard):";
say "  filter():    ", join(", ", sort keys %$f2);
say "  make_filter(): ", join(", ", sort keys %$c2);
say "  Match: ", (join(" ", sort keys %$f2) eq join(" ", sort keys %$c2) ? "✅" : "❌");
say "";

my $f3 = filter($test_data, \@req3, \@ok3, \@no3);
my $c3 = $closure3->($test_data);

say "Scenario 3 (accepted-specific):";
say "  filter():    ", join(", ", sort keys %$f3);
say "  make_filter(): ", join(", ", sort keys %$c3);
say "  Match: ", (join(" ", sort keys %$f3) eq join(" ", sort keys %$c3) ? "✅" : "❌");
say "";

say "=" x 80;
say "ANALYSIS";
say "=" x 80;
say "";
say "Key insights:";
say "  • Both interfaces now use identical optimization techniques";
say "  • Pre-computed exclusion hash (O(1) lookups)";
say "  • Hash slice for required field copying";
say "  • Non-destructive operations";
say "  • Single wildcard check";
say "";
say "Performance differences expected:";
say "  • filter() has overhead for input parsing";
say "  • filter() builds error messages each call";
say "  • make_filter() closures are pre-compiled";
say "";
say "Use filter() when you need:";
say "  - Input format flexibility (hashref, arrayref, scalar)";
say "  - Detailed error messages";
say "  - One-time filtering operations";
say "";
say "Use make_filter() when you need:";
say "  - Maximum performance";
say "  - Reusable filters";
say "  - High-frequency filtering (hot code paths)";
say "";
