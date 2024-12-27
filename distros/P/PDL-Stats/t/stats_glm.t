use strict;
use warnings;
use Test::More;
use PDL::Stats::Basic;
use PDL::Stats::GLM;
use PDL::LiteF;
use PDL::NiceSlice;
use Test::PDL;

is_pdl pdl('BAD 1 2 3 4')->fill_m, pdl('2.5 1 2 3 4'), "fill_m replaces bad values with sample mean";

{
my $stdv = pdl('BAD 1 2 3 4')->fill_rand->stdv;
ok PDL::Core::approx( $stdv, 1.01980390271856 ) || PDL::Core::approx( $stdv, 1.16619037896906 ), "fill_rand replaces bad values with random sample of good values from same variable";
}

my $a = sequence 5;
is_pdl $a->dev_m, pdl('-2 -1 0 1 2'), "dev_m replaces values with deviations from the mean on $a";
is_pdl $a->stddz, pdl('-1.41421356237309 -0.707106781186547 0 0.707106781186547 1.41421356237309'), "stddz standardizes data on $a";

my $b = pdl(0, 0, 0, 1, 1);
is_pdl $a->sse($b), pdl(18), "sse gives sum of squared errors between actual and predicted values between $a and $b";
is_pdl $a->mse($b), pdl(3.6), "mse gives mean of squared errors between actual and predicted values between $a and $b";
is_pdl $a->rmse($b), pdl(1.89736659610103), "rmse gives root mean squared error, ie. stdv around predicted value between $a and $b";

is_pdl $b->glue(1,ones(5))->pred_logistic(pdl(1,2)), pdl('0.880797077977882 0.880797077977882 0.880797077977882 0.952574126822433 0.952574126822433'), "pred_logistic calculates predicted probability value for logistic regression";

my $y = pdl(0, 1, 0, 1, 0);
is_pdl $y->d0(), pdl( 6.73011667009256 ), 'd0';
is_pdl $y->dm( ones(5) * .5 ), pdl( 6.93147180559945 ), 'dm';
is_pdl $y->dvrs(ones(5) * .5) ** 2, pdl('1.38629436111989 1.38629436111989 1.38629436111989 1.38629436111989 1.38629436111989'), 'dvrs';

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
  is_pdl $m{R2}, $rsq, 'ols_t R2';
  is_pdl $m{b}, $coeff, 'ols_t b';

  my %m0 = $a->ols_t(sequence(5), {CONST=>0});
  my $b0 = pdl ([ 0.2 ], [ 0.23333333 ]);
  is_pdl $m0{b}, $b0, 'ols_t, const=>0';
}

{
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

{
  my $a = pdl '0 1 2 3 4 BAD';
  my $b = pdl(0,0,0,1,1,1);
  my %m = $a->ols($b, {plot=>0});
  is_pdl $b, pdl(0,0,0,1,1,1), "ols with bad value didn't change caller value";
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

{
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
eigenvalue  => float( qw( 2.786684 0.18473727 0.028578689) ),
  # loadings in R
eigenvector => [float(
    # v1       v2        v3
 [qw(  0.58518141   0.58668657   0.55978709)],  # comp1
 [qw( -0.41537629  -0.37601061   0.82829859)],  # comp2
 [qw( -0.69643754   0.71722722 -0.023661276)],  # comp3
), \&PDL::abs],

loadings	=> [float(
 [qw(   0.97686463    0.97937725    0.93447296)],
 [qw(  -0.17853319    -0.1616134    0.35601163)],
 [qw(  -0.11773439    0.12124893 -0.0039999937)],
), \&PDL::abs],

pct_var	=> pdl( qw(0.92889468 0.06157909 0.0095262297) ),
  );
  test_stats_cmp(\%p, \%a, 1e-5);

  %p = $a->pca({CORR=>0, PLOT=>0});
  %a = (
eigenvalue => [float(qw[ 22.0561695 1.581758022 0.202065959 ]), \&PDL::abs],
eigenvector => [float(
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

{
  # pca_sorti - principal component analysis output sorted to find which vars a component is best represented
  my $a = pdl '
    0 1 2 3 4 5 6 0 8 9; 10 11 12 13  0 15 16 17 18 19;
    20  0 22 23 24 25 26 27  0 29; 30 31 32 33 34  0 36 37 38 39;
    40 41  0 43 44 45 46 47 48  0
  ';
  my %m = $a->pca({PLOT=>0});
  my ($iv, $ic) = $m{loadings}->pca_sorti;
  is_pdl $iv, indx(qw(4 1 0 2 3));
  is_pdl $ic, pdl(qw( 0 1 2 ));
}

SKIP: {
  eval { require PDL::Fit::LM; };
  skip 'no PDL::Fit::LM', 1 if $@;
  my $y = pdl( 0, 0, 0, 1, 1 );
  my $x = pdl(2, 3, 5, 5, 5);
  my %m = $y->logistic( $x );
  my $y_pred = $x->glue(1, ones(5))->pred_logistic( $m{b} );
  my $y_pred_ans
    = pdl qw(7.2364053e-07 0.00010154254 0.66666667 0.66666667 0.66666667);
  is_pdl $y_pred, $y_pred_ans;
  is_pdl $m{Dm_chisq}, pdl 2.91082711764867;
  %m = $y->logistic( $x, {COV=>1} );
  isnt $m{cov}, undef, 'get cov from logistic if ask';
};

my $a_bad = pdl '0 1 2 3 4 BAD';
my $b_bad = pdl 'BAD 0 0 0 1 1';
is_pdl $a_bad->dev_m, pdl( '-2 -1 0 1 2 BAD' ), "dev_m with bad values $a_bad";
is_pdl $a_bad->stddz, pdl( '-1.41421356237309 -0.707106781186547 0 0.707106781186547 1.41421356237309 BAD' ), "stdz with bad values $a_bad";
is_pdl $a_bad->sse($b_bad), pdl(23), "sse with bad values between $a_bad and $b_bad";
is_pdl $a_bad->mse($b_bad), pdl(5.75), "mse with badvalues between $a_bad and $b_bad";
is_pdl $a_bad->rmse($b_bad), pdl( 2.39791576165636 ), "rmse with bad values between $a_bad and $b_bad";
is_pdl $b_bad->glue(1,ones(6))->pred_logistic(pdl(1,2)), pdl( 'BAD 0.880797077977882 0.880797077977882 0.880797077977882 0.952574126822433 0.952574126822433' ), "pred_logistic with bad values";
is_pdl $b_bad->d0(), pdl( 6.73011667009256 ), "null deviance with bad values on $b_bad";
is_pdl $b_bad->dm( ones(6) * .5 ), pdl( 6.93147180559945 ), "model deviance with bad values on $b_bad";
is_pdl $b_bad->dvrs(ones(6) * .5), pdl( 'BAD -1.17741002251547 -1.17741002251547 -1.17741002251547 1.17741002251547 1.17741002251547' ), "deviance residual with bad values on $b_bad";

{
  eval { effect_code(['a']) };
  isnt $@, '', 'effect_code with only one value dies';
  my $a = scalar effect_code([qw(a a a b b b b c c BAD)]);
  is_pdl $a, pdl('1 1 1 0 0 0 0 -1 -1 BAD; 0 0 0 1 1 1 1 -1 -1 BAD'), 'effect_code coded with bad value';
}

{
  eval { effect_code_w(['a']) };
  isnt $@, '', 'effect_code_w with only one value dies';
  is_pdl scalar effect_code_w([qw(a a a b b b b c c c)]), pdl '
    1 1 1 0 0 0 0 -1 -1 -1; 0 0 0 1 1 1 1 -1.3333333 -1.3333333 -1.3333333
  ';
}

{ # anova 3 way
  my $d = sequence 60;
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  my $b = $d % 3;
  my $c = $d % 2;
  $d->set( 20, 10 );
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0});
  $m{'# A ~ B ~ C # m'} = $m{'# A ~ B ~ C # m'}->(,2,)->squeeze;
  test_stats_cmp(\%m, {
    '| A | F' => 165.252100840336,
    '| A ~ B ~ C | F' => 0.0756302521008415,
    '# A ~ B ~ C # m' => pdl([[qw(8 18 38 53)], [qw(8 23 38 53)]]),
  });
}

{ # anova 1 way
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

{ # anova_3w bad dv
  my $d = sequence 60;
  $d->set( 20, 10 );
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

{ # anova_3w bad dv iv
  my $d = sequence 63;
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  push @a, undef, qw( b c );
  my $b = $d % 3;
  my $c = $d % 2;
  $d->set( 20, 10 );
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

is_pdl pdl('BAD 1 2 3 4; BAD BAD BAD BAD BAD')->fill_m, pdl('2.5 1 2 3 4; 0 0 0 0 0'), 'fill_m nan to bad';
is_pdl pdl([1,1,1], [2,2,2])->stddz, zeroes(3,2), 'stddz nan vs bad';

{
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

{ # anova_rptd_1w
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

my %anova_bad_a = (
  '| a | F' => 0.351351351351351,
  '| a | ms' => 0.722222222222222,
  '| a ~ b | F' => 5.25,
  '# a ~ b # m' => pdl(qw( 3  1.3333333  3.3333333 3.3333333  3.6666667  2.6666667  ))->reshape(3,2),
);
{ # anova_rptd_2w bad dv
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

{ # anova_rptd_2w bad iv
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

{ # anova_rptd_3w
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

{ # anova_rptd mixed
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

sub test_stats_cmp {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($m, $ans, $eps) = @_;
  $eps ||= 1e-6;
  foreach (sort keys %$ans) {
    my $got = PDL->topdl($m->{$_});
    my $exp = $ans->{$_};
    if (ref $exp eq 'ARRAY') {
      ($exp, my $func) = @$exp;
      ($got, $exp) = map &$func($_), $got, $exp;
    }
    is_pdl $got, PDL->topdl($exp), {atol=>$eps, require_equal_types=>0, test_name=>$_};
  }
}
my %anova_ans_l2_common = (
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
$anova_ans_l2_common{"| within ~ between || err $_"} = $anova_ans_l2_common{"| within || err $_"} foreach qw/df ss ms/;
my %anova_ans_l3_common = (
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
$anova_ans_l3_common{"| within ~ between || err $_"} = $anova_ans_l3_common{"| within || err $_"} foreach qw/df ss ms/;
if (0) { # FIXME
  # anova_rptd mixed with 2 btwn-subj var levels, data grouped by within var
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
  my $s = sequence(8)->dummy(1,3)->flat;
  # [0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7]
  my $w = qsort sequence(24) % 3;
  # [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  my $b = (sequence(8) % 2)->qsort->dummy(1,3)->flat;
  # [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l2_common);
}
{
  # anova_rptd mixed with 2 btwn-subj var levels, data grouped by subject
  my $d = pdl qw( 3 1 4 2 4 2 1 1 1 5 2 5 2 3 4 1 5 3 5 5 2 3 3 2);
  my $s = qsort sequence(24) % 8;
  # [0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7]
  my $w = sequence(3)->dummy(1,8)->flat;
  # [0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]
  my $b = qsort sequence(24) % 2;
  # [0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1]
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l2_common);
}
if (0) { # FIXME
  # eps=.001 anova_rptd mixed with 3 btwn-subj var levels, data grouped by within var
  my $d = pdl qw( 5 2 2 5 4 1 5 3 5 4 4 3 4 3 4 3 5 1 4 3 3 4 5 4 5 5 2 );
  my $s = sequence(9)->dummy(1,3)->flat;
  # [0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8]
  my $w = qsort sequence(27) % 3;
  # [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]
  my $b = (sequence(9) % 3)->qsort->dummy(1,3)->flat;
  # [0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2]
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l3_common);
}
if (0) { # FIXME
  # eps=.001 anova_rptd mixed with 3 btwn-subj var levels, data grouped by subject
  my $d = pdl qw( 5 4 4 2 4 3 2 3 3 5 4 4 4 3 5 1 4 4 5 3 5 3 5 5 5 1 2 );
  my $s = qsort sequence(27) % 9;
  # [0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8]
  my $w = sequence(3)->dummy(1,9)->flat;
  # [0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]
  my $b = qsort sequence(27) % 3;
  # [0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l3_common);
}

{ # anova_rptd mixed bad
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

{ # anova_rptd_mixed_4w
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
  my $ans = pdl '1 -1  0 -0 -1  1 -1  1 -0  0  1 -1; 0 -0  1 -1 -1  1 -0  0 -1  1  1 -1';
  my $inter = interaction_code( $a, $b, $c);
  is_pdl $inter, $ans, 'interaction_code';
}

done_testing();

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
