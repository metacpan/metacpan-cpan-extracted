#!/usr/bin/env perl

# This is a test that crawls over several buckets
#    and checks if upper bound of current bucket
#    matches lower bound of next bucket.
# The test is set up to crawl from negative log area into linear area
#    and then into positive log area.

use strict;
use warnings;
use Test::More;
use Test::Number::Delta within => 1E-12;

use Statistics::Descriptive::LogScale;

my $eps = 1E-9;

my $stat = Statistics::Descriptive::LogScale->new (
	base => 1.1, linear_width => 0.1 );

my $t = -2;
note "linear thresh = ", $stat->linear_threshold;

for (1..30) {
	my $mid = $stat->_round($t);
	my $up  = $stat->_upper($t);
	note sprintf "Testing bucket ( %f, %f, %f )", $stat->_lower($t), $mid, $up;

	delta_ok ($stat->_upper($up-$eps), $up,      "[$mid] upper(-eps) == upper");
	delta_ok ($stat->_lower($up+$eps), $up,      "[$mid] lower(+eps) == upper");
	delta_ok ($stat->_round($up-$eps), $mid,     "[$mid] round(-eps) == round");
	cmp_ok   ($stat->_round($up+$eps), ">", $up, "[$mid] round(+eps) > upper")
		or die "Cannot progress, stop right here";

	$t = $stat->_round($up + $eps);
};

done_testing;
