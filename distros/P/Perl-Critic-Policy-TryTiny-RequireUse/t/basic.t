#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Perl::Critic;

my @tests = (
    [NoUseCall               => 0],
    [NoUseNoCall             => 1],
    [UseCall                 => 1],
    [UseCallSeparatePackages => 0],
    [UseNoCall               => 1],
);

foreach my $test (@tests) {
    my ($package, $expected_ok) = @$test;

    my $file = "t/$package.pm";
    my $critic = Perl::Critic->new(
        '-single-policy' => 'TryTiny::RequireUse',
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
