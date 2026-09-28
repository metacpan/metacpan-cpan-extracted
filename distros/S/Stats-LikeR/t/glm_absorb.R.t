#!/usr/bin/env perl
# glm(..., absorb => ...) and the `y ~ x | id` formula: factors absorbed by
# within-group demeaning, cross-validated against glm() with the same factors
# as dummy columns, and against fixest.
#
# PROVENANCE
#
# %DATA, %EXPECT, %FIXEST and %DID are frozen output of t/glm_absorb.R.R under
# R 4.6.1 with MASS 7.3-66, sandwich 3.1-3 and fixest 0.14.2 (re-run with
# `Rscript t/glm_absorb.R.R`; it also rewrites t/base_did.csv).
#
#   %EXPECT  fixest's own tests/fixest_tests.R, section "ESTIMATION": its iris
#            corpus with the same derived columns after the same set.seed(0),
#            and its loop over model families, weights, an offset and fixed
#            effects.  The specifications absorb => can express are fixest's
#            id_fe 0 (none), 1 (species), 2 (species + fe_2) and 7
#            (species^fe_2, here a combined column); the rest are varying
#            slopes.  fixest compares feglm() with glm() on dummy columns at
#            1e-5; the reference here is that glm() fit (glm.nb() for the
#            negative binomial), recorded at full precision, plus its
#            vcovCL(cluster = ~ species, type = "HC0").
#   %FIXEST  the fixest estimates of four of those models, which must agree
#            with glm() and so with absorb =>.
#   %DID     fixest_tests.R, "obs removal": base_did with the first ten ids'
#            outcomes set to zero.  Their fixed effects are minus infinity;
#            fixef.rm = "infinite" removes those 100 observations, and so does
#            absorb =>.  (The same test's fixef.rm = "singletons" case is not
#            reproduced: a singleton group is fitted exactly and changes no
#            coefficient, so absorb => keeps it, as glm() does.)
#
# TOLERANCE
#
# gaussian, poisson and binomial: 1e-9 relative on coefficients, standard
# errors, clustered standard errors, deviance and log-likelihood.  The demeaned
# IRLS takes the same steps as glm()'s on the dummy columns, so they agree to
# rounding; the observed worst is printed at the end (3.5e-13 on this build).
# The negative binomial on y_int has theta near 2e6 -- the data are all but
# Poisson -- and glm.nb()'s alternation stops on MASS's absolute 2^-13 in
# theta.ml(), which at that theta moves nothing but theta itself: 1e-7 on the
# coefficient block (observed 1.8e-9), and theta is only checked to be
# enormous, since MASS's own value there is an artefact of its iteration
# limit ("iteration limit reached" is among the warnings the generator
# prints).  fixest's estimates are compared at 1e-8, fixest's glm.tol, against
# an observed 1.2e-15.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(glm predict);

my %DATA = (
  base => {
    y => [5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, 4.9, 5.4, 4.8, 4.8, 4.3, 5.8, 5.7, 5.4, 5.1, 5.7, 5.1, 5.4, 5.1, 4.6, 5.1, 4.8, 5, 5, 5.2, 5.2, 4.7, 4.8, 5.4, 5.2, 5.5, 4.9, 5, 5.5, 4.9, 4.4, 5.1, 5, 4.5, 4.4, 5, 5.1, 4.8, 5.1, 4.6, 5.3, 5, 7, 6.4, 6.9, 5.5, 6.5, 5.7, 6.3, 4.9, 6.6, 5.2, 5, 5.9, 6, 6.1, 5.6, 6.7, 5.6, 5.8, 6.2, 5.6, 5.9, 6.1, 6.3, 6.1, 6.4, 6.6, 6.8, 6.7, 6, 5.7, 5.5, 5.5, 5.8, 6, 5.4, 6, 6.7, 6.3, 5.6, 5.5, 5.5, 6.1, 5.8, 5, 5.6, 5.7, 5.7, 6.2, 5.1, 5.7, 6.3, 5.8, 7.1, 6.3, 6.5, 7.6, 4.9, 7.3, 6.7, 7.2, 6.5, 6.4, 6.8, 5.7, 5.8, 6.4, 6.5, 7.7, 7.7, 6, 6.9, 5.6, 7.7, 6.3, 6.7, 7.2, 6.2, 6.1, 6.4, 7.2, 7.4, 7.9, 6.4, 6.3, 6.1, 7.7, 6.3, 6.4, 6, 6.9, 6.7, 6.9, 5.8, 6.8, 6.7, 6.7, 6.3, 6.5, 6.2, 5.9],
    x1 => [3.5, 3, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, 3.1, 3.7, 3.4, 3, 3, 4, 4.4, 3.9, 3.5, 3.8, 3.8, 3.4, 3.7, 3.6, 3.3, 3.4, 3, 3.4, 3.5, 3.4, 3.2, 3.1, 3.4, 4.1, 4.2, 3.1, 3.2, 3.5, 3.6, 3, 3.4, 3.5, 2.3, 3.2, 3.5, 3.8, 3, 3.8, 3.2, 3.7, 3.3, 3.2, 3.2, 3.1, 2.3, 2.8, 2.8, 3.3, 2.4, 2.9, 2.7, 2, 3, 2.2, 2.9, 2.9, 3.1, 3, 2.7, 2.2, 2.5, 3.2, 2.8, 2.5, 2.8, 2.9, 3, 2.8, 3, 2.9, 2.6, 2.4, 2.4, 2.7, 2.7, 3, 3.4, 3.1, 2.3, 3, 2.5, 2.6, 3, 2.6, 2.3, 2.7, 3, 2.9, 2.9, 2.5, 2.8, 3.3, 2.7, 3, 2.9, 3, 3, 2.5, 2.9, 2.5, 3.6, 3.2, 2.7, 3, 2.5, 2.8, 3.2, 3, 3.8, 2.6, 2.2, 3.2, 2.8, 2.8, 2.7, 3.3, 3.2, 2.8, 3, 2.8, 3, 2.8, 3.8, 2.8, 2.8, 2.6, 3, 3.4, 3.1, 3, 3.1, 3.1, 3.1, 2.7, 3.2, 3.3, 3, 2.5, 3, 3.4, 3],
    x2 => [1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, 1.4, 1.5, 1.5, 1.6, 1.4, 1.1, 1.2, 1.5, 1.3, 1.4, 1.7, 1.5, 1.7, 1.5, 1, 1.7, 1.9, 1.6, 1.6, 1.5, 1.4, 1.6, 1.6, 1.5, 1.5, 1.4, 1.5, 1.2, 1.3, 1.4, 1.3, 1.5, 1.3, 1.3, 1.3, 1.6, 1.9, 1.4, 1.6, 1.4, 1.5, 1.4, 4.7, 4.5, 4.9, 4, 4.6, 4.5, 4.7, 3.3, 4.6, 3.9, 3.5, 4.2, 4, 4.7, 3.6, 4.4, 4.5, 4.1, 4.5, 3.9, 4.8, 4, 4.9, 4.7, 4.3, 4.4, 4.8, 5, 4.5, 3.5, 3.8, 3.7, 3.9, 5.1, 4.5, 4.5, 4.7, 4.4, 4.1, 4, 4.4, 4.6, 4, 3.3, 4.2, 4.2, 4.2, 4.3, 3, 4.1, 6, 5.1, 5.9, 5.6, 5.8, 6.6, 4.5, 6.3, 5.8, 6.1, 5.1, 5.3, 5.5, 5, 5.1, 5.3, 5.5, 6.7, 6.9, 5, 5.7, 4.9, 6.7, 4.9, 5.7, 6, 4.8, 4.9, 5.6, 5.8, 6.1, 6.4, 5.6, 5.1, 5.6, 6.1, 5.6, 5.5, 4.8, 5.4, 5.6, 5.1, 5.1, 5.9, 5.7, 5.2, 5, 5.2, 5.4, 5.1],
    y_int => [5, 4, 4, 4, 5, 5, 4, 5, 4, 4, 5, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 4, 5, 4, 5, 5, 5, 5, 4, 4, 5, 5, 5, 4, 5, 5, 4, 4, 5, 5, 4, 4, 5, 5, 4, 5, 4, 5, 5, 7, 6, 6, 5, 6, 5, 6, 4, 6, 5, 5, 5, 6, 6, 5, 6, 5, 5, 6, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 6, 5, 6, 6, 6, 5, 5, 5, 6, 5, 5, 5, 5, 5, 6, 5, 5, 6, 5, 7, 6, 6, 7, 4, 7, 6, 7, 6, 6, 6, 5, 5, 6, 6, 7, 7, 6, 6, 5, 7, 6, 6, 7, 6, 6, 6, 7, 7, 7, 6, 6, 6, 7, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6, 6, 6, 5],
    y_int_null => [5, 4, 0, 4, 0, 0, 4, 5, 4, 4, 0, 4, 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 4, 0, 0, 5, 5, 5, 0, 0, 0, 5, 5, 5, 4, 5, 0, 0, 0, 5, 5, 4, 4, 5, 0, 4, 0, 4, 5, 5, 7, 6, 6, 5, 6, 5, 6, 4, 6, 5, 5, 0, 6, 6, 5, 6, 0, 5, 0, 5, 5, 6, 0, 0, 0, 6, 6, 6, 6, 5, 5, 5, 5, 6, 0, 0, 6, 6, 5, 5, 5, 6, 0, 5, 5, 5, 5, 6, 5, 5, 6, 0, 7, 0, 6, 7, 0, 7, 6, 7, 0, 6, 0, 5, 5, 6, 6, 7, 7, 6, 0, 5, 0, 6, 0, 7, 6, 6, 6, 7, 7, 7, 6, 0, 6, 7, 6, 6, 0, 6, 6, 6, 0, 0, 6, 0, 6, 0, 6, 5],
    y_01 => [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0],
    w => [0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05],
    offset_value => [0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 0.050000000000000044, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05, 2.05],
    species => ['setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'setosa', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'versicolor', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica', 'virginica'],
    fe_2 => ['f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5', 'f1', 'f2', 'f3', 'f4', 'f5'],
    sp_fe2 => ['setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'setosa 1', 'setosa 2', 'setosa 3', 'setosa 4', 'setosa 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'versicolor 1', 'versicolor 2', 'versicolor 3', 'versicolor 4', 'versicolor 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5', 'virginica 1', 'virginica 2', 'virginica 3', 'virginica 4', 'virginica 5'],
  },
);

my %EXPECT = (
  ols_w0_o0_fe0 => {
    names => ['x1'],
    coef => [-0.2233610611299002],
    se => [0.15508092994240769],
    deviance => 100.75609579749603,
    df => 148,
    loglik => -182.99583566273148,
    resp => 'y',
    id_fe => 0,
    weights => 0,
    offset => 0,
    model => 'ols',
  },
  ols_w0_o0_fe1 => {
    names => ['x1'],
    coef => [0.8035609008371664],
    se => [0.1063389772177948],
    deviance => 28.00366492158944,
    df => 146,
    loglik => -86.96828729847775,
    resp => 'y',
    id_fe => 1,
    weights => 0,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1'], se => [0.07115744031935149] },
  },
  ols_w0_o0_fe2 => {
    names => ['x1'],
    coef => [0.7907995083955309],
    se => [0.10784356456456999],
    deviance => 27.054322635238712,
    df => 142,
    loglik => -84.38164248832977,
    resp => 'y',
    id_fe => 2,
    weights => 0,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1'], se => [0.08190370467015516] },
  },
  ols_w0_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [0.4433050040821069, 0.74600530662187],
    se => [0.08459045769672521, 0.06787322724732112],
    deviance => 13.006855871034157,
    df => 133,
    loglik => -29.453877409229975,
    resp => 'y',
    id_fe => 7,
    weights => 0,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1', 'x2'], se => [0.16598531870159725, 0.13475043817538282] },
  },
  ols_w0_o1_fe0 => {
    names => ['x1'],
    coef => [0.5785626136352934],
    se => [0.09073782080573385],
    deviance => 34.493020555623595,
    df => 148,
    loglik => -102.59990798616728,
    resp => 'y',
    id_fe => 0,
    weights => 0,
    offset => 1,
    model => 'ols',
  },
  ols_w0_o1_fe1 => {
    names => ['x1'],
    coef => [0.8035609008371664],
    se => [0.1063389772177948],
    deviance => 28.00366492158944,
    df => 146,
    loglik => -86.96828729847775,
    resp => 'y',
    id_fe => 1,
    weights => 0,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1'], se => [0.07115744031935109] },
  },
  ols_w0_o1_fe2 => {
    names => ['x1'],
    coef => [0.7907995083955309],
    se => [0.10784356456456999],
    deviance => 27.054322635238712,
    df => 142,
    loglik => -84.38164248832977,
    resp => 'y',
    id_fe => 2,
    weights => 0,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1'], se => [0.08190370467015483] },
  },
  ols_w0_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [0.44330500408210555, 0.7460053066218699],
    se => [0.0845904576967252, 0.0678732272473211],
    deviance => 13.006855871034155,
    df => 133,
    loglik => -29.45387740922996,
    resp => 'y',
    id_fe => 7,
    weights => 0,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1', 'x2'], se => [0.16598531870159755, 0.13475043817538265] },
  },
  ols_w1_o0_fe0 => {
    names => ['x1'],
    coef => [0.94031837454382],
    se => [0.1476769339221084],
    deviance => 58.04462531975023,
    df => 148,
    loglik => -197.3615995873162,
    resp => 'y',
    id_fe => 0,
    weights => 1,
    offset => 0,
    model => 'ols',
  },
  ols_w1_o0_fe1 => {
    names => ['x1'],
    coef => [0.8852100469572335],
    se => [0.13496919926405523],
    deviance => 42.19645453751852,
    df => 146,
    loglik => -173.4459059653755,
    resp => 'y',
    id_fe => 1,
    weights => 1,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1'], se => [0.016227140528010116] },
  },
  ols_w1_o0_fe2 => {
    names => ['x1'],
    coef => [0.86448972406681],
    se => [0.1359707173621709],
    deviance => 39.077859538775286,
    df => 142,
    loglik => -167.68739490969455,
    resp => 'y',
    id_fe => 2,
    weights => 1,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1'], se => [0.06267066997495609] },
  },
  ols_w1_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [0.2350915220404559, 0.862219671745323],
    se => [0.09837864158795455, 0.060894430669861735],
    deviance => 15.010119178553671,
    df => 133,
    loglik => -95.92503474614765,
    resp => 'y',
    id_fe => 7,
    weights => 1,
    offset => 0,
    model => 'ols',
    cl => { names => ['x1', 'x2'], se => [0.023847314363213155, 0.0744209039402137] },
  },
  ols_w1_o1_fe0 => {
    names => ['x1'],
    coef => [0.6653798690802137],
    se => [0.1385516319475655],
    deviance => 51.092831262570364,
    df => 148,
    loglik => -187.79400575168344,
    resp => 'y',
    id_fe => 0,
    weights => 1,
    offset => 1,
    model => 'ols',
  },
  ols_w1_o1_fe1 => {
    names => ['x1'],
    coef => [0.885210046957234],
    se => [0.13496919926405523],
    deviance => 42.196454537518505,
    df => 146,
    loglik => -173.44590596537546,
    resp => 'y',
    id_fe => 1,
    weights => 1,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1'], se => [0.01622714052800933] },
  },
  ols_w1_o1_fe2 => {
    names => ['x1'],
    coef => [0.8644897240668105],
    se => [0.1359707173621709],
    deviance => 39.07785953877528,
    df => 142,
    loglik => -167.68739490969455,
    resp => 'y',
    id_fe => 2,
    weights => 1,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1'], se => [0.0626706699749564] },
  },
  ols_w1_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [0.23509152204045686, 0.8622196717453231],
    se => [0.09837864158795455, 0.060894430669861735],
    deviance => 15.01011917855367,
    df => 133,
    loglik => -95.92503474614763,
    resp => 'y',
    id_fe => 7,
    weights => 1,
    offset => 1,
    model => 'ols',
    cl => { names => ['x1', 'x2'], se => [0.023847314363213988, 0.07442090394021368] },
  },
  pois_w0_o0_fe0 => {
    names => ['x1'],
    coef => [-0.2207016646656006],
    se => [0.09579000969652103],
    deviance => 388.7846770084886,
    df => 148,
    loglik => -388.09789492922044,
    resp => 'y_int_null',
    id_fe => 0,
    weights => 0,
    offset => 0,
    model => 'pois',
  },
  pois_w0_o0_fe1 => {
    names => ['x1'],
    coef => [0.056348062444003574],
    se => [0.12382602324758331],
    deviance => 373.78747245079614,
    df => 146,
    loglik => -380.59929265037425,
    resp => 'y_int_null',
    id_fe => 1,
    weights => 0,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1'], se => [0.09083046990376403] },
  },
  pois_w0_o0_fe2 => {
    names => ['x1'],
    coef => [0.023446792097432296],
    se => [0.12601771230901537],
    deviance => 371.5717561036236,
    df => 142,
    loglik => -379.491434476788,
    resp => 'y_int_null',
    id_fe => 2,
    weights => 0,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1'], se => [0.07808436262310932] },
  },
  pois_w0_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [-0.10010048099379457, 0.25487290364372417],
    se => [0.1385064919316944, 0.10657745482477687],
    deviance => 359.6180346429476,
    df => 133,
    loglik => -373.51457374644997,
    resp => 'y_int_null',
    id_fe => 7,
    weights => 0,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1', 'x2'], se => [0.0600523573599942, 0.23295597058989823] },
  },
  pois_w0_o1_fe0 => {
    names => ['x1'],
    coef => [0.37631404002801855],
    se => [0.10937632898410429],
    deviance => 600.2415898656797,
    df => 148,
    loglik => -493.826351357816,
    resp => 'y_int_null',
    id_fe => 0,
    weights => 0,
    offset => 1,
    model => 'pois',
  },
  pois_w0_o1_fe1 => {
    names => ['x1'],
    coef => [0.056348062444003505],
    se => [0.1238260232475834],
    deviance => 373.7874724507962,
    df => 146,
    loglik => -380.59929265037425,
    resp => 'y_int_null',
    id_fe => 1,
    weights => 0,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1'], se => [0.09083046990376412] },
  },
  pois_w0_o1_fe2 => {
    names => ['x1'],
    coef => [0.02344679209743262],
    se => [0.12601771230901535],
    deviance => 371.5717561036236,
    df => 142,
    loglik => -379.491434476788,
    resp => 'y_int_null',
    id_fe => 2,
    weights => 0,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1'], se => [0.07808436262310901] },
  },
  pois_w0_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [-0.1001004809937956, 0.2548729036437243],
    se => [0.1385064919316945, 0.10657745482477686],
    deviance => 359.6180346429476,
    df => 133,
    loglik => -373.51457374644997,
    resp => 'y_int_null',
    id_fe => 7,
    weights => 0,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1', 'x2'], se => [0.060052357359994, 0.23295597058989775] },
  },
  pois_w1_o0_fe0 => {
    names => ['x1'],
    coef => [0.1087420020953931],
    se => [0.11147534327981778],
    deviance => 408.15081082092587,
    df => 148,
    loglik => -419.37116396042023,
    resp => 'y_int_null',
    id_fe => 0,
    weights => 1,
    offset => 0,
    model => 'pois',
  },
  pois_w1_o0_fe1 => {
    names => ['x1'],
    coef => [0.1530678264124826],
    se => [0.11886003916981226],
    deviance => 406.01829511634105,
    df => 146,
    loglik => -418.30490610812785,
    resp => 'y_int_null',
    id_fe => 1,
    weights => 1,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1'], se => [0.061606288584298716] },
  },
  pois_w1_o0_fe2 => {
    names => ['x1'],
    coef => [0.10581245598392615],
    se => [0.12238893989084625],
    deviance => 400.8312401571185,
    df => 142,
    loglik => -415.71137862851657,
    resp => 'y_int_null',
    id_fe => 2,
    weights => 1,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1'], se => [0.0644834748554132] },
  },
  pois_w1_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [-0.1392307545543243, 0.35753691642885543],
    se => [0.1349467864866232, 0.08616528578872108],
    deviance => 379.43248737075146,
    df => 133,
    loglik => -405.01200223533306,
    resp => 'y_int_null',
    id_fe => 7,
    weights => 1,
    offset => 0,
    model => 'pois',
    cl => { names => ['x1', 'x2'], se => [0.04283843942978077, 0.18553452881044538] },
  },
  pois_w1_o1_fe0 => {
    names => ['x1'],
    coef => [-0.1624311640383621],
    se => [0.11604280055777474],
    deviance => 551.4375621740872,
    df => 148,
    loglik => -491.0145396370009,
    resp => 'y_int_null',
    id_fe => 0,
    weights => 1,
    offset => 1,
    model => 'pois',
  },
  pois_w1_o1_fe1 => {
    names => ['x1'],
    coef => [0.15306782641248318],
    se => [0.11886003916981229],
    deviance => 406.018295116341,
    df => 146,
    loglik => -418.3049061081278,
    resp => 'y_int_null',
    id_fe => 1,
    weights => 1,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1'], se => [0.06160628858429813] },
  },
  pois_w1_o1_fe2 => {
    names => ['x1'],
    coef => [0.10581245598392626],
    se => [0.12238893989084629],
    deviance => 400.83124015711854,
    df => 142,
    loglik => -415.71137862851657,
    resp => 'y_int_null',
    id_fe => 2,
    weights => 1,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1'], se => [0.06448347485541295] },
  },
  pois_w1_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [-0.1392307545543243, 0.35753691642885577],
    se => [0.13494678648662328, 0.0861652857887213],
    deviance => 379.4324873707515,
    df => 133,
    loglik => -405.01200223533306,
    resp => 'y_int_null',
    id_fe => 7,
    weights => 1,
    offset => 1,
    model => 'pois',
    cl => { names => ['x1', 'x2'], se => [0.042838439429781154, 0.18553452881044577] },
  },
  logit_w0_o0_fe0 => {
    names => ['x1'],
    coef => [2.666508542889177],
    se => [0.5419328752130543],
    deviance => 173.65112179960067,
    df => 148,
    loglik => -86.82556089980034,
    resp => 'y_01',
    id_fe => 0,
    weights => 0,
    offset => 0,
    model => 'logit',
  },
  logit_w0_o0_fe1 => {
    names => ['x1'],
    coef => [2.2312444867988575],
    se => [0.6366565189571997],
    deviance => 172.19105683334448,
    df => 146,
    loglik => -86.09552841667224,
    resp => 'y_01',
    id_fe => 1,
    weights => 0,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1'], se => [0.8762175363244551] },
  },
  logit_w0_o0_fe2 => {
    names => ['x1'],
    coef => [2.720463840996022],
    se => [0.7115462496428311],
    deviance => 165.08813186735128,
    df => 142,
    loglik => -82.54406593367564,
    resp => 'y_01',
    id_fe => 2,
    weights => 0,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1'], se => [0.9688591758434395] },
  },
  logit_w0_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [2.8404725229790286, 0.2665948762533665],
    se => [0.7877853915322708, 0.5008135292398066],
    deviance => 161.7183107767504,
    df => 133,
    loglik => -80.8591553883752,
    resp => 'y_01',
    id_fe => 7,
    weights => 0,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1', 'x2'], se => [1.16016469099959, 0.2699182714783776] },
  },
  logit_w0_o1_fe0 => {
    names => ['x1'],
    coef => [3.870512208803103],
    se => [0.5834104310713041],
    deviance => 194.5815742256479,
    df => 148,
    loglik => -97.29078711282395,
    resp => 'y_01',
    id_fe => 0,
    weights => 0,
    offset => 1,
    model => 'logit',
  },
  logit_w0_o1_fe1 => {
    names => ['x1'],
    coef => [2.2312444867988592],
    se => [0.6366565189571998],
    deviance => 172.19105683334448,
    df => 146,
    loglik => -86.09552841667224,
    resp => 'y_01',
    id_fe => 1,
    weights => 0,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1'], se => [0.8762175363244555] },
  },
  logit_w0_o1_fe2 => {
    names => ['x1'],
    coef => [2.7204638409960156],
    se => [0.7115462496428311],
    deviance => 165.08813186735128,
    df => 142,
    loglik => -82.54406593367564,
    resp => 'y_01',
    id_fe => 2,
    weights => 0,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1'], se => [0.9688591758434381] },
  },
  logit_w0_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [2.840472522979028, 0.2665948762533678],
    se => [0.7877853915322702, 0.5008135292398068],
    deviance => 161.7183107767504,
    df => 133,
    loglik => -80.8591553883752,
    resp => 'y_01',
    id_fe => 7,
    weights => 0,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1', 'x2'], se => [1.1601646909995829, 0.269918271478375] },
  },
  logit_w1_o0_fe0 => {
    names => ['x1'],
    coef => [2.309378149460986],
    se => [0.5919849465976521],
    deviance => 193.08410933360148,
    df => 148,
    loglik => -92.17923171374498,
    resp => 'y_01',
    id_fe => 0,
    weights => 1,
    offset => 0,
    model => 'logit',
  },
  logit_w1_o0_fe1 => {
    names => ['x1'],
    coef => [2.194209917057694],
    se => [0.6149002350742764],
    deviance => 192.61689083169284,
    df => 146,
    loglik => -92.00358409876021,
    resp => 'y_01',
    id_fe => 1,
    weights => 1,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1'], se => [0.9588757180226992] },
  },
  logit_w1_o0_fe2 => {
    names => ['x1'],
    coef => [2.941505010577185],
    se => [0.725517734178919],
    deviance => 181.69080116378788,
    df => 142,
    loglik => -86.69240060958869,
    resp => 'y_01',
    id_fe => 2,
    weights => 1,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1'], se => [1.3657436069850184] },
  },
  logit_w1_o0_fe7 => {
    names => ['x1', 'x2'],
    coef => [3.0554728532813207, 0.32297034226175286],
    se => [0.8233982059200038, 0.40089597798928356],
    deviance => 178.67800848388538,
    df => 133,
    loglik => -85.2933524985476,
    resp => 'y_01',
    id_fe => 7,
    weights => 1,
    offset => 0,
    model => 'logit',
    cl => { names => ['x1', 'x2'], se => [1.624736921912691, 0.18611480362127572] },
  },
  logit_w1_o1_fe0 => {
    names => ['x1'],
    coef => [2.18290352895769],
    se => [0.6112390472886204],
    deviance => 199.0607067199733,
    df => 148,
    loglik => -93.92063375829058,
    resp => 'y_01',
    id_fe => 0,
    weights => 1,
    offset => 1,
    model => 'logit',
  },
  logit_w1_o1_fe1 => {
    names => ['x1'],
    coef => [2.1942099170576994],
    se => [0.6149002350742766],
    deviance => 192.61689083169284,
    df => 146,
    loglik => -92.00358409876021,
    resp => 'y_01',
    id_fe => 1,
    weights => 1,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1'], se => [0.9588757180227024] },
  },
  logit_w1_o1_fe2 => {
    names => ['x1'],
    coef => [2.9415050105771843],
    se => [0.725517734178919],
    deviance => 181.69080116378788,
    df => 142,
    loglik => -86.69240060958869,
    resp => 'y_01',
    id_fe => 2,
    weights => 1,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1'], se => [1.3657436069850197] },
  },
  logit_w1_o1_fe7 => {
    names => ['x1', 'x2'],
    coef => [3.0554728532813185, 0.32297034226175325],
    se => [0.8233982059200037, 0.40089597798928334],
    deviance => 178.67800848388538,
    df => 133,
    loglik => -85.2933524985476,
    resp => 'y_01',
    id_fe => 7,
    weights => 1,
    offset => 1,
    model => 'logit',
    cl => { names => ['x1', 'x2'], se => [1.6247369219126986, 0.18611480362127691] },
  },
  negbin_w0_o0_fe0 => {
    names => ['x1'],
    coef => [-0.036985804847497195],
    se => [0.08118848873896145],
    deviance => 19.527042200664084,
    df => 148,
    loglik => -275.3445549104363,
    resp => 'y_int',
    id_fe => 0,
    weights => 0,
    offset => 0,
    model => 'negbin',
    theta => 736185.6364450782,
  },
  negbin_w0_o0_fe1 => {
    names => ['x1'],
    coef => [0.1466383933301707],
    se => [0.10539993441077432],
    deviance => 7.39233888809149,
    df => 146,
    loglik => -269.27686858177185,
    resp => 'y_int',
    id_fe => 1,
    weights => 0,
    offset => 0,
    model => 'negbin',
    theta => 1884780.4834067344,
    cl => { names => ['x1'], se => [0.016732986259945556] },
  },
  negbin_w0_o0_fe2 => {
    names => ['x1'],
    coef => [0.14854249625960855],
    se => [0.10753105752255138],
    deviance => 7.115372161592353,
    df => 142,
    loglik => -269.1383780762553,
    resp => 'y_int',
    id_fe => 2,
    weights => 0,
    offset => 0,
    model => 'negbin',
    theta => 1952902.9311761782,
    cl => { names => ['x1'], se => [0.012663779251099985] },
  },
);

my %FIXEST = (
  pois_fe1 => 0.056348062444005864,
  pois_fe2 => 0.02344679209743403,
  logit_fe1 => 2.231244486798858,
  ols_fe2 => 0.7907995083955297,
);

my %DID = (
  nobs => 980,
  removed => 100,
  fixest => 0.05555175722523464,
  glm => 0.055551757225234616,
  glm_se => 0.005162987119762412,
  deviance => 2143.186199867592,
  df => 872,
);

my %worst;
sub close_to {
	my ($got, $want, $tol, $class, $name) = @_;
	my $r = (defined $got && defined $want)
	      ? ($got == $want ? 0 : abs($got - $want) / (abs($want) > 0 ? abs($want) : 1))
	      : 9**9**9;
	$worst{$class} = $r if !defined $worst{$class} || $r > $worst{$class};
	ok($r <= $tol, $name) or diag("got " . ($got // 'undef') . ", want $want, relative $r > $tol");
}

my $base = $DATA{base};
for my $key (sort keys %EXPECT) {
	my $e = $EXPECT{$key};
	my $fam = { ols => 'gaussian', pois => 'poisson', logit => 'binomial', negbin => 'negbin' }->{ $e->{model} };
	my $rhs = $e->{id_fe} == 7 ? 'x1 + x2' : 'x1';
	my @fe = $e->{id_fe} == 1 ? ('species') : $e->{id_fe} == 2 ? ('species', 'fe_2')
	       : $e->{id_fe} == 7 ? ('sp_fe2') : ();
	my %o = (data => $base, family => $fam);
	$o{weights} = 'w' if $e->{weights};
	$o{offset} = 'offset_value' if $e->{offset};
	my $tol = $fam eq 'negbin' ? 1e-7 : 1e-9;
	# fixest's weights, species - 0.95, are not whole numbers, so a weighted
	# logit warns exactly as binomial()$initialize does in R
	my $warned = 0;
	local $SIG{__WARN__} = sub {
		die $_[0] unless $fam eq 'binomial' && $e->{weights} && $_[0] =~ /non-integer #successes/;
		$warned++;
	};
	my $class = $fam eq 'negbin' ? 'negbin' : 'glm';
	# both spellings: the formula's `| a + b` and absorb =>
	my @fits = (glm(%o, formula => "$e->{resp} ~ $rhs" . (@fe ? ' | ' . join(' + ', @fe) : '')));
	push @fits, glm(%o, formula => "$e->{resp} ~ $rhs", absorb => [@fe]) if @fe;
	for my $k (0 .. $#fits) {
		my $f = $fits[$k];
		my $how = $k ? 'absorb =>' : (@fe ? '| in formula' : 'no factor');
		for my $i (0 .. $#{ $e->{names} }) {
			my $nm = $e->{names}[$i];
			close_to($f->{coefficients}{$nm}, $e->{coef}[$i], $tol, $class, "$key ($how): coef $nm");
			close_to($f->{summary}{$nm}{'Std. Error'}, $e->{se}[$i], $tol, $class, "$key ($how): se $nm");
		}
		close_to($f->{deviance}, $e->{deviance}, $tol, $class, "$key ($how): deviance");
		close_to($f->{loglik}, $e->{loglik}, $tol, $class, "$key ($how): loglik");
		is($f->{'df.residual'}, $e->{df}, "$key ($how): df.residual counts the absorbed levels");
		ok(!exists $f->{coefficients}{Intercept}, "$key ($how): no intercept beside a factor") if @fe;
		ok($f->{theta} > 1e5, "$key ($how): theta is enormous, as glm.nb's is") if $fam eq 'negbin';
	}
	ok($warned, "$key: the non-integer-successes warning, as R gives it") if $fam eq 'binomial' && $e->{weights};
	if ($e->{cl}) {
		my $f = glm(%o, formula => "$e->{resp} ~ $rhs", absorb => [@fe], cluster => 'species');
		for my $i (0 .. $#{ $e->{cl}{names} }) {
			my $nm = $e->{cl}{names}[$i];
			close_to($f->{summary}{$nm}{'Std. Error'}, $e->{cl}{se}[$i], $tol, $class,
			         "$key: clustered se $nm, vcovCL(glm with dummies)");
		}
	}
}

close_to(glm(formula => 'y_int_null ~ x1 | species', data => $base, family => 'poisson')->{coefficients}{x1},
         $FIXEST{pois_fe1}, 1e-8, 'fixest', 'fepois(y_int_null ~ x1 | species)');
close_to(glm(formula => 'y_int_null ~ x1 | species + fe_2', data => $base, family => 'poisson')->{coefficients}{x1},
         $FIXEST{pois_fe2}, 1e-8, 'fixest', 'fepois(y_int_null ~ x1 | species + fe_2)');
close_to(glm(formula => 'y_01 ~ x1 | species', data => $base, family => 'binomial')->{coefficients}{x1},
         $FIXEST{logit_fe1}, 1e-8, 'fixest', 'feglm(y_01 ~ x1 | species, binomial)');
close_to(glm(formula => 'y ~ x1 | species + fe_2', data => $base)->{coefficients}{x1},
         $FIXEST{ols_fe2}, 1e-8, 'fixest', 'feols(y ~ x1 | species + fe_2)');

# ------------------------------------------------------------ base_did
{
	my %B;
	my $f = File::Spec->catfile('t', 'base_did.csv');
	open my $fh, '<', $f or die "cannot open $f: $!";
	my $hdr = <$fh>; $hdr =~ s/[\r\n"]+//g;
	my @c = split /,/, $hdr;
	while (my $l = <$fh>) {
		$l =~ s/[\r\n]+//;
		my @v = split /,/, $l;
		push @{ $B{ $c[$_] } }, $v[$_] + 0 for 0 .. $#c;
	}
	my $g = glm(formula => 'y ~ x1 | id + period', data => \%B, family => 'poisson');
	is($g->{'fe.removed'}, $DID{removed}, 'base_did: the ten all-zero ids are removed');
	is($g->{nobs}, $DID{nobs}, 'base_did: nobs, as fepois(fixef.rm = "infinite")');
	close_to($g->{coefficients}{x1}, $DID{fixest}, 1e-8, 'fixest', 'base_did: x1 against fepois');
	close_to($g->{coefficients}{x1}, $DID{glm}, 1e-9, 'glm', 'base_did: x1 against glm on the kept rows');
	close_to($g->{summary}{x1}{'Std. Error'}, $DID{glm_se}, 1e-9, 'glm', 'base_did: se against glm');
	close_to($g->{deviance}, $DID{deviance}, 1e-9, 'glm', 'base_did: deviance against glm');
	is($g->{'df.residual'}, $DID{df}, 'base_did: df.residual, two factors less their shared level');
	is_deeply($g->{absorb}, { id => 98, period => 10 }, 'absorb records the levels kept per factor');
}

# ------------------------------------------------------------ edges
{
	my %d = (y => [1, 3, 2, 5, 4, 6, 8, 7], x => [1, 2, 2, 3, 5, 4, 6, 6],
	         c => [1, 1, 1, 1, 2, 2, 2, 2], g => [qw(a a b b c c d d)]);
	# x constant within g is absorbed completely: aliased, as glm() gives NA
	my $f = glm(formula => 'y ~ x + c | g', data => \%d);
	is($f->{summary}{c}{Estimate}, 'NaN', 'a covariate constant within the factor is aliased');
	ok($f->{coefficients}{x} == $f->{coefficients}{x}, 'and the others are still estimated');
	eval { glm(formula => 'y ~ x |', data => \%d) };
	like($@, qr/nothing to absorb after '\|'/, 'an empty | croaks');
	eval { glm(formula => 'y ~ x', data => \%d, absorb => {}) };
	like($@, qr/absorb must be a column name or an array ref/, 'absorb of the wrong type croaks');
	eval { glm(formula => 'y ~ x', data => \%d, absorb => 'g', vcov => 'HC3') };
	like($@, qr/HC2\/HC3 are not available with absorbed factors/, 'HC3 with absorb croaks');
	eval { predict(glm(formula => 'y ~ x | g', data => \%d), \%d) };
	like($@, qr/absorbed fixed effects/, 'predict refuses a model with absorbed factors');
	my %z = (y => [0, 0, 1, 2, 3, 1], x => [1, 2, 3, 4, 5, 6], g => [qw(a a b b c c)]);
	eval { glm(formula => 'y ~ x | g', data => { y => [0, 0, 0, 0], x => [1, 2, 3, 4], g => [qw(a a b b)] },
	           family => 'poisson') };
	like($@, qr/some positive counts|every group of the absorbed factor/, 'all-zero outcome croaks');
	my $p = glm(formula => 'y ~ x | g', data => \%z, family => 'poisson');
	is($p->{'fe.removed'}, 2, 'an all-zero group is removed before fitting');
	ok(!exists $p->{'fitted.values'}{1} && exists $p->{'fitted.values'}{3},
	   'and its rows have no fitted value');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub {
		glm(formula => 'y_int_null ~ x1 | species + fe_2', data => $base, family => 'poisson',
		    cluster => 'species', weights => 'w');
	}, 'no leaks: two absorbed factors, weights and a cluster');
	Test::LeakTrace::no_leaks_ok(sub {
		eval { glm(formula => 'y ~ x1', data => $base, absorb => 'species', vcov => 'HC2') };
	}, 'no leaks: croak with absorbed factors');
}

diag(sprintf('worst relative disagreement, %s: %.3g', $_, $worst{$_})) for sort keys %worst;
done_testing();
