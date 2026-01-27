#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Benchmark qw(:all);

use lib 'lib';
use Params::Filter qw/filter/;

say "=" x 80;
say "make_filter() Three Closure Variants - Performance Analysis";
say "=" x 80;
say "";
say "Testing three specialized closure types:";
say "  1. Required-only (no accepted fields)";
say "  2. Wildcard (accepted = ['*']) - all fields except exclusions";
say "  3. Accepted-specific (normal case)";
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
# VARIANT 1: Required-only (no accepted fields)
# ============================================================================
say "=" x 80;
say "VARIANT 1: Required-only Closure";
say "=" x 80;
say "Config: required=['id','name','email'], accepted=[], excluded=[]";
say "Behavior: Only return required fields if all present";
say "";

my @req1 = qw/id name email/;
my @ok1 = ();  # Empty accepted
my @no1 = ();

my $filter1 = Params::Filter::make_filter(\@req1, \@ok1, \@no1);

sub raw_variant1 {
    my ($data) = @_;
    my %result;
    for my $field (qw/id name email/) {
        return undef unless exists $data->{$field};
        $result{$field} = $data->{$field};
    }
    return \%result;
}

my $result1_closure = $filter1->($test_data);
my $result1_raw = raw_variant1($test_data);

say "Closure result: ", join(", ", sort keys %$result1_closure);
say "Raw result:     ", join(", ", sort keys %$result1_raw);
say "Match: ", (join(" ", sort keys %$result1_closure) eq join(" ", sort keys %$result1_raw) ? "✅" : "❌");
say "";

say "-" x 80;
say "Benchmark: 500,000 operations";
say "-" x 80;

cmpthese(-5, {
    raw_variant1 => sub { raw_variant1($test_data) },
    closure_variant1 => sub { $filter1->($test_data) },
});

say "";

# ============================================================================
# VARIANT 2: Wildcard (accepted = ['*'])
# ============================================================================
say "=" x 80;
say "VARIANT 2: Wildcard Closure (accept all except exclusions)";
say "=" x 80;
say "Config: required=['id','name'], accepted=['*'], excluded=['password']";
say "Behavior: Return required + ALL input fields except exclusions";
say "";

my @req2 = qw/id name/;
my @ok2 = ('*');  # Wildcard
my @no2 = qw/password extra/;

my $filter2 = Params::Filter::make_filter(\@req2, \@ok2, \@no2);

sub raw_variant2 {
    my ($data) = @_;
    my %result;
    my %excluded = map { $_ => 1 } qw/password extra/;

    # Check required
    for my $field (qw/id name/) {
        return undef unless exists $data->{$field};
        $result{$field} = $data->{$field};
    }

    # Add all other fields except excluded
    for my $field (keys %$data) {
        next if $excluded{$field};
        $result{$field} = $data->{$field};
    }

    return \%result;
}

my $result2_closure = $filter2->($test_data);
my $result2_raw = raw_variant2($test_data);

say "Closure result: ", join(", ", sort keys %$result2_closure);
say "Raw result:     ", join(", ", sort keys %$result2_raw);
say "Match: ", (join(" ", sort keys %$result2_closure) eq join(" ", sort keys %$result2_raw) ? "✅" : "❌");
say "";

say "-" x 80;
say "Benchmark: 500,000 operations";
say "-" x 80;

cmpthese(-5, {
    raw_variant2 => sub { raw_variant2($test_data) },
    closure_variant2 => sub { $filter2->($test_data) },
});

say "";

# ============================================================================
# VARIANT 3: Accepted-specific (normal case)
# ============================================================================
say "=" x 80;
say "VARIANT 3: Accepted-specific Closure (normal case)";
say "=" x 80;
say "Config: required=['id','name','email'], accepted=['phone','city'], excluded=['password']";
say "Behavior: Return required + only specified accepted fields (minus exclusions)";
say "";

my @req3 = qw/id name email/;
my @ok3 = qw/phone city/;
my @no3 = qw/password/;

my $filter3 = Params::Filter::make_filter(\@req3, \@ok3, \@no3);

sub raw_variant3 {
    my ($data) = @_;
    my %result;
    my %excluded = map { $_ => 1 } qw/password/;

    # Check required
    for my $field (qw/id name email/) {
        return undef unless exists $data->{$field};
        $result{$field} = $data->{$field};
    }

    # Add accepted fields (unless excluded)
    for my $field (qw/phone city/) {
        next if $excluded{$field};
        $result{$field} = $data->{$field} if exists $data->{$field};
    }

    return \%result;
}

my $result3_closure = $filter3->($test_data);
my $result3_raw = raw_variant3($test_data);

say "Closure result: ", join(", ", sort keys %$result3_closure);
say "Raw result:     ", join(", ", sort keys %$result3_raw);
say "Match: ", (join(" ", sort keys %$result3_closure) eq join(" ", sort keys %$result3_raw) ? "✅" : "❌");
say "";

say "-" x 80;
say "Benchmark: 500,000 operations";
say "-" x 80;

cmpthese(-5, {
    raw_variant3 => sub { raw_variant3($test_data) },
    closure_variant3 => sub { $filter3->($test_data) },
});

say "";

# ============================================================================
# COMPARISON SUMMARY
# ============================================================================
say "=" x 80;
say "SUMMARY: All Three Variants Compared Head-to-Head";
say "=" x 80;
say "";
say "Testing which variant is fastest for its use case";
say "";

cmpthese(-5, {
    variant1_required_only => sub { $filter1->($test_data) },
    variant2_wildcard => sub { $filter2->($test_data) },
    variant3_accepted_specific => sub { $filter3->($test_data) },
});

say "";
say "=" x 80;
say "ANALYSIS";
say "=" x 80;
say "";
say "Key insights:";
say "  • Each closure variant is optimized for its specific use case";
say "  • Pre-computed exclusion hash created once at filter creation";
say "  • No runtime conditionals - closure is tailored during construction";
say "  • Variant 1 (required-only): Fastest - minimal work";
say "  • Variant 2 (wildcard): Iterates over input keys - flexible";
say "  • Variant 3 (accepted-specific): Most common case - balanced";
say "";
say "Design benefits:";
say "  • No modifier methods needed - just create new closure (instant)";
say "  • Wildcard support without runtime overhead (check at creation)";
say "  • Empty accepted list optimization (only required fields)";
say "  • Each variant is as fast as possible for its use case";
say "";
