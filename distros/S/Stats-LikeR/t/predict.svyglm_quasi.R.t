#!/usr/bin/env perl
#
# predict() on svyglm() fits of the quasibinomial and quasipoisson families.
# Up to 0.3418 only "binomial"/"poisson" were inverted, so type => 'response'
# (the default) returned the linear predictor for the quasi families.
#
# Provenance: R 4.6.1 with survey (svydesign(ids=~cl, weights=~w, data=d);
# svyglm(y ~ x, des, family=quasibinomial()) and svyglm(cnt ~ x, des,
# family=quasipoisson())), then predict(m, data.frame(x=0.5), type=...),
# printed at options(digits=17).  The data below are the data frame used.
# Re-run: write the data into R as shown and run those two calls.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my @x   = (-0.9,-0.7,-0.5,-0.4,-0.2,0,0.1,0.3,0.4,0.6,0.8,0.9);
my @y   = (0,0,1,0,0,1,0,1,1,0,1,1);
my @cnt = (1,0,2,1,3,2,4,3,5,4,6,8);
my @w   = (1,2,3,1,2,3,1,2,3,1,2,3);
my @cl  = (1,2,3,4,1,2,3,4,1,2,3,4);
my $d = { x => \@x, y => \@y, cnt => \@cnt, w => \@w, cl => \@cl };

# 1e-8 relative: the fit is an IRLS solve; observed disagreement with R on
# double was about 1e-13, leaving five orders of magnitude for wider NVs.
sub near { my ($got, $want, $name) = @_;
	cmp_ok(abs($got - $want), '<=', 1e-8 * (abs($want) > 1 ? abs($want) : 1), $name)
		or diag("got $got, want $want") }

my %ref = (
	quasibinomial => { resp => 0.87239272154195391, link => 1.9222822807730315, f => 'y ~ x' },
	quasipoisson  => { resp => 4.6991248746119227,  link => 1.5473762944881395, f => 'cnt ~ x' },
);
for my $fam (sort keys %ref) {
	my $m = svyglm(formula => $ref{$fam}{f}, data => $d, family => $fam, weights => 'w', cluster => 'cl');
	my $nd = { x => [0.5] };
	my ($p) = values %{ predict($m, $nd) };
	my ($l) = values %{ predict($m, $nd, type => 'link') };
	near($l, $ref{$fam}{link}, "$fam: link");
	near($p, $ref{$fam}{resp}, "$fam: response is the inverse link of R's");
	near($p, $fam eq 'quasibinomial' ? 1 / (1 + exp(-$l)) : exp($l), "$fam: response is the inverse link of link");
}
done_testing;
