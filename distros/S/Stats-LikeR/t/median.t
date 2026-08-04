#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace;
use Stats::LikeR;

# median() selects the middle order statistic(s) instead of sorting the whole
# sample, so what needs covering is not just "is the answer right" but the
# input shapes a quickselect can go wrong on: already ordered data, reversed
# data, heavy duplicates, and the pattern that defeats a median-of-three pivot.
# Every case is checked against a plain Perl sort, which is the definition.

sub by_sort {
	my @s = sort { $a <=> $b } @{ $_[0] };
	return @s % 2 ? $s[ $#s / 2 ] : ($s[ @s / 2 - 1 ] + $s[ @s / 2 ]) / 2;
}

# --- the basics
is(median(5),            5,   'median: single scalar');
is(median(1, 2, 3),      2,   'median: odd count, varargs');
is(median(1, 2, -1, 9),  1.5, 'median: even count, varargs');
is(median([1, 2, -1, 9]),1.5, 'median: even count, array ref');
is(median([3, 1, 2]),    2,   'median: array ref is not required to be sorted');
is(median(1, [2, 3], 4), 2.5, 'median: scalars and array refs mixed');
is(median(-5, -1, -3),  -3,   'median: negatives');
is(median('3', '1', '2'),2,   'median: numeric strings');

# --- shapes that stress the selection ------------------------------------
# lengths chosen to straddle the insertion-sort cutoff (20) and the point
# where the buffer moves from the C stack to the heap (256)
my @N = (1 .. 25, 254 .. 258, 1000, 5000);

my %shape = (
	'sorted'      => sub { [ 1 .. $_[0] ] },
	'reversed'    => sub { [ reverse 1 .. $_[0] ] },
	'all equal'   => sub { [ (7) x $_[0] ] },
	'two valued'  => sub { [ map { $_ % 2 } 1 .. $_[0] ] },
	'duplicates'  => sub { [ map { $_ % 3 } 1 .. $_[0] ] },
	'organ pipe'  => sub { my $n = shift; [ (1 .. $n / 2), reverse(1 .. $n - int($n / 2)) ] },
	'mo3 killer'  => sub { my $n = shift; [ map { $_ % 2 ? $_ : $n - $_ } 1 .. $n ] },
);

for my $name (sort keys %shape) {
	my $wrong = 0;
	for my $n (@N) {
		my $data = $shape{$name}->($n);
		my ($got, $want) = (median($data), by_sort($data));
		$wrong++, diag("$name n=$n: got $got, want $want") if abs($got - $want) > 1e-9;
	}
	is($wrong, 0, "median: '$name' agrees with sort at every length");
}

# --- pseudo-random data, fixed seed so a failure is reproducible
srand 20260803;
my $wrong = 0;
for my $n (1 .. 60, 300, 1024) {
	my $data = [ map { rand(200) - 100 } 1 .. $n ];
	my ($got, $want) = (median($data), by_sort($data));
	$wrong++, diag("random n=$n: got $got, want $want") if abs($got - $want) > 1e-9;
}
is($wrong, 0, 'median: random samples agree with sort at every length');

# --- tied arrays ---------------------------------------------------------
# A tied array keeps nothing in AvARRAY, so median takes a separate av_fetch
# path for it.  What that path needs is SvGETMAGIC: av_fetch on a tied array
# returns a deferred PVLV, not the value, and SvOK on one of those is false
# until its get-magic has run -- so the bug this covers is every element of a
# tied array looking undefined.  The lengths straddle the stack-buffer cutoff.
{
	package Tie::Plain;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
for my $n (1, 2, 5, 6, 25, 257, 600) {
	my @tied;
	tie @tied, 'Tie::Plain';
	@tied = map { ($_ * 37) % 101 } 1 .. $n;
	my @plain = @tied;
	is(median(\@tied), by_sort(\@plain), "median: tied array of $n elements");
}
{
	my @tied;
	tie @tied, 'Tie::Plain';
	@tied = (1, undef, 3);
	throws_ok { median(\@tied) }
		qr/\Qmedian: undefined value at array ref index 1 (argument 0)\E/,
		'median: an undef in a tied array is still reported by position';
}

# --- the caller's data is left alone -------------------------------------
# the selection reorders its own copy; an in-place partition of the input
# would be a silent corruption of the caller's array
my @orig  = (5, 3, 9, 1, 7, 2);
my @snap  = @orig;
median(\@orig);
is_deeply(\@orig, \@snap, 'median: does not reorder the array it was given');

# --- extremes ------------------------------------------------------------
is(median([1e308, -1e308, 0]), 0, 'median: very large magnitudes');
is(median([0.1, 0.2, 0.3]), 0.2, 'median: fractions');

# --- errors --------------------------------------------------------------
dies_ok { median() } 'median: dies with no arguments';
dies_ok { median([]) } 'median: dies on an empty array ref';
throws_ok { median(1, undef) } qr/\Qmedian: undefined value at argument index 1\E/,
	'median: names the argument index of an undef scalar';
throws_ok { median(1, [2, undef]) }
	qr/\Qmedian: undefined value at array ref index 1 (argument 1)\E/,
	'median: names the element and argument of an undef inside an array ref';

# --- leaks, on both the stack-buffer and heap paths ----------------------
unless ($INC{'Devel/Cover.pm'}) {
	my $small = [ map { $_ * 1.5 } 1 .. 20 ];
	my $large = [ map { $_ * 1.5 } 1 .. 1000 ];
	no_leaks_ok { eval { my $m = median($small) } }        'median no leaks: stack buffer';
	no_leaks_ok { eval { my $m = median($large) } }        'median no leaks: heap buffer';
	no_leaks_ok { eval { my $m = median(1, 2, [3, 4]) } }  'median no leaks: mixed arguments';
	no_leaks_ok { eval { my $m = median(1, undef) } }      'median no leaks: croak path';
	my @tied;
	tie @tied, 'Tie::Plain';
	@tied = @$small;
	no_leaks_ok { eval { my $m = median(\@tied) } }        'median no leaks: tied array';
}

done_testing();
