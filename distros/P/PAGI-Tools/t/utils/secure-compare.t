#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use PAGI::Utils::SecureCompare qw(secure_compare);

subtest 'constant-time comparison' => sub {
    # Basic equality tests
    ok(secure_compare('abc', 'abc'), 'identical strings match');
    ok(!secure_compare('abc', 'abd'), 'different strings do not match');
    ok(!secure_compare('abc', 'ab'), 'different length strings do not match');
    ok(!secure_compare('ab', 'abc'), 'different length strings do not match (reversed)');

    # Edge cases
    ok(secure_compare('', ''), 'empty strings match');
    ok(!secure_compare('', 'a'), 'empty vs non-empty do not match');
    ok(!secure_compare('a', ''), 'non-empty vs empty do not match');

    # Undefined handling
    ok(!secure_compare(undef, 'abc'), 'undef vs string returns false');
    ok(!secure_compare('abc', undef), 'string vs undef returns false');
    ok(!secure_compare(undef, undef), 'undef vs undef returns false');

    # Long strings (ensure full comparison)
    my $long1 = 'a' x 1000;
    my $long2 = 'a' x 1000;
    my $long3 = 'a' x 999 . 'b';
    ok(secure_compare($long1, $long2), 'long identical strings match');
    ok(!secure_compare($long1, $long3), 'long strings differing at end do not match');

    # Difference at beginning vs end should both fail
    # (timing attack would show faster failure at beginning with naive compare)
    my $token1 = 'abcdef1234567890abcdef1234567890';
    my $token2 = 'Xbcdef1234567890abcdef1234567890';  # differs at start
    my $token3 = 'abcdef1234567890abcdef123456789X';  # differs at end
    ok(!secure_compare($token1, $token2), 'difference at start fails');
    ok(!secure_compare($token1, $token3), 'difference at end fails');
};

done_testing;
