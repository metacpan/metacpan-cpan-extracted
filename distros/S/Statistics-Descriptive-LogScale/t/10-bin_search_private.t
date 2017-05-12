#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

use Statistics::Descriptive::LogScale;

# import
*bin_ge = \&Statistics::Descriptive::LogScale::_bin_search_ge;

note "--- Testing >=";
is (bin_ge([], 0), 0, "empty = 0");
is (bin_ge([1], 0), 0, "found[0]");
is (bin_ge([1], 1), 0, "found[0]");
is (bin_ge([1], 2), 1, "not found");

is (bin_ge([1,2], 1), 0, "found[2]");
is (bin_ge([1,2], 2), 1, "found[2]");
is (bin_ge([1,2], 3), 2, "not found[2]");
is (bin_ge([0..100], 50), 50, "larger array");

