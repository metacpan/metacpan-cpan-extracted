#!/usr/bin/env perl
# glm() offsets and prior weights, cross-validated against R and Stata.
#
# PROVENANCE
#
# %DATA and %EXPECT below are frozen output of t/glm_offset_weights.R.R, run
# under R 4.6.1 with MASS 7.3-66 (re-run with `Rscript t/glm_offset_weights.R.R`
# and paste its two blocks over these).  Every model in it is one that R's or
# MASS's own test suites fit:
#
#   lindsey_*       tests/reg-tests-1a.R:385, "these are the same -- example
#                   from Jim Lindsey": glm(y1 - y2 ~ 1) against
#                   glm(y1 ~ offset(y2)).  R draws y from an unseeded rnorm();
#                   the generator seeds it and freezes the draw.
#   anorexia        tests/reg-tests-1a.R:419, and the example in
#                   src/library/stats/man/glm.Rd:349 (Venables & Ripley p.189):
#                   a gaussian fit with offset(Prewt).
#   connelly_*      tests/reg-tests-1a.R:1270 (Patrick Connelly, 2001): the
#                   offset as a formula term and as offset =, and prediction on
#                   new data carrying it.
#   ships           tests/reg-tests-1a.R:1434, PR#1422: MASS's ships data,
#                   poisson with offset(log(service)).
#   pr6656_*        tests/reg-tests-1a.R:1228, PR#6656: successive offsets.
#   yeast_*         MASS tests/glm.nb.R:1: glm.nb with frequency weights must
#                   equal the expanded data ("wrong results in 7.2-18").
#   fm2/gm2/fm3/gm3 MASS tests/glm.nb.R:21 ("corrected in 7.2-43"): each row
#                   split in two with fractional weights summing to 1 must
#                   reproduce the plain fit, by glm.nb and by glm() at a fixed
#                   theta.  Data from set.seed(13245), as in MASS's own test.
#   nobs0           tests/reg-tests-1b.R:1670: nobs() with zero weights.
#   pr8720_*        tests/reg-tests-2.R:1805, PR#8720: dispersion with a zero
#                   weight, against the fit on the subset.
#   binprop         tests/reg-tests-1a.R:3225: a binomial proportion with its
#                   number of trials as the prior weight.
#   hills           tests/reg-tests-3.R:75: MASS's hills, weights 1/dist^2 and
#                   no intercept.
#
# @CPUNISH is from statsmodels 0.14.6,
# statsmodels/genmod/tests/results/results_glm_poisson_weights.py, the block
# `results_poisson_fweight_nonrobust`: Stata's
#   glm executions income perpoverty perblack LN_VC100k96 south degree
#       [fweight=fweight], family(poisson)
# on statsmodels/datasets/cpunish/cpunish.csv, with the frequency weights that
# statsmodels' TestGlmPoissonFwNr uses.  For a poisson fit a Stata fweight is
# an R prior weight, so point estimates, model-based standard errors, deviance
# and log-likelihood must all agree.
#
# TOLERANCE
#
# Coefficients, standard errors, deviances and log-likelihoods: 1e-9 relative
# against R for the gaussian, binomial and poisson fits.  Observed worst on
# this build is printed as a diagnostic at the end; it was 2.6e-13 -- the IRLS
# here takes the same steps as glm.fit(), so the two agree to rounding.  The
# negative-binomial fits alternate an IRLS with MASS's theta.ml(), whose own
# stopping rule is an absolute 2^-13 on the Newton step, so theta (and
# everything downstream of it) is only as reproducible as that rule: 1e-7
# relative, against an observed worst of 1.6e-9 (SE.theta: 1e-6, observed
# 6.7e-9, because it is the inverse information at the theta BEFORE the last
# Newton step, which moves with that step).  Stata stops its Newton-Raphson on
# its own criterion, which leaves its coefficients about 1e-6 from the MLE --
# R's glm() refitted at epsilon = 1e-14 moves toward Stata's standard errors
# but not onto its coefficients (perpoverty: Stata .09081422305585, R at 1e-14
# .09081418176174) -- so %CPUNISH is held to 1e-5, against an observed worst
# of 1.6e-6 (the standard error of perpoverty).  The same fit is held to R at
# 1e-9 as `cpunish`.  None of these is loosened to make a
# failure pass; a real divergence means an offset or a weight went missing
# from one of the sums.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(glm predict);

my %DATA = (
  lindsey => {
    'y1' => [0.1496, -0.5609, 0.9054, -2.9466, 1.0393, -0.9344, -0.1022, 0.4183, -0.3237, -1.618, 0.4173, 0.2906, 0.4239, 0.8683, 0.2198, -1.2975, 0.7559, 0.3028, 0.9197],
    'y2' => [-1.9125, 0.1496, -0.5609, 0.9054, -2.9466, 1.0393, -0.9344, -0.1022, 0.4183, -0.3237, -1.618, 0.4173, 0.2906, 0.4239, 0.8683, 0.2198, -1.2975, 0.7559, 0.3028],
    'd' => [2.0621, -0.7104999999999999, 1.4663, -3.8520000000000003, 3.9859, -1.9737, 0.8322, 0.5205, -0.742, -1.2943000000000002, 2.0353000000000003, -0.12669999999999998, 0.13329999999999997, 0.44439999999999996, -0.6485, -1.5173, 2.0534, -0.4531, 0.6169],
  },
  anorexia => {
    'Treat' => ['Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT'],
    'Prewt' => [80.7, 89.4, 91.8, 74, 78.1, 88.3, 87.3, 75.1, 80.6, 78.4, 77.6, 88.7, 81.3, 78.1, 70.5, 77.3, 85.2, 86, 84.1, 79.7, 85.5, 84.4, 79.6, 77.5, 72.3, 89, 80.5, 84.9, 81.5, 82.6, 79.9, 88.7, 94.9, 76.3, 81, 80.5, 85, 89.2, 81.3, 76.5, 70, 80.4, 83.3, 83, 87.7, 84.2, 86.4, 76.5, 80.2, 87.8, 83.3, 79.7, 84.5, 80.8, 87.4, 83.8, 83.3, 86, 82.5, 86.7, 79.6, 76.9, 94.2, 73.4, 80.5, 81.6, 82.1, 77.6, 83.5, 89.9, 86, 87.3],
    'Postwt' => [80.2, 80.1, 86.4, 86.3, 76.1, 78.1, 75.1, 86.7, 73.5, 84.6, 77.4, 79.5, 89.6, 81.4, 81.8, 77.3, 84.2, 75.4, 79.5, 73, 88.3, 84.7, 81.4, 81.2, 88.2, 78.8, 82.2, 85.6, 81.4, 81.9, 76.4, 103.6, 98.4, 93.4, 73.4, 82.1, 96.7, 95.3, 82.4, 72.5, 90.9, 71.3, 85.4, 81.6, 89.1, 83.9, 82.7, 75.7, 82.6, 100.4, 85.2, 83.6, 84.6, 96.2, 86.7, 95.2, 94.3, 91.5, 91.9, 100.3, 76.7, 76.8, 101.6, 94.9, 75.2, 77.8, 95.5, 90.7, 92.5, 93.8, 91.7, 98],
  },
  connelly => {
    'counts' => [18, 17, 15, 20, 10, 20, 25, 13, 12],
    'outcome' => ['o1', 'o2', 'o3', 'o1', 'o2', 'o3', 'o1', 'o2', 'o3'],
    'treatment' => ['t1', 't1', 't1', 't2', 't2', 't2', 't3', 't3', 't3'],
    'exposure' => [1.17, 1.78, 1, 2.36, 2.58, 0.8, 2.51, 1.16, 1.77],
  },
  ships => {
    'incidents' => [0, 0, 3, 4, 6, 18, 11, 39, 29, 58, 53, 12, 44, 18, 1, 1, 0, 1, 6, 2, 1, 0, 0, 0, 0, 2, 11, 4, 0, 7, 7, 5, 12, 1],
    'type' => ['A', 'A', 'A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'D', 'D', 'D', 'D', 'D', 'D', 'D', 'E', 'E', 'E', 'E', 'E', 'E'],
    'year' => [60, 60, 65, 65, 70, 70, 75, 60, 60, 65, 65, 70, 70, 75, 60, 60, 65, 65, 70, 70, 75, 60, 60, 65, 65, 70, 70, 75, 60, 65, 65, 70, 70, 75],
    'period' => [60, 75, 60, 75, 60, 75, 75, 60, 75, 60, 75, 60, 75, 75, 60, 75, 60, 75, 60, 75, 75, 60, 75, 60, 75, 60, 75, 75, 60, 60, 75, 60, 75, 75],
    'service' => [127, 63, 1095, 1095, 1512, 3353, 2244, 44882, 17176, 28609, 20370, 7064, 13099, 7117, 1179, 552, 781, 676, 783, 1948, 274, 251, 105, 288, 192, 349, 1208, 2051, 45, 789, 437, 1157, 2161, 542],
  },
  pr6656 => {
    'x' => [1, 2, 3, 4],
    'y' => [1, 1.4142135623730951, 1.7320508075688772, 2],
    'z' => [2, 3, 4, 1],
  },
  yeast => {
    'numbers' => [0, 1, 2, 3, 4, 5],
    'fr' => [213, 128, 37, 18, 3, 1],
  },
  yeast_long => {
    'n' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 5],
  },
  nb_dat => {
    'x' => [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5],
    'y' => [8, 0, 2, 5, 5, 1, 7, 0, 6, 18, 1],
  },
  nb_dat2 => {
    'x' => [-5, -5, -4, -4, -3, -3, -2, -2, -1, -1, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
    'y' => [8, 8, 0, 0, 2, 2, 5, 5, 5, 5, 1, 1, 7, 7, 0, 0, 6, 6, 18, 18, 1, 1],
    'w' => [0.48, 0.52, 0.71, 0.29000000000000004, 0.41, 0.5900000000000001, 0.75, 0.25, 0.6, 0.4, 0.19, 0.81, 0.87, 0.13, 0.62, 0.38, 0.35, 0.65, 0.98, 0.020000000000000018, 0.94, 0.06000000000000005],
  },
  nobs0 => {
    'x1' => [0, 0.6931471805599453, 1.0986122886681098, 1.3862943611198906, 1.6094379124341003, 1.791759469228055, 1.9459101490553132, 2.0794415416798357, 2.1972245773362196, 2.302585092994046],
    'x2' => [1, 0.5, 0.3333333333333333, 0.25, 0.2, 0.16666666666666666, 0.14285714285714285, 0.125, 0.1111111111111111, undef],
    'y' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'wt' => [0, 2, 0, 4, 0, 6, 7, 8, 9, 10],
  },
  pr8720 => {
    'y' => [0.0637, -0.3812, 0.0444, 1.6043, -1.0104, 0.5665, 0.1944, 2.6199, -0.1602, 0.1183],
    'x' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'w' => [1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
  },
  binprop => {
    'p' => [0.7, 0.2, 0.6, 0.4, 0.5, 0.5, 0.5, 0.2, 0.6, 0.6],
    'x' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'n' => [10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
  },
  hills => {
    'time' => [16.083, 48.35, 33.65, 45.6, 62.267, 73.217, 204.617, 36.367, 29.75, 39.75, 192.667, 43.05, 65, 44.133, 26.933, 72.25, 98.417, 78.65, 17.417, 32.567, 15.95, 27.9, 47.633, 17.933, 18.683, 26.217, 34.433, 28.567, 50.5, 20.95, 85.583, 32.383, 170.25, 28.1, 159.833],
    'dist' => [2.5, 6, 6, 7.5, 8, 8, 16, 6, 5, 6, 28, 5, 9.5, 6, 4.5, 10, 14, 3, 4.5, 5.5, 3, 3.5, 6, 2, 3, 4, 6, 5, 6.5, 5, 10, 6, 18, 4.5, 20],
    'climb' => [650, 2500, 900, 800, 3070, 2866, 7500, 800, 800, 650, 2100, 2000, 2200, 500, 1500, 3000, 2200, 350, 1000, 600, 300, 1500, 2200, 900, 600, 2000, 800, 950, 1750, 500, 4400, 600, 5200, 850, 5000],
    'w' => [0.16, 0.027777777777777776, 0.027777777777777776, 0.017777777777777778, 0.015625, 0.015625, 0.00390625, 0.027777777777777776, 0.04, 0.027777777777777776, 0.0012755102040816326, 0.04, 0.0110803324099723, 0.027777777777777776, 0.04938271604938271, 0.01, 0.00510204081632653, 0.1111111111111111, 0.04938271604938271, 0.03305785123966942, 0.1111111111111111, 0.08163265306122448, 0.027777777777777776, 0.25, 0.1111111111111111, 0.0625, 0.027777777777777776, 0.04, 0.023668639053254437, 0.04, 0.01, 0.027777777777777776, 0.0030864197530864196, 0.04938271604938271, 0.0025],
  },
);

my %EXPECT = (
  lindsey_g1 => {
    names => ['Intercept'],
    coef => [0.14906315789473687],
    se => [0.40535091037103554],
    deviance => 56.19380130421054,
    null => 56.19380130421054,
    aic => 78.52264627864425,
    loglik => -37.26132313932212,
    df => 18,
    dfnull => 18,
  },
  lindsey_g2 => {
    names => ['Intercept'],
    coef => [0.14906315789473687],
    se => [0.4053509103710355],
    deviance => 56.19380130421053,
    null => 56.19380130421053,
    aic => 78.52264627864425,
    loglik => -37.26132313932212,
    df => 18,
    dfnull => 18,
  },
  anorexia => {
    names => ['Intercept', 'Prewt', 'TreatCont', 'TreatFT'],
    coef => [49.77110901498459, -0.5655388496390964, -4.097065528072894, 4.563062652918789],
    se => [13.390958142025935, 0.16118236185182946, 1.8934926069669256, 2.1333359226431114],
    deviance => 3311.2626199196125,
    null => 4525.386111111112,
    aic => 489.97329754222415,
    loglik => -239.98664877111207,
    df => 68,
    dfnull => 71,
  },
  connelly_term => {
    names => ['Intercept', 'outcomeo2', 'outcomeo3', 'treatmentt2', 'treatmentt3'],
    coef => [2.6427700405767176, -0.42773835132169746, 0.20511443506022423, -0.3450224178543599, -0.42439136496060653],
    se => [0.18044581857068073, 0.20526235132512818, 0.19496509760232303, 0.20201909405868346, 0.2031390462381761],
    deviance => 20.44327137413963,
    null => 33.207864063560386,
    aic => 72.07544869909616,
    loglik => -31.03772434954808,
    df => 4,
    dfnull => 8,
    link => [2.799773789386382, 2.7916450535590136, 2.847884475636942, 3.1564092417598766, 2.817798670334186, 2.2797185064683725, 3.1386614287598036, 1.9390603294126865, 2.9944726572620732],
    resp => [16.440927238175004, 16.30782499330056, 17.251247774879218, 23.48611139006391, 16.739959912315623, 9.773928724541765, 23.072961376217428, 6.952215108285452, 19.97482353383394],
  },
  connelly_arg => {
    names => ['Intercept', 'outcomeo2', 'outcomeo3', 'treatmentt2', 'treatmentt3'],
    coef => [2.6427700405767176, -0.42773835132169746, 0.20511443506022423, -0.3450224178543599, -0.42439136496060653],
    se => [0.18044581857068073, 0.20526235132512818, 0.19496509760232303, 0.20201909405868346, 0.2031390462381761],
    deviance => 20.44327137413963,
    null => 33.207864063560386,
    aic => 72.07544869909616,
    loglik => -31.03772434954808,
    df => 4,
    dfnull => 8,
    link => [2.799773789386382, 2.7916450535590136, 2.847884475636942, 3.1564092417598766, 2.817798670334186, 2.2797185064683725, 3.1386614287598036, 1.9390603294126865, 2.9944726572620732],
  },
  ships => {
    names => ['Intercept', 'typeB', 'typeC', 'typeD', 'typeE', 'year', 'period'],
    coef => [-10.079076048952674, -0.5460899673147874, -0.6326305028042322, -0.2322568985087154, 0.4059748651351769, 0.042247381537909794, 0.02370485673076224],
    se => [0.8761487585852049, 0.17841479741134783, 0.3294999464081915, 0.28797898183048576, 0.23493338102926764, 0.012826247579405975, 0.008090978182186142],
    deviance => 59.3745522029215,
    null => 146.328336532458,
    aic => 171.24104352654652,
    loglik => -78.62052176327326,
    df => 27,
    dfnull => 33,
  },
  pr6656_one => {
    names => ['Intercept', 'z'],
    coef => [-1.3660254037844388, 0.16103659850797275],
    se => [1.2574848105060497, 0.45916853095618176],
    deviance => 2.1083573982045807,
    null => 2.2380213284996704,
    aic => 14.789967461351875,
    loglik => -4.394983730675937,
    df => 2,
    dfnull => 3,
  },
  pr6656_two => {
    names => ['Intercept', 'z'],
    coef => [-2.203013620570275, 0.17802650218751254],
    se => [2.1534781771175564, 0.7863390498015939],
    deviance => 6.183291012428736,
    null => 6.341758189834337,
    aic => 19.093733445200876,
    loglik => -6.546866722600438,
    df => 2,
    dfnull => 3,
  },
  yeast_w => {
    names => ['Intercept'],
    coef => [-0.3819927519230222],
    se => [0.0660313733373915],
    deviance => 408.8980690589913,
    null => 408.89806905899144,
    aic => 897.0631523914278,
    loglik => -446.5315761957139,
    df => 5,
    dfnull => 5,
    theta => 3.5860874279996664,
    se_theta => 1.7496092969954897,
    twologlik => -893.0631523914278,
  },
  yeast_long => {
    names => ['Intercept'],
    coef => [-0.3819927519230343],
    se => [0.06603137333739195],
    deviance => 408.8980690589873,
    null => 408.898069058987,
    aic => 897.0631523914285,
    loglik => -446.53157619571425,
    df => 399,
    dfnull => 399,
    theta => 3.586087427999357,
    se_theta => 1.749609296995685,
    twologlik => -893.0631523914285,
  },
  fm2 => {
    names => ['Intercept', 'x'],
    coef => [1.54532044396339, 0.06913287143199366],
    se => [0.32585627675143125, 0.10315592126329783],
    deviance => 12.591594775772846,
    null => 13.102886758185697,
    aic => 64.23473193383089,
    loglik => -29.117365966915447,
    df => 9,
    dfnull => 10,
    theta => 1.0530223078342678,
    se_theta => 0.6004404061881867,
  },
  gm2 => {
    names => ['Intercept', 'x'],
    coef => [1.5453204439633903, 0.06913287143199372],
    se => [0.3258562767514312, 0.10315592126329781],
    deviance => 12.591594775772855,
    null => 13.102886758185713,
    aic => 64.23473193383089,
    loglik => -29.117365966915443,
    df => 20,
    dfnull => 21,
    theta => 1.0530223078342678,
    se_theta => 0.6004404061881863,
  },
  fm3 => {
    names => ['Intercept', 'x'],
    coef => [1.5453205206128846, 0.06913673293854426],
    se => [0.32585573898474185, 0.10315566649857597],
    deviance => 12.591594798644858,
    null => 13.102886780587317,
    aic => 62.234731935440024,
    loglik => -29.117365967720012,
    df => 9,
    dfnull => 10,
    theta_used => 1.0530223078342678,
  },
  gm3 => {
    names => ['Intercept', 'x'],
    coef => [1.5453205206128844, 0.06913673293854436],
    se => [0.32585573898474174, 0.10315566649857597],
    deviance => 12.591594798644852,
    null => 13.102886780587317,
    aic => 62.23473193544002,
    loglik => -29.11736596772001,
    df => 20,
    dfnull => 21,
    theta_used => 1.0530223078342678,
  },
  nobs0 => {
    names => ['Intercept', 'x1', 'x2'],
    coef => [-14.538111557211503, 9.666424505503239, 19.80336659039609],
    se => [1.6487208970402731, 0.6440983729362602, 2.6734391012535466],
    deviance => 0.3584722244633361,
    null => 135.88888888888889,
    aic => 9**9**9,
    loglik => -9**9**9,
    df => 3,
    dfnull => 5,
    nobs => 6,
    dispersion => 0.1194907414877787,
  },
  pr8720_w => {
    names => ['Intercept', 'x'],
    coef => [-0.22066944444444422, 0.12283166666666662],
    se => [0.8097005100499123, 0.14388755653470905],
    deviance => 8.695524148722223,
    null => 9.600781248888888,
    aic => 9**9**9,
    loglik => -9**9**9,
    df => 7,
    dfnull => 8,
    dispersion => 1.242217735531746,
  },
  pr8720_sub => {
    names => ['Intercept', 'x'],
    coef => [-0.22066944444444422, 0.12283166666666662],
    se => [0.8097005100499123, 0.14388755653470905],
    deviance => 8.695524148722223,
    null => 9.600781248888888,
    aic => 31.231148250180173,
    loglik => -12.615574125090086,
    df => 7,
    dfnull => 8,
    dispersion => 1.242217735531746,
  },
  binprop => {
    names => ['Intercept', 'x'],
    coef => [-0.10675677029035292, 0.004856394764106939],
    se => [0.43251120173166546, 0.06968982355706943],
    deviance => 10.801389916220295,
    null => 10.806246241029683,
    aic => 41.70946887772925,
    loglik => -18.854734438864625,
    df => 8,
    dfnull => 9,
  },
  hills => {
    names => ['dist', 'climb'],
    coef => [6.563132441863461, 0.004056554598201106],
    se => [1.3207175885656972, 0.004759843965600639],
    deviance => 442.21605978221896,
    null => 2451.0197269862747,
    aic => 322.2317549770948,
    loglik => -158.1158774885474,
    df => 33,
    dfnull => 35,
    AIC => 322.2317549770948,
  },
  cpunish => {
    names => ['Intercept', 'income', 'perpoverty', 'perblack', 'log(vc)', 'south', 'degree'],
    coef => [-6.5630028143416705, 0.0002534386725720739, 0.09081418175989012, -0.09416452451659463, 0.27652310902072186, 2.239890998908552, -18.842583691638698],
    se => [3.235243942610818, 4.015412011171055e-05, 0.06472597125948486, 0.01795768489963424, 0.38626096954194733, 0.3633935651512196, 3.7369363550214745],
    deviance => 23.3496963639238,
    null => 164.0713236739928,
    aic => 119.93883816662989,
    loglik => -52.969419083314946,
    df => 10,
    dfnull => 16,
  },
);

# ------------------------------------------------------------ statsmodels
# cpunish.csv, and the fweights of TestGlmPoissonFwNr.
my %CPUNISH_DATA = (
	executions => [37, 9, 6, 4, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	income     => [34453, 41534, 35802, 26954, 31468, 32552, 40873, 34861, 42562,
	               31900, 37421, 33305, 32108, 45844, 34743, 29709, 36777],
	perpoverty => [16.7, 12.5, 10.6, 18.4, 14.8, 18.8, 11.6, 13.1, 9.4, 14.3, 8.2,
	               16.4, 18.4, 9.3, 10, 15.2, 11.7],
	perblack   => [12.2, 20, 11.2, 16.1, 25.9, 3.5, 15.3, 30.1, 4.3, 15.4, 8.2, 7.2,
	               32.1, 27.4, 4, 7.7, 1.8],
	vc         => [644, 351, 591, 524, 565, 632, 886, 997, 405, 1051, 537, 321, 929,
	               931, 435, 597, 463],
	south      => [1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0],
	degree     => [0.16, 0.27, 0.21, 0.16, 0.19, 0.25, 0.25, 0.21, 0.31, 0.24, 0.19,
	               0.16, 0.18, 0.29, 0.24, 0.21, 0.25],
	fweight    => [1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 1, 1, 2, 2, 2, 3, 3],
);
# params_table columns b and se, rows income perpoverty perblack LN_VC100k96
# south degree _cons; est{deviance}; est{ll}.
my %CPUNISH = (
	names => [qw(income perpoverty perblack log(vc) south degree Intercept)],
	coef  => [.00025343868829, .09081422305585, -.09416451429381, .27652273809506,
	          2.239890838384, -18.842583191417, -6.5630017977416],
	se    => [.00004015414514, .06472607217881, .01795769655821, .38626128010796,
	          .36339399714255, 3.736940161486, 3.2352486362722],
	deviance => 23.34969514421719,
	loglik   => -52.96941847346162,
);

# ---------------------------------------------------------------- harness
my %worst;            # quantity class => worst relative disagreement seen
sub rel {
	my ($got, $want) = @_;
	return 0 if $got == $want;               # also covers matching infinities
	return abs($got - $want) / (abs($want) > 0 ? abs($want) : 1);
}
sub close_to {
	my ($got, $want, $tol, $class, $name) = @_;
	my $r = (defined $got && defined $want) ? rel($got, $want) : 9**9**9;
	$worst{$class} = $r if !defined $worst{$class} || $r > $worst{$class};
	ok($r <= $tol, $name) or diag("got $got, want $want, relative $r > $tol");
}
# Compare one fit against one %EXPECT record.
sub check_fit {
	my ($label, $fit, $e, $tol, $class) = @_;
	$class //= 'fit';
	my @nm = @{ $e->{names} };
	is_deeply([ sort @{ $fit->{terms} } ], [ sort @nm ], "$label: coefficient names");
	for my $k (0 .. $#nm) {
		close_to($fit->{coefficients}{ $nm[$k] }, $e->{coef}[$k], $tol, $class, "$label: coef $nm[$k]");
		close_to($fit->{summary}{ $nm[$k] }{'Std. Error'}, $e->{se}[$k], $tol, $class, "$label: se $nm[$k]");
	}
	close_to($fit->{deviance}, $e->{deviance}, $tol, $class, "$label: deviance");
	close_to($fit->{'null.deviance'}, $e->{null}, $tol, $class, "$label: null deviance") if defined $e->{null};
	close_to($fit->{aic}, $e->{aic}, $tol, $class, "$label: aic") if defined $e->{aic};
	close_to($fit->{loglik}, $e->{loglik}, $tol, $class, "$label: loglik") if defined $e->{loglik};
	is($fit->{'df.residual'}, $e->{df},     "$label: df.residual") if defined $e->{df};
	is($fit->{'df.null'},     $e->{dfnull}, "$label: df.null")     if defined $e->{dfnull};
}

# --------------------------------------------------------------- offsets
{
	my $g1 = glm(formula => 'd ~ 1',             data => $DATA{lindsey});
	my $g2 = glm(formula => 'y1 ~ offset(y2)',   data => $DATA{lindsey});
	check_fit('lindsey g1', $g1, $EXPECT{lindsey_g1}, 1e-9);
	check_fit('lindsey g2', $g2, $EXPECT{lindsey_g2}, 1e-9);
	# R's own assertion: all.equal(..., tol = 1e-12) between the two fits.
	close_to($g2->{coefficients}{Intercept}, $g1->{coefficients}{Intercept}, 1e-12, 'identity',
	         'lindsey: offset(y2) gives the coefficient of y1 - y2');
	close_to($g2->{deviance}, $g1->{deviance}, 1e-12, 'identity', 'lindsey: same deviance');
	my $maxr = 0;
	for my $r (keys %{ $g1->{'deviance.resid'} }) {
		my $d = abs($g1->{'deviance.resid'}{$r} - $g2->{'deviance.resid'}{$r});
		$maxr = $d if $d > $maxr;
	}
	cmp_ok($maxr, '<=', 1e-12, 'lindsey: same residuals');
}
check_fit('anorexia', glm(formula => 'Postwt ~ Prewt + Treat + offset(Prewt)',
                          data => $DATA{anorexia}, family => 'gaussian'),
          $EXPECT{anorexia}, 1e-9);
{
	my $d = $DATA{connelly};
	my $f1 = glm(formula => 'counts ~ outcome + treatment + offset(log(exposure))',
	             data => $d, family => 'poisson');
	my $f2 = glm(formula => 'counts ~ outcome + treatment', offset => 'log(exposure)',
	             data => $d, family => 'poisson');
	my $f3 = glm(formula => 'counts ~ outcome + treatment',
	             offset => [ map { log $_ } @{ $d->{exposure} } ],
	             data => $d, family => 'poisson');
	check_fit('connelly offset()',       $f1, $EXPECT{connelly_term}, 1e-9);
	check_fit('connelly offset =>',      $f2, $EXPECT{connelly_arg},  1e-9);
	check_fit('connelly offset => \@v',  $f3, $EXPECT{connelly_arg},  1e-9);
	# R's check is predict(fit) == predict(fit, newdata = DF); here the
	# prediction is pinned to R's too, on both scales.
	for my $pair ([$f1, 'offset()'], [$f2, 'offset =>']) {
		my ($f, $how) = @$pair;
		my $lp = predict($f, $d, type => 'link');
		my $rp = predict($f, $d, type => 'response');
		for my $i (0 .. 8) {
			close_to($lp->{ $i + 1 }, $EXPECT{connelly_term}{link}[$i], 1e-9, 'fit',
			         "connelly $how: predict link row " . ($i + 1));
			close_to($rp->{ $i + 1 }, $EXPECT{connelly_term}{resp}[$i], 1e-9, 'fit',
			         "connelly $how: predict response row " . ($i + 1));
			close_to($rp->{ $i + 1 }, $f->{'fitted.values'}{ $i + 1 }, 1e-12, 'identity',
			         "connelly $how: predict(newdata = data) is the fitted value, row " . ($i + 1));
		}
	}
	eval { predict($f3, $d) };
	like($@, qr/offset was given as an array/, 'predict: an array offset cannot be carried to new data');
}
check_fit('ships', glm(formula => 'incidents ~ type + year + period + offset(log(service))',
                       data => $DATA{ships}, family => 'poisson'),
          $EXPECT{ships}, 1e-9);
check_fit('pr6656 one offset', glm(formula => 'y ~ offset(x) + z', data => $DATA{pr6656}),
          $EXPECT{pr6656_one}, 1e-9);
check_fit('pr6656 two offsets', glm(formula => 'y ~ offset(x) + offset(log(x)) + z', data => $DATA{pr6656}),
          $EXPECT{pr6656_two}, 1e-9);
{
	# The offset in the middle of the formula, and an offset => on top of an
	# offset() term: R sums every offset it is given.
	my $a = glm(formula => 'y ~ z + offset(x)', data => $DATA{pr6656});
	check_fit('pr6656 offset last', $a, $EXPECT{pr6656_one}, 1e-9);
	my $b = glm(formula => 'y ~ offset(x) + z', offset => 'log(x)', data => $DATA{pr6656});
	check_fit('pr6656 offset() plus offset =>', $b, $EXPECT{pr6656_two}, 1e-9);
}

# --------------------------------------------------------------- weights
{
	my $w = glm(formula => 'numbers ~ 1', weights => 'fr', data => $DATA{yeast}, family => 'negbin');
	my $l = glm(formula => 'n ~ 1', data => $DATA{yeast_long}, family => 'negbin');
	for my $pair ([$w, 'yeast_w'], [$l, 'yeast_long']) {
		my ($f, $k) = @$pair;
		my $e = $EXPECT{$k};
		# the intercept-only negbin has no rank beyond the intercept
		check_fit($k, $f, $e, 1e-7, 'negbin');
		close_to($f->{theta},     $e->{theta},     1e-7, 'negbin', "$k: theta");
		close_to($f->{'SE.theta'}, $e->{se_theta}, 1e-6, 'se.theta', "$k: SE.theta");
		close_to($f->{twologlik}, $e->{twologlik}, 1e-7, 'negbin', "$k: twologlik");
	}
	# MASS: all.equal(deviance(yeast2.fit), deviance(yeast3.fit)) and theta
	close_to($w->{deviance}, $l->{deviance}, 1e-7, 'negbin', 'yeast: weighted deviance = expanded');
	close_to($w->{theta},    $l->{theta},    1e-7, 'negbin', 'yeast: weighted theta = expanded');
}
{
	my $fm2 = glm(formula => 'y ~ x', data => $DATA{nb_dat},  family => 'negbin');
	my $gm2 = glm(formula => 'y ~ x', data => $DATA{nb_dat2}, family => 'negbin', weights => 'w');
	check_fit('fm2', $fm2, $EXPECT{fm2}, 1e-7, 'negbin');
	check_fit('gm2', $gm2, $EXPECT{gm2}, 1e-7, 'negbin');
	close_to($fm2->{theta}, $EXPECT{fm2}{theta}, 1e-7, 'negbin', 'fm2: theta');
	close_to($gm2->{theta}, $EXPECT{gm2}{theta}, 1e-7, 'negbin', 'gm2: theta');
	close_to($gm2->{theta},    $fm2->{theta},    1e-7, 'negbin', 'gm2 theta = fm2 theta (MASS 7.2-43)');
	close_to($gm2->{deviance}, $fm2->{deviance}, 1e-7, 'negbin', 'gm2 deviance = fm2 deviance');
	my $th = $EXPECT{fm3}{theta_used};
	my $fm3 = glm(formula => 'y ~ x', data => $DATA{nb_dat},  family => 'negbin', theta => $th);
	my $gm3 = glm(formula => 'y ~ x', data => $DATA{nb_dat2}, family => 'negbin', theta => $th, weights => 'w');
	check_fit('fm3', $fm3, $EXPECT{fm3}, 1e-9);
	check_fit('gm3', $gm3, $EXPECT{gm3}, 1e-9);
	close_to($gm3->{deviance}, $fm3->{deviance}, 1e-9, 'fit', 'gm3 deviance = fm3 deviance');
}
{
	my $g = glm(formula => 'y ~ x1 + x2', weights => 'wt', data => $DATA{nobs0});
	check_fit('nobs0', $g, $EXPECT{nobs0}, 1e-9);
	is($g->{nobs}, $EXPECT{nobs0}{nobs}, 'nobs0: zero weights and the NA row are not observations');
	close_to($g->{dispersion}, $EXPECT{nobs0}{dispersion}, 1e-9, 'fit', 'nobs0: dispersion');
}
{
	my $w = glm(formula => 'y ~ x', weights => 'w', data => $DATA{pr8720});
	my %sub = map { my $c = $_; ($c => [ @{ $DATA{pr8720}{$c} }[0 .. 8] ]) } keys %{ $DATA{pr8720} };
	my $s = glm(formula => 'y ~ x', data => \%sub);
	check_fit('pr8720 weighted', $w, $EXPECT{pr8720_w}, 1e-9);
	check_fit('pr8720 subset',   $s, $EXPECT{pr8720_sub}, 1e-9);
	close_to($w->{dispersion}, $EXPECT{pr8720_w}{dispersion}, 1e-9, 'fit', 'pr8720: dispersion ignores the zero-weight row');
	close_to($w->{dispersion}, $s->{dispersion}, 1e-12, 'identity', 'pr8720: dispersion equals the subset fit');
	# gaussian()$aic sums log(weights), so one zero weight makes it Inf in R
	# (and logLik -Inf); reproduced rather than "fixed".
	ok($w->{aic} == 9**9**9, 'pr8720: a zero weight makes the gaussian AIC infinite, as in R');
}
check_fit('binprop', glm(formula => 'p ~ x', weights => 'n', data => $DATA{binprop}, family => 'binomial'),
          $EXPECT{binprop}, 1e-9);
check_fit('hills', glm(formula => 'time ~ 0 + dist + climb', weights => 'w', data => $DATA{hills}),
          $EXPECT{hills}, 1e-9);
{
	my $f = glm(formula => 'executions ~ income + perpoverty + perblack + log(vc) + south + degree',
	            weights => 'fweight', data => \%CPUNISH_DATA, family => 'poisson');
	check_fit('cpunish fweight vs R', $f, $EXPECT{cpunish}, 1e-9);
	check_fit('cpunish fweight vs Stata (statsmodels)', $f,
	          { %CPUNISH, null => undef, aic => undef, df => undef, dfnull => undef }, 1e-5, 'stata');
}

# ------------------------------------------------ warnings, errors, shapes
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my %d = (y => [0, 1, 1, 0, 1, 0], x => [1, 2, 3, 4, 5, 6], w => [1, 1.5, 1, 1, 1, 1]);
	glm(formula => 'y ~ x', data => \%d, family => 'binomial', weights => 'w');
	is(scalar(@w), 1, 'binomial: non-integer successes warn once, as binomial()$initialize does');
	like($w[0] // '', qr/non-integer #successes in a binomial glm!/, 'binomial: R\'s wording');
}
{
	my %d = (y => [1, 2, 3, 4, 5], x => [1, 2, 3, 4, 6], w => [1, 1, -1, 1, 1], t => [1, 2, 3, 4, 5]);
	eval { glm(formula => 'y ~ x', data => \%d, weights => 'w') };
	like($@, qr/negative weights not allowed/, 'negative weight croaks');
	eval { glm(formula => 'y ~ x', data => \%d, weights => [1, 2]) };
	like($@, qr/'weights' has 2 elements but the data has 5 rows/, 'weights array of the wrong length croaks');
	eval { glm(formula => 'y ~ x', data => \%d, offset => {}) };
	like($@, qr/'offset' must be a column name or an array ref/, 'offset of the wrong type croaks');
	eval { glm(formula => 'y ~ x + offset(log(t)', data => \%d) };
	like($@, qr/unbalanced parentheses in offset\(\)/, 'unbalanced offset() croaks');
	eval { glm(formula => 'y ~ x + offset()', data => \%d) };
	like($@, qr/offset\(\) is empty/, 'empty offset() croaks');
	my %hoh = map { ("r$_" => { y => $d{y}[$_], x => $d{x}[$_] }) } 0 .. 4;
	eval { glm(formula => 'y ~ x', data => \%hoh, weights => [1, 1, 1, 1, 1]) };
	like($@, qr/needs data with ordered rows/, 'an array ref cannot line up with a hash of hashes');
	# a row whose offset or weight is missing is dropped, as na.omit drops it
	my %m = (y => [1, 2, 3, 4, 5, 7], x => [1, 2, 3, 4, 6, 5], t => [1, 2, undef, 4, 5, 6],
	         w => [1, 1, 1, 'NA', 1, 1]);
	my $a = glm(formula => 'y ~ x + offset(log(t))', data => \%m, weights => 'w');
	is($a->{nobs}, 4, 'rows with a missing offset or weight are left out');
	ok(!exists $a->{'fitted.values'}{3} && !exists $a->{'fitted.values'}{4},
	   'and have no fitted value');
}
{
	# the AoH and HoH shapes read offset and weights from their rows
	my $d = $DATA{connelly};
	my @aoh = map { my $i = $_; +{ map { ($_ => $d->{$_}[$i]) } keys %$d } } 0 .. 8;
	my %hoh = map { my $i = $_; ("r$i" => +{ map { ($_ => $d->{$_}[$i]) } keys %$d }) } 0 .. 8;
	for my $pair ([\@aoh, 'AoH'], [\%hoh, 'HoH']) {
		my $f = glm(formula => 'counts ~ outcome + treatment', offset => 'log(exposure)',
		            data => $pair->[0], family => 'poisson');
		check_fit("connelly $pair->[1]", $f, $EXPECT{connelly_arg}, 1e-9);
	}
}

SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	my $d = $DATA{connelly};
	Test::LeakTrace::no_leaks_ok(sub {
		glm(formula => 'counts ~ outcome + treatment + offset(log(exposure))', data => $d,
		    family => 'poisson', weights => 'exposure');
	}, 'no leaks: offset and weights');
	Test::LeakTrace::no_leaks_ok(sub {
		eval { glm(formula => 'y ~ x', data => { y => [1, 2, 3], x => [1, 2, 4], w => [1, -1, 1] },
		           weights => 'w') };
	}, 'no leaks: croak on a negative weight');
}

diag(sprintf('worst relative disagreement, %s: %.3g', $_, $worst{$_})) for sort keys %worst;
done_testing();
