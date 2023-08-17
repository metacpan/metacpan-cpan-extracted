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
	my $x = $_[0]->slice('(0)');

	$count++;

	# The parabola (x+3)^2 - 5 has a minima at x=-3:
	return (($x+3)**2 - 5);
}

sub log
{
	my ($vec, $vals, $ssize) = @_;

	# $vec is the array of values being optimized
	# $vals is f($vec)
	# $ssize is the simplex size, or roughly, how close to being converged.

	#my $x = $vec->slice(0);
	#print "vec=$vec x=$x\n";

	# each vector element passed to log() has a min and max value. 
	# ie: x=[6 0] -> vals=[76 4]
	# so, from above: f(6) == 76 and f(0) == 4

	#print "$count: $x -> $vals\n";
}

test("basic ops",
	-fitFunc => \&f,
	-dimensions => 1,
	-logFunc => \&log,
	-iterations => 2000,
	-exitFit => -5 + 1e-12,
	);

test("initial guess",
	-fitFunc => \&f,
	-dimensions => 1,
	-logFunc => \&log,
	-initialGuess => pdl([30]),
	-exitFit => -5 + 1e-12,
	);

test("constrained search",
	-fitFunc => \&f,
	-dimensions => 1,
	-logFunc => \&log,
	-exitFit => -5 + 1e-12,
	-initialGuess => pdl([0]),
	-posMin => -10,
	-posMax => 10,
	);

test("search size",
	-fitFunc => \&f,
	-dimensions => 1,
	-logFunc => \&log,
	-exitFit => -5 + 1e-12,
	-initialGuess => pdl([0]),
	-posMin => -10,
	-posMax => 10,
	-searchSize => .5,
	-iterations => 2000
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
	print "opt=$x -> minima=$optval - iterations=$iters log_count=$count\n";
	ok(all abs($x - (-3)) < 1e-6);
}
