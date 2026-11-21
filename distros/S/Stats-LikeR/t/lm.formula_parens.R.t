#!/usr/bin/env perl
#
# Arithmetic inside a formula term: log(x+1), I(x+z), I(x*2), exp(x/10) and
# the like.  Up to 0.3418 lm_tok()/lm_expand_cross() split a term at a '+' or
# '*' inside its parentheses and every such formula died with "0 degrees of
# freedom".  A term that cannot be read now croaks naming it.
#
# Provenance: R 4.6.1 lm(), options(digits=17), on the data below (y, x, z as
# written); R labels the coefficients with spaces around operators
# ("log(x + 1)"), the module keeps the formula's own spelling ("log(x+1)").
# Re-run: d <- data.frame(y=..., x=1:8, z=...); coef(lm(<formula>, d)).
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my %d = (y => [1,2.5,3,4.5,5,7.5,7,8.5], x => [1..8], z => [2,1,4,3,6,5,8,9]);
# [formula, [coefficient name, R value] ...]
my @cases = (
	['y ~ log(x+1)',  [Intercept => -3.0447422614652120], ['log(x+1)' => 4.9491323164838104]],
	['y ~ I(x+z)',    [Intercept => 0.47199999999999859], ['I(x+z)' => 0.47600000000000009]],
	['y ~ I(x*2)',    [Intercept => 0.10714285714285773], ['I(x*2)' => 0.52976190476190466]],
	['y ~ exp(x/10)', [Intercept => -5.6916759008264206], ['exp(x/10)' => 6.5639727772243086]],
	['y ~ log(x^2)',  [Intercept => 0.14750235111826163], ['log(x^2)' => 1.78318705273081535]],
	['y ~ I(x^2+z)',  [Intercept => 1.877786490422312715], ['I(x^2+z)' => 0.099081438333146657]],
	['y ~ I(x/z-1)',  [Intercept => 4.88317465497978365], ['I(x/z-1)' => -0.17184676161883347]],
	['y ~ x + I(2*x-z)', [Intercept => 0.078431372549020661], [x => 0.686274509803921573],
	                     ['I(2*x-z)' => 0.401960784313725339]],
);
# 1e-9 relative: observed disagreement with R about 1e-14 on double; room for
# the long-double and quadmath builds' different rounding of exp() and log().
for my $c (@cases) {
	my ($f, @want) = @$c;
	my $r = eval { lm(formula => $f, data => \%d) };
	ok($r, $f) or do { diag($@); next };
	for my $w (@want) {
		my $g = $r->{coefficients}{$w->[0]};
		ok(defined $g && abs($g - $w->[1]) <= 1e-9 * (abs($w->[1]) > 1 ? abs($w->[1]) : 1),
			"$f: $w->[0]") or diag("got " . ($g // 'undef') . ", want $w->[1]");
	}
}
# A bare group is a group of terms, not arithmetic: in R (x + z)*x is x + z +
# x:z, (x + z)^2 the same crossing, and (x + z) the two terms x and z, so
# each fits as the formula it expands to, never as one regressor x + z.  Since
# 0.3426; through 0.3425 all three were refused here as unreadable.
# t/formula_groups.R.t checks groups against R's own coefficients.
for my $c (['(x + z)*x', 'x*z'], ['(x + z)^2', 'x*z'], ['(x + z)', 'x + z']) {
	my ($f, $expanded) = @$c;
	my ($g, $e) = map { lm(formula => "y ~ $_", data => \%d) } $f, $expanded;
	is_deeply($g->{coefficients}, $e->{coefficients}, "y ~ $f fits as y ~ $expanded");
}
# unreadable terms croak, naming the term
for my $f ('foo(x)', 'poly(x,2)', 'log(x+)', 'log(x,2)') {
	eval { lm(formula => "y ~ $f", data => \%d) };
	like($@, qr/cannot evaluate term/, "$f is refused") or diag($@);
}
like($@, qr/log\(x,2\)/, 'the message names the term');
# an unclosed call is a parenthesis the formula does not balance
eval { lm(formula => 'y ~ I(x+z', data => \%d) };
like($@, qr/unbalanced parenthesis/, 'I(x+z is refused');
# a column of all undef is still the usual NaN column, not the new croak
eval { lm(formula => 'y ~ log(x)', data => { y => [1,2,3,4], x => [undef, undef, undef, undef] }) };
like($@, qr/0 degrees of freedom/, 'an all-undef column keeps its message');
done_testing;
