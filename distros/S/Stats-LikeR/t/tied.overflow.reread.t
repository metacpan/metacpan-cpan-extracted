#!/usr/bin/env perl
# A tied array that changes between the two reads of an overflow recovery.
#
# sum(), mean(), sd() and var() read their arguments once, and read them again
# only when the running total overflowed (args_sum_rescaled() and
# args_mean_of() in LikeR.xs).  Up to 0.3423 that second read skipped an
# element that had become undef and re-took the array's length, so a tied
# array whose FETCH or FETCHSIZE changed gave the sum or mean of a different
# sample, divided by the first count.  It now croaks as the first read does.
# Hand-written: R has no tied vectors, so there is no reference to take.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(:all);
use Test::More;
use Test::Exception;

# The largest power of two this perl's NV holds, so that big + big overflows on
# double, long double and quadmath builds alike (1e308 + 1e308 does not on the
# wider two), and every value is exact.
my $inf = 9**9**9;
my $big = 1;
$big *= 2 until $big * 2 == $inf;

{
	# Serves v on the first read.  The second FETCHSIZE starts the re-read, in
	# which 'hole' makes element 1 undef and 'grow' adds an element.
	package FlipTie;
	sub TIEARRAY  { my ($c, %o) = @_; return bless { %o, sizes => 0 }, $c }
	sub FETCHSIZE {
		my $s = shift;
		my $n = @{ $s->{v} };
		return ++$s->{sizes} > 1 && $s->{grow} ? $n + 1 : $n;
	}
	sub FETCH {
		my ($s, $i) = @_;
		my $reread = $s->{sizes} > 1;
		return undef if $reread && $s->{hole} && $i == 1;
		return $i < @{ $s->{v} } ? $s->{v}[$i] : 1;
	}
}

sub flip { my @a; tie @a, 'FlipTie', v => [ $big, $big, -$big ], @_; return \@a }

# An unchanged tied array still gets the recovered answer.
is(sum(flip()), $big, 'sum: unchanged tied array recovers from the overflow');
is(mean(flip()), $big / 3, 'mean: unchanged tied array recovers from the overflow');

for my $fn (qw(sum mean sd var)) {
	no strict 'refs';
	my $f = \&{"Stats::LikeR::$fn"};
	throws_ok { $f->(flip(hole => 1)) }
		qr/^\Q$fn\E: undefined value at array ref index 1 \(argument 0\)/,
		"$fn: an element that turns undef on the re-read croaks";
	throws_ok { $f->(flip(grow => 1)) }
		qr/^\Q$fn\E: a tied array changed its length between reads/,
		"$fn: a tied array that grows on the re-read croaks";
}
done_testing();
