#!/usr/bin/env perl
#
# srand() governs every random draw this module makes, and it governs the same
# stream perl's own rand() draws from.
#
# That is the documented contract -- rnorm(), runif(), sample() and rbinom()
# are all Drand01(), so set.seed()-style reproducibility is what an R user
# expects of them -- and up to 0.316 it was silently false on one class of
# build.  config.h defines Drand01() as libc's drand48() and seedDrand01() as
# srand48(); on a threaded perl before 5.20, reentr.h redefines both over the
# interpreter's own PL_reentrant_buffer, but only for PERL_CORE and PERL_EXT
# (perlxs, "Thread-aware system interfaces").  An XS file is neither, so
# pp_srand() seeded one generator and every draw here read another, and
# srand($seed) did nothing at all.  See the comment above AUTO_SEED_PRNG() in
# LikeR.xs for the whole of it.
#
# It reached CPAN in 0.316 and came back as a FAIL from a 5.18.3 smoker
# (x86_64-linux-thread-multi-ld): two subtests of t/rbinom.dist.t, which was
# the only file in the suite that drew the same seed twice, and nothing else
# -- an unseeded drand48 is still a good drand48, so every distribution test
# passed either way.  That is why these checks are here rather than left to
# rbinom's file: the property is module-wide, and the bug is invisible to a
# test that only asks whether the numbers are distributed correctly.
#
# Nothing here pins a value.  Which numbers a seed produces is libc's business
# on some builds and perl's on others, and it differs between them; what is
# asserted is only that a seed determines them and that one stream feeds both
# sides.  Reproduced before the fix on a perl 5.16.3 built with -Duseithreads
# -Duselongdouble, the local stand-in for the smoker.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 15;
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(runif rnorm rbinom sample);

# runif(n => 1, min => 0, max => 1) is `min + (max - min) * Drand01()`, i.e.
# 0 + 1 * Drand01(): the uniform comes back unrounded, so it can be compared
# with perl's own rand() for exact equality rather than to a tolerance.
sub one_unif { return runif(n => 1, min => 0, max => 1)->[0] }

# ------------------------------------------------- one seed, one sequence
{
	srand 20260912; my $a = runif(n => 8, min => 0, max => 1);
	srand 20260912; my $b = runif(n => 8, min => 0, max => 1);
	is_deeply($a, $b, 'runif: the same seed gives the same numbers');

	srand 20260912; my $c = rnorm(n => 8, mean => 0, sd => 1);
	srand 20260912; my $d = rnorm(n => 8, mean => 0, sd => 1);
	is_deeply($c, $d, 'rnorm: the same seed gives the same numbers');

	srand 20260912; my $e = rbinom(n => 8, size => 250, prob => 0.37);
	srand 20260912; my $f = rbinom(n => 8, size => 250, prob => 0.37);
	is_deeply($e, $f, 'rbinom: the same seed gives the same variates');

	srand 20260912; my $g = sample([1 .. 50], 8);
	srand 20260912; my $h = sample([1 .. 50], 8);
	is_deeply($g, $h, 'sample: the same seed gives the same draw');
}

# A generator stuck at one sequence would pass every test above, so each of
# them is paired with a seed that has to move it.
{
	srand 4242; my $a = runif(n => 8, min => 0, max => 1);
	srand 4243; my $b = runif(n => 8, min => 0, max => 1);
	isnt(join(',', @$a), join(',', @$b), 'runif: a different seed moves the numbers');

	srand 4242; my $c = rnorm(n => 8, mean => 0, sd => 1);
	srand 4243; my $d = rnorm(n => 8, mean => 0, sd => 1);
	isnt(join(',', @$c), join(',', @$d), 'rnorm: a different seed moves the numbers');

	srand 4242; my $e = rbinom(n => 8, size => 250, prob => 0.37);
	srand 4243; my $f = rbinom(n => 8, size => 250, prob => 0.37);
	isnt(join(',', @$e), join(',', @$f), 'rbinom: a different seed moves the variates');

	srand 4242; my $g = sample([1 .. 50], 8);
	srand 4243; my $h = sample([1 .. 50], 8);
	isnt(join(',', @$g), join(',', @$h), 'sample: a different seed moves the draw');
}

# ------------------------------------ perl's rand() and the XS share a stream
#
# This is the check the 0.316 bug fails outright: there, the two sides had a
# generator each, so the module's first uniform was unrelated to perl's and
# carried on from wherever its own stream happened to be.
{
	srand 911; my @perl = (rand, rand, rand);

	srand 911; my $first = one_unif();
	is($first, $perl[0], 'the XS draws perl\'s next uniform, not one of its own');

	srand 911; my $r1 = rand; my $second = one_unif();
	is($second, $perl[1], 'a draw in the XS follows one made by rand()');
	is($r1, $perl[0], 'and rand() is where it was');

	srand 911; my $u = one_unif(); my $r2 = rand;
	is($u,  $perl[0], 'the XS advances the one stream ...');
	is($r2, $perl[1], '... so rand() carries on from after it');
}

# Interleaving the two in one run has to be reproducible as a whole, which is
# the property a script mixing rand() with this module actually depends on.
{
	srand 5150;
	my @a = (rand, one_unif(), rand, @{ runif(n => 2, min => 0, max => 1) }, rand);
	srand 5150;
	my @b = (rand, one_unif(), rand, @{ runif(n => 2, min => 0, max => 1) }, rand);
	is_deeply(\@a, \@b, 'rand() and the XS interleaved replay identically');
	is(scalar(grep { $_ >= 0 && $_ < 1 } @a), 6, 'and every one of them is a uniform in [0, 1)');
}
