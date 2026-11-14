#!/usr/bin/env perl
# lmer(): a nesting with three or more levels, (1 | a/b/c).
#
# PROVENANCE
#
# %D, %REF and %REF2 are frozen output of t/lmer.nested3.R.R (re-run:
# `Rscript t/lmer.nested3.R.R`) under R 4.6.1 with the lme4 installed there:
# lmer(y ~ x + (1 | ga/gb/gc), REML = TRUE) for %REF and
# lmer(y ~ x + (x || ga/gb), REML = TRUE) for %REF2, on simulated data (72
# rows; 4 a, 3 b within each a, 2 c within each b).  lme4 expands a/b/c to
# a + a:b + a:b:c; until 0.3419 lmer() split at the first '/' only, produced
# the group 'ga:gb/gc', which names no column, dropped every row and died with
# "lmer: not enough complete observations".
# %REF2 is a singular fit in lme4 (the slope variance of ga is 8e-9), where the
# fixed effects are determined only to about 2e-6 between optimizers, so only
# the REML criterion and the well-determined variance are compared there.
# Tolerances, against the worst disagreement seen with lme4 when this was
# written (double): REML criterion 6e-13, intercept 2e-8, slope 3e-7, its SE
# 1.5e-7, residual variance 5e-7, group variances up to 1e-5 (the optimizers
# stop at different points on a flat REML surface); so 1e-8 on the criterion,
# 1e-6 on fixed effects and 1e-4 on variances.  In the singular %REF2 fit the
# a:b slope variance differs by 9e-5, so it is held to 1e-3.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(lmer);

my %D = (
	a => ['a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a1', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a2', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a3', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4', 'a4'],
	b => ['b1', 'b1', 'b1', 'b1', 'b1', 'b1', 'b2', 'b2', 'b2', 'b2', 'b2', 'b2', 'b3', 'b3', 'b3', 'b3', 'b3', 'b3', 'b1', 'b1', 'b1', 'b1', 'b1', 'b1', 'b2', 'b2', 'b2', 'b2', 'b2', 'b2', 'b3', 'b3', 'b3', 'b3', 'b3', 'b3', 'b1', 'b1', 'b1', 'b1', 'b1', 'b1', 'b2', 'b2', 'b2', 'b2', 'b2', 'b2', 'b3', 'b3', 'b3', 'b3', 'b3', 'b3', 'b1', 'b1', 'b1', 'b1', 'b1', 'b1', 'b2', 'b2', 'b2', 'b2', 'b2', 'b2', 'b3', 'b3', 'b3', 'b3', 'b3', 'b3'],
	c => ['c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2', 'c1', 'c1', 'c1', 'c2', 'c2', 'c2'],
	x => [0.27725, 0.00051800000000000001, 0.51060799999999995, 0.014048, 0.064689999999999998, 0.95484899999999995, 0.086496000000000003, 0.28997499999999998, 0.88069900000000001, 0.12321600000000001, 0.17511299999999999, 0.44074999999999998, 0.90718299999999996, 0.85104199999999997, 0.73398699999999995, 0.57368600000000003, 0.48176600000000003, 0.33061099999999999, 0.15765999999999999, 0.48013400000000001, 0.20371300000000001, 0.68036700000000006, 0.363788, 0.35034799999999999, 0.061988000000000001, 0.483018, 0.39914300000000003, 0.016215, 0.125083, 0.39814899999999998, 0.50491799999999998, 0.327679, 0.41177999999999998, 0.20241300000000001, 0.81266799999999995, 0.64203200000000005, 0.27687299999999998, 0.103556, 0.25600299999999998, 0.057859000000000001, 0.24745600000000001, 0.21501100000000001, 0.493674, 0.65344599999999997, 0.32902599999999999, 0.86388799999999999, 0.63778999999999997, 0.013781, 0.529165, 0.83436299999999997, 0.50285599999999997, 0.59776099999999999, 0.425595, 0.31220500000000001, 0.22192700000000001, 0.44342599999999999, 0.412524, 0.81570299999999996, 0.162659, 0.59698300000000004, 0.13473499999999999, 0.752363, 0.17408399999999999, 0.57983300000000004, 0.75131199999999998, 0.18279799999999999, 0.057341000000000003, 0.49848799999999999, 0.192167, 0.61973500000000004, 0.68604699999999996, 0.42554799999999998],
	y => [6.2203460000000002, 6.8086029999999997, 6.308287, 8.1025150000000004, 7.7374609999999997, 9.8980490000000003, 9.3849699999999991, 9.490024, 13.840666000000001, 9.8442980000000002, 9.2534569999999992, 11.589043999999999, 11.769895, 11.004916, 13.479165999999999, 11.523809, 13.306103999999999, 11.522368999999999, 14.098271, 13.877533, 15.003814999999999, 12.062732, 13.982836000000001, 11.940666999999999, 13.25948, 14.786848000000001, 14.972239999999999, 16.678267999999999, 14.946301, 18.147801999999999, 13.953322, 12.102857, 14.547307999999999, 12.153832, 13.09291, 13.529764, 7.037191, 3.9439860000000002, 6.4686219999999999, 6.7832359999999996, 7.2679150000000003, 7.9254819999999997, 10.262333, 10.718375999999999, 12.426933, 10.109854, 11.509036, 9.7607920000000004, 10.110861999999999, 12.335115999999999, 11.549669, 12.398421000000001, 12.747597000000001, 10.367940000000001, 10.392993000000001, 9.7793949999999992, 11.2422, 10.059805000000001, 9.3188300000000002, 10.626645999999999, 9.6464029999999994, 8.9726180000000006, 9.7878310000000006, 12.157830000000001, 10.664058000000001, 11.627338999999999, 8.655132, 10.783474, 10.352096, 10.614100000000001, 10.877192000000001, 11.982707],
);
my %REF = (
	fixef => [10.314904180877196, 1.7978097025423296],
	se => [1.0658092168309885, 0.57356007542054643],
	var_names => ['gc:gb:ga', 'gb:ga', 'ga', 'Residual'],
	var => [0.604876309840085, 2.4987703586313996, 3.3297617680272569, 1.1026492002419785],
	REML => [257.72502126938087],
);
my %REF2 = (
	fixef => [10.37950909176976, 1.6463345257833448],
	var_names => ['gb.ga x', 'gb.ga.1 (Intercept)', 'ga x', 'ga.1 (Intercept)', 'Residual NA'],
	var => [0.32205022998847727, 2.7889888974783998, 7.9117927180108868e-09, 3.3832807843989205, 1.4418933679001751],
	REML => [263.02134621000801],
);

sub rel_ok {
	my ($got, $want, $tol, $name) = @_;
	my $r = abs($got - $want) / abs($want);
	ok($r <= $tol, $name) or diag("got $got, want $want: relative $r > $tol");
}
my %data = (y => $D{y}, x => $D{x}, ga => $D{a}, gb => $D{b}, gc => $D{c});

my $nest = lmer(formula => 'y ~ x + (1 | ga/gb/gc)', data => \%data);
my $expl = lmer(formula => 'y ~ x + (1 | ga) + (1 | ga:gb) + (1 | ga:gb:gc)', data => \%data);
is_deeply([map { "$_->{group}:$_->{levels}" } @{ $nest->{varcor} }], ['ga:4', 'ga:gb:12', 'ga:gb:gc:24'],
          'a/b/c gives one term per cumulative prefix');
is($nest->{REML}, $expl->{REML}, 'the same REML criterion as the explicit terms, bit for bit');
is_deeply($nest->{coefficients}, $expl->{coefficients}, 'and the same coefficients');
is_deeply($nest->{varcor}, $expl->{varcor}, 'and the same variance components');

rel_ok($nest->{coefficients}{Intercept}, $REF{fixef}[0], 1e-6, 'lme4 intercept');
rel_ok($nest->{coefficients}{x}, $REF{fixef}[1], 1e-6, 'lme4 slope');
rel_ok($nest->{summary}{x}{'Std. Error'}, $REF{se}[1], 1e-6, 'lme4 slope SE');
rel_ok($nest->{REML}, $REF{REML}[0], 1e-8, 'lme4 REML criterion');
my %sd = map { $_->{group} => $_->{sd}{Intercept} } @{ $nest->{varcor} };
rel_ok($sd{'ga:gb:gc'}**2, $REF{var}[0], 1e-4, 'variance of a:b:c');
rel_ok($sd{'ga:gb'}**2, $REF{var}[1], 1e-4, 'variance of a:b');
rel_ok($sd{ga}**2, $REF{var}[2], 1e-4, 'variance of a');
rel_ok($nest->{sigma}**2, $REF{var}[3], 1e-4, 'residual variance');

# the prefixes of a nesting whose first factor is itself an interaction
my $inter = lmer(formula => 'y ~ x + (1 | ga:gb/gc)', data => \%data);
is_deeply([map { $_->{group} } @{ $inter->{varcor} }], ['ga:gb', 'ga:gb:gc'], '(1 | a:b/c) is a:b and a:b:c');

# random slopes through a nesting
my $sl = lmer(formula => 'y ~ x + (x || ga/gb)', data => \%data);
rel_ok($sl->{REML}, $REF2{REML}[0], 1e-8, 'lme4 REML criterion, (x || a/b)');
rel_ok($sl->{coefficients}{x}, $REF2{fixef}[1], 1e-5, 'slope, (x || a/b)');
my ($ab) = grep { $_->{group} eq 'ga:gb' } @{ $sl->{varcor} };
rel_ok($ab->{sd}{x}**2, $REF2{var}[0], 1e-3, 'slope variance within a:b');
my $sl3 = lmer(formula => 'y ~ x + (x | ga/gb/gc)', data => \%data);
is(scalar(@{ $sl3->{varcor} }), 3, '(x | a/b/c) is three terms with slopes');

eval { lmer(formula => 'y ~ x + (1 | ga/gb/)', data => \%data) };
like($@, qr/empty grouping factor/, 'a trailing slash is refused');

done_testing();
