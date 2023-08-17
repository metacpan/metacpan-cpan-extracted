#!/usr/bin/perl

use strict;
use warnings;

# Make sure PDL::Opt::ParticleSwarm is working

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;


use PDL;
use PDL::Opt::ParticleSwarm;

my $count = 0;
# find value of $x that returns a minima.
sub f
{
	my $vec = shift;
	my $x = $vec->slice('(0)');
	my $y = $vec->slice('(1)');

	#print "vec=$vec x=$x y=$y\n";
	$count++;

	# The parabola (x+3)^2 - 5 has a minima at x=-3:
	return (($x+3)**2 - 5) + (($y+7)**2 - 9);
}

sub log
{
	my ($vec, $vals, $ssize) = @_;

	# $vec is the array of values being optimized
	# $vals is f($vec)
	# $ssize is the simplex size, or roughly, how close to being converged.

	my $x = $vec->slice('(0)');

	# each vector element passed to log() has a min and max value. 
	# ie: x=[6 0] -> vals=[76 4]
	# so, from above: f(6) == 76 and f(0) == 4

	#print "$count: $x -> $vals\n";
}

test("basic ops",
	-fitFunc => \&f,
	-dimensions => 2,
	-logFunc => \&log,
	-iterations => 4000,
	-exitFit => -14 + 1e-9,
	-stallSpeed => 1e-6,
	);

test("initial guess",
	-fitFunc => \&f,
	-dimensions => 2,
	-logFunc => \&log,
	-iterations => 4000,
	-initialGuess => pdl([0, 0]),
	-exitFit => -14 + 1e-9,
	-stallSpeed => 1e-6,
	);

test("constrained search",
	-fitFunc => \&f,
	-dimensions => 2,
	-logFunc => \&log,
	-iterations => 4000,
	-exitFit => -14 + 1e-9,
	-initialGuess => pdl([-5, -10]),
	-posMin => -20,
	-posMax => 20,
	-stallSpeed => 1e-6,
	);

test("search size",
	-fitFunc => \&f,
	-dimensions => 2,
	-logFunc => \&log,
	-iterations => 4000,
	-exitFit => -14 + 1e-9,
	-initialGuess => pdl([-5, -10]),
	-posMin => -20,
	-posMax => 20,
	-searchSize => .5,
	-stallSpeed => 1e-6,
	);

sub test
{
	my ($t, %opts) = @_;

	$count = 0;
	print "testing $t...\n";
	my $pso = PDL::Opt::ParticleSwarm->new(%opts);

	$pso->optimize();
	my $vec_optimal = $pso->getBestPos();
	my $optval = $pso->getBestFit();

	my $iters = $pso->getIterationCount();

	my $x = $vec_optimal->slice('(0)');
	my $y = $vec_optimal->slice('(1)');
	my $stalls = $pso->getStallCount->sum;
	print "opt=($x,$y) -> minima=$optval - iterations=$iters log_count=$count stalls=$stalls\n";
	ok(all abs($x - (-3)) < 1e-3);
}
