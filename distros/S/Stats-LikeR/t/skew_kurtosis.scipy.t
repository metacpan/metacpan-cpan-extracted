#!/usr/bin/env perl
# skew() and kurtosis(), against SciPy 1.18.1's own cases.
#
# Provenance (scipy/stats/tests/test_stats.py, SciPy 1.18.1, NumPy 2.4.6;
# t/skew_kurtosis.scipy.py, committed beside this file, printed every number
# below on 2026-11-26.  Re-run it with
#     /home/con/.pyenv/versions/3.14.2/bin/python3 -I t/skew_kurtosis.scipy.py
# This test never runs Python.):
#   SkewKurtosisTest   testmathworks = [1.165, 0.6268, 0.0751, 0.3516, -0.6965],
#                      testcase = [1, 2, 3, 4]
#   TestSkew.test_skewness            skew(testmathworks) -0.29322304336607 and
#                      bias=0 -0.437111105023940 (their literals; the
#                      generator's full-precision values are used here),
#                      skew(testcase) 0.0
#   TestSkew.test_nan_policy          skew(arange(9), nan_policy='omit') 0.0;
#                      a NaN in the sample gives NaN
#   TestSkew.test_skew_propagate_nan  [0, 1, 2, 3] row, and the NaN row's NaN
#   TestSkew.test_vectorization       the naive implementation there, run on
#                      default_rng(1283413549926).random((3, 4, 5)) with
#                      axis=None and axis=-1, bias both ways
#   TestKurtosis.test_kurtosis        fisher=0 bias=1 2.1658856802973,
#                      fisher=0 bias=0 3.663542721189047, testcase 1.64
#   TestKurtosis.test_kurtosis_nan_policy   arange(9) omit -1.23
#   TestKurtosis.test_kurtosis_propagate_nan  arange(4) -1.36
#   TestKurtosis.test_vectorization   random((4, 5, 6)) from the same seed, axis
#                      None and -1, bias x fisher
# README mapping: bias=True is type 1 (g1, g2), bias=False is type 2 (G1, G2),
# fisher=False adds 3 to the kurtosis.  Type 3 (e1071's b1, b2) is not in SciPy;
# the generator computes it from m3 / s**3 and m4 / s**4 - 3 with s the n - 1
# standard deviation, independently of the README's (n-1)/n form.  The README
# examples (skew(2,4,4,4,5,5,7,9), kurtosis of it, skew(1,2,4), kurtosis(1,2,3,10))
# are checked against SciPy's numbers for the same samples.
#
# Tolerance: relative to max(1, |expected|), 4e-12 (about 18000 double
# epsilons).  SciPy and the XS both use central moments in double; on 0.3430
# the two agree to the last digit or two (worst observed 1.8e-15, relative to max(1, |expected|)), and the
# margin is for long-double and quadmath NV builds, whose own rounding differs
# from the double reference.  The tolerance was not loosened.
#
# Deliberate differences, kept so that changing one is a decision:
#   - SciPy returns NaN for a sample of one value, a constant sample and an
#     empty sample (with a warning); skew() and kurtosis() croak instead (the
#     README's "Errors" section), so those SciPy cases are croak tests here.
#   - SciPy's nan_policy='omit' has no counterpart: a NaN gives NaN (README),
#     so the omit cases are given the sample with the NaN removed.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $TOL = 4e-12; # see header
sub near {
	my ($got, $exp, $name) = @_;
	if (!defined $got) { return ok(0, "$name (got undef)") }
	my $scale = abs($exp) > 1 ? abs($exp) : 1;
	my $ok = abs($got - $exp) <= $TOL * $scale;
	ok($ok, $name) or diag("got $got, expected $exp, difference " . abs($got - $exp));
}
sub isnan_ { my ($v, $name) = @_; ok(defined $v && $v != $v, $name) or diag('got ' . ($v // 'undef')) }

my @mw = (1.165, 0.6268, 0.0751, 0.3516, -0.6965);
my @tc = (1, 2, 3, 4);
my @x2 = (2, 4, 4, 4, 5, 5, 7, 9);
# default_rng(1283413549926).random((4, 5, 6)), row-major; its first 60 values
# are the random((3, 4, 5)) of TestSkew.test_vectorization (same seed)
my @K = (
	0.9259606203411983, 0.5788083333574375, 0.004681723552698691,
	0.4128116874798783, 0.9977154245009708, 0.1168120327254839,
	0.6663294619204525, 0.9605569982260099, 0.37903702295714414,
	0.4950889277404923, 0.3174818231956188, 0.28732744125715737,
	0.5482417701745635, 0.14669362805653552, 0.6030159834239763,
	0.6293180340328621, 0.7929001729115193, 0.9859105212447351,
	0.7283061653242558, 0.3948955688998188, 0.15965237152420741,
	0.34830667735565135, 0.7896116982776592, 0.916322417781504,
	0.4813386058280251, 0.6849979911337984, 0.7539714045608684,
	0.8812058878511015, 0.5962685011415095, 0.6231265741683013,
	0.9527538201950007, 0.3626970715138992, 0.6964086316235514,
	0.04221229329313525, 0.04757043202883626, 0.8101682427124792,
	0.06745905395820395, 0.30827486899599477, 0.6803035814319871,
	0.10725806493408929, 0.07593407732382151, 0.6146957989235696,
	0.04451829315714051, 0.7596777997223505, 0.946659840163453,
	0.5538120179849377, 0.24607874456668122, 0.15201148473884407,
	0.9139884284686929, 0.1673491022853415, 0.2694452101120779,
	0.45736590254603726, 0.6057762958291912, 0.1739453873173209,
	0.10356007208531115, 0.2575838349653268, 0.14206814485375785,
	0.451013524432345, 0.9347606322344785, 0.25287933786332084,
	0.8710916933524944, 0.06373739707405168, 0.660822600360056,
	0.2763139171604312, 0.7528915031700133, 0.16242570457584737,
	0.7959064281619184, 0.8986197765932646, 0.6831754026810675,
	0.8972751699504854, 0.23621814001786912, 0.04732778243107627,
	0.771021908123218, 0.9793128514175405, 0.7649004165322212,
	0.6427612489733361, 0.9477698313229076, 0.6306404549079647,
	0.335840347872995, 0.09851953915916567, 0.7179674802927183,
	0.8330500120682702, 0.36428372680957766, 0.9280677014266401,
	0.012091389550470732, 0.06051810697599391, 0.20735732642704707,
	0.10522841202017996, 0.9995527322561943, 0.7679075681410986,
	0.9034544951461663, 0.04054104928841484, 0.5491767315568797,
	0.41252355929824225, 0.8543963117853025, 0.3720121920909446,
	0.8419579636078021, 0.8618780263579958, 0.04157891384198842,
	0.8325261153821044, 0.7223161513613091, 0.7612980399314201,
	0.6399167208587273, 0.8251546044536187, 0.07887468173187906,
	0.5411423839924725, 0.48314326679451614, 0.8561645571857307,
	0.7997629745476733, 0.7013028557066489, 0.9577899070045601,
	0.19829600060737107, 0.3197158981346657, 0.7646304179779426,
	0.6172287586481853, 0.7988682964050984, 0.07880845910598866,
	0.03770260716087437, 0.292082632837084, 0.443448473495063
);
my @S = @K[0 .. 59];

#--------
# TestSkew.test_skewness and README samples: type 1 = bias, type 2 = unbiased
#--------
near(skew(\@mw, type => 1), -0.2932230433660737, 'test_skewness: testmathworks, bias=True (type 1)');
near(skew(\@mw, type => 2), -0.4371111050239397, 'test_skewness: testmathworks, bias=False (type 2)');
near(skew(\@mw, type => 3), -0.20981333041149106, 'testmathworks, type 3 (e1071 b1)');
near(skew(\@mw), -0.4371111050239397, 'default type is 2, as scipy bias=False');
near(skew(\@tc, type => 1), 0.0, 'test_skewness: testcase [1,2,3,4], type 1');
near(skew(\@tc), 0.0, 'test_skewness: testcase [1,2,3,4], type 2');
near(skew(\@tc, type => 3), 0.0, 'testcase [1,2,3,4], type 3');
near(skew(@x2), 0.8184875533567996, 'README sample 2,4,4,4,5,5,7,9, type 2');
near(skew(\@x2, type => 1), 0.65625, 'sample 2,4,4,4,5,5,7,9, type 1');
near(skew(\@x2, type => 3), 0.5371324568903997, 'sample 2,4,4,4,5,5,7,9, type 3');
near(skew(1, 2, 4, type => 1), 0.3818017741606059, 'README skew(1,2,4), type 1');
near(skew(1, 2, 4), 0.9352195295828235, 'README skew(1,2,4), type 2');
near(skew(1, 2, 4, type => 3), 0.2078265621295164, 'README skew(1,2,4), type 3');
near(skew(1, 2, 3, 10, type => 1), 1.0182337649086284, 'skew(1,2,3,10), type 1');
near(skew(1, 2, 3, 10, type => 2), 1.763632614803888, 'skew(1,2,3,10), type 2');
near(skew(1, 2, 3, 10, type => 3), 0.6613622305514579, 'skew(1,2,3,10), type 3');
near(skew(x => \@mw, type => 1), -0.2932230433660737, 'named x => arrayref');
near(skew([1.165, 0.6268], 0.0751, [0.3516, -0.6965], type => 1), -0.2932230433660737, 'mixed args flatten');

#--------
# nan_policy and NaN propagation
#--------
near(skew(0 .. 8, type => 1), 0.0, 'test_nan_policy: arange(10)[:9] (NaN omitted), type 1');
{
	my @x = (0 .. 8, 'NaN');
	isnan_(skew(\@x), 'test_nan_policy: NaN in the sample gives NaN (type 2)');
	isnan_(skew(\@x, type => 1), 'test_nan_policy: NaN in the sample gives NaN (type 1)');
	isnan_(skew(0, 'NaN', 2, 3), 'test_skew_propagate_nan: row with NaN');
	near(skew(0, 1, 2, 3, type => 1), 0.0, 'test_skew_propagate_nan: the clean row');
}

#--------
# TestSkew.test_vectorization (axis None, axis -1 row 0)
#--------
near(skew(\@S, type => 1), 0.07439450833297089, 'test_vectorization axis=None bias=True');
near(skew(\@S, type => 2), 0.0763158095184241, 'test_vectorization axis=None bias=False');
near(skew(\@S, type => 3), 0.07254241671445756, 'test_vectorization axis=None, type 3');
near(skew([ @S[0 .. 4] ], type => 1), -0.37555469724638013, 'test_vectorization axis=-1 row 0 bias=True');

#--------
# TestKurtosis.test_kurtosis
#--------
near(kurtosis(\@mw, type => 1) + 3, 2.165885680297262, 'test_kurtosis: fisher=0 bias=1 (type 1 + 3)');
near(kurtosis(\@mw, type => 2) + 3, 3.6635427211890494, 'test_kurtosis: fisher=0 bias=0 (type 2 + 3)');
near(kurtosis(\@mw, type => 1), -0.8341143197027381, 'testmathworks, type 1');
near(kurtosis(\@mw, type => 2), 0.6635427211890494, 'testmathworks, type 2');
near(kurtosis(\@mw, type => 3), -1.6138331646097523, 'testmathworks, type 3 (e1071 b2)');
near(kurtosis(\@mw), 0.6635427211890494, 'default type is 2, as scipy bias=False');
near(kurtosis(\@tc, type => 1) + 3, 1.64, 'test_kurtosis: testcase, fisher=0');
near(kurtosis(\@tc, type => 1), -1.36, 'testcase, type 1');
near(kurtosis(\@tc, type => 2), -1.1999999999999993, 'testcase, type 2');
near(kurtosis(\@tc, type => 3), -2.0775, 'testcase, type 3');
near(kurtosis(@x2), 0.9406249999999998, 'README sample 2,4,4,4,5,5,7,9, type 2');
near(kurtosis(\@x2, type => 1), -0.21875, 'sample 2,4,4,4,5,5,7,9, type 1');
near(kurtosis(\@x2, type => 3), -0.8706054687500004, 'sample 2,4,4,4,5,5,7,9, type 3');
near(kurtosis(1, 2, 3, 10, type => 1), -0.7696000000000001, 'README kurtosis(1,2,3,10), type 1');
near(kurtosis(1, 2, 3, 10), 3.2280000000000015, 'README kurtosis(1,2,3,10), type 2');
near(kurtosis(1, 2, 3, 10, type => 3), -1.7454000000000003, 'README kurtosis(1,2,3,10), type 3');
near(kurtosis(x => \@x2, type => 1), -0.21875, 'named x => arrayref');
near(kurtosis(0 .. 8, type => 1), -1.2300000000000002, 'test_kurtosis_nan_policy: arange(10)[:9] (NaN omitted)');
near(kurtosis(0, 1, 2, 3, type => 1), -1.36, 'test_kurtosis_propagate_nan: the clean row');
isnan_(kurtosis(0, 'NaN', 2, 3), 'test_kurtosis_propagate_nan: row with NaN');
isnan_(kurtosis(0 .. 7, 'NaN', type => 1), 'test_kurtosis: NaN in the sample (type 1)');
isnan_(kurtosis(0 .. 7, 'NaN', type => 3), 'test_kurtosis: NaN in the sample (type 3)');
isnan_(skew(1, 2, 'Inf'), 'an infinite value gives NaN (README), skew');
isnan_(kurtosis(1, 2, 3, 'Inf'), 'an infinite value gives NaN (README), kurtosis');

#--------
# TestKurtosis.test_vectorization (axis None, bias x fisher; axis -1 row 0)
#--------
near(kurtosis(\@K, type => 2) + 3, 1.6348740919690048, 'test_vectorization axis=None bias=False fisher=False');
near(kurtosis(\@K, type => 2), -1.3651259080309952, 'test_vectorization axis=None bias=False fisher=True');
near(kurtosis(\@K, type => 1) + 3, 1.6415078626101867, 'test_vectorization axis=None bias=True fisher=False');
near(kurtosis(\@K, type => 1), -1.3584921373898133, 'test_vectorization axis=None bias=True fisher=True');
near(kurtosis(\@K, type => 3), -1.3857366081650793, 'test_vectorization axis=None, type 3');
near(kurtosis([ @K[0 .. 5] ], type => 1), -1.4871384661435403, 'test_vectorization axis=-1 row 0 bias=True fisher=True');

#--------
# SkewKurtosisTest.test_empty_1d, test_skewness (scalar), constant-value tests:
# SciPy returns NaN; these croak (README "Errors")
#--------
throws_ok { skew([]) } qr/skew/, 'test_empty_1d: skew([]) croaks (scipy gives NaN)';
throws_ok { kurtosis([]) } qr/kurtosis/, 'test_empty_1d: kurtosis([]) croaks (scipy gives NaN)';
throws_ok { skew(4) } qr/needs >= 2 elements/, 'test_skewness: skew(4) croaks (scipy gives NaN)';
throws_ok { kurtosis(4) } qr/needs >= 2 elements/, 'test_kurtosis: kurtosis(4) croaks (scipy gives NaN)';
throws_ok { skew(1, 2, type => 2) } qr/type 2 needs >= 3 elements/, 'README: type 2 skew needs 3 values';
throws_ok { kurtosis(1, 2, 3, type => 2) } qr/type 2 needs >= 4 elements/, 'README: type 2 kurtosis needs 4 values';
lives_and { near(skew(1, 2, type => 1), 0.0, 'two values, type 1') } 'README: types 1 and 3 need only 2 values (skew)';
lives_and { near(kurtosis(1, 2, type => 1), -2, 'two values, type 1') } 'README: types 1 and 3 need only 2 values (kurtosis)';
throws_ok { skew((-0.27829495) x 10) } qr/zero variance/, 'test_skew_constant_value: constant -0.27829495 x10 croaks';
throws_ok { skew((14.3) x 7) } qr/zero variance/, 'test_skew_constant_value (gh-11086): 14.3 x7 croaks';
throws_ok { kurtosis((-0.27829495) x 10) } qr/zero variance/, 'test_kurtosis_constant_value: constant x10 croaks';
throws_ok { kurtosis((-0.27829495) x 10, type => 1) } qr/zero variance/, 'test_kurtosis_constant_value, type 1';
throws_ok { skew(1, 2, 3, type => 4) } qr/type/, 'type outside 1 .. 3 croaks (skew)';
throws_ok { kurtosis(1, 2, 3, 4, type => 0) } qr/type/, 'type outside 1 .. 3 croaks (kurtosis)';
throws_ok { skew(1, undef, 3) } qr/undefined value at argument index 1/, 'README: undef croaks (skew)';
throws_ok { kurtosis([1, 2, undef]) } qr/undefined value at array ref index 2 \(argument 0\)/, 'README: undef croaks (kurtosis)';

#--------
# leaks
#--------
no_leaks_ok { my $v = skew(\@mw, type => 3) } 'skew no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { my $v = kurtosis(\@K, type => 3) } 'kurtosis no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
