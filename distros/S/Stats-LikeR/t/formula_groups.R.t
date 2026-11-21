#!/usr/bin/env perl
# A parenthesised group of terms in a formula, through every function that
# reads one: lm, glm, aov, anova, zerotrunc, hurdle, svyglm, ivreg, lmer,
# coxph and vif.  Through 0.3425 `y ~ (a + b)*c` and `y ~ (a + b + c)^2` died
# with "cannot evaluate term" (until 0.3419, with "0 degrees of freedom"), and
# car's own vif() example, (income + education)*type, had to be written out as
# its expansion.  lm_formula_terms() in LikeR.xs is now R's formula algebra,
# terms.formula() of R 4.6.1 (src/library/stats/src/model.c, EncodeVars() and
# the Plus/Interact/Cross/Power/In/Nest/DeleteTerms() it calls).
#
# PROVENANCE
#
# t/formula_groups.R.R, committed beside this file, generated every literal
# below, under R 4.6.1 (2026-06-24), lme4 2.0-6, survival 3.8-12, survey 4.5,
# ivreg 0.6-8, pscl 1.5.9, countreg 0.3-0 and car 3.1-5, at options(digits =
# 17).  Re-run it with
#     Rscript t/formula_groups.R.R
# and paste each "== name" section over the one of the same name here.  This
# test never invokes R; it reads the frozen literals.
#
# The formulas are the forms R documents and tests:
#   R 4.6.1 src/library/stats/man/formula.Rd: (a+b+c)^2 is (a+b+c)*(a+b+c),
#       which is a + b + c + a:b + a:c + b:c; (a+b+c)^2 - a:b is a + b + c +
#       b:c + a:c; a/b nests; %in%; and `log(y) ~ a + log(x)`
#   R 4.6.1 tests/reg-tests-2.R line 707: lm(y ~ (A + B) : (U + V) - 1), with
#       set.seed(1); y <- rnorm(18), in @REG2_CASES
#   car 3.1-5 man/vif.Rd: (income + education)*type, in t/vif.R.t
# with the others from the same grammar: groups on either side of `*` and `:`,
# nested groups, `- (a + b)` removal, a group inside `.`, function calls and
# I() as opaque variables inside a group, and factors in a group.
#
# WHAT IT PINS
#
# That each formula gives R's term labels, in R's order (by degree, then by
# appearance) and with each interaction named in R's variable order, and R's
# coefficients, on mtcars (cyl and am read as strings, so as factors), the
# first six subjects of lme4's sleepstudy and the first 70 complete rows of
# survival's lung.  @LABELS_ONLY is terms() alone, for forms a fit cannot take
# without more data than is worth freezing.
#
# Two departures from R are left standing, both in README.md: a lone term
# crossed with itself (`wt*wt`) keeps the product, tested in lm.R.scipy.t, and
# an intercept marker inside a group croaks, tested below.  Every other product
# of a group is R's: (a + b)*a is a + b + a:b, as @LABELS_ONLY has it.
#
# The reg-tests-2.R case also needed the margin rule of R's TermCode(), which
# codes a factor by contrasts when its margin lies inside any earlier term and
# not only when it is one: before 0.3426 A:V got dummy coding in
# `y ~ A:U + A:V - 1`, the very mistake the comment on that test says R 1.5.1
# made.
#
# TOLERANCES
#
# Per quantity, relative to the larger of 1 and |R's value|, from the worst
# disagreement observed on the double build (the diag() at the end reports
# them on every run) with headroom for the long-double and quadmath builds:
#   lm         1e-9  observed 6.4e-13, on the degree-3 product of four continuous columns: 1500-fold headroom
#   glm        1e-9  observed 2.8e-15
#   aov        1e-9  observed 3.3e-14, on sums of squares up to 1e3
#   svyglm     1e-9  observed 1.2e-15
#   ivreg      1e-9  observed 1.7e-14
#   coxph      1e-9  observed 1.9e-15
#   lmer       1e-6  observed 1.7e-13; the optimizer's own stopping rule, not the algebra, limits it, so t/lmer.R.t's slack is kept
#   zerotrunc  1e-3  observed 1.1e-5: R's BFGS stops short of the maximum at its default reltol (see t/zerotrunc_hurdle.R.t) and this module's Newton does not
#   hurdle     1e-3  observed 2.4e-6, for the same reason

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(lm glm aov anova zerotrunc hurdle svyglm ivreg lmer coxph vif);

my %DATA = (
	cars => {
		'mpg' => [ 21, 21, 22.800000000000001, 21.399999999999999, 18.699999999999999, 18.100000000000001, 14.300000000000001, 24.399999999999999, 22.800000000000001, 19.199999999999999, 17.800000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.4, 10.4, 14.699999999999999, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.5, 15.5, 15.199999999999999, 13.300000000000001, 19.199999999999999, 27.300000000000001, 26, 30.399999999999999, 15.800000000000001, 19.699999999999999, 15, 21.399999999999999 ],
		'wt' => [ 2.6200000000000001, 2.875, 2.3199999999999998, 3.2149999999999999, 3.4399999999999999, 3.46, 3.5699999999999998, 3.1899999999999999, 3.1499999999999999, 3.4399999999999999, 3.4399999999999999, 4.0700000000000003, 3.73, 3.7799999999999998, 5.25, 5.4240000000000004, 5.3449999999999998, 2.2000000000000002, 1.615, 1.835, 2.4649999999999999, 3.52, 3.4350000000000001, 3.8399999999999999, 3.8450000000000002, 1.9350000000000001, 2.1400000000000001, 1.5129999999999999, 3.1699999999999999, 2.77, 3.5699999999999998, 2.7799999999999998 ],
		'hp' => [ 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180, 205, 215, 230, 66, 52, 65, 97, 150, 150, 245, 175, 66, 91, 113, 264, 175, 335, 109 ],
		'disp' => [ 160, 160, 108, 258, 360, 225, 360, 146.69999999999999, 140.80000000000001, 167.59999999999999, 167.59999999999999, 275.80000000000001, 275.80000000000001, 275.80000000000001, 472, 460, 440, 78.700000000000003, 75.700000000000003, 71.099999999999994, 120.09999999999999, 318, 304, 350, 400, 79, 120.3, 95.099999999999994, 351, 145, 301, 121 ],
		'qsec' => [ 16.460000000000001, 17.02, 18.609999999999999, 19.440000000000001, 17.02, 20.219999999999999, 15.84, 20, 22.899999999999999, 18.300000000000001, 18.899999999999999, 17.399999999999999, 17.600000000000001, 18, 17.98, 17.82, 17.420000000000002, 19.469999999999999, 18.52, 19.899999999999999, 20.010000000000002, 16.870000000000001, 17.300000000000001, 15.41, 17.050000000000001, 18.899999999999999, 16.699999999999999, 16.899999999999999, 14.5, 15.5, 14.6, 18.600000000000001 ],
		'cyl' => [ 'c6', 'c6', 'c4', 'c6', 'c8', 'c6', 'c8', 'c4', 'c4', 'c6', 'c6', 'c8', 'c8', 'c8', 'c8', 'c8', 'c8', 'c4', 'c4', 'c4', 'c4', 'c8', 'c8', 'c8', 'c8', 'c4', 'c4', 'c4', 'c8', 'c6', 'c8', 'c4' ],
		'am' => [ 'm1', 'm1', 'm1', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm0', 'm1', 'm1', 'm1', 'm0', 'm0', 'm0', 'm0', 'm0', 'm1', 'm1', 'm1', 'm1', 'm1', 'm1', 'm1' ],
		'carb' => [ 4, 4, 1, 1, 2, 1, 4, 2, 2, 4, 4, 3, 3, 3, 4, 4, 4, 1, 2, 1, 1, 2, 2, 4, 2, 1, 2, 2, 4, 6, 8, 2 ],
		'gear' => [ 4, 4, 4, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3, 3, 3, 3, 4, 5, 5, 5, 5, 5, 4 ],
		'ncarb' => [ 3, 3, 0, 0, 1, 0, 3, 1, 1, 3, 3, 2, 2, 2, 3, 3, 3, 0, 1, 0, 0, 1, 1, 3, 1, 0, 1, 1, 3, 5, 7, 1 ],
		'w' => [ 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4 ],
	},
	dd => {
		'mpg' => [ 21, 21, 22.800000000000001, 21.399999999999999, 18.699999999999999, 18.100000000000001, 14.300000000000001, 24.399999999999999, 22.800000000000001, 19.199999999999999, 17.800000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.4, 10.4, 14.699999999999999, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.5, 15.5, 15.199999999999999, 13.300000000000001, 19.199999999999999, 27.300000000000001, 26, 30.399999999999999, 15.800000000000001, 19.699999999999999, 15, 21.399999999999999 ],
		'disp' => [ 160, 160, 108, 258, 360, 225, 360, 146.69999999999999, 140.80000000000001, 167.59999999999999, 167.59999999999999, 275.80000000000001, 275.80000000000001, 275.80000000000001, 472, 460, 440, 78.700000000000003, 75.700000000000003, 71.099999999999994, 120.09999999999999, 318, 304, 350, 400, 79, 120.3, 95.099999999999994, 351, 145, 301, 121 ],
		'hp' => [ 110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180, 205, 215, 230, 66, 52, 65, 97, 150, 150, 245, 175, 66, 91, 113, 264, 175, 335, 109 ],
		'wt' => [ 2.6200000000000001, 2.875, 2.3199999999999998, 3.2149999999999999, 3.4399999999999999, 3.46, 3.5699999999999998, 3.1899999999999999, 3.1499999999999999, 3.4399999999999999, 3.4399999999999999, 4.0700000000000003, 3.73, 3.7799999999999998, 5.25, 5.4240000000000004, 5.3449999999999998, 2.2000000000000002, 1.615, 1.835, 2.4649999999999999, 3.52, 3.4350000000000001, 3.8399999999999999, 3.8450000000000002, 1.9350000000000001, 2.1400000000000001, 1.5129999999999999, 3.1699999999999999, 2.77, 3.5699999999999998, 2.7799999999999998 ],
	},
	sleep => {
		'Reaction' => [ 249.56, 258.7047, 250.8006, 321.43979999999999, 356.8519, 414.69009999999997, 382.2038, 290.14859999999999, 430.58530000000002, 466.3535, 222.73390000000001, 205.26580000000001, 202.9778, 204.70699999999999, 207.71610000000001, 215.96180000000001, 213.63030000000001, 217.72720000000001, 224.29570000000001, 237.3142, 199.0539, 194.3322, 234.31999999999999, 232.8416, 229.3074, 220.4579, 235.42080000000001, 255.75110000000001, 261.01249999999999, 247.5153, 321.54259999999999, 300.40019999999998, 283.85649999999998, 285.13299999999998, 285.79730000000001, 297.58550000000002, 280.2396, 318.26130000000001, 305.34949999999998, 354.0487, 287.60789999999997, 285, 301.82060000000001, 320.11529999999999, 316.27730000000003, 293.31869999999998, 290.07499999999999, 334.8177, 293.74689999999998, 371.58109999999999, 283.8424, 289.55500000000001, 276.76929999999999, 299.80970000000002, 297.17099999999999, 338.16649999999998, 332.0265, 348.8399, 333.36000000000001, 362.0428 ],
		'Days' => [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
		'Subject' => [ '308', '308', '308', '308', '308', '308', '308', '308', '308', '308', '309', '309', '309', '309', '309', '309', '309', '309', '309', '309', '310', '310', '310', '310', '310', '310', '310', '310', '310', '310', '330', '330', '330', '330', '330', '330', '330', '330', '330', '330', '331', '331', '331', '331', '331', '331', '331', '331', '331', '331', '333', '333', '333', '333', '333', '333', '333', '333', '333', '333' ],
		'grp' => [ 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g1', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2', 'g2' ],
	},
	lung => {
		'time' => [ 306, 455, 1010, 210, 883, 1022, 310, 361, 218, 166, 170, 654, 728, 71, 567, 144, 613, 707, 61, 88, 301, 81, 624, 371, 394, 520, 574, 118, 390, 12, 473, 26, 533, 107, 53, 122, 814, 965, 93, 731, 460, 153, 433, 145, 583, 95, 303, 519, 643, 765, 735, 189, 53, 246, 689, 65, 5, 132, 687, 345, 444, 223, 175, 60, 163, 65, 208, 821, 428, 230 ],
		'status' => [ 2, 2, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 2, 2 ],
		'age' => [ 74, 68, 56, 57, 60, 74, 68, 71, 53, 61, 57, 68, 68, 60, 57, 67, 70, 63, 56, 57, 67, 49, 50, 58, 72, 70, 60, 70, 53, 74, 69, 73, 48, 60, 61, 62, 65, 66, 74, 64, 70, 73, 59, 60, 68, 76, 74, 63, 74, 50, 72, 63, 68, 58, 59, 62, 65, 57, 58, 64, 75, 48, 73, 65, 69, 68, 67, 64, 68, 67 ],
		'sex' => [ 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 2, 2, 1, 2, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 2, 1, 2, 2, 2, 1, 1, 2, 1, 1, 2, 2, 1, 1 ],
		'ph.karno' => [ 90, 90, 90, 90, 100, 50, 70, 60, 70, 70, 80, 70, 90, 60, 80, 80, 90, 50, 60, 90, 80, 100, 70, 90, 90, 90, 100, 60, 80, 70, 90, 60, 60, 50, 70, 50, 70, 70, 50, 80, 80, 60, 90, 70, 60, 60, 90, 80, 90, 90, 90, 80, 90, 100, 90, 90, 100, 70, 80, 90, 70, 90, 80, 90, 80, 70, 70, 90, 100, 80 ],
	},
	reg2 => {
		'y' => [ -0.62645381074233242, 0.18364332422208224, -0.83562861241004716, 1.5952808021377916, 0.32950777181536051, -0.82046838411801526, 0.48742905242848528, 0.73832470512921733, 0.57578135165349231, -0.30538838715635602, 1.511781168450848, 0.38984323641143109, -0.62124058054180376, -2.2146998871774999, 1.1249309181431082, -0.044933609015230851, -0.016190263098946087, 0.94383621068529922 ],
		'A' => [ 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 ],
		'B' => [ 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0 ],
		'U' => [ 'a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b', 'c', 'c', 'c', 'c', 'c', 'c' ],
		'V' => [ 'a', 'a', 'b', 'b', 'c', 'c', 'a', 'a', 'b', 'b', 'c', 'c', 'a', 'a', 'b', 'b', 'c', 'c' ],
	},
);

my @LM_CASES = (
	[ 'mpg ~ (wt + hp)*disp', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'Intercept', 45.358918042930298 ], [ 'wt', -4.581342207538972 ], [ 'hp', -0.074421361680738068 ], [ 'disp', -0.045919667637153896 ], [ 'wt:disp', 0.0040709986126482439 ], [ 'hp:disp', 0.00018673809044036097 ] ],
	[ 'mpg ~ wt*(hp + disp)', [ 'wt', 'hp', 'disp', 'wt:hp', 'wt:disp' ], [ 'Intercept', 49.988882326082255 ], [ 'wt', -8.1432271512520895 ], [ 'hp', -0.13190073903659916 ], [ 'disp', 0.0028469309917071445 ], [ 'wt:hp', 0.031829561229770924 ], [ 'wt:disp', -0.0016443616098025424 ] ],
	[ 'mpg ~ (wt + hp):disp', [ 'wt:disp', 'hp:disp' ], [ 'Intercept', 26.363540925690778 ], [ 'wt:disp', -0.0039836841494390006 ], [ 'hp:disp', -7.1869237764987819e-05 ] ],
	[ 'mpg ~ (wt + hp + disp)^2', [ 'wt', 'hp', 'disp', 'wt:hp', 'wt:disp', 'hp:disp' ], [ 'Intercept', 48.255824659438076 ], [ 'wt', -6.2016994373144172 ], [ 'hp', -0.11934111829344976 ], [ 'disp', -0.019865109222784123 ], [ 'wt:hp', 0.018197906849763665 ], [ 'wt:disp', -0.00057427292877763349 ], [ 'hp:disp', 0.00012378451364582685 ] ],
	[ 'mpg ~ (wt + hp + disp + qsec)^3', [ 'wt', 'hp', 'disp', 'qsec', 'wt:hp', 'wt:disp', 'wt:qsec', 'hp:disp', 'hp:qsec', 'disp:qsec', 'wt:hp:disp', 'wt:hp:qsec', 'wt:disp:qsec', 'hp:disp:qsec' ], [ 'Intercept', 15.225707582395508 ], [ 'wt', -13.070226576677605 ], [ 'hp', 1.9221945463497654 ], [ 'disp', -1.2286921676492939 ], [ 'qsec', 2.1814516917756723 ], [ 'wt:hp', -0.42676396989276694 ], [ 'wt:disp', 0.39447382989071111 ], [ 'wt:qsec', 0.33183172510552317 ], [ 'hp:disp', -0.0012287974908391053 ], [ 'hp:qsec', -0.11802211185207499 ], [ 'disp:qsec', 0.064095340585692551 ], [ 'wt:hp:disp', -9.8238049202642507e-05 ], [ 'wt:hp:qsec', 0.025427896846860257 ], [ 'wt:disp:qsec', -0.021413254100679135 ], [ 'hp:disp:qsec', 0.00010557616603676277 ] ],
	[ 'mpg ~ (wt + hp + disp)^2 - wt:hp', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'Intercept', 45.358918042930298 ], [ 'wt', -4.581342207538972 ], [ 'hp', -0.074421361680738068 ], [ 'disp', -0.045919667637153896 ], [ 'wt:disp', 0.0040709986126482439 ], [ 'hp:disp', 0.00018673809044036097 ] ],
	[ 'mpg ~ (wt + hp + disp)^2 - (wt:hp + hp:disp)', [ 'wt', 'hp', 'disp', 'wt:disp' ], [ 'Intercept', 44.29408250932557 ], [ 'wt', -6.3548509634628507 ], [ 'hp', -0.023028756763856999 ], [ 'disp', -0.038133228546868736 ], [ 'wt:disp', 0.0099430637428069447 ] ],
	[ 'mpg ~ (wt + hp)^3', [ 'wt', 'hp', 'wt:hp' ], [ 'Intercept', 49.808423428760278 ], [ 'wt', -8.2166242972436088 ], [ 'hp', -0.1201020909780231 ], [ 'wt:hp', 0.0278481483187412 ] ],
	[ 'mpg ~ (wt + hp)/disp', [ 'wt', 'hp', 'wt:hp:disp' ], [ 'Intercept', 44.005921562532293 ], [ 'wt', -5.9820605668536828 ], [ 'hp', -0.055307735189383631 ], [ 'wt:hp:disp', 2.2099048432836612e-05 ] ],
	[ 'mpg ~ wt/(hp + disp)', [ 'wt', 'wt:hp', 'wt:disp' ], [ 'Intercept', 37.934258330705845 ], [ 'wt', -5.1170280823274004 ], [ 'wt:hp', -0.0093988956127884597 ], [ 'wt:disp', 0.004083504298433311 ] ],
	[ 'mpg ~ wt/hp/disp', [ 'wt', 'wt:hp', 'wt:hp:disp' ], [ 'Intercept', 38.577471066444609 ], [ 'wt', -4.2406247395986192 ], [ 'wt:hp', -0.019367800206786717 ], [ 'wt:hp:disp', 3.2895472379111192e-05 ] ],
	[ 'mpg ~ wt + hp %in% wt', [ 'wt', 'wt:hp' ], [ 'Intercept', 34.297354271690502 ], [ 'wt', -3.3710518946003223 ], [ 'wt:hp', -0.0065298976259711046 ] ],
	[ 'mpg ~ (wt + hp) %in% disp', [ 'wt:disp', 'hp:disp' ], [ 'Intercept', 26.363540925690778 ], [ 'wt:disp', -0.0039836841494390006 ], [ 'hp:disp', -7.1869237764987819e-05 ] ],
	[ 'mpg ~ wt*hp - (wt + hp)', [ 'wt:hp' ], [ 'Intercept', 27.745642157373901 ], [ 'wt:hp', -0.014871561204203092 ] ],
	[ 'mpg ~ wt + hp + disp - (hp + disp)', [ 'wt' ], [ 'Intercept', 37.285126167342028 ], [ 'wt', -5.3444715727226786 ] ],
	[ 'mpg ~ wt*hp*disp - wt:hp - hp:disp', [ 'wt', 'hp', 'disp', 'wt:disp', 'wt:hp:disp' ], [ 'Intercept', 43.056203778388024 ], [ 'wt', -4.3014082769304327 ], [ 'hp', -0.067157868558598746 ], [ 'disp', -0.0046784101364928934 ], [ 'wt:disp', -0.0063083644944708622 ], [ 'wt:hp:disp', 4.5851265567008947e-05 ] ],
	[ 'mpg ~ ((wt + hp) + disp)^2', [ 'wt', 'hp', 'disp', 'wt:hp', 'wt:disp', 'hp:disp' ], [ 'Intercept', 48.255824659438076 ], [ 'wt', -6.2016994373144172 ], [ 'hp', -0.11934111829344976 ], [ 'disp', -0.019865109222784123 ], [ 'wt:hp', 0.018197906849763665 ], [ 'wt:disp', -0.00057427292877763349 ], [ 'hp:disp', 0.00012378451364582685 ] ],
	[ 'mpg ~ wt + (hp + disp)*qsec', [ 'wt', 'hp', 'disp', 'qsec', 'hp:qsec', 'disp:qsec' ], [ 'Intercept', 18.125555642709966 ], [ 'wt', -3.7856057286513423 ], [ 'hp', 0.049280668712589945 ], [ 'disp', 0.020713754414077173 ], [ 'qsec', 1.0554295430725331 ], [ 'hp:qsec', -0.0050242996733461491 ], [ 'disp:qsec', -0.00098620823219930007 ] ],
	[ 'mpg ~ (wt + hp)*(disp + qsec)', [ 'wt', 'hp', 'disp', 'qsec', 'wt:disp', 'wt:qsec', 'hp:disp', 'hp:qsec' ], [ 'Intercept', 6.3526021105899595 ], [ 'wt', 0.39131180315412462 ], [ 'hp', 0.074594153591924547 ], [ 'disp', -0.033518162842133194 ], [ 'qsec', 2.1140321841701186 ], [ 'wt:disp', 0.0098952505557069054 ], [ 'wt:qsec', -0.36904256196663165 ], [ 'hp:disp', 6.3807646860175768e-07 ], [ 'hp:qsec', -0.0062281431769383331 ] ],
	[ 'mpg ~ (wt + hp):(disp + qsec)', [ 'wt:disp', 'wt:qsec', 'hp:disp', 'hp:qsec' ], [ 'Intercept', 38.011335846550246 ], [ 'wt:disp', -0.0022385644661883615 ], [ 'wt:qsec', -0.09968476546555817 ], [ 'hp:disp', 7.2463895663267403e-05 ], [ 'hp:qsec', -0.0052306020534474392 ] ],
	[ 'mpg ~ (wt + hp) + (disp + qsec):hp', [ 'wt', 'hp', 'hp:disp', 'hp:qsec' ], [ 'Intercept', 41.776874597961779 ], [ 'wt', -5.4268421643808429 ], [ 'hp', -0.090203150100858207 ], [ 'hp:disp', 9.4713804905263398e-05 ], [ 'hp:qsec', 0.002045176970286468 ] ],
	[ 'mpg ~ (log(wt) + I(hp^2))*disp', [ 'log(wt)', 'I(hp^2)', 'disp', 'log(wt):disp', 'I(hp^2):disp' ], [ 'Intercept', 39.668117940378664 ], [ 'log(wt)', -11.854476318244394 ], [ 'I(hp^2)', -0.00022158775604383805 ], [ 'disp', -0.027427615157259843 ], [ 'log(wt):disp', 0.0034215367713877464 ], [ 'I(hp^2):disp', 6.009558368081024e-07 ] ],
	[ 'mpg ~ (log(wt + 1) + hp)^2', [ 'log(wt + 1)', 'hp', 'log(wt + 1):hp' ], [ 'Intercept', 62.383955715081221 ], [ 'log(wt + 1)', -27.206163913034409 ], [ 'hp', -0.13644177058819359 ], [ 'log(wt + 1):hp', 0.074248001294014834 ] ],
	[ 'mpg ~ (wt + I(hp/disp))*qsec', [ 'wt', 'I(hp/disp)', 'qsec', 'wt:qsec', 'I(hp/disp):qsec' ], [ 'Intercept', -7.9767768336071985 ], [ 'wt', 4.7248225293619903 ], [ 'I(hp/disp)', -4.1711818797546698 ], [ 'qsec', 2.4284449792369576 ], [ 'wt:qsec', -0.54139218602731654 ], [ 'I(hp/disp):qsec', 0.27168951821409321 ] ],
	[ 'mpg ~ (cyl + wt)*hp', [ 'cyl', 'wt', 'hp', 'cyl:hp', 'wt:hp' ], [ 'Intercept', 48.100152100964699 ], [ 'cylc6', -6.5937783159556558 ], [ 'cylc8', -7.1102914287615615 ], [ 'wt', -6.1562863388414852 ], [ 'hp', -0.13008783269861651 ], [ 'cylc6:hp', 0.054016895118669001 ], [ 'cylc8:hp', 0.052946129902200066 ], [ 'wt:hp', 0.017758426923225074 ] ],
	[ 'mpg ~ (cyl + am)^2', [ 'cyl', 'am', 'cyl:am' ], [ 'Intercept', 22.899999999999995 ], [ 'cylc6', -3.7749999999999972 ], [ 'cylc8', -7.8499999999999952 ], [ 'amm1', 5.1750000000000043 ], [ 'cylc6:amm1', -3.7333333333333516 ], [ 'cylc8:amm1', -4.8250000000000011 ] ],
	[ 'mpg ~ cyl*(wt + am)', [ 'cyl', 'wt', 'am', 'cyl:wt', 'cyl:am' ], [ 'Intercept', 38.966499469973485 ], [ 'cylc6', 5.6484592147530481 ], [ 'cylc8', -13.928997964027884 ], [ 'wt', -5.4741054412175423 ], [ 'amm1', 0.28799236735303768 ], [ 'cylc6:wt', -2.0478299876947537 ], [ 'cylc8:wt', 3.0405531239857777 ], [ 'cylc6:amm1', -3.6133522787595673 ], [ 'cylc8:amm1', -1.7244225642275877 ] ],
	[ 'mpg ~ hp + wt:hp', [ 'hp', 'hp:wt' ], [ 'Intercept', 27.47510874498608 ], [ 'hp', 0.0053320955169951561 ], [ 'hp:wt', -0.015865492821909449 ] ],
	[ 'mpg ~ wt:hp + hp', [ 'hp', 'wt:hp' ], [ 'Intercept', 27.47510874498608 ], [ 'hp', 0.0053320955169951561 ], [ 'wt:hp', -0.015865492821909449 ] ],
	[ 'mpg ~ (wt + hp)*disp - 1', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'wt', 8.5780862317442974 ], [ 'hp', 0.030608398663238771 ], [ 'disp', 0.051361732075296158 ], [ 'wt:disp', -0.020718074039200136 ], [ 'hp:disp', -0.00017698343779262325 ] ],
	[ 'mpg ~ -1 + (wt + hp)*disp', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'wt', 8.5780862317442974 ], [ 'hp', 0.030608398663238771 ], [ 'disp', 0.051361732075296158 ], [ 'wt:disp', -0.020718074039200136 ], [ 'hp:disp', -0.00017698343779262325 ] ],
	[ 'mpg ~ (wt + hp)*disp + 0', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'wt', 8.5780862317442974 ], [ 'hp', 0.030608398663238771 ], [ 'disp', 0.051361732075296158 ], [ 'wt:disp', -0.020718074039200136 ], [ 'hp:disp', -0.00017698343779262325 ] ],
	[ 'mpg ~ (wt)', [ 'wt' ], [ 'Intercept', 37.285126167342028 ], [ 'wt', -5.3444715727226786 ] ],
	[ 'mpg ~ ((wt)) + (hp)', [ 'wt', 'hp' ], [ 'Intercept', 37.227270116447201 ], [ 'wt', -3.8778307424046821 ], [ 'hp', -0.031772946982161002 ] ],
	[ 'mpg ~ +wt + hp', [ 'wt', 'hp' ], [ 'Intercept', 37.227270116447201 ], [ 'wt', -3.8778307424046821 ], [ 'hp', -0.031772946982161002 ] ],
	[ 'mpg ~ (wt + hp)^2.9', [ 'wt', 'hp', 'wt:hp' ], [ 'Intercept', 49.808423428760278 ], [ 'wt', -8.2166242972436088 ], [ 'hp', -0.1201020909780231 ], [ 'wt:hp', 0.0278481483187412 ] ],
	[ 'mpg ~ wt^2 + hp', [ 'wt', 'hp' ], [ 'Intercept', 37.227270116447201 ], [ 'wt', -3.8778307424046821 ], [ 'hp', -0.031772946982161002 ] ],
	[ 'mpg ~ (wt + hp)*disp - 0', [ 'wt', 'hp', 'disp', 'wt:disp', 'hp:disp' ], [ 'Intercept', 45.358918042930298 ], [ 'wt', -4.581342207538972 ], [ 'hp', -0.074421361680738068 ], [ 'disp', -0.045919667637153896 ], [ 'wt:disp', 0.0040709986126482439 ], [ 'hp:disp', 0.00018673809044036097 ] ],
	[ 'mpg ~ log(wt + hp)*disp', [ 'log(wt + hp)', 'disp', 'log(wt + hp):disp' ], [ 'Intercept', 81.966246462182895 ], [ 'log(wt + hp)', -11.497160911988562 ], [ 'disp', -0.18881232075610208 ], [ 'log(wt + hp):disp', 0.03231449715063868 ] ],
);

my @DOT_CASES = (
	[ 'mpg ~ (.)^2', [ 'disp', 'hp', 'wt', 'disp:hp', 'disp:wt', 'hp:wt' ], [ 'Intercept', 48.255824659438055 ], [ 'disp', -0.019865109222784168 ], [ 'hp', -0.11934111829344957 ], [ 'wt', -6.2016994373144172 ], [ 'disp:hp', 0.00012378451364582674 ], [ 'disp:wt', -0.0005742729287776194 ], [ 'hp:wt', 0.018197906849763641 ] ],
	[ 'mpg ~ .^2', [ 'disp', 'hp', 'wt', 'disp:hp', 'disp:wt', 'hp:wt' ], [ 'Intercept', 48.255824659438055 ], [ 'disp', -0.019865109222784168 ], [ 'hp', -0.11934111829344957 ], [ 'wt', -6.2016994373144172 ], [ 'disp:hp', 0.00012378451364582674 ], [ 'disp:wt', -0.0005742729287776194 ], [ 'hp:wt', 0.018197906849763641 ] ],
	[ 'mpg ~ (. - hp)^2', [ 'disp', 'wt', 'disp:wt' ], [ 'Intercept', 44.081997696204205 ], [ 'disp', -0.056358157751331558 ], [ 'wt', -6.4956796578135467 ], [ 'disp:wt', 0.01170541798893465 ] ],
	[ 'mpg ~ . - (hp + wt) + hp:wt', [ 'disp', 'hp:wt' ], [ 'Intercept', 29.151904926494684 ], [ 'disp', -0.022562827754259589 ], [ 'hp:wt', -0.0074902417166850125 ] ],
	[ 'mpg ~ (.)*disp', [ 'disp', 'hp', 'wt', 'disp:hp', 'disp:wt' ], [ 'Intercept', 45.358918042930284 ], [ 'disp', -0.045919667637153841 ], [ 'hp', -0.074421361680737971 ], [ 'wt', -4.5813422075389756 ], [ 'disp:hp', 0.00018673809044036067 ], [ 'disp:wt', 0.0040709986126482509 ] ],
);

my @GLM_CASES = (
	[ 'carb ~ (wt + hp)*disp', 'poisson', [ 'Intercept', -0.57631087670908565 ], [ 'wt', 0.14153689673249176 ], [ 'hp', 0.014226812965587983 ], [ 'disp', -0.0030031229787212234 ], [ 'wt:disp', 0.00073031804991121338 ], [ 'hp:disp', -2.3606375583166859e-05 ] ],
	[ 'carb ~ (wt + hp)*cyl', 'poisson', [ 'Intercept', -0.11585655340114223 ], [ 'wt', 0.11465220823266192 ], [ 'hp', 0.0034388116021280149 ], [ 'cylc6', 1.5460563958021347 ], [ 'cylc8', -0.6995608462629973 ], [ 'wt:cylc6', -0.60055486939605707 ], [ 'wt:cylc8', 0.0071931223266444941 ], [ 'hp:cylc6', 0.006850325990861811 ], [ 'hp:cylc8', 0.0037747103809223572 ] ],
	[ 'mpg ~ (wt + hp)^2', 'gaussian', [ 'Intercept', 49.808423428760278 ], [ 'wt', -8.2166242972436088 ], [ 'hp', -0.1201020909780231 ], [ 'wt:hp', 0.0278481483187412 ] ],
);

my @AOV_CASES = (
	[ 'mpg ~ (cyl + am)^2', [ 'cyl', 2, 824.78459009740209, 44.851656687219965 ], [ 'am', 1, 36.766919492544375, 3.9987586342550663 ], [ 'cyl:am', 2, 25.436511243386324, 1.3832334930921106 ], 26, 239.05916666666656 ],
	[ 'mpg ~ cyl*(wt + am)', [ 'cyl', 2, 824.78459009740209, 62.865484068102923 ], [ 'wt', 1, 118.20394973421948, 18.019125497788128 ], [ 'am', 1, 0.090314155832152854, 0.013767578087073316 ], [ 'cyl:wt', 2, 29.258017532183352, 2.2300603783304633 ], [ 'cyl:am', 2, 2.8322478842844623, 0.21587531627546094 ], 23, 150.87806809607775 ],
	[ 'mpg ~ (wt + hp)*disp', [ 'wt', 1, 847.72524995665708, 172.64111689877925 ], [ 'hp', 1, 83.274182801877146, 16.958970997365284 ], [ 'disp', 1, 0.057080020909940722, 0.011624472154158058 ], [ 'wt:disp', 1, 52.715491334475786, 10.735626079696377 ], [ 'hp:disp', 1, 14.606543986604366, 2.9746548991049351 ], 26, 127.66863939947631 ],
	[ 'mpg ~ (cyl + am + wt)^2 - cyl:am', [ 'cyl', 2, 824.78459009740209, 72.408703147524264 ], [ 'am', 1, 36.766919492544375, 6.4556127530708931 ], [ 'wt', 1, 81.527344397507306, 14.314741933255419 ], [ 'cyl:wt', 2, 29.258017532183331, 2.5685920076692232 ], [ 'am:wt', 1, 17.022118968961504, 2.9887793107769354 ], 24, 136.68819701140069 ],
);

my @ZT_CASES = (
	[ 'carb ~ (wt + hp)*cyl', 'poisson', [ 'Intercept', -1.5102255807432121 ], [ 'wt', 0.29035975861902102 ], [ 'hp', 0.0090740773114943701 ], [ 'cylc6', 3.0643130523363671 ], [ 'cylc8', 0.28304726257923651 ], [ 'wt:cylc6', -0.86522140654302249 ], [ 'wt:cylc8', -0.13335516392575447 ], [ 'hp:cylc6', 0.0019234172182476638 ], [ 'hp:cylc8', -0.00092162494561442423 ] ],
	[ 'carb ~ (wt + hp)^2', 'poisson', [ 'Intercept', -1.4269238149580077 ], [ 'wt', 0.42073165344160374 ], [ 'hp', 0.013249725570862396 ], [ 'wt:hp', -0.0021000986443751521 ] ],
);

my @HURDLE_CASES = (
	[ 'ncarb ~ (wt + hp)*am | wt + hp', [ [ 'count_(Intercept)', -1.7168313615030391 ], [ 'count_wt', 0.22719039348625267 ], [ 'count_hp', 0.0070814791413536006 ], [ 'count_amm1', -2.0937285447159071 ], [ 'count_wt:amm1', 1.4908723362868475 ], [ 'count_hp:amm1', -0.0081374756516601216 ] ], [ [ 'zero_(Intercept)', -3.1039819135773516 ], [ 'zero_wt', -0.075239096245343251 ], [ 'zero_hp', 0.040400294258261901 ] ] ],
	[ 'ncarb ~ (wt + hp)^2 | (wt + hp)^2', [ [ 'count_(Intercept)', -1.7805542949432234 ], [ 'count_wt', 0.31364067908963955 ], [ 'count_hp', 0.013163060984266534 ], [ 'count_wt:hp', -0.0016011610026504084 ] ], [ [ 'zero_(Intercept)', -1.1338822140233369 ], [ 'zero_wt', -0.78582674527617113 ], [ 'zero_hp', 0.018983866157274595 ], [ 'zero_wt:hp', 0.0074085582302184502 ] ] ],
);

my @SVYGLM_CASES = (
	[ 'mpg ~ (wt + hp)*am', 'gaussian', [ 'Intercept', 32.423473285442341 ], [ 'wt', -2.2441707015988031 ], [ 'hp', -0.043910775235416623 ], [ 'amm1', 11.942876763290386 ], [ 'wt:amm1', -5.3306386529722065 ], [ 'hp:amm1', 0.031970827104480022 ] ],
	[ 'carb ~ (wt + hp)^2', 'poisson', [ 'Intercept', -0.41516070825371704 ], [ 'wt', 0.17997351629748407 ], [ 'hp', 0.0087183036890762337 ], [ 'wt:hp', -0.00095930145783027431 ] ],
);

my @IVREG_CASES = (
	[ 'mpg ~ (wt + hp)*am | (qsec + disp + hp)*am', [ 'Intercept', 29.834768137226686 ], [ 'wt', -1.460458723298111 ], [ 'hp', -0.04482056022681534 ], [ 'amm1', 14.015864285751613 ], [ 'wt:amm1', -5.8054073365884875 ], [ 'hp:amm1', 0.029523906749742979 ] ],
	[ 'mpg ~ (wt + hp)^2 | (qsec + disp + hp)^2', [ 'Intercept', 49.689306885550039 ], [ 'wt', -8.1813268360600198 ], [ 'hp', -0.11891347988304234 ], [ 'wt:hp', 0.027520219756903129 ] ],
);

my @LMER_CASES = (
	[ 'Reaction ~ (Days + grp)^2 + (1 | Subject)', [ 'Intercept', 217.577279999994 ], [ 'Days', 10.047128888888995 ], [ 'grpg2', 65.903774545462923 ], [ 'Days:grpg2', -4.2417498989900642 ] ],
	[ 'Reaction ~ (Days + I(Days^2))*grp + (1 | Subject)', [ 'Intercept', 218.80729818180941 ], [ 'Days', 9.1246152525258406 ], [ 'I(Days^2)', 0.1025015151514698 ], [ 'grpg2', 78.29479272728355 ], [ 'Days:grpg2', -13.53501353535469 ], [ 'I(Days^2):grpg2', 1.0325848484849489 ] ],
);

my @COXPH_CASES = (
	[ 'Surv(time, status) ~ (age + sex)*ph.karno', [ 'age', -0.061284360604222536 ], [ 'sex', 2.2109313494740386 ], [ 'ph.karno', -0.023358363132975471 ], [ 'age:ph.karno', 0.00083176913383254671 ], [ 'sex:ph.karno', -0.030867790644192625 ] ],
	[ 'Surv(time, status) ~ (age + sex + ph.karno)^2', [ 'age', -0.030410049885491675 ], [ 'sex', 4.6970536135034351 ], [ 'ph.karno', -0.030274160469400124 ], [ 'age:sex', -0.034636997986408624 ], [ 'age:ph.karno', 0.00099066011180331333 ], [ 'sex:ph.karno', -0.033998079541052217 ] ],
);

my @REG2_CASES = (
	[ 'y ~ (A + B) : (U + V) - 1', [ 'A:U', 'A:V', 'B:U', 'B:V' ], [ 'A:Ua', -0.16314070643019368 ], [ 'A:Ub', -0.20836610238271572 ], [ 'A:Uc', -0.92122504901329039 ], [ 'A:Vb', 0.8458968879308012 ], [ 'A:Vc', 0.60198097360163816 ], [ 'B:Ua', -0.84538188514179702 ], [ 'B:Ub', 0.39047352281481812 ], [ 'B:Uc', -0.30535697652867139 ], [ 'B:Vb', 0.5417829987474011 ], [ 'B:Vc', 0.86178800534097111 ] ],
);

my @LABELS_ONLY = (
	[ 'y ~ (a + b + c)^2', [ 'a', 'b', 'c', 'a:b', 'a:c', 'b:c' ] ],
	[ 'y ~ (a + b + c)^2 - a:b', [ 'a', 'b', 'c', 'a:c', 'b:c' ] ],
	[ 'y ~ a + b + c + b:c + a:c', [ 'a', 'b', 'c', 'b:c', 'a:c' ] ],
	[ 'y ~ (a + b + c)*(a + b + c)', [ 'a', 'b', 'c', 'a:b', 'a:c', 'b:c' ] ],
	[ 'y ~ (a + b)*a', [ 'a', 'b', 'a:b' ] ],
	[ 'y ~ a %in% b', [ 'a:b' ] ],
	[ 'y ~ a:b:c %in% d', [ 'a:b:c:d' ] ],
	[ 'y ~ a*b %in% c', [ 'a', 'b:c', 'a:b:c' ] ],
	[ 'y ~ a/b/c', [ 'a', 'a:b', 'a:b:c' ] ],
	[ 'y ~ (a + b)/c', [ 'a', 'b', 'a:b:c' ] ],
	[ 'y ~ (a + b)^2:c', [ 'a:c', 'b:c', 'a:b:c' ] ],
	[ 'y ~ -(a + b)', [  ] ],
	[ 'y ~ a + b + c - (a + b)', [ 'c' ] ],
	[ 'y ~ (a + b + c + d)^2 - (a + b)^2', [ 'c', 'd', 'a:c', 'a:d', 'b:c', 'b:d', 'c:d' ] ],
	[ 'y ~ a + log(x) + (b + c)^2', [ 'a', 'log(x)', 'b', 'c', 'b:c' ] ],
	[ 'y ~ (a + b)^2 + (c + d)^2', [ 'a', 'b', 'c', 'd', 'a:b', 'c:d' ] ],
	[ 'y ~ b + a:b', [ 'b', 'b:a' ] ],
	[ 'y ~ a:c + b + b:c', [ 'b', 'a:c', 'c:b' ] ],
);

my %TOL = (
	lm => 1e-9,
	glm => 1e-9,
	aov => 1e-9,
	svyglm => 1e-9,
	ivreg => 1e-9,
	coxph => 1e-9,
	lmer => 1e-6,
	zerotrunc => 1e-3,
	hurdle => 1e-3,
);

my %worst;   # quantity => [ worst error / its tolerance, where ]
# $got is within the family's tolerance of $want, relative above 1
sub close_to {
	my ($family, $got, $want, $name) = @_;
	my $err = defined $got ? abs($got - $want) / (abs($want) > 1 ? abs($want) : 1) : 9**9**9;
	my $ratio = $err / $TOL{$family};
	$worst{$family} = [ $ratio, $name ] if !$worst{$family} || $ratio > $worst{$family}[0];
	return ok($err <= $TOL{$family}, $name)
		|| diag(sprintf "  got %s\n  want %.17g", defined $got ? sprintf('%.17g', $got) : 'undef', $want);
}

# R writes `log(wt + 1)`; the module keeps the formula's own spelling, and the
# formulas below are R's, so the spaces inside a name are dropped before it is
# compared
sub nospace { my ($n) = @_; $n =~ s/\s+//g; return $n }

# R's term labels of $formula, as the design reads them (vif()'s own view)
sub labels_of { Stats::LikeR::_vif_design($_[0], $_[1])->{term_labels} }

# every R coefficient is in the fit's coefficient hash, within tolerance, and
# the fit has no finite coefficient R does not
sub check_coefs {
	my ($family, $label, $got, @want) = @_;
	@want = map { [ nospace($_->[0]), $_->[1] ] } @want;
	is_deeply([ sort grep { $got->{$_} == $got->{$_} } keys %$got ], [ sort map { $_->[0] } @want ],
		"$label: R's coefficients") or diag('got ' . join(', ', sort keys %$got));
	close_to($family, $got->{ $_->[0] }, $_->[1], "$label: $_->[0]") for @want;
}

for my $c ((map { [ $DATA{cars}, $_ ] } @LM_CASES), (map { [ $DATA{dd}, $_ ] } @DOT_CASES)) {
	my ($data, $case) = @$c;
	my ($formula, $labels, @want) = @$case;
	my $fit = lm(formula => $formula, data => $data);
	is_deeply(labels_of($data, $formula), [ map { nospace($_) } @$labels ], "lm, $formula: R's term labels");
	check_coefs('lm', "lm, $formula", $fit->{coefficients}, @want);
}

for my $c (@GLM_CASES) {
	my ($formula, $family, @want) = @$c;
	my $fit = glm(formula => $formula, data => $DATA{cars}, family => $family);
	check_coefs('glm', "glm $family, $formula", $fit->{coefficients}, @want);
}

for my $c (@AOV_CASES) {
	my ($formula, @rows) = @$c;
	my ($resid_df, $resid_ss) = splice @rows, -2;
	my $aov = aov($DATA{cars}, $formula);
	my $anv = anova($DATA{cars}, $formula);
	for my $fn (['aov', $aov], ['anova', $anv]) {
		my ($name, $t) = @$fn;
		is_deeply([ sort grep { $_ ne 'Residuals' && ref $t->{$_} eq 'HASH' && exists $t->{$_}{Df} } keys %$t ], [ sort map { $_->[0] } @rows ],
			"$name, $formula: R's terms");
		for my $r (@rows) {
			my ($term, $df, $ss, $f) = @$r;
			is($t->{$term}{Df}, $df, "$name, $formula: Df of $term");
			close_to('aov', $t->{$term}{'Sum Sq'}, $ss, "$name, $formula: Sum Sq of $term");
			close_to('aov', $t->{$term}{'F value'}, $f, "$name, $formula: F of $term");
		}
		is($t->{Residuals}{Df}, $resid_df, "$name, $formula: residual Df");
		close_to('aov', $t->{Residuals}{'Sum Sq'}, $resid_ss, "$name, $formula: residual Sum Sq");
	}
}

for my $c (@ZT_CASES) {
	my ($formula, $dist, @want) = @$c;
	my $fit = zerotrunc(formula => $formula, data => $DATA{cars}, dist => $dist);
	check_coefs('zerotrunc', "zerotrunc $dist, $formula", $fit->{coefficients}, @want);
}

for my $c (@HURDLE_CASES) {
	my ($formula, $count, $zero) = @$c;
	my $fit = hurdle(formula => $formula, data => $DATA{cars}, dist => 'poisson', zero_dist => 'binomial');
	for my $part (['count', $count], ['zero', $zero]) {
		my ($which, $want) = @$part;
		my @w = map { (my $n = $_->[0]) =~ s/^${which}_//; $n = 'Intercept' if $n eq '(Intercept)'; [ $n, $_->[1] ] } @$want;
		check_coefs('hurdle', "hurdle, $formula, $which part", $fit->{coefficients}{$which}, @w);
	}
}

for my $c (@SVYGLM_CASES) {
	my ($formula, $family, @want) = @$c;
	my $fit = svyglm(formula => $formula, data => $DATA{cars}, weights => 'w', family => $family);
	check_coefs('svyglm', "svyglm $family, $formula", $fit->{coefficients}, @want);
}

for my $c (@IVREG_CASES) {
	my ($formula, @want) = @$c;
	my $fit = ivreg(formula => $formula, data => $DATA{cars});
	check_coefs('ivreg', "ivreg, $formula", $fit->{coefficients}, @want);
}

for my $c (@LMER_CASES) {
	my ($formula, @want) = @$c;
	my $fit = lmer(formula => $formula, data => $DATA{sleep});
	check_coefs('lmer', "lmer, $formula", $fit->{coefficients}, @want);
}

for my $c (@COXPH_CASES) {
	my ($formula, @want) = @$c;
	my $fit = coxph(formula => $formula, data => $DATA{lung});
	check_coefs('coxph', "coxph, $formula", $fit->{coefficients}, @want);
}

for my $c (@REG2_CASES) {
	my ($formula, $labels, @want) = @$c;
	my $fit = lm(formula => $formula, data => $DATA{reg2});
	is_deeply(labels_of($DATA{reg2}, $formula), $labels, "reg-tests-2.R: $formula: R's term labels");
	check_coefs('lm', "reg-tests-2.R: $formula", $fit->{coefficients}, @want);
}

# terms() alone: the labels of each formula on twenty rows of arbitrary data
{
	my %d = (y => [ map { ($_ * 7) % 11 + $_ / 10 } 1 .. 30 ]);
	for my $v (qw(a b c d x)) {
		my $k = ord($v);
		$d{$v} = [ map { (($_ * $k) % 13) + ($_ % 3) / 4 + 1 } 1 .. 30 ];
	}
	for my $c (@LABELS_ONLY) {
		my ($formula, $labels) = @$c;
		is_deeply(labels_of(\%d, $formula), [ map { nospace($_) } @$labels ], "$formula: R's term labels");
	}
}

# The identities formula.Rd states, as fits: each pair of formulas is one model
{
	my @same = (
		['mpg ~ (wt + hp + disp)^2',         'mpg ~ (wt + hp + disp)*(wt + hp + disp)'],
		['mpg ~ (wt + hp + disp)^2 - wt:hp', 'mpg ~ wt + hp + disp + hp:disp + wt:disp'],
		['mpg ~ (wt + hp)*disp',             'mpg ~ wt + hp + disp + wt:disp + hp:disp'],
		['mpg ~ (wt + hp)/disp',             'mpg ~ wt + hp + wt:hp:disp'],
		['mpg ~ wt*hp - (wt + hp)',          'mpg ~ wt:hp'],
	);
	for my $s (@same) {
		my ($g, $e) = map { lm(formula => $_, data => $DATA{cars}) } @$s;
		# formula.Rd says "identical" of the set of terms; R lists a:c before b:c in
		# the first, the second in the order it is written, so the order is not compared
		is_deeply([ sort @{ labels_of($DATA{cars}, $s->[0]) } ], [ sort @{ labels_of($DATA{cars}, $s->[1]) } ],
			"$s->[0] has the terms of $s->[1]");
		# the columns come in another order, so the fits agree to rounding, which
		# is exact on x86-64 SSE doubles and not on the x87 builds
		is_deeply([ sort keys %{ $g->{coefficients} } ], [ sort keys %{ $e->{coefficients} } ],
			"$s->[0] has the coefficients of $s->[1]");
		close_to('lm', $g->{coefficients}{$_}, $e->{coefficients}{$_}, "$s->[0] fits as $s->[1] does: $_")
			for sort keys %{ $e->{coefficients} };
	}
}

# The forms R refuses are refused here, with R's message where R has one, and
# a form R reads that this does not is refused, never fitted as something else.
{
	my %bad = (
		'(wt + hp)^1'    => qr/^lm: invalid power in formula/m,
		'wt^0'           => qr/^lm: invalid power in formula/m,
		'wt^hp'          => qr/^lm: invalid power in formula/m,
		'(wt + hp)^2^2'  => qr/^lm: invalid power in formula/m,
		'(wt + hp)^(2)'  => qr/^lm: invalid power in formula/m,
		'wt^2y'          => qr/^lm: invalid power in formula/m,
		'(wt + hp)^65'   => qr/^lm: a formula power may not exceed 64/m,
		'(wt + hp'       => qr/^lm: unbalanced parenthesis in the formula/m,
		'wt + hp)'       => qr/^lm: unbalanced parenthesis in the formula/m,
		'(wt + hp)*'     => qr/^lm: the formula has an operator with no operand/m,
		'wt:*hp'         => qr/^lm: the formula has an operator with no operand/m,
		'wt %o% hp'      => qr/^lm: unsupported operator in the formula near '%o%hp'/m,
		'wt %in'         => qr/^lm: unsupported operator in the formula/m,
		'(wt + 1)*hp'    => qr/^lm: the intercept marker '1' is read only at the top level/m,
		'(wt + hp - 1)'  => qr/^lm: the intercept marker '1' is read only at the top level/m,
		'(0 + wt)*hp'    => qr/^lm: the intercept marker '0' is read only at the top level/m,
		'foo(wt)*hp'     => qr/^lm: cannot evaluate term 'foo\(wt\)'/m,
		'(log(wt,2) + hp)*disp' => qr/^lm: cannot evaluate term 'log\(wt,2\)'/m,
	);
	for my $f (sort keys %bad) {
		throws_ok { lm(formula => "mpg ~ $f", data => $DATA{cars}) } $bad{$f}, "mpg ~ $f is refused";
	}
	# what the algebra can make is bounded: twenty variables crossed are 2**20 - 1 terms
	my @v = map { "v$_" } 1 .. 20;
	my %d = (y => [1 .. 5], map { $_ => [ 1 .. 5 ] } @v);
	throws_ok { lm(formula => 'y ~ ' . join('*', @v), data => \%d) } qr/^lm: the formula expands to too many terms/m,
		'a formula of 2**20 - 1 terms is refused';
	throws_ok { lm(formula => 'y ~ ' . join('+', @v) . ')^2', data => \%d) } qr/^lm: unbalanced parenthesis/m,
		'a stray parenthesis after a long sum is refused';
}

# no leak, on a fit and on each way of refusing one.  The refusals are caught
# in the block; no qr// is evaluated in it, which leaks one SV on perl 5.10.0.
{
	my $cars = $DATA{cars};
	no_leaks_ok {
		lm(formula => 'mpg ~ (wt + hp)*disp - hp:disp', data => $cars);
		lm(formula => 'mpg ~ (wt + hp) %in% disp + (cyl + am)^2', data => $cars);
		eval { lm(formula => 'mpg ~ (wt + hp', data => $cars) };
		eval { lm(formula => 'mpg ~ (wt + hp)^1', data => $cars) };
		eval { lm(formula => 'mpg ~ (wt + 1)*hp', data => $cars) };
		eval { lm(formula => 'mpg ~ (foo(wt) + hp)*disp', data => $cars) };
	} 'a formula with groups, and its refusals, do not leak' unless $INC{'Devel/Cover.pm'};
}

diag(sprintf '%-10s worst error is %.3g of its tolerance, %.3g (%s)', $_, $worst{$_}[0], $TOL{$_}, $worst{$_}[1]) for sort keys %worst;
done_testing();
