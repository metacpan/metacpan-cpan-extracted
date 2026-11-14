#!/usr/bin/env perl
# sum() whose running total overflows although the true sum is finite.
#
# Provenance: R 4.6.1 (long double accumulator) gives
# sum(c(1e308, 1e308, -1e308)) = 1e308 and sum(c(1e308, 1e308, -1e308, 5e307))
# = 1.5e308 (options(digits=17)); this module returned Inf for both.  A sum
# that truly exceeds the NV range stays Inf as in R (sum(c(1e308,1e308)) is
# Inf).  The scaling is by an exact power of two, so the results are exact
# and compared with is().
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

my $inf = 9**9**9;
is(sum(1e308, 1e308, -1e308), 1e308, 'list form');
is(sum([1e308, 1e308, -1e308]), 1e308, 'array ref form');
is(sum([1e308, 1e308, -1e308, 5e307]), 1.5e308, 'four values');
is(sum([1e308, 1e308, -1e308, -1e308]), 0, 'cancels to 0');
# 2e308 is past a double and inside a long double or __float128, so what a
# true overflow gives is whatever this perl's own arithmetic gives: Inf on a
# double build, 2e308 on the wider ones.
is(sum([1e308, 1e308]), 1e308 + 1e308, 'a sum past the NV range is what perl\'s own + gives');
is(sum([-1e308, -1e308]), -1e308 - 1e308, 'and so is the negative one');
is(sum([$inf, 1]), $inf, 'infinite input');
is(sum([$inf, -$inf]) != sum([$inf, -$inf]) ? 'nan' : 'num', 'nan', 'Inf - Inf is NaN');
is(sum([1, 2, 3]), 6, 'ordinary path');
done_testing();
