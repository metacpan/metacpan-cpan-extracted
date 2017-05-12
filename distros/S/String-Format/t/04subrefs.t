#!/usr/bin/env perl
# vim: set ft=perl ts=4 sw=4:

# ======================================================================
# 04subrefs.t
#
# The design of String::Format is such that you can pass a subroutine
# reference as a hash value, and it will be called in place.  Let's
# test that.
# ======================================================================

use strict;

use Test::More tests => 2;
use String::Format;
use POSIX qw(strftime); # for test 1

my ($orig, $target, $result);

# ======================================================================
# Test 1
# Using strftime in a subroutine reference.
# ======================================================================
$orig   = q(It is now %{%Y/%m%d}d.);
$target = sprintf q(It is now %s.), strftime("%Y/%m/%d", localtime);
$result = stringf $orig, "d" => sub { strftime("%Y/%m/%d", localtime) };
is $target => $result;

# ======================================================================
# Test 2
# using getpwuid
# ======================================================================
SKIP: {
    skip "Test skipped on this platform", 1 
        if $^O eq 'MSWin32';

    $orig   = "I am %u.";
    $target = "I am " . getpwuid($<) . ".";
    $result = stringf $orig, "u" => sub { getpwuid($<) };
    is $target => $result;
}

