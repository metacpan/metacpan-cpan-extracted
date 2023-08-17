#!/usr/bin/perl

use strict;
use warnings;

# Make sure PDL::Opt::Simplex is working

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;


use PDL;
use PDL::Opt::Simplex;

my $count = 0;

# find value of $x that returns a minima.
sub f
{
	my $vec = shift;
	my $x = $vec->slice('(0)');
	my $y = $vec->slice('(1)');

	$count++;

	# Parabola with minima at x=-3,y=-7 == -14
	return (($x+3)**2 - 5) + (($y+7)**2 - 9);
}

sub log
{
	my ($vec, $vals, $ssize) = @_;

	# $vec is the array of values being optimized
	# $vals is f($vec)
	# $ssize is the simplex size, or roughly, how close to being converged.

	my $x = $vec->slice('(0)');
	my $y = $vec->slice('(1)');

	# each vector element passed to log() has a min and max value. 
	# ie: x=[6 0] -> vals=[76 4]
	# so, from above: f(6) == 76 and f(0) == 4

	print "$count [$ssize]: ($x,$y) -> $vals\n";
}

my $vec_initial = pdl [30, -30];
my ( $vec_optimal, $ssize, $optval ) = simplex($vec_initial, 3, 1e-6, 100, \&f, \&log);

my $x = $vec_optimal->slice('(0)');
my $y = $vec_optimal->slice('(1)');
print "ssize=$ssize  opt=($x,$y) -> minima=$optval\n";

ok(all abs($x - (-3)) < 1e-6);
