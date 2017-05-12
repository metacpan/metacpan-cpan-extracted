#!/usr/bin/env perl
# vim: set ft=perl:

# ======================================================================
# 02basic.t
#
# Simple test, testing multiple format chars in a single string.
# There are many variations on this theme; a few are covered here.
# ======================================================================

use strict;

use Test::More tests => 8;
use String::Format;

# ======================================================================
# Lexicals.  $orig is the original format string.
# ======================================================================
my ($orig, $target, $result);
my %fruit = (
    'a' => "apples",
    'b' => "bannanas",
    'g' => "grapefruits",
    'm' => "melons",
    'w' => "watermelons",
);

# ======================================================================
# Test 1
# Standard test, with all elements in place.
# ======================================================================
$orig   = qq(I like %a, %b, and %g, but not %m or %w.);
$target = "I like apples, bannanas, and grapefruits, ".
          "but not melons or watermelons.";
$result = stringf $orig, \%fruit;
is $target  => $result;

# ======================================================================
# Test 2
# Test where some of the elements are missing.
# ======================================================================
delete $fruit{'b'};
$target = "I like apples, %b, and grapefruits, ".
          "but not melons or watermelons.";
$result = stringf $orig, \%fruit;
is $target => $result;

# ======================================================================
# Test 3
# Upper and lower case of same char
# ======================================================================
$orig   = '%A is not %a';
$target = 'two is not one';
$result = stringf $orig, { "a" => "one", "A" => "two" };
is $target => $result;

# ======================================================================
# Test 4
# Field width
# ======================================================================
$orig   = "I am being %.5r.";
$target = "I am being trunc.";
$result = stringf $orig, { "r" => "truncated" };
is $result => $target;

# ======================================================================
# Test 5
# Alignment
# ======================================================================
$orig   = "I am being %30e.";
$target = "I am being                      elongated.";
$result = stringf $orig, { "e" => "elongated" };
is $target => $result;

# ======================================================================
# Test 6 - 8
# Testing of non-alphabet characters
# ======================================================================
# Test 6 => '/'
# ======================================================================
$orig   = "holy shit %/.";
$target = "holy shit w00t.";
$result = stringf $orig, { '/' => "w00t" };
is $target => $result;

# ======================================================================
# Test 7 => numbers
# ======================================================================
$orig   = '%1 %2 %3';
$target = "1 2 3";
$result = stringf $orig, { '1' => 1, '2' => 2, '3' => 3 };
is $target => $result;

# ======================================================================
# Test 8 => perl sigils ($@&)
# ======================================================================
# Note: The %$ must be single quoted so it does not interpolate!
# This was causing this test to unexpenctedly fail.
# ======================================================================
$orig   = '%$ %@ %&';
$target = "1 2 3";
$result = stringf $orig, { '$' => 1, '@' => 2, '&' => 3 };
is $target => $result;


