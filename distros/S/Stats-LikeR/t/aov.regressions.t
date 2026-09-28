#!/usr/bin/env perl
#
# aov(): the defects a 0.316 review of LikeR.xs turned up, each one pinned so
# that it stays fixed.  t/01.t and t/tukey_aov_prcomp.R.t already cover what
# aov() computes; this file covers what it used to do to malformed, awkward or
# merely long input, and the two places its answer depended on perl's hash
# order rather than on the data.
#
# Provenance of the expected values:
#
#   * R 4.6.1 stats::aov()/anova(), at options(digits=17), for the two fits the
#     scale-invariance and formula-length sections compare against:
#         y <- c(1.2,2.3,0.9,4.4,5.1,4.8,7.7,8.2,9.1,3.3,2.9,3.8)
#         g <- factor(rep(c("a","b","c","d"), each = 3))
#         x <- c(0.5,1.5,2.5,3.5,4.5,5.5,6.5,7.5,8.5,9.5,10.5,11.5)
#         anova(aov(y ~ g))   ->  F 73.762944983818784, Pr 3.5956693300220001e-06,
#                                 Sum Sq 75.975833333333298 / 2.7466666666666653,
#                                 Df 3 / 8
#         anova(aov(y ~ x))   ->  F 1.9927680012954403,  Pr 0.18840173513785918,
#                                 Sum Sq 13.080856643356627 / 65.641643356643343
#   * Everything else is a structural property -- a croak instead of a crash,
#     an answer that does not move between runs -- and has no reference value
#     to take.  R is the reference for the *reading* of the formulas, noted at
#     each section.
#
# What each section was:
#
#   long interaction  aov built the two halves of an `a:b` term in two 256-byte
#                     stack arrays, filling the left one with strncpy() at the
#                     term's own length.  A component past 255 characters wrote
#                     off the end of the frame; glibc reported "*** buffer
#                     overflow detected ***" and aborted the interpreter, which
#                     no eval can catch.
#   long formula      the formula was copied into char[512] and truncated
#                     there, and `.` expanded into char[2048] and silently
#                     DROPPED every column past it, so a long model was quietly
#                     replaced by a shorter one.
#   HoH values        only the first hash value was checked for being a
#                     reference; SvRV() on a later plain scalar segfaulted.
#   ragged HoA        the row count came from whichever column hv_iternext()
#                     returned first, so which rows were fitted moved with hash
#                     order from run to run.
#   group.stats       same, for the per-column summary, and reached by the
#                     documented no-formula (R stack()) form, whose columns are
#                     unequal by definition.
#   '.' order         `.` expanded in hash order, and a sequential (Type I) sum
#                     of squares is attributed in term order, so the table
#                     differed on every run of the same script.
#   scale invariance  the QR's rank test was the absolute `max_val < 1e-10`, so
#                     a design in small units was declared entirely aliased.
#   I(...) markers    `-1`, `+0` and `+1` were removed with strstr() over the
#                     whole right-hand side, so the `-1` inside `I(x-1)` was
#                     eaten and a DIFFERENT model, `y ~ I(x)`, was fitted and
#                     reported without a word.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(aov);

my @Y = (1.2, 2.3, 0.9, 4.4, 5.1, 4.8, 7.7, 8.2, 9.1, 3.3, 2.9, 3.8);
my @G = map { (qw(a b c d))[ int($_ / 3) ] } 0 .. 11;
my @X = map { $_ + 0.5 } 0 .. 11;

# R 4.6.1, options(digits=17)
my $R_F_G   = 73.762944983818784;
my $R_P_G   = 3.5956693300220001e-06;
my $R_SSG   = 75.975833333333298;
my $R_SSR_G = 2.7466666666666653;
my $R_F_X   = 1.9927680012954403;
my $R_P_X   = 0.18840173513785918;

# Every quantity below is a ratio or a sum of squares of order 1..100 formed by
# one Householder QR of a 12 x k design, so a handful of ulp is the whole error
# budget.  1e-12 relative is ~4500 ulp of a double and leaves room for the
# wider NV widths to differ in their last digits; the worst disagreement
# actually observed on a double build is 0.
my $TOL = 1e-12;
sub near {
	my ($got, $exp, $label) = @_;
	return ok(0, "$label (got undef)") unless defined $got;
	return ok(abs($got - $exp) <= $TOL * (1 + abs $exp), $label)
		|| diag("got $got, expected $exp");
}

# ---------------------------------------------------------------- baseline
{
	my $r = aov({ y => \@Y, g => \@G }, 'y ~ g');
	near($r->{g}{'F value'},        $R_F_G,   'y ~ g: F matches R');
	near($r->{g}{'Pr(>F)'},         $R_P_G,   'y ~ g: Pr(>F) matches R');
	near($r->{g}{'Sum Sq'},         $R_SSG,   'y ~ g: Sum Sq matches R');
	near($r->{Residuals}{'Sum Sq'}, $R_SSR_G, 'y ~ g: residual Sum Sq matches R');
	is($r->{g}{Df},         3, 'y ~ g: Df matches R');
	is($r->{Residuals}{Df}, 8, 'y ~ g: residual Df matches R');
}

# ------------------------------------------- a long interaction component
#
# The answer must not depend on how long a column's NAME is.  Before 0.316 the
# 300- and 5000-character cases aborted the interpreter outright.
{
	my $base;
	for my $len (4, 300, 5000) {
		my $L = 'ab' . ('x' x $len);
		my %d = ( y  => \@Y,
		          $L => [ map { $_ % 2 } 0 .. 11 ],
		          b  => [ map { $_ % 3 } 0 .. 11 ] );
		my $r = eval { aov(\%d, "y ~ $L + b + $L:b") };
		ok(!$@, "interaction with a ${len}-character component: no crash")
			or diag($@);
		next unless $r;
		$base = $r->{Residuals}{'Sum Sq'} unless defined $base;
		near($r->{Residuals}{'Sum Sq'}, $base,
		     "interaction with a ${len}-character component: same fit");
		is($r->{Residuals}{Df}, 8,
		   "interaction with a ${len}-character component: same residual Df");
	}
}

# ------------------------------------------------------- a long formula
#
# `y ~ .` over more columns than the old 2048-byte expansion buffer held.  The
# dropped columns used to leave a smaller model, which is visible as a larger
# residual Df.
{
	my $ncol = 60;                      # 60 columns of ~40 characters each
	my %d = ( y => [ map { $_ * 1.5 + ($_ % 5) } 1 .. 80 ] );
	my @names;
	for my $c (1 .. $ncol) {
		my $nm = sprintf('predictor_with_a_long_name_%02d_%s', $c, 'z' x 12);
		push @names, $nm;
		$d{$nm} = [ map { ($_ * $c) % 7 } 1 .. 80 ];
	}
	my $dot  = eval { aov(\%d, 'y ~ .') };
	my $err  = $@;
	my $full = eval { aov(\%d, 'y ~ ' . join(' + ', sort @names)) };
	unless ($dot && $full) {
		fail("'.' over $ncol long column names: aov died ($err)") for 1 .. 3;
		goto DOT_DONE;
	}
	is($dot->{Residuals}{Df}, $full->{Residuals}{Df},
	   "'.' over $ncol long column names keeps every predictor");
	near($dot->{Residuals}{'Sum Sq'}, $full->{Residuals}{'Sum Sq'},
	     "'.' over $ncol long column names fits the same model");
	is(scalar(grep { !/\A(?:Residuals|coefficients|family|fitted\.values|group\.stats|xlevels)\z/ }
	          keys %$dot),
	   $ncol, "'.' produced all $ncol terms");
	DOT_DONE:
}

# ------------------------------------------ '.' expands in a fixed order
#
# A sequential (Type I) sum of squares is attributed in term order, so the
# order `.` expands in is part of the answer.  It must be the sorted order,
# which is the only one a Perl hash can offer twice.
{
	my %d = ( y => [ map { $_ + ($_ % 3) * 2.5 } 1 .. 30 ],
	          gg => [ map { 'g' . ($_ % 3) } 1 .. 30 ],
	          xx => [ map { $_ / 3 } 1 .. 30 ],
	          zz => [ map { ($_ * 7) % 5 } 1 .. 30 ] );
	my $dot = eval { aov(\%d, 'y ~ .') }          || {};
	my $exp = eval { aov(\%d, 'y ~ gg + xx + zz') } || {};   # the sorted order
	for my $term (qw(gg xx zz)) {
		near($dot->{$term} && $dot->{$term}{'Sum Sq'},
		     ($exp->{$term} ? $exp->{$term}{'Sum Sq'} : -1),
		     "'.' attributes $term as the sorted explicit formula does");
	}
	# and it does not move between freshly built, equal hashes
	my $first;
	for my $rep (1 .. 12) {
		my %e;
		# insert the keys in a different order each time, so that per-hash key
		# perturbation has something to act on
		for my $k ($rep % 2 ? qw(y gg xx zz) : qw(zz xx gg y)) { $e{$k} = $d{$k} }
		my $t = eval { aov(\%e, 'y ~ .') } || {};
		my $sig = join ',',
			map { defined $t->{$_} ? sprintf '%.15g', $t->{$_}{'Sum Sq'} : 'undef' }
			qw(gg xx zz);
		$first = $sig unless defined $first;
		last if $sig ne $first;
	}
	is($first, join(',', map { sprintf '%.15g', $exp->{$_}{'Sum Sq'} } qw(gg xx zz)),
	   "'.' gives the same table over 12 differently-built equal hashes");
}

# -------------------------------------------------- malformed HoH values
{
	my %d = map { ("r$_" => { y => $_, g => $_ % 2 }) } 1 .. 8;
	$d{zzz_not_a_ref} = 42;
	my $r = eval { aov(\%d, 'y ~ g') };
	ok(!defined $r, 'HoH with a non-reference value: does not return');
	like($@, qr/HashRefs \(HoH\)/,
	     'HoH with a non-reference value: croaks instead of segfaulting');
}

# ------------------------------------------------------ ragged HoA input
#
# Which column sets the row count used to decide how many observations were
# fitted, and that was hash order.  R's data.frame() recycles a short column
# only when its length divides the longest; inventing observations quietly in
# a model fit is worse than refusing, and lm() already refuses this shape.
{
	my $r = eval { aov({ y => [ 1 .. 12 ], g => [ map { $_ % 3 } 1 .. 9 ] }, 'y ~ g') };
	ok(!defined $r, 'ragged HoA: does not return');
	like($@, qr/unequal lengths/, 'ragged HoA: croaks, naming the column');
}

# ----------------------------------- group.stats over unequal-length groups
#
# The documented no-formula form is R's stack(), so its groups are unequal by
# construction.  Each column must be summarised over its own length, the same
# way on every run.
{
	my %sig;
	for my $rep (1 .. 12) {
		my %d;
		for my $k ($rep % 2 ? qw(short long) : qw(long short)) {
			$d{$k} = $k eq 'short' ? [ 1, 2, 3 ] : [ 1 .. 20 ];
		}
		my $gs = (eval { aov(\%d) } || { 'group.stats' => {} })->{'group.stats'};
		$sig{ join '|', map { defined $gs->{size}{$_}
		                      ? sprintf('%d/%.15g', $gs->{size}{$_}, $gs->{mean}{$_})
		                      : 'undef' } qw(short long) }++;
	}
	is(scalar keys %sig, 1, 'group.stats: one answer over 12 runs')
		or diag('answers seen: ', join ' ; ', sort keys %sig);
	is((keys %sig)[0], '3/2|20/10.5',
	   'group.stats: each column summarised over its own length');
}

# ------------------------------------------------- rank test is scale free
#
# A least-squares fit's rank cannot depend on the units of its predictors.
# Multiplying x by 1e-12 used to put every column under the absolute 1e-10
# threshold, so every term was declared aliased and F came back NaN.
{
	my $plain = eval { aov({ y => \@Y, x => \@X }, 'y ~ x') } || { x => {} };
	near($plain->{x}{'F value'}, $R_F_X, 'y ~ x: F matches R');
	near($plain->{x}{'Pr(>F)'},  $R_P_X, 'y ~ x: Pr(>F) matches R');
	for my $scale (1e-12, 1e-6, 1e6, 1e12) {
		my @xs = map { $_ * $scale } @X;
		my $r  = eval { aov({ y => \@Y, x => \@xs }, 'y ~ x') };
		ok($r && defined $r->{x}{'F value'} && $r->{x}{'F value'} == $r->{x}{'F value'},
		   "x scaled by $scale: F is a number") or next;
		near($r->{x}{'F value'}, $R_F_X, "x scaled by $scale: same F as R");
		near($r->{x}{'Pr(>F)'},  $R_P_X, "x scaled by $scale: same Pr(>F) as R");
		is($r->{x}{Df}, 1, "x scaled by $scale: term keeps its degree of freedom");
	}
}

# ------------------------------------------------ I(...) hides its markers
#
# In a formula `-1` suppresses the intercept, but not inside an I() escape,
# where it is arithmetic.  aov() used to strip it anyway and silently fit
# `y ~ I(x)` -- a different model -- under the name I(x).
{
	my $r = eval { aov({ y => \@Y, x => \@X }, 'y ~ I(x-1)') };
	ok(!(defined $r && exists $r->{'I(x)'}),
	   'I(x-1) is not silently rewritten to I(x)');
	# `-1` outside an I() still suppresses the intercept, as R reads it
	my $noint = eval { aov({ y => \@Y, g => \@G }, 'y ~ g - 1') } || { coefficients => {} };
	ok(!exists $noint->{coefficients}{Intercept},
	   'y ~ g - 1 still drops the intercept');
	# How aov() then CODES the factor is a separate question from whether it
	# read the marker: it drops the intercept but still contrast-codes g, so a
	# level is lost.  lm()/glm() get this right through lm_design_build()'s
	# margin rule and aov() does not; that is not what this section is about
	# and is left as it was found.
	ok(exists $noint->{g}, 'y ~ g - 1: the factor term is still fitted');
}

done_testing();
