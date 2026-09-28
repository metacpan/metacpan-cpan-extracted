#!/usr/bin/env perl
# anova() on fitted models -- R's anova(m0, m1, ...) for lm and glm fits, and
# MASS's likelihood-ratio table for glm.nb fits.
#
# PROVENANCE
#
# %DATA and %EXPECT are frozen output of t/anova_fits.R.R under R 4.6.1 and
# MASS 7.3-66 (re-run with `Rscript t/anova_fits.R.R`).  Each comparison is
# one R's or MASS's own documentation or tests make:
#
#   lcs_*       src/library/stats/man/anova.lm.Rd: LifeCycleSavings, fit0 to
#               fit4 with test = "F", and the "unconventional order"
#               anova(fit4, fit2, fit0), whose five-figure output
#               tests/Examples/stats-Ex.Rout.save pins -- @ROUT below is that
#               output, copied verbatim.
#   pr14960     tests/reg-tests-1b.R:1894, "anova.lmlist could fail", with its
#               set.seed(1) draws.
#   d93_*       src/library/stats/man/glm.Rd and anova.glm.Rd: Dobson's
#               glm.D93 against the saturated glm.D93a, by the default test
#               (Chisq, for a family whose dispersion is 1), "Chisq" and "F".
#   anorex_*    tests/reg-tests-1a.R:419's anorexia fits: gaussian, so the
#               default is an F test on the estimated dispersion.
#   quine_*     MASS man/anova.negbin.Rd: glm.nb(Days ~ Eth*Age*Lrn*Sex)
#               against the model without the four-way interaction.
#
# TOLERANCE
#
# 1e-9 relative on every statistic and p-value, and 1e-12 absolute on a
# deviance that is zero (the saturated model's, which R reports as 1.8e-15).
# The observed worst is printed at the end with where it was: 2.1e-10 on this
# build, theta in the negative-binomial table, which inherits theta.ml()'s
# 2^-13 stopping rule.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(anova lm glm);

my %DATA = (
  lcs => {
    'sr' => [11.43, 12.07, 13.17, 5.75, 12.88, 8.79, 0.6, 11.9, 4.98, 10.78, 16.85, 3.59, 11.24, 12.64, 12.55, 10.67, 3.01, 7.7, 1.27, 9, 11.34, 14.28, 21.1, 3.98, 10.35, 15.48, 10.25, 14.65, 10.67, 7.3, 4.44, 2.02, 12.7, 12.78, 12.49, 11.14, 13.3, 11.77, 6.86, 14.13, 5.13, 2.81, 7.81, 7.56, 9.22, 18.56, 7.72, 9.24, 8.89, 4.71],
    'pop15' => [29.35, 23.32, 23.8, 41.89, 42.19, 31.72, 39.74, 44.75, 46.64, 47.64, 24.42, 46.31, 27.84, 25.06, 23.31, 25.62, 46.05, 47.32, 34.03, 41.31, 31.16, 24.52, 27.01, 41.74, 21.8, 32.54, 25.95, 24.71, 32.61, 45.04, 43.56, 41.18, 44.19, 46.26, 28.96, 31.94, 31.92, 27.74, 21.44, 23.49, 43.42, 46.12, 23.27, 29.81, 46.4, 45.25, 41.12, 28.13, 43.69, 47.2],
    'pop75' => [2.87, 4.41, 4.43, 1.67, 0.83, 2.85, 1.34, 0.67, 1.06, 1.14, 3.93, 1.19, 2.37, 4.7, 3.35, 3.1, 0.87, 0.58, 3.08, 0.96, 4.19, 3.48, 1.91, 0.91, 3.73, 2.47, 3.67, 3.25, 3.17, 1.21, 1.2, 1.05, 1.28, 1.12, 2.85, 2.28, 1.52, 2.87, 4.54, 3.73, 1.08, 1.21, 4.46, 3.43, 0.9, 0.56, 1.73, 2.72, 2.07, 0.66],
    'dpi' => [2329.68, 1507.99, 2108.47, 189.13, 728.47, 2982.88, 662.86, 289.52, 276.65, 471.24, 2496.53, 287.77, 1681.25, 2213.82, 2457.12, 870.85, 289.71, 232.44, 1900.1, 88.94, 1139.95, 1390, 1257.28, 207.68, 2449.39, 601.05, 2231.03, 1740.7, 1487.52, 325.54, 568.56, 220.56, 400.06, 152.01, 579.51, 651.11, 250.96, 768.79, 3299.49, 2630.96, 389.66, 249.87, 1813.93, 4001.89, 813.39, 138.33, 380.47, 766.54, 123.58, 242.69],
    'ddpi' => [2.87, 3.93, 3.82, 0.22, 4.56, 2.43, 2.67, 6.51, 3.08, 2.8, 3.99, 2.19, 4.32, 4.52, 3.44, 6.28, 1.48, 3.19, 1.12, 1.54, 2.99, 3.54, 8.21, 5.81, 1.57, 8.12, 3.62, 7.66, 1.76, 2.48, 3.61, 1.03, 0.67, 2, 7.48, 2.19, 2, 4.35, 3.01, 2.7, 2.96, 1.13, 2.01, 2.45, 0.53, 5.14, 10.23, 1.88, 16.71, 5.08],
  },
  pr14960 => {
    'y' => [-0.6264538107423324, 0.18364332422208224, -0.8356286124100472, 1.5952808021377916, 0.3295077718153605, -0.8204683841180153, 0.4874290524284853, 0.7383247051292173, 0.5757813516534923, -0.305388387156356, 1.511781168450848, 0.3898432364114311, -0.6212405805418038, -2.2146998871775, 1.1249309181431082, -0.04493360901523085, -0.016190263098946087, 0.9438362106852992, 0.8212211950980886, 0.5939013212175088],
    'x' => [0.9189773716082182, 0.7821363007310671, 0.0745649833651906, -1.9893516958633728, 0.6198257478947102, -0.056128739529000785, -0.1557955067053293, -1.4707523838992744, -0.47815005510862035, 0.4179415601997024, 1.358679551529044, -0.10278772734299552, 0.38767161155936913, -0.05380504058290512, -1.3770595568286066, -0.41499456329967976, -0.3942899537103493, -0.05931339671118566, 1.100025371983883, 0.7631757484575442],
    'f' => ['a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b', 'b'],
  },
  d93 => {
    'counts' => [18, 17, 15, 20, 10, 20, 25, 13, 12],
    'outcome' => ['o1', 'o2', 'o3', 'o1', 'o2', 'o3', 'o1', 'o2', 'o3'],
    'treatment' => ['t1', 't1', 't1', 't2', 't2', 't2', 't3', 't3', 't3'],
  },
  anorexia => {
    'Treat' => ['Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'Cont', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'CBT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT', 'FT'],
    'Prewt' => [80.7, 89.4, 91.8, 74, 78.1, 88.3, 87.3, 75.1, 80.6, 78.4, 77.6, 88.7, 81.3, 78.1, 70.5, 77.3, 85.2, 86, 84.1, 79.7, 85.5, 84.4, 79.6, 77.5, 72.3, 89, 80.5, 84.9, 81.5, 82.6, 79.9, 88.7, 94.9, 76.3, 81, 80.5, 85, 89.2, 81.3, 76.5, 70, 80.4, 83.3, 83, 87.7, 84.2, 86.4, 76.5, 80.2, 87.8, 83.3, 79.7, 84.5, 80.8, 87.4, 83.8, 83.3, 86, 82.5, 86.7, 79.6, 76.9, 94.2, 73.4, 80.5, 81.6, 82.1, 77.6, 83.5, 89.9, 86, 87.3],
    'Postwt' => [80.2, 80.1, 86.4, 86.3, 76.1, 78.1, 75.1, 86.7, 73.5, 84.6, 77.4, 79.5, 89.6, 81.4, 81.8, 77.3, 84.2, 75.4, 79.5, 73, 88.3, 84.7, 81.4, 81.2, 88.2, 78.8, 82.2, 85.6, 81.4, 81.9, 76.4, 103.6, 98.4, 93.4, 73.4, 82.1, 96.7, 95.3, 82.4, 72.5, 90.9, 71.3, 85.4, 81.6, 89.1, 83.9, 82.7, 75.7, 82.6, 100.4, 85.2, 83.6, 84.6, 96.2, 86.7, 95.2, 94.3, 91.5, 91.9, 100.3, 76.7, 76.8, 101.6, 94.9, 75.2, 77.8, 95.5, 90.7, 92.5, 93.8, 91.7, 98],
  },
  quine => {
    'Days' => [2, 11, 14, 5, 5, 13, 20, 22, 6, 6, 15, 7, 14, 6, 32, 53, 57, 14, 16, 16, 17, 40, 43, 46, 8, 23, 23, 28, 34, 36, 38, 3, 5, 11, 24, 45, 5, 6, 6, 9, 13, 23, 25, 32, 53, 54, 5, 5, 11, 17, 19, 8, 13, 14, 20, 47, 48, 60, 81, 2, 0, 2, 3, 5, 10, 14, 21, 36, 40, 6, 17, 67, 0, 0, 2, 7, 11, 12, 0, 0, 5, 5, 5, 11, 17, 3, 4, 22, 30, 36, 8, 0, 1, 5, 7, 16, 27, 0, 30, 10, 14, 27, 41, 69, 25, 10, 11, 20, 33, 5, 7, 0, 1, 5, 5, 5, 5, 7, 11, 15, 5, 14, 6, 6, 7, 28, 0, 5, 14, 2, 2, 3, 8, 10, 12, 1, 1, 9, 22, 3, 3, 5, 15, 18, 22, 37],
    'Eth' => ['A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N'],
    'Sex' => ['M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'M', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F', 'F'],
    'Age' => ['F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F1', 'F1', 'F1', 'F1', 'F1', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F0', 'F0', 'F0', 'F0', 'F0', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F0', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F0', 'F0', 'F0', 'F0', 'F0', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F1', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F2', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3', 'F3'],
    'Lrn' => ['SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'SL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL', 'AL'],
  },
);

my %EXPECT = (
  lcs_all => {
    'Res.Df' => [49, 48, 47, 46, 45],
    'RSS' => [983.62825, 779.5106846253956, 726.1679749519313, 713.7670287603918, 650.7129981676327],
    'Df' => [undef, 1, 1, 1, 1],
    'Sum of Sq' => [undef, 204.1175653746044, 53.34270967346424, 12.40094619153956, 63.05403059275909],
    'F' => [undef, 14.115732231755635, 3.688910383018827, 0.8575863402002011, 4.360495924722865],
    'Pr(>F)' => [undef, 0.0004921954681666046, 0.06112545983034587, 0.35935508477849776, 0.04247113872491377],
  },
  lcs_unconventional => {
    'Res.Df' => [45, 47, 49],
    'RSS' => [650.7129981676327, 726.1679749519313, 983.62825],
    'Df' => [undef, -2, -2],
    'Sum of Sq' => [undef, -75.45497678429865, -257.46027504806864],
    'F' => [undef, 2.609041132461533, 8.902321307387231],
    'Pr(>F)' => [undef, 0.0847088477965798, 0.0005526716859402219],
  },
  lcs_chisq => {
    'Res.Df' => [49, 47, 45],
    'RSS' => [983.62825, 726.1679749519313, 650.7129981676327],
    'Df' => [undef, 2, 2],
    'Sum of Sq' => [undef, 257.46027504806864, 75.45497678429865],
    'Pr(>Chi)' => [undef, 0.00013607269303894713, 0.07360508746565574],
  },
  pr14960 => {
    'Res.Df' => [18, 17],
    'RSS' => [15.096799389549869, 14.940801758998797],
    'Df' => [undef, 1],
    'Sum of Sq' => [undef, 0.15599763055107196],
    'F' => [undef, 0.17749781853379834],
    'Pr(>F)' => [undef, 0.6788111886849602],
  },
  d93_default => {
    'Resid. Df' => [8, 4, 0],
    'Resid. Dev' => [10.581445863750858, 5.129141077001142, 1.7763568394001455e-15],
    'Df' => [undef, 4, 4],
    'Deviance' => [undef, 5.452304786749716, 5.12914107700114],
    'Pr(>Chi)' => [undef, 0.24395384728813785, 0.27430162470809805],
  },
  d93_chisq => {
    'Resid. Df' => [4, 0],
    'Resid. Dev' => [5.129141077001142, 1.7763568394001455e-15],
    'Df' => [undef, 4],
    'Deviance' => [undef, 5.12914107700114],
    'Pr(>Chi)' => [undef, 0.27430162470809805],
  },
  d93_F => {
    'Resid. Df' => [8, 4],
    'Resid. Dev' => [10.581445863750858, 5.129141077001142],
    'Df' => [undef, 4],
    'Deviance' => [undef, 5.452304786749716],
    'F' => [undef, 1.363076196687429],
    'Pr(>F)' => [undef, 0.24395384728813785],
  },
  anorex_default => {
    'Resid. Df' => [70, 68],
    'Resid. Dev' => [4077.5354326752904, 3311.2626199196125],
    'Df' => [undef, 2],
    'Deviance' => [undef, 766.2728127556779],
    'F' => [undef, 7.868078924626506],
    'Pr(>F)' => [undef, 0.0008438398238574915],
  },
  anorex_chisq => {
    'Resid. Df' => [70, 68],
    'Resid. Dev' => [4077.5354326752904, 3311.2626199196125],
    'Df' => [undef, 2],
    'Deviance' => [undef, 766.2728127556779],
    'Pr(>Chi)' => [undef, 0.00038276898441148865],
  },
  quine_nb => {
    'Model' => ['Eth + Age + Lrn + Sex + Eth:Age + Eth:Lrn + Age:Lrn + Eth:Sex + Age:Sex + Lrn:Sex + Eth:Age:Lrn + Eth:Age:Sex + Eth:Lrn:Sex + Age:Lrn:Sex', 'Eth * Age * Lrn * Sex'],
    'theta' => [1.9079895685541808, 1.9283601451070147],
    'Resid. df' => [120, 118],
    '   2 x log-lik.' => [-1040.7278638768742, -1039.3240205183747],
    'Test' => ['', '1 vs 2'],
    '   df' => [undef, 2],
    'LR stat.' => [undef, 1.4038433584994436],
    'Pr(Chi)' => [undef, 0.4956319424381469],
  },
  quine_nb_fits => {
    'theta' => [1.9079895685541808, 1.9283601451070147],
    'rank' => [26, 28],
    'twologlik' => [-1040.7278638768742, -1039.3240205183747],
  },
);

# tests/Examples/stats-Ex.Rout.save, "anova(fit0, fit1, fit2, fit3, fit4, test = "F")":
# Res.Df RSS Df Sum of Sq F Pr(>F), as printed
my @ROUT = ([49, 983.63], [48, 779.51, 1, 204.118, 14.1157, 0.0004922],
            [47, 726.17, 1, 53.343, 3.6889, 0.0611255], [46, 713.77, 1, 12.401, 0.8576, 0.3593551],
            [45, 650.71, 1, 63.054, 4.3605, 0.0424711]);

my ($worst, $worst_at) = (0, '');
sub check_table {
	my ($label, $got, $e) = @_;
	my @cols = grep { $_ ne 'Model' && $_ ne 'Test' } keys %$e;
	my $n = @{ $e->{ (keys %$e)[0] } };
	is(scalar(@$got), $n, "$label: one row per model");
	for my $c (@cols) {
		(my $k = $c) =~ s/^\s+//;           # MASS pads '   2 x log-lik.' and '   df'
		for my $i (0 .. $n - 1) {
			my $want = $e->{$c}[$i];
			my $g = $got->[$i]{$k};
			if (!defined $want) {
				ok(!defined $g, "$label row $i: no $k");
				next;
			}
			my $r = !defined $g ? 9**9**9
			      : abs($want) < 1e-12 ? abs($g - $want)
			      : abs($g - $want) / abs($want);
			($worst, $worst_at) = ($r, "$label, $k") if $r > $worst && $r != 9**9**9;
			ok($r <= 1e-9, "$label row $i: $k") or diag("got " . ($g // 'undef') . ", want $want");
		}
	}
}

my $L = $DATA{lcs};
my @f = map { lm(formula => $_, data => $L) }
        ('sr ~ 1', 'sr ~ pop15', 'sr ~ pop15 + pop75', 'sr ~ pop15 + pop75 + dpi', 'sr ~ pop15 + pop75 + dpi + ddpi');
check_table('LifeCycleSavings fit0..fit4', anova(@f, test => 'F'), $EXPECT{lcs_all});
check_table('LifeCycleSavings, lm default test is F', anova(@f), $EXPECT{lcs_all});
check_table('LifeCycleSavings unconventional order', anova($f[4], $f[2], $f[0], test => 'F'), $EXPECT{lcs_unconventional});
check_table('LifeCycleSavings, test = Chisq', anova($f[0], $f[2], $f[4], test => 'Chisq'), $EXPECT{lcs_chisq});
{
	my $t = anova(@f, test => 'F');
	my @k = ('Res.Df', 'RSS', 'Df', 'Sum of Sq', 'F', 'Pr(>F)');
	for my $i (0 .. 4) {
		for my $j (0 .. $#{ $ROUT[$i] }) {
			my $v = $ROUT[$i][$j];
			# printed to 5 significant figures (7 decimals for Pr)
			my $tol = $k[$j] eq 'Pr(>F)' ? 5e-8 : 5e-5 * abs($v) + 5e-4 * ($k[$j] =~ /RSS|Sum/ ? 1 : 0);
			cmp_ok(abs($t->[$i]{ $k[$j] } - $v), '<=', $tol, "stats-Ex.Rout.save: row $i $k[$j]");
		}
	}
}
check_table('PR#14960', anova(lm(formula => 'y ~ x', data => $DATA{pr14960}),
                              lm(formula => 'y ~ x + f', data => $DATA{pr14960}), test => 'F'),
            $EXPECT{pr14960});
{
	my $d = $DATA{d93};
	my $g0 = glm(formula => 'counts ~ 1', data => $d, family => 'poisson');
	my $g  = glm(formula => 'counts ~ outcome + treatment', data => $d, family => 'poisson');
	my $ga = glm(formula => 'counts ~ outcome * treatment', data => $d, family => 'poisson');
	check_table('glm.D93, default test', anova($g0, $g, $ga), $EXPECT{d93_default});
	check_table('glm.D93 vs glm.D93a, Chisq', anova($g, $ga, test => 'Chisq'), $EXPECT{d93_chisq});
	check_table('glm.D93 vs glm.D93a, LRT', anova($g, $ga, test => 'LRT'), $EXPECT{d93_chisq});
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		check_table('glm.D93, F on a poisson', anova($g0, $g, test => 'F'), $EXPECT{d93_F});
	}
	like($w[0] // '', qr/using F test with a 'poisson' family is inappropriate/, 'F on a poisson warns, as R does');
	eval { anova($g, lm(formula => 'counts ~ 1', data => { counts => $d->{counts} })) };
	like($@, qr/cannot compare lm\(\) and glm\(\) fits/, 'lm and glm do not mix');
	eval { anova($g, glm(formula => 'counts ~ 1', data => $d, family => 'gaussian')) };
	like($@, qr/not all of the same family/, 'families must match');
	eval { anova($g, glm(formula => 'counts ~ 1', data => { counts => [ @{ $d->{counts} }[0 .. 7] ] },
	                     family => 'poisson')) };
	like($@, qr/not all fitted to the same size of dataset/, 'the same data size, as R insists');
	eval { anova($g) };
	like($@, qr/at least two fitted models/, 'one model is not a comparison');
	eval { anova($g, $ga, test => 'Rao') };
	like($@, qr/test must be 'F', 'Chisq' or 'LRT'/, 'unknown test');
	eval { anova($g, $ga, tests => 'F') };
	like($@, qr/unknown argument 'tests'/, 'unknown option');
}
{
	my $A = $DATA{anorexia};
	my $a0 = glm(formula => 'Postwt ~ Prewt + offset(Prewt)', data => $A);
	my $a1 = glm(formula => 'Postwt ~ Prewt + Treat + offset(Prewt)', data => $A);
	check_table('anorexia, gaussian default F', anova($a0, $a1), $EXPECT{anorex_default});
	check_table('anorexia, Chisq', anova($a0, $a1, test => 'Chisq'), $EXPECT{anorex_chisq});
}
{
	my $Q = $DATA{quine};
	my $m1 = glm(formula => 'Days ~ Eth*Age*Lrn*Sex', data => $Q, family => 'negbin');
	my $m2 = glm(formula => 'Days ~ ' . $EXPECT{quine_nb}{Model}[0], data => $Q, family => 'negbin');
	my $e = $EXPECT{quine_nb_fits};
	is($m2->{rank}, $e->{rank}[0], 'quine m2: rank, as glm.nb');
	is($m1->{rank}, $e->{rank}[1], 'quine m1: rank with the empty cells aliased, as glm.nb');
	check_table('MASS anova.negbin example', anova($m2, $m1), $EXPECT{quine_nb});
	check_table('MASS anova.negbin example, given in the other order (MASS sorts)', anova($m1, $m2), $EXPECT{quine_nb});
	eval { anova($m2, $m1, test => 'F') };
	like($@, qr/likelihood-ratio test only/, 'negbin: only the LR test');
}
{
	# the XS anova() still takes data and formulas
	my $t = anova($DATA{lcs}, 'sr ~ pop15', 'sr ~ pop15 + pop75');
	ok(ref $t eq 'ARRAY' && exists $t->[1]{F}, 'anova(\%data, formulas) is the XS function, unchanged');
}
diag(sprintf('worst relative disagreement: %.3g (%s)', $worst, $worst_at));
done_testing();
