#!/usr/bin/env perl

# This test checks that specifying both linear_thresh and linear_width
#    results in consistent rounding.

use strict;
use warnings;
use Test::More;
use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	base => 1.5, linear_width => 1, linear_thresh => 10);

ok_within( $stat->linear_threshold, 20/3, 10, "linear_thresh near expected" );
ok_within( $stat->linear_width,     2/3,  1,  "linear_width near expected" );

for (0..9) {
	cmp_ok( range($stat, $_), "<=", 1, "Interval $_ < 1");
};

ok_within( range( $stat, 11  ), 11 *1/3, 11 *1/2, "11 outside linear range");
ok_within( range( $stat, 110 ), 110*1/3, 110*1/2, "11 outside linear range");

done_testing;

sub range {
	my ($st, $x) = @_;
	return $st->_upper($x) - $st->_lower($x);
};

sub ok_within {
	my ($got, $lower, $upper, $msg) = @_;

	my $ok = $got >= $lower && $got <= $upper;
	ok( $ok, $msg );
	$ok	and note "Value $got within range [$lower, $upper]";
	$ok or diag "Value $got outside range [$lower, $upper]";
	return $ok;
};
