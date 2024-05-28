use strict;
use warnings;
use Test::More;
use PDL::Stats::Basic;
use PDL::Stats::GLM;
use PDL::LiteF;
use PDL::NiceSlice;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->max;
  return $diff < $eps;
}

my $a = sequence 5;
my $b = pdl(0, 0, 0, 1, 1);

is( t_fill_m(), 1, "fill_m replaces bad values with sample mean");
sub t_fill_m {
  my $aa = sequence 5;
  $aa = $aa->setvaltobad(0);
  tapprox( $aa->fill_m->sum, 12.5 );
}

is( t_fill_rand(), 1, "fill_rand replaces bad values with random sample of good values from same variable");
sub t_fill_rand {
  my $aa = sequence 5;
  $aa = $aa->setvaltobad(0);
  my $stdv = $aa->fill_rand->stdv;
  tapprox( $stdv, 1.01980390271856 ) || tapprox( $stdv, 1.16619037896906 );
}

ok tapprox( $a->dev_m->avg, 0 ), "dev_m replaces values with deviations from the mean on $a";
ok tapprox( $a->stddz->avg, 0 ), "stddz standardizes data on $a";

ok tapprox( $a->sse($b), 18), "sse gives sum of squared errors between actual and predicted values between $a and $b";
ok tapprox( $a->mse($b), 3.6), "mse gives mean of squared errors between actual and predicted values between $a and $b";
ok tapprox( $a->rmse($b), 1.89736659610103 ), "rmse gives root mean squared error, ie. stdv around predicted value between $a and $b";

ok tapprox( $b->glue(1,ones(5))->pred_logistic(pdl(1,2))->sum, 4.54753948757851 ), "pred_logistic calculates predicted probability value for logistic regression";

my $y = pdl(0, 1, 0, 1, 0);
ok tapprox( $y->d0(), 6.73011667009256 ), 'd0';
ok tapprox( $y->dm( ones(5) * .5 ), 6.93147180559945 ), 'dm';
ok tapprox( sum($y->dvrs(ones(5) * .5) ** 2), 6.93147180559945 ), 'dvrs';

{
  my $a = pdl(ushort, [0,0,1,0,1], [0,0,0,1,1] );
  my $b = cat sequence(5), sequence(5)**2;
  $b = cat $b, $b * 2;
  my %m = $a->ols_t($b->dummy(2));
  my $rsq = pdl( [
                  [ 0.33333333, 0.80952381 ],
                  [ 0.33333333, 0.80952381 ],
                 ],
            );
  my $coeff = pdl(
   [
    [qw(           0.2 -3.3306691e-16  -1.110223e-16)],
    [qw(   0.014285714    0.071428571   -0.057142857)],
   ],
   [
    [qw(           0.1 -1.6653345e-16  -1.110223e-16)],
    [qw(  0.0071428571    0.035714286   -0.057142857)],
   ],
  );
  ok tapprox( sum( abs($m{R2} - $rsq) ), 0 ), 'ols_t R2';
  ok tapprox( sum( abs($m{b} - $coeff) ), 0 ), 'ols_t b';

  my %m0 = $a->ols_t(sequence(5), {CONST=>0});
  my $b0 = pdl ([ 0.2 ], [ 0.23333333 ]);

  ok tapprox( sum( abs($m0{b} - $b0) ), 0 ), 'ols_t, const=>0';
}

ok tapprox( t_ols(), 0 ), 'ols';
sub t_ols {
  my $a = sequence 5;
  my $b = pdl(0,0,0,1,1);
  my %m = $a->ols($b, {plot=>0});
  my %a = (
    F    => 9,
    F_df => pdl(1,3),
    R2   => .75,
    b    => pdl(2.5, 1),
    b_se => pdl(0.83333333, 0.52704628),
    b_t  => pdl(3, 1.8973666),
    ss_total => 10,
    ss_model => 7.5,
  );
  test_stats_cmp(\%m, \%a);
}

ok tapprox( t_ols_bad(), 0 ), 'ols with bad value';
sub t_ols_bad {
  my $a = sequence 6;
  my $b = pdl(0,0,0,1,1,1);
  $a->setbadat(5);
  my %m = $a->ols($b, {plot=>0});
  is( $b->sumover, 3, "ols with bad value didn't change caller value" );
  ok $a->check_badflag, "ols with bad value didn't remove caller bad flag";
  my %a = (
    F    => 9,
    F_df => pdl(1,3),
    R2   => .75,
    b    => pdl(2.5, 1),
    b_se => pdl(0.83333333, 0.52704628),
    b_t  => pdl(3, 1.8973666),
    ss_total => 10,
    ss_model => 7.5,
  );
  test_stats_cmp(\%m, \%a);
}

ok tapprox( t_r2_change(), 0 ), 'r2_change';
sub t_r2_change {
  my $a = sequence 5, 2;
  my $b = pdl(0,0,0,1,1);
  my $c = pdl(0,0,2,2,2);
  my %m = $a->r2_change( $b, cat $b, $c );
  my %a = (
F_change  => pdl(3, 3),
F_df      => pdl(1, 2),
R2_change => pdl(.15, .15),
  );
  test_stats_cmp(\%m, \%a);
}

{ # pca
  my $a = pdl (
   [qw(1 3 6 6 8)],
   [qw(1 4 6 8 9)],
   [qw(0 2 2 4 9)],
  );

  my %p = $a->pca({CORR=>1, PLOT=>0});
  my %a = (
eigenvalue  => pdl( qw( 2.786684 0.18473727 0.028578689) ),
  # loadings in R
eigenvector => [pdl(
    # v1       v2        v3
 [qw(  0.58518141   0.58668657   0.55978709)],  # comp1
 [qw( -0.41537629  -0.37601061   0.82829859)],  # comp2
 [qw( -0.69643754   0.71722722 -0.023661276)],  # comp3
), \&PDL::abs],

loadings	=> [pdl(
 [qw(   0.97686463    0.97937725    0.93447296)],
 [qw(  -0.17853319    -0.1616134    0.35601163)],
 [qw(  -0.11773439    0.12124893 -0.0039999937)],
), \&PDL::abs],

pct_var	=> pdl( qw(0.92889468 0.06157909 0.0095262297) ),
  );
  test_stats_cmp(\%p, \%a, 1e-5);

  %p = $a->pca({CORR=>0, PLOT=>0});
  %a = (
eigenvalue => [pdl(qw[ 22.0561695 1.581758022 0.202065959 ]), \&PDL::abs],
eigenvector => [pdl(
 [qw(-0.511688 -0.595281 -0.619528)],
 [qw( 0.413568  0.461388  -0.78491)],
 [qw( 0.753085 -0.657846 0.0101023)],
), \&PDL::abs],

loadings    => [pdl(
 [qw(-0.96823408  -0.9739215 -0.94697802)],
 [qw( 0.20956865  0.20214966 -0.32129495)],
 [qw( 0.13639532 -0.10301693 0.001478041)],
), \&PDL::abs],

pct_var => pdl( qw[0.925175 0.0663489 0.00847592] ),
  );
  test_stats_cmp(\%p, \%a, 1e-4);
}

ok tapprox( t_pca_sorti(), 0 ), "pca_sorti - principal component analysis output sorted to find which vars a component is best represented";
sub t_pca_sorti {
  my $a = sequence 10, 5;
  $a = lvalue_assign_detour( $a, which($a % 7 == 0), 0 );

  my %m = $a->pca({PLOT=>0});

  my ($iv, $ic) = $m{loadings}->pca_sorti;

  return sum($iv - pdl(qw(4 1 0 2 3))) + sum($ic - pdl(qw( 0 1 2 )));
}

SKIP: {
  eval { require PDL::Fit::LM; };
  skip 'no PDL::Fit::LM', 1 if $@;

  ok tapprox( t_logistic(), 0 ), 'logistic';

  my $y = pdl( 0, 0, 0, 1, 1 );
  my $x = pdl(2, 3, 5, 5, 5);
  my %m = $y->logistic( $x, {COV=>1} );
  isnt $m{cov}, undef, 'get cov from logistic if ask';
};
sub t_logistic {
  my $y = pdl( 0, 0, 0, 1, 1 );
  my $x = pdl(2, 3, 5, 5, 5);
  my %m = $y->logistic( $x );
  my $y_pred = $x->glue(1, ones(5))->pred_logistic( $m{b} );
  my $y_pred_ans
    = pdl qw(7.2364053e-07 0.00010154254 0.66666667 0.66666667 0.66666667);
  return sum( $y_pred - $y_pred_ans, $m{Dm_chisq} - 2.91082711764867 );
}

my $a_bad = sequence 6;
$a_bad->setbadat(-1);
my $b_bad = pdl(0, 0, 0, 0, 1, 1);
$b_bad->setbadat(0);

ok tapprox( $a_bad->dev_m->avg, 0 ), "dev_m with bad values $a_bad";
ok tapprox( $a_bad->stddz->avg, 0 ), "stdz with bad values $a_bad";

ok tapprox( $a_bad->sse($b_bad), 23), "sse with bad values between $a_bad and $b_bad";
ok tapprox( $a_bad->mse($b_bad), 5.75), "mse with badvalues between $a_bad and $b_bad";
ok tapprox( $a_bad->rmse($b_bad), 2.39791576165636 ), "rmse with bad values between $a_bad and $b_bad";

ok tapprox( $b_bad->glue(1,ones(6))->pred_logistic(pdl(1,2))->sum, 4.54753948757851 ), "pred_logistic with bad values";

ok tapprox( $b_bad->d0(), 6.73011667009256 ), "null deviance with bad values on $b_bad";
ok tapprox( $b_bad->dm( ones(6) * .5 ), 6.93147180559945 ), "model deviance with bad values on $b_bad";
ok tapprox( sum($b_bad->dvrs(ones(6) * .5) ** 2), 6.93147180559945 ), "deviance residual with bad values on $b_bad";

{
  eval { effect_code(['a']) };
  isnt $@, '', 'effect_code with only one value dies';
  my @a = qw( a a a b b b b c c BAD );
  my $a = effect_code(\@a);
  my $ans = pdl [
   [qw( 1   1   1   0   0   0   0  -1  -1 -99 )],
   [qw( 0   0   0   1   1   1   1  -1  -1 -99 )]
  ];
  $ans = $ans->setvaltobad(-99);
  is( sum(abs(which($a->isbad) - pdl(9,19))), 0, 'effect_code got bad value' );
  ok tapprox( sum(abs($a - $ans)), 0 ), 'effect_code coded with bad value';
}

ok tapprox( t_effect_code_w(), 0 ), 'effect_code_w';
sub t_effect_code_w {
  eval { effect_code_w(['a']) };
  isnt $@, '', 'effect_code_w with only one value dies';
  my @a = qw( a a a b b b b c c c );
  my $a = effect_code_w(\@a);
  return sum($a->sumover - pdl byte, (0, 0));
}

ok tapprox( t_anova(), 0 ), 'anova_3w';
sub t_anova {
  my $d = sequence 60;
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  my $b = $d % 3;
  my $c = $d % 2;
  $d = lvalue_assign_detour( $d, 20, 10 );
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0});
  $m{'# A ~ B ~ C # m'} = $m{'# A ~ B ~ C # m'}->(,2,)->squeeze;
  test_stats_cmp(\%m, {
    '| A | F' => 165.252100840336,
    '| A ~ B ~ C | F' => 0.0756302521008415,
    '# A ~ B ~ C # m' => pdl([[qw(8 18 38 53)], [qw(8 23 38 53)]]),
  });
}

ok tapprox( t_anova_1way(), 0 ), 'anova_1w';
sub t_anova_1way {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 );
  my $a = qsort sequence(15) % 3;
  my %m = $d->anova($a, {plot=>0});
  $m{$_} = $m{$_}->squeeze for '# IV_0 # m';
  test_stats_cmp(\%m, {
    F => 0.160919540229886,
    ms_model => 0.466666666666669,
    '# IV_0 # m' => pdl(qw( 2.6 2.8 3.2 )),
  });
}

ok tapprox( t_anova_bad_dv(), 0 ), 'anova_3w bad dv';
sub t_anova_bad_dv {
  my $d = sequence 60;
  $d = lvalue_assign_detour( $d, 20, 10 );
  $d->setbadat(1);
  $d->setbadat(10);
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  my $b = sequence(60) % 3;
  my $c = sequence(60) % 2;
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0, v=>0});
  $m{$_} = $m{$_}->(,1,)->squeeze for '# A ~ B ~ C # m', '# A ~ B ~ C # se';
  test_stats_cmp(\%m, {
    '| A | F' => 150.00306433446,
    '| A ~ B ~ C | F' => 0.17534855325553,
    '# A ~ B ~ C # m' => pdl([qw( 4 22 37 52 )], [qw( 10 22 37 52 )]),
    '# A ~ B ~ C # se' => pdl([qw( 0 6 1.7320508 3.4641016 )], [qw( 3 3 3.4641016 1.7320508 )]),
  });
}

ok tapprox( t_anova_bad_dv_iv(), 0 ), 'anova_3w bad dv iv';
sub t_anova_bad_dv_iv {
  my $d = sequence 63;
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  push @a, undef, qw( b c );
  my $b = $d % 3;
  my $c = $d % 2;
  $d = lvalue_assign_detour( $d, 20, 10 );
  $d->setbadat(62);
  $b->setbadat(61);
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0});
  $m{$_} = $m{$_}->(,2,)->squeeze for '# A ~ B ~ C # m';
  test_stats_cmp(\%m, {
    '| A | F' => 165.252100840336,
    '| A ~ B ~ C | F' => 0.0756302521008415,
    '# A ~ B ~ C # m' => pdl([qw(8 18 38 53)], [qw(8 23 38 53)]),
  });
}

{
  my $a = pdl([0,1,2,3,4], [0,0,0,0,0]);
  $a = $a->setvaltobad(0);
  is( $a->fill_m->setvaltobad(0)->nbad, 5, 'fill_m nan to bad');
}

{
  my $a = pdl([1,1,1], [2,2,2]);
  is( which($a->stddz == 0)->nelem, 6, 'stddz nan vs bad');
}

ok tapprox( t_anova_rptd_basic(), 0 ), 'anova_rptd_basic';
sub t_anova_rptd_basic {
  # data from https://www.youtube.com/watch?v=Fh73dAOMm9M
  # Person,Before,After 2 weeks,After 4 weeks
  # P1,102,97,95
  # P2,79,77,75
  # P3,83,77,75
  # P4,92,93,87
  # in Octave, statistics package 1.4.2:
  # [p, table] = repanova([102 97 95; 79 77 75; 83 77 75; 92 93 87], 3, 'string')
  # p = 7.3048e-03
  # table =
  # Source	SS	df	MS	F	Prob > F
  # Subject	916.667	3	305.556
  # Measure	72	2	36	12.4615	0.00730475
  # Error	17.3333	6	2.88889
  # turned into format for anova_rptd, then ($data, $idv, $subj) = rtable 'diet.txt', {SEP=>','}
  # Person,Week,Weight
  # P1,0,102
  # P1,2,97
  # P1,4,95
  # P2,0,79
  # P2,2,77
  # P2,4,75
  # P3,0,83
  # P3,2,77
  # P3,4,75
  # P4,0,92
  # P4,2,93
  # P4,4,87
  my ($data, $ivnm, $subj) = (
    pdl( q[
      [  0   2   4   0   2   4   0   2   4   0   2   4]
      [102  97  95  79  77  75  83  77  75  92  93  87]
    ] ),
    [ qw(Week) ],
    [ qw(P1 P1 P1 P2 P2 P2 P3 P3 P3 P4 P4 P4) ],
  );
  my ($w, $dv) = $data->dog;
  my %m = $dv->anova_rptd($subj, $w, {ivnm=>$ivnm});
  test_stats_cmp(\%m, {
    '| Week | F' => 12.4615384615385,
    '| Week | df' => 2,
    '| Week | ms' => 36,
    '| Week | ss' => 72,
    ss_subject => 916.666666,
  });
}

ok tapprox( t_anova_rptd_1way(), 0 ), 'anova_rptd_1w';
sub t_anova_rptd_1way {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 );
  my $s = sequence(5)->dummy(1,3)->flat;
  my $a = qsort sequence(15) % 3;
  my %m = $d->anova_rptd($s, $a, {plot=>0});
  $m{$_} = $m{$_}->squeeze for '# IV_0 # m';
  test_stats_cmp(\%m, {
    '| IV_0 | F' => 0.145077720207254,
    '| IV_0 | ms' => 0.466666666666667,
    '# IV_0 # m' => pdl(qw( 2.6 2.8 3.2 )),
  });
}

ok tapprox( t_anova_rptd_2way_bad_dv(), 0 ), 'anova_rptd_2w bad dv';
my %anova_bad_a = (
  '| a | F' => 0.351351351351351,
  '| a | ms' => 0.722222222222222,
  '| a ~ b | F' => 5.25,
  '# a ~ b # m' => pdl(qw( 3  1.3333333  3.3333333 3.3333333  3.6666667  2.6666667  ))->reshape(3,2),
);
sub t_anova_rptd_2way_bad_dv {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
  $d = $d->setbadat(5);
  my $s = sequence(4)->dummy(1,6)->flat;
# [0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]
  my $a = qsort sequence(24) % 3;
# [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  my $b = (sequence(8) > 3)->dummy(1,3)->flat;
# [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_bad_a);
}

ok tapprox( t_anova_rptd_2way_bad_iv(), 0 ), 'anova_rptd_2w bad iv';
sub t_anova_rptd_2way_bad_iv {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
  my $s = sequence(4)->dummy(1,6)->flat;
# [0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]
  my $a = qsort sequence(24) % 3;
  $a = $a->setbadat(5);
# [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  my $b = (sequence(8) > 3)->dummy(1,3)->flat;
# [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_bad_a);
}

ok tapprox( t_anova_rptd_3way(), 0 ), 'anova_rptd_3w';
sub t_anova_rptd_3way {
  my $d = pdl( qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2 ),
               qw( 5 5 1 1 4 4 1 4 4 2 3 3 5 1 1 2 4 4 4 5 5 1 1 2 )
  );
  my $s = sequence(4)->dummy(0,12)->flat;
  my $a = sequence(2)->dummy(0,6)->flat->dummy(1,4)->flat;
  my $b = sequence(2)->dummy(0,3)->flat->dummy(1,8)->flat;
  my $c = sequence(3)->dummy(1,16)->flat;
  my %m = $d->anova_rptd($s, $a, $b, $c, {ivnm=>['a','b', 'c'],plot=>0});
  test_stats_cmp(\%m, {
    '| a | F' => 0.572519083969459,
    '| a | ms' => 0.520833333333327,
    '| a ~ c | F' => 3.64615384615385,
    '| b ~ c || err ms' => 2.63194444444445,
    '| a ~ b ~ c | F' => 1.71299093655589,
    '# a ~ b ~ c # m' => pdl(qw( 4 2.75 2.75 2.5 3.25 4.25 3.5 1.75 2 3.5 2.75 2.25 ))->reshape(2,2,3),
    '# a ~ b # se' => ones(2, 2) * 0.55014729,
  });
}

ok tapprox( t_anova_rptd_mixed(), 0 ), 'anova_rptd mixed';
sub t_anova_rptd_mixed {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
  my $s = sequence(4)->dummy(1,6)->flat;
# [0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]
  my $a = qsort sequence(24) % 3;
# [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  my $b = (sequence(8) > 3)->dummy(1,3)->flat;
# [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, {
    '| a | F' => 0.0775862068965517,
    '| a | ms' => 0.125,
    '| a ~ b | F' => 1.88793103448276,
    '| b | F' => 0.585657370517928,
    '| b || err ms' => 3.48611111111111,
    '# a ~ b # se' => ones(3,2) * 0.63464776,
  });
}

# Tests for mixed anova thanks to Erich Greene

ok tapprox( t_anova_rptd_mixed_l2ord2(), 0,      ), 'anova_rptd mixed with 2 btwn-subj var levels, data grouped by subject';
SKIP: {
    skip "yet to be fixed", 3;
    ok tapprox( t_anova_rptd_mixed_l2ord1(), 0,      ), 'anova_rptd mixed with 2 btwn-subj var levels, data grouped by within var';
    ok tapprox( t_anova_rptd_mixed_l3ord1(), 0, .001 ), 'anova_rptd mixed with 3 btwn-subj var levels, data grouped by within var';
    ok tapprox( t_anova_rptd_mixed_l3ord2(), 0, .001 ), 'anova_rptd mixed with 3 btwn-subj var levels, data grouped by subject';
}
sub test_stats_cmp {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($m, $ans, $eps) = @_;
  $eps ||= 1e-6;
  my $error = pdl 0;
  foreach (sort keys %$ans) {
    my $got = PDL->topdl($m->{$_});
    my $exp = $ans->{$_};
    if (ref $exp eq 'ARRAY') {
      ($exp, my $func) = @$exp;
      ($got, $exp) = map &$func($_), $got, $exp;
    }
    $exp = PDL->topdl($exp);
    $error = $error + (my $this_diff = $got - $exp);
    fail($_), diag "got $m->{$_}\nexpected $exp" if any($this_diff->abs > $eps);
  }
  return $error;
}
sub t_anova_rptd_mixed_backend {
    my ($d,$s,$w,$b,$ans) = @_;
    my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
    test_stats_cmp(\%m, $ans);
}
sub t_anova_rptd_mixed_l2_common {
    my ($d,$s,$w,$b) = @_;
    my %ans = (
	       '| within | df'           => 2,
	       '| within || err df'      => 12,
	       '| within | ss'           =>   .25,
	       '| within | ms'           =>   .125,
	       '| within || err ss'      => 23.666667,
	       '| within || err ms'      =>  1.9722222,
	       '| within | F'            =>  0.063380282,
	       '| between | df'          =>  1,
	       '| between || err df'     =>  6,
	       '| between | ss'          =>  2.0416667,
	       '| between | ms'          =>  2.0416667,
	       '| between || err ss'     => 16.583333,
	       '| between || err ms'     =>  2.7638889,
	       '| between | F'           =>  0.73869347,
	       '| within ~ between | df' =>  2,
	       '| within ~ between | ss' =>  6.0833333,
	       '| within ~ between | ms' =>  3.0416667,
	       '| within ~ between | F'  =>  1.5422535,
	      );
    $ans{"| within ~ between || err $_"} = $ans{"| within || err $_"} foreach qw/df ss ms/;
    return t_anova_rptd_mixed_backend($d,$s,$w,$b,\%ans);
}
sub t_anova_rptd_mixed_l3_common {
    my ($d,$s,$w,$b) = @_;
    my %ans = (
	       '| within | df'           =>  2,
	       '| within || err df'      => 12,
	       '| within | ss'           =>   .963,
	       '| within | ms'           =>   .481,
	       '| within || err ss'      => 20.889,
	       '| within || err ms'      =>  1.741,
	       '| within | F'            =>   .277,
	       '| between | df'          =>  2,
	       '| between || err df'     =>  6,
	       '| between | ss'          =>  1.185,
	       '| between | ms'          =>   .593,
	       '| between || err ss'     => 13.111,
	       '| between || err ms'     =>  2.185,
	       '| between | F'           =>   .271,
	       '| within ~ between | df' =>  4,
	       '| within ~ between | ss' =>  4.148,
	       '| within ~ between | ms' =>  1.037,
	       '| within ~ between | F'  =>   .596,
	      );
    $ans{"| within ~ between || err $_"} = $ans{"| within || err $_"} foreach qw/df ss ms/;
    return t_anova_rptd_mixed_backend($d,$s,$w,$b,\%ans);
}
sub t_anova_rptd_mixed_l2ord1 {
    my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
    my $s = sequence(8)->dummy(1,3)->flat;
    # [0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7]
    my $w = qsort sequence(24) % 3;
    # [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
    my $b = (sequence(8) % 2)->qsort->dummy(1,3)->flat;
    # [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
    return t_anova_rptd_mixed_l2_common($d,$s,$w,$b);
}
sub t_anova_rptd_mixed_l2ord2 {
    my $d = pdl qw( 3 1 4 2 4 2 1 1 1 5 2 5 2 3 4 1 5 3 5 5 2 3 3 2);
    my $s = qsort sequence(24) % 8;
    # [0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7]
    my $w = sequence(3)->dummy(1,8)->flat;
    # [0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]
    my $b = qsort sequence(24) % 2;
    # [0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1]
    return t_anova_rptd_mixed_l2_common($d,$s,$w,$b);
}
sub t_anova_rptd_mixed_l3ord1 {
    my $d = pdl qw( 5 2 2 5 4 1 5 3 5 4 4 3 4 3 4 3 5 1 4 3 3 4 5 4 5 5 2 );
    my $s = sequence(9)->dummy(1,3)->flat;
    # [0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8]
    my $w = qsort sequence(27) % 3;
    # [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]
    my $b = (sequence(9) % 3)->qsort->dummy(1,3)->flat;
    # [0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2]
    return t_anova_rptd_mixed_l3_common($d,$s,$w,$b);
}
sub t_anova_rptd_mixed_l3ord2 {
    my $d = pdl qw( 5 4 4 2 4 3 2 3 3 5 4 4 4 3 5 1 4 4 5 3 5 3 5 5 5 1 2 );
    my $s = qsort sequence(27) % 9;
    # [0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8]
    my $w = sequence(3)->dummy(1,9)->flat;
    # [0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]
    my $b = qsort sequence(27) % 3;
    # [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]
    return t_anova_rptd_mixed_l3_common($d,$s,$w,$b);
}


ok tapprox( t_anova_rptd_mixed_bad(), 0 ), 'anova_rptd mixed bad';
sub t_anova_rptd_mixed_bad {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2 1 1 1 1 );
  my $s = sequence(4)->dummy(1,6)->flat;
# [0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]
# add subj 4 at the end
  $s = $s->append(ones(4) * 4);
  my $a = qsort sequence(24) % 3;
# [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  $a = $a->append(zeroes(4));
  my $b = (sequence(8) > 3)->dummy(1,3)->flat;
# [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  $b = $b->append(zeroes(4));
  # any missing value causes all data from the subject (4) to be dropped
  $b->setbadat(-1);
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, {
    '| a | F' => 0.0775862068965517,
    '| a | ms' => 0.125,
    '| a ~ b | F' => 1.88793103448276,
    '| b | F' => 0.585657370517928,
    '| b || err ms' => 3.48611111111111,
    '# a ~ b # se' => ones(3,2) * 0.63464776,
  });
}

ok tapprox( t_anova_rptd_mixed_4w(), 0 ), 'anova_rptd_mixed_4w';
sub t_anova_rptd_mixed_4w {
  my ($data, $idv, $subj) = rtable \*DATA, {v=>0};
  my ($age, $aa, $beer, $wings, $dv) = $data->dog;
  my %m = $dv->anova_rptd( $subj, $age, $aa, $beer, $wings, { ivnm=>[qw(age aa beer wings)], btwn=>[0,1], v=>0, plot=>0 } );
  test_stats_cmp(\%m, {
    '| aa | F' => 0.0829493087557666,
    '| age ~ aa | F' => 2.3594470046083,
    '| beer | F' => 0.00943396226415362,
    '| aa ~ beer | F' => 0.235849056603778,
    '| age ~ beer ~ wings | F' => 0.0303030303030338,
    '| beer ~ wings | F' => 2.73484848484849,
    '| age ~ aa ~ beer ~ wings | F' => 3.03030303030303,
  });
}

{
  my $a = effect_code( sequence(12) > 5 );
  my $b = effect_code([ map {(0, 1)} (1..6) ]);
  my $c = effect_code([ map {(0,0,1,1,2,2)} (1..2) ]);

  my $ans = pdl [
   [qw( 1 -1  0 -0 -1  1 -1  1 -0  0  1 -1 )],
   [qw( 0 -0  1 -1 -1  1 -0  0 -1  1  1 -1 )]
  ];
  my $inter = interaction_code( $a, $b, $c);

  is(sum(abs($inter - $ans)), 0, 'interaction_code');
}

done_testing();

sub lvalue_assign_detour {
    my ($pdl, $index, $new_value) = @_;

    my @arr = list $pdl;
    my @ind = ref($index)? list($index) : $index; 
    $arr[$_] = $new_value
        for (@ind);

    return pdl(\@arr)->reshape($pdl->dims)->sever;
}

__DATA__
subj	age	Apple-android	beer	wings	recall
1	0	0	0	0	5
1	0	0	0	1	4
1	0	0	1	0	8
1	0	0	1	1	3
2	0	0	0	0	3
2	0	0	0	1	7
2	0	0	1	0	9
2	0	0	1	1	3
3	0	0	0	0	2
3	0	0	0	1	9
3	0	0	1	0	1
3	0	0	1	1	0
1	0	1	0	0	4
1	0	1	0	1	6
1	0	1	1	0	9
1	0	1	1	1	6
2	0	1	0	0	9
2	0	1	0	1	7
2	0	1	1	0	5
2	0	1	1	1	8
3	0	1	0	0	6
3	0	1	0	1	6
3	0	1	1	0	3
3	0	1	1	1	4
1	1	0	0	0	8
1	1	0	0	1	8
1	1	0	1	0	10
1	1	0	1	1	7
2	1	0	0	0	10
2	1	0	0	1	1
2	1	0	1	0	8
2	1	0	1	1	11
3	1	0	0	0	4
3	1	0	0	1	10
3	1	0	1	0	5
3	1	0	1	1	2
1	1	1	0	0	10
1	1	1	0	1	6
1	1	1	1	0	10
1	1	1	1	1	6
2	1	1	0	0	2
2	1	1	0	1	5
2	1	1	1	0	9
2	1	1	1	1	4
3	1	1	0	0	3
3	1	1	0	1	5
3	1	1	1	0	9
3	1	1	1	1	2
