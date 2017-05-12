#!/usr/bin/env perl
# vim: set ft=perl ts=4 sw=4:

# ======================================================================
# 03multiple.t
#
# Attempting to pass a multi-character format string will not work.
# This means that stringf will return the malformed format characters
# as they were passed in.
# ======================================================================

use strict;

use Test::More tests => 3;
use String::Format;

my ($orig, $target, $result);

# ======================================================================
# Test 1
# ======================================================================
$orig   = q(My %foot hurts.);
$target = q(My %foot hurts.);
$result = stringf $orig, { 'foot' => 'pretzel' };
is $target => $result;

# ======================================================================
# Test 2, same as Test 1, but with a one-char format string.
# ======================================================================
$target = "My pretzeloot hurts.";
$result = stringf $orig, { 'f' => 'pretzel' };
is $target => $result;

# ======================================================================
# Test 3
# ======================================================================
$orig   = 'I am %undefined';
$target = 'I am not ndefined';
$result = stringf $orig, { u => "not " };
is $target => $result;
