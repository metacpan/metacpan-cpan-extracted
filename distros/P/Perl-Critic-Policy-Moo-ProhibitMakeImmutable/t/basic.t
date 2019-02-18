#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use Perl::Critic;

my @tests = (
    [MooImmutable   => 0],
    [MooMutable     => 1],
    [MooseImmutable => 1],
    [MooseMutable   => 1],
    [ComplexBad     => 0],
    [ComplexGood    => 1],
);

foreach my $test (@tests) {
    my ($package, $expected_ok) = @$test;

    my $file = "t/$package.pm";
    my $critic = Perl::Critic->new(
        '-single-policy' => 'Moo::ProhibitMakeImmutable',
    );
    my @violations = $critic->critique($file);

    if ($expected_ok) {
        ok(
            (@violations == 0),
            "$package should NOT violate",
        );
    }
    else {
        ok(
            (@violations > 0),
            "$package should violate",
        );
    }
}

done_testing;
