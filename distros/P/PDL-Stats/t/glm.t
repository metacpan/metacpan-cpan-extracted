use strict;
use warnings;
use Test::More;
use PDL::Stats::Basic;
use PDL::Stats::GLM;
use PDL::LiteF;
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
  my $rsq = pdl('0.33333333 0.80952381; 0.33333333 0.80952381');
  my $coeff = pdl('
   [0 0.2 0; -0.057142 0.014285 0.071428]
   [0 0.1 0; -0.057142 0.007142 0.035714]
  ');
  is_pdl $m{R2}, $rsq, 'ols_t R2';
  is_pdl $m{b}, $coeff, 'ols_t b';

  my %m0 = $a->ols_t(sequence(5), {CONST=>0});
  is_pdl $m0{b}, pdl('0.2; 0.23333333'), 'ols_t, const=>0';
}

{
  my $a = sequence 5;
  my $b = pdl(0,0,0,1,1);
  my %m = $a->ols($b, {plot=>0});
  my %a = (
    F    => 9,
    F_df => pdl(1,3),
    R2   => .75,
    b    => pdl(1, 2.5),
    b_se => pdl(0.52704628, 0.83333333),
    b_t  => pdl(1.8973666, 3),
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
    b    => pdl(1, 2.5),
    b_se => pdl(0.52704628, 0.83333333),
    b_t  => pdl(1.8973666, 3),
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

{
  # This is the example from Lorch and Myers (1990),
  # a study on how characteristics of sentences affected reading time
  # Three within-subject IVs:
  # SP -- serial position of sentence
  # WORDS -- number of words in sentence
  # NEW -- number of new arguments in sentence
  my $lorch_data = <<'EOF';
Snt	Sp	Wrds	New	subj	DV
1	1	13	1	1	3.429
2	2	16	3	1	6.482
3	3	9	2	1	1.714
4	4	9	2	1	3.679
5	5	10	3	1	4.000
6	6	18	4	1	6.973
7	7	6	1	1	2.634
1	1	13	1	2	2.795
2	2	16	3	2	5.411
3	3	9	2	2	2.339
4	4	9	2	2	3.714
5	5	10	3	2	2.902
6	6	18	4	2	8.018
7	7	6	1	2	1.750
1	1	13	1	3	4.161
2	2	16	3	3	4.491
3	3	9	2	3	3.018
4	4	9	2	3	2.866
5	5	10	3	3	2.991
6	6	18	4	3	6.625
7	7	6	1	3	2.268
1	1	13	1	4	3.071
2	2	16	3	4	5.063
3	3	9	2	4	2.464
4	4	9	2	4	2.732
5	5	10	3	4	2.670
6	6	18	4	4	7.571
7	7	6	1	4	2.884
1	1	13	1	5	3.625
2	2	16	3	5	9.295
3	3	9	2	5	6.045
4	4	9	2	5	4.205
5	5	10	3	5	3.884
6	6	18	4	5	8.795
7	7	6	1	5	3.491
1	1	13	1	6	3.161
2	2	16	3	6	5.643
3	3	9	2	6	2.455
4	4	9	2	6	6.241
5	5	10	3	6	3.223
6	6	18	4	6	13.188
7	7	6	1	6	3.688
1	1	13	1	7	3.232
2	2	16	3	7	8.357
3	3	9	2	7	4.920
4	4	9	2	7	3.723
5	5	10	3	7	3.143
6	6	18	4	7	11.170
7	7	6	1	7	2.054
1	1	13	1	8	7.161
2	2	16	3	8	4.313
3	3	9	2	8	3.366
4	4	9	2	8	6.330
5	5	10	3	8	6.143
6	6	18	4	8	6.071
7	7	6	1	8	1.696
1	1	13	1	9	1.536
2	2	16	3	9	2.946
3	3	9	2	9	1.375
4	4	9	2	9	1.152
5	5	10	3	9	2.759
6	6	18	4	9	7.964
7	7	6	1	9	1.455
1	1	13	1	10	4.063
2	2	16	3	10	6.652
3	3	9	2	10	2.179
4	4	9	2	10	3.661
5	5	10	3	10	3.330
6	6	18	4	10	7.866
7	7	6	1	10	3.705
EOF
  open my $fh, '<', \$lorch_data or die "Couldn't open scalar: $!";
  my ($data, $idv, $ido) = rtable $fh, {V=>0};
  my %r = $data->slice(',(4)')->ols_rptd( $data->t->using(3,0,1,2) );
  #print "\n$_\t$r{$_}\n" for sort keys %r;
  test_stats_cmp(\%r, {
    ss_total => pdl(405.188241771429),
    ss_residual => pdl(58.3754646504336),
    ss_subject => pdl(51.8590337714289),
    ss => pdl(18.450705, 73.813294, 0.57026483),
    ss_err => pdl(23.036272, 10.827623, 5.0104731),
    coeff => pdl(0.33337285, 0.45858933, 0.15162986),
    F => pdl(7.208473, 61.354153, 1.0243311),
  });
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
  my %exp = (
eigenvalue => [float('1.59695565700531 1.17390930652618 1.05055177211761 0.60359400510788 0.574989080429077'), \&PDL::abs],
eigenvector => [float('
0.576511 0.538729 0.213031 0.232488 0.527233;
0.237671 0.290144 0.792538 0.305884 0.371008;
0.279697 0.367018 0.0690239 0.811981 0.350699;
0.707315 0.697799 0.0780877 0.0814506 0.00705761;
0.180619 0.062942 0.561818 0.431784 0.679219
'), \&PDL::abs],

loadings    => [my $loadings = pdl('
0.72854035 0.68079491 0.2692094 0.29379663 -0.66626785;
-0.25750895 -0.31436277 0.85869179 -0.33141797 -0.4019762;
-0.28667967 -0.37618117 -0.07074587 0.83225134 -0.35945416;
-0.54952221 0.54212932 0.060667887 0.063280383 0.0054838393;
0.13696062 0.047727115 0.42601542 0.32741254 0.51503877
'), \&PDL::abs],

pct_var => pdl('0.319391131401062 0.234781861305237 0.210110354423523 0.120718801021576 0.114997816085815'),
  );
  test_stats_cmp(\%m, \%exp, 1e-4);
  is_pdl $m{loadings}, $loadings, {require_equal_types=>0};
  my ($iv, $ic) = $loadings->pca_sorti;
  is_pdl $iv, indx(qw(0 1 4 2 3));
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
  my @a = (('a')x 15, ('b')x 15, ('c')x 15, ('d')x 15);
  my $b = $d % 3;
  my $c = $d % 2;
  $d->set( 20, 10 );
  my @idv = qw(A B C);
  my %m = $d->anova(\@a, $b, $c, {IVNM=>\@idv, plot=>0});
  $m{'| A ~ B ~ C | m'} = $m{'| A ~ B ~ C | m'}->slice(',(2),');
  test_stats_cmp(\%m, {
    '| A | F' => 165.252100840336,
    '| A ~ B ~ C | F' => 0.0756302521008415,
    '| A ~ B ~ C | m' => pdl([[qw(8 18 38 53)], [qw(8 23 38 53)]]),
  });
  my $dsgn = $d->anova_design_matrix(undef, \@a, $b, $c, {IVNM=>\@idv});
  is_pdl $dsgn, pdl '
 [1  1  0  0  1  0  1  1  0  0  0  0  0  1  0  0  1  0  1  0  0  0  0  0]
 [1  1  0  0  0  1 -1  0  0  0  1  0  0 -1  0  0  0 -1  0  0  0 -1  0  0]
 [1  1  0  0 -1 -1  1 -1  0  0 -1  0  0  1  0  0 -1 -1 -1  0  0 -1  0  0]
 [1  1  0  0  1  0 -1  1  0  0  0  0  0 -1  0  0 -1  0 -1  0  0  0  0  0]
 [1  1  0  0  0  1  1  0  0  0  1  0  0  1  0  0  0  1  0  0  0  1  0  0]
 [1  1  0  0 -1 -1 -1 -1  0  0 -1  0  0 -1  0  0  1  1  1  0  0  1  0  0]
 [1  1  0  0  1  0  1  1  0  0  0  0  0  1  0  0  1  0  1  0  0  0  0  0]
 [1  1  0  0  0  1 -1  0  0  0  1  0  0 -1  0  0  0 -1  0  0  0 -1  0  0]
 [1  1  0  0 -1 -1  1 -1  0  0 -1  0  0  1  0  0 -1 -1 -1  0  0 -1  0  0]
 [1  1  0  0  1  0 -1  1  0  0  0  0  0 -1  0  0 -1  0 -1  0  0  0  0  0]
 [1  1  0  0  0  1  1  0  0  0  1  0  0  1  0  0  0  1  0  0  0  1  0  0]
 [1  1  0  0 -1 -1 -1 -1  0  0 -1  0  0 -1  0  0  1  1  1  0  0  1  0  0]
 [1  1  0  0  1  0  1  1  0  0  0  0  0  1  0  0  1  0  1  0  0  0  0  0]
 [1  1  0  0  0  1 -1  0  0  0  1  0  0 -1  0  0  0 -1  0  0  0 -1  0  0]
 [1  1  0  0 -1 -1  1 -1  0  0 -1  0  0  1  0  0 -1 -1 -1  0  0 -1  0  0]
 [1  0  1  0  1  0 -1  0  1  0  0  0  0  0 -1  0 -1  0  0 -1  0  0  0  0]
 [1  0  1  0  0  1  1  0  0  0  0  1  0  0  1  0  0  1  0  0  0  0  1  0]
 [1  0  1  0 -1 -1 -1  0 -1  0  0 -1  0  0 -1  0  1  1  0  1  0  0  1  0]
 [1  0  1  0  1  0  1  0  1  0  0  0  0  0  1  0  1  0  0  1  0  0  0  0]
 [1  0  1  0  0  1 -1  0  0  0  0  1  0  0 -1  0  0 -1  0  0  0  0 -1  0]
 [1  0  1  0 -1 -1  1  0 -1  0  0 -1  0  0  1  0 -1 -1  0 -1  0  0 -1  0]
 [1  0  1  0  1  0 -1  0  1  0  0  0  0  0 -1  0 -1  0  0 -1  0  0  0  0]
 [1  0  1  0  0  1  1  0  0  0  0  1  0  0  1  0  0  1  0  0  0  0  1  0]
 [1  0  1  0 -1 -1 -1  0 -1  0  0 -1  0  0 -1  0  1  1  0  1  0  0  1  0]
 [1  0  1  0  1  0  1  0  1  0  0  0  0  0  1  0  1  0  0  1  0  0  0  0]
 [1  0  1  0  0  1 -1  0  0  0  0  1  0  0 -1  0  0 -1  0  0  0  0 -1  0]
 [1  0  1  0 -1 -1  1  0 -1  0  0 -1  0  0  1  0 -1 -1  0 -1  0  0 -1  0]
 [1  0  1  0  1  0 -1  0  1  0  0  0  0  0 -1  0 -1  0  0 -1  0  0  0  0]
 [1  0  1  0  0  1  1  0  0  0  0  1  0  0  1  0  0  1  0  0  0  0  1  0]
 [1  0  1  0 -1 -1 -1  0 -1  0  0 -1  0  0 -1  0  1  1  0  1  0  0  1  0]
 [1  0  0  1  1  0  1  0  0  1  0  0  0  0  0  1  1  0  0  0  1  0  0  0]
 [1  0  0  1  0  1 -1  0  0  0  0  0  1  0  0 -1  0 -1  0  0  0  0  0 -1]
 [1  0  0  1 -1 -1  1  0  0 -1  0  0 -1  0  0  1 -1 -1  0  0 -1  0  0 -1]
 [1  0  0  1  1  0 -1  0  0  1  0  0  0  0  0 -1 -1  0  0  0 -1  0  0  0]
 [1  0  0  1  0  1  1  0  0  0  0  0  1  0  0  1  0  1  0  0  0  0  0  1]
 [1  0  0  1 -1 -1 -1  0  0 -1  0  0 -1  0  0 -1  1  1  0  0  1  0  0  1]
 [1  0  0  1  1  0  1  0  0  1  0  0  0  0  0  1  1  0  0  0  1  0  0  0]
 [1  0  0  1  0  1 -1  0  0  0  0  0  1  0  0 -1  0 -1  0  0  0  0  0 -1]
 [1  0  0  1 -1 -1  1  0  0 -1  0  0 -1  0  0  1 -1 -1  0  0 -1  0  0 -1]
 [1  0  0  1  1  0 -1  0  0  1  0  0  0  0  0 -1 -1  0  0  0 -1  0  0  0]
 [1  0  0  1  0  1  1  0  0  0  0  0  1  0  0  1  0  1  0  0  0  0  0  1]
 [1  0  0  1 -1 -1 -1  0  0 -1  0  0 -1  0  0 -1  1  1  0  0  1  0  0  1]
 [1  0  0  1  1  0  1  0  0  1  0  0  0  0  0  1  1  0  0  0  1  0  0  0]
 [1  0  0  1  0  1 -1  0  0  0  0  0  1  0  0 -1  0 -1  0  0  0  0  0 -1]
 [1  0  0  1 -1 -1  1  0  0 -1  0  0 -1  0  0  1 -1 -1  0  0 -1  0  0 -1]
 [1 -1 -1 -1  1  0 -1 -1 -1 -1  0  0  0  1  1  1 -1  0  1  1  1  0  0  0]
 [1 -1 -1 -1  0  1  1  0  0  0 -1 -1 -1 -1 -1 -1  0  1  0  0  0 -1 -1 -1]
 [1 -1 -1 -1 -1 -1 -1  1  1  1  1  1  1  1  1  1  1  1 -1 -1 -1 -1 -1 -1]
 [1 -1 -1 -1  1  0  1 -1 -1 -1  0  0  0 -1 -1 -1  1  0 -1 -1 -1  0  0  0]
 [1 -1 -1 -1  0  1 -1  0  0  0 -1 -1 -1  1  1  1  0 -1  0  0  0  1  1  1]
 [1 -1 -1 -1 -1 -1  1  1  1  1  1  1  1 -1 -1 -1 -1 -1  1  1  1  1  1  1]
 [1 -1 -1 -1  1  0 -1 -1 -1 -1  0  0  0  1  1  1 -1  0  1  1  1  0  0  0]
 [1 -1 -1 -1  0  1  1  0  0  0 -1 -1 -1 -1 -1 -1  0  1  0  0  0 -1 -1 -1]
 [1 -1 -1 -1 -1 -1 -1  1  1  1  1  1  1  1  1  1  1  1 -1 -1 -1 -1 -1 -1]
 [1 -1 -1 -1  1  0  1 -1 -1 -1  0  0  0 -1 -1 -1  1  0 -1 -1 -1  0  0  0]
 [1 -1 -1 -1  0  1 -1  0  0  0 -1 -1 -1  1  1  1  0 -1  0  0  0  1  1  1]
 [1 -1 -1 -1 -1 -1  1  1  1  1  1  1  1 -1 -1 -1 -1 -1  1  1  1  1  1  1]
 [1 -1 -1 -1  1  0 -1 -1 -1 -1  0  0  0  1  1  1 -1  0  1  1  1  0  0  0]
 [1 -1 -1 -1  0  1  1  0  0  0 -1 -1 -1 -1 -1 -1  0  1  0  0  0 -1 -1 -1]
 [1 -1 -1 -1 -1 -1 -1  1  1  1  1  1  1  1  1  1  1  1 -1 -1 -1 -1 -1 -1]
';
}

{ # anova with too few samples for experiment (3*2*2 categories, 12 samples)
my $y = pdl '[1 1 2 2 3 3 3 3 4 5 5 5]'; # ratings for 12 apples
my $a = sequence(12) % 3 + 1; # IV for types of apple
my @b = qw( y y y y y y n n n n n n ); # IV for whether we baked the apple
my @c = qw( r g r g r g r g r g r g ); # IV for apple colour (red/green)
eval {$y->anova( $a, \@b, \@c, { IVNM=>[qw(apple bake colour)], PLOT=>0 } )};
like $@, qr/residual df = 0/, 'error when too few sample';
}

{ # anova 1 way
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 );
  my $a = qsort sequence(15) % 3;
  my %m = $d->anova($a, {plot=>0});
  test_stats_cmp(\%m, {
    F => 0.160919540229886,
    ms_model => 0.466666666666669,
    '| IV_0 | m' => pdl(qw( 2.6 2.8 3.2 )),
  });
}

{ # anova_3w bad dv
  my $d = sequence 60;
  $d->set( 20, 10 );
  $d->setbadat(1);
  $d->setbadat(10);
  my @a = (('a')x 15, ('b')x 15, ('c')x 15, ('d')x 15);
  my $b = sequence(60) % 3;
  my $c = sequence(60) % 2;
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0, v=>0});
  $m{$_} = $m{$_}->slice(',(1)') for '| A ~ B ~ C | m', '| A ~ B ~ C | se';
  test_stats_cmp(\%m, {
    '| A | F' => 150.00306433446,
    '| A ~ B ~ C | F' => 0.17534855325553,
    '| A ~ B ~ C | m' => pdl([qw( 4 22 37 52 )], [qw( 10 22 37 52 )]),
    '| A ~ B ~ C | se' => pdl([qw( 0 6 1.7320508 3.4641016 )], [qw( 3 3 3.4641016 1.7320508 )]),
  });
}

{ # anova_3w bad dv iv
  my $d = sequence 63;
  my @a = (('a')x 15, ('b')x 15, ('c')x 15, ('d')x 15);
  push @a, undef, qw( b c );
  my $b = $d % 3;
  my $c = $d % 2;
  $d->set( 20, 10 );
  $d->setbadat(62);
  $b->setbadat(61);
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0, V=>0});
  $m{$_} = $m{$_}->slice(',(2)') for '| A ~ B ~ C | m';
  test_stats_cmp(\%m, {
    '| A | F' => 165.252100840336,
    '| A ~ B ~ C | F' => 0.0756302521008415,
    '| A ~ B ~ C | m' => pdl([qw(8 18 38 53)], [qw(8 23 38 53)]),
  });
}

{ # anova_nist_low
  # data from https://www.itl.nist.gov/div898/strd/anova/SmLs01.html
  #  1   2   3   4   5   6   7   8   9
  # 1.4 1.3 1.5 1.3 1.5 1.3 1.5 1.3 1.5
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # 1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4
  # 1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6
  # Certified Values:
  # Source of                  Sums of               Mean
  # Variation          df      Squares              Squares             F Statistic
  # Between Treatment   8 1.68000000000000E+00 2.10000000000000E-01 2.10000000000000E+01
  # Within Treatment  180 1.80000000000000E+00 1.00000000000000E-02
  #  Certified R-Squared 4.82758620689655E-01
  #  Certified Residual
  #  Standard Deviation  1.00000000000000E-01
  my $data = pdl('[
   [1.4 1.3 1.5 1.3 1.5 1.3 1.5 1.3 1.5]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
   [1.3 1.2 1.4 1.2 1.4 1.2 1.4 1.2 1.4]
   [1.5 1.4 1.6 1.4 1.6 1.4 1.6 1.4 1.6]
  ]')->flat;
  my %m = $data->anova(my $iv = sequence(9)->dummy(1,21)->flat);
  test_stats_cmp(\%m, {
    '| IV_0 | ms' => 0.21,
    '| IV_0 | ss' => 1.68,
    F => 21,
    F_df => pdl(8, 180),
    ss_model => 1.68,
    ss_residual => 1.8,
    ms_residual => 0.01,
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
  # library(data.table)
  # library(rstatix)
  # tdata <- data.frame(
  #  stringsAsFactors = FALSE,
  #  dv = c(102.0,97.0,95.0,79.0,77.0,75.0,83.0,77.0,75.0,92.0,93.0,87.0),
  #  id = c(0L,0L,0L,1L,1L,1L,2L,2L,2L,3L,3L,3L),
  #  wk = c(0L,2L,4L,0L,2L,4L,0L,2L,4L,0L,2L,4L)
  # )
  # as.data.table(tdata)
  # res.aov <- anova_test(
  #   data = tdata, dv = dv, wid = id,
  #   within = c(wk), detailed = TRUE
  #   )
  # res.aov
  # get_anova_table(res.aov, correction = "none")
  # ANOVA Table (type III tests)
  #        Effect DFn DFd   SSn     SSd       F       p p<.05   ges
  # 1 (Intercept)   1   3 88752 916.667 290.461 0.00044     * 0.990
  # 2          wk   2   6    72  17.333  12.462 0.00700     * 0.072
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
  my $dsgn = $d->anova_design_matrix($s, $a, {plot=>0});
  is_pdl $dsgn, pdl '
 [1  1  0  1  0  0  0]
 [1  1  0  0  1  0  0]
 [1  1  0  0  0  1  0]
 [1  1  0  0  0  0  1]
 [1  1  0 -1 -1 -1 -1]
 [1  0  1  1  0  0  0]
 [1  0  1  0  1  0  0]
 [1  0  1  0  0  1  0]
 [1  0  1  0  0  0  1]
 [1  0  1 -1 -1 -1 -1]
 [1 -1 -1  1  0  0  0]
 [1 -1 -1  0  1  0  0]
 [1 -1 -1  0  0  1  0]
 [1 -1 -1  0  0  0  1]
 [1 -1 -1 -1 -1 -1 -1]
';
  my %m = $d->anova_rptd($s, $a, {plot=>0});
  test_stats_cmp(\%m, {
    '| IV_0 | F' => 0.145077720207254,
    '| IV_0 | ms' => 0.466666666666667,
    '| IV_0 | m' => pdl(qw( 2.6 2.8 3.2 )),
  });
}

my %anova_bad_a = (
  '| a | F' => 0.351351351351351,
  '| a | ms' => 0.722222222222222,
  '| a ~ b | F' => 5.25,
  '| a ~ b | m' => pdl(qw( 3  1.3333333  3.3333333 3.3333333  3.6666667  2.6666667  ))->reshape(3,2),
);
{ # anova_rptd_2w bad dv
  my $d = pdl '[3 2 1 5 2 BAD 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2]';
  my $s = pdl '[0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]';
  my $a = pdl '[0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]';
  my $b = pdl '[0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]';
  my $dsgn = $d->anova_design_matrix($s, $a, $b, {v=>0});
  is_pdl $dsgn, pdl '
 [ 1  1  0  1  1  0  1  0  0  0  1  0  1  0]
 [ 1  1  0  1  1  0  0  0  1  0  0  1  0  1]
 [ 1  1  0  1  1  0 -1  0 -1  0 -1 -1 -1 -1]
 [ 1  1  0 -1 -1  0  1  0  0  0 -1  0  1  0]
 [ 1  1  0 -1 -1  0  0  0  1  0  0 -1  0  1]
 [ 1  1  0 -1 -1  0 -1  0 -1  0  1  1 -1 -1]
 [ 1  0  1  1  0  1  0  1  0  0  1  0  1  0]
 [ 1  0  1  1  0  1  0  0  0  1  0  1  0  1]
 [ 1  0  1  1  0  1  0 -1  0 -1 -1 -1 -1 -1]
 [ 1  0  1 -1  0 -1  0  1  0  0 -1  0  1  0]
 [ 1  0  1 -1  0 -1  0  0  0  1  0 -1  0  1]
 [ 1  0  1 -1  0 -1  0 -1  0 -1  1  1 -1 -1]
 [ 1 -1 -1  1 -1 -1 -1 -1  0  0  1  0  1  0]
 [ 1 -1 -1  1 -1 -1  0  0 -1 -1  0  1  0  1]
 [ 1 -1 -1  1 -1 -1  1  1  1  1 -1 -1 -1 -1]
 [ 1 -1 -1 -1  1  1 -1 -1  0  0 -1  0  1  0]
 [ 1 -1 -1 -1  1  1  0  0 -1 -1  0 -1  0  1]
 [ 1 -1 -1 -1  1  1  1  1  1  1  1  1 -1 -1]
';
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_bad_a);
}

{ # anova_rptd_2w bad iv
  my $d = pdl '[3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2]';
  my $s = pdl '[0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]';
  my $a = pdl '[0 0 0 0 0 BAD 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]';
  my $b = pdl '[0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]';
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
    '| a ~ b ~ c | m' => pdl(qw( 4 2.75 2.75 2.5 3.25 4.25 3.5 1.75 2 3.5 2.75 2.25 ))->reshape(2,2,3),
    '| a ~ b | se' => ones(2, 2) * 0.55014729,
  });
}

sub test_stats_cmp {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($m, $ans, $eps) = @_;
  $eps ||= 1e-6;
  foreach (sort keys %$ans) {
    die "No '$_' value received" if !exists $m->{$_};
    my $got = PDL->topdl($m->{$_});
    my $exp = $ans->{$_};
    if (ref $exp eq 'ARRAY') {
      ($exp, my $func) = @$exp;
      ($got, $exp) = map &$func($_), $got, $exp;
    }
    is_pdl $got, PDL->topdl($exp), {atol=>$eps, require_equal_types=>0, test_name=>$_};
  }
}

# Tests for mixed anova thanks to Erich Greene
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
{
  # anova_rptd mixed with 2 btwn-subj var levels, data grouped by within var
  my $d = pdl '[3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2]';
  my $s = pdl '[0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7]';
  my $w = pdl '[0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]';
  my $b = pdl '[0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]';
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l2_common);
}
{
  # anova_rptd mixed with 2 btwn-subj var levels, data grouped by subject
  my $d = pdl '[3 1 4 2 4 2 1 1 1 5 2 5 2 3 4 1 5 3 5 5 2 3 3 2]';
  my $s = pdl '[0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7]';
  my $w = pdl '[0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]';
  my $b = pdl '[0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1]';
  my @idv = qw(within between);
  my %m = $d->anova_rptd($s,$w,$b,{ivnm=>\@idv,btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l2_common);
  my $dsgn = $d->anova_design_matrix($s,$w,$b,{ivnm=>\@idv,btwn=>[1],v=>0});
  is_pdl $dsgn, pdl '
 [1  1  0  1  1  0  1  0  0  0  0  0]
 [1  0  1  1  0  1  1  0  0  0  0  0]
 [1 -1 -1  1 -1 -1  1  0  0  0  0  0]
 [1  1  0  1  1  0  0  1  0  0  0  0]
 [1  0  1  1  0  1  0  1  0  0  0  0]
 [1 -1 -1  1 -1 -1  0  1  0  0  0  0]
 [1  1  0  1  1  0  0  0  1  0  0  0]
 [1  0  1  1  0  1  0  0  1  0  0  0]
 [1 -1 -1  1 -1 -1  0  0  1  0  0  0]
 [1  1  0  1  1  0 -1 -1 -1  0  0  0]
 [1  0  1  1  0  1 -1 -1 -1  0  0  0]
 [1 -1 -1  1 -1 -1 -1 -1 -1  0  0  0]
 [1  1  0 -1 -1  0  0  0  0  1  0  0]
 [1  0  1 -1  0 -1  0  0  0  1  0  0]
 [1 -1 -1 -1  1  1  0  0  0  1  0  0]
 [1  1  0 -1 -1  0  0  0  0  0  1  0]
 [1  0  1 -1  0 -1  0  0  0  0  1  0]
 [1 -1 -1 -1  1  1  0  0  0  0  1  0]
 [1  1  0 -1 -1  0  0  0  0  0  0  1]
 [1  0  1 -1  0 -1  0  0  0  0  0  1]
 [1 -1 -1 -1  1  1  0  0  0  0  0  1]
 [1  1  0 -1 -1  0  0  0  0 -1 -1 -1]
 [1  0  1 -1  0 -1  0  0  0 -1 -1 -1]
 [1 -1 -1 -1  1  1  0  0  0 -1 -1 -1]
';
}
my %anova_ans_l3_common = (
  '| within | df'           =>  2,
  '| within || err df'      => 12,
  '| within | ss'           =>   .962962,
  '| within | ms'           =>   .481481,
  '| within || err ss'      => 20.888888,
  '| within || err ms'      =>  1.740740,
  '| within | F'            =>   .276596,
  '| between | df'          =>  2,
  '| between || err df'     =>  6,
  '| between | ss'          =>  1.185185,
  '| between | ms'          =>   .592592,
  '| between || err ss'     => 13.111111,
  '| between || err ms'     =>  2.185185,
  '| between | F'           =>   .271186,
  '| between ~ within | df' =>  4,
  '| between ~ within | ss' =>  4.148148,
  '| between ~ within | ms' =>  1.037037,
  '| between ~ within | F'  =>   .595744,
);
$anova_ans_l3_common{"| between ~ within || err $_"} = $anova_ans_l3_common{"| within || err $_"} foreach qw/df ss ms/;
{
  # anova_rptd mixed with 3 btwn-subj var levels, data grouped by within var
  my $d = pdl '[5 2 2 5 4 1 5 3 5 4 4 3 4 3 4 3 5 1 4 3 3 4 5 4 5 5 2]';
  my $s = pdl '[0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8 0 1 2 3 4 5 6 7 8]';
  my $w = pdl '[0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]';
  my $b = pdl '[0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2 0 0 0 1 1 1 2 2 2]';
  my @idv = qw(between within);
  my %m = $d->anova_rptd($s,$b,$w,{ivnm=>\@idv,btwn=>[0],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l3_common);
}
{
  # anova_rptd mixed with 3 btwn-subj var levels, data grouped by subject
  my $d = pdl '[5 4 4 2 4 3 2 3 3 5 4 4 4 3 5 1 4 4 5 3 5 3 5 5 5 1 2]';
  my $s = pdl '[0 0 0 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8]';
  my $w = pdl '[0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2 0 1 2]';
  my $b = pdl '[0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2]';
  my @idv = qw(between within);
  my %m = $d->anova_rptd($s,$b,$w,{ivnm=>\@idv,btwn=>[0],plot=>0, v=>0});
  test_stats_cmp(\%m, \%anova_ans_l3_common);
}

{ # from Rutherford (2011) p200, mixed anova
  my $d = pdl '7 7 8 16 16 24 3 11 14 7 10 29 6 9 10 11 13 10 6 11 11 9 10 22 5 10 12 10 10 25 8 10 10 11 14 28 6 11 11 8 11 22 7 11 12 8 12 24';
  my $s = pdl '1 1 1 9 9 9 2 2 2 10 10 10 3 3 3 11 11 11 4 4 4 12 12 12 5 5 5 13 13 13 6 6 6 14 14 14 7 7 7 15 15 15 8 8 8 16 16 16';
  my $w = pdl '1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3 1 2 3';
  my $b = pdl '1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2 1 1 1 2 2 2';
  my $exp = {
    '| time | F' => 37.2348284960422,
    '| time | ms' => 336,
    '| instructions ~ time | F' => 12.4116094986807,
    '| instructions | F' => 47.4973821989529,
  };
  my @idv = qw(instructions time);
  my %m = $d->anova_rptd($s,$b,$w,{ivnm=>\@idv,btwn=>[0],plot=>0, v=>0});
  test_stats_cmp(\%m, $exp);
  my $inds_by_i_t_subj = PDL::glue(0, map $_->t, $b, $w, $s)->qsortveci;
  $_ = $_->index($inds_by_i_t_subj) for $d, $s, $b, $w;
  my $dsgn = $d->anova_design_matrix($s,$b,$w,{ivnm=>\@idv,btwn=>[0],v=>0});
  is_pdl $dsgn, pdl '
 [1  1  1  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  1  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  0  1  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  0  0  1  0  0  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  0  0  0  1  0  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  0  0  0  0  1  0  0  0  0  0  0  0  0]
 [1  1  1  0  1  0  0  0  0  0  0  0  1  0  0  0  0  0  0  0]
 [1  1  1  0  1  0 -1 -1 -1 -1 -1 -1 -1  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  1  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  0  1  0  0  0  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  0  0  1  0  0  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  0  0  0  1  0  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  0  0  0  0  1  0  0  0  0  0  0  0  0]
 [1  1  0  1  0  1  0  0  0  0  0  0  1  0  0  0  0  0  0  0]
 [1  1  0  1  0  1 -1 -1 -1 -1 -1 -1 -1  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  1  0  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  1  0  0  0  0  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  0  1  0  0  0  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  0  0  1  0  0  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  0  0  0  1  0  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  0  0  0  0  1  0  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1  0  0  0  0  0  0  1  0  0  0  0  0  0  0]
 [1  1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  0  0  0  0  0  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  1  0  0  0  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  0  1  0  0  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  1  0  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  0  1  0  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  0  0  1  0]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  0  0  0  1]
 [1 -1  1  0 -1  0  0  0  0  0  0  0  0 -1 -1 -1 -1 -1 -1 -1]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  1  0  0  0  0  0  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  1  0  0  0  0  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  0  1  0  0  0  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  0  0  1  0  0  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  1  0  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  0  1  0]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0  0  0  0  0  0  0  1]
 [1 -1  0  1  0 -1  0  0  0  0  0  0  0 -1 -1 -1 -1 -1 -1 -1]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  1  0  0  0  0  0  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  0  1  0  0  0  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  0  0  1  0  0  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  0  0  0  1  0  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  1  0]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0  0  0  0  0  0  0  1]
 [1 -1 -1 -1  1  1  0  0  0  0  0  0  0 -1 -1 -1 -1 -1 -1 -1]
';
  %m = $d->anova_rptd($s,$b,$w,{ivnm=>\@idv,btwn=>[0],plot=>0, v=>0});
  test_stats_cmp(\%m, $exp);
}

my %ans_mixed = (
  '| a | F' => 0.0633802816901399,
  '| a | ms' => 0.125,
  '| a ~ b | F' => 1.54225352112676,
  '| b | F' => 0.738693467336681,
  '| b || err ms' => 2.76388888888889,
  '| a ~ b | se' => ones(3,2) * 0.70217915,
);
{ # anova_rptd mixed
  my $d = pdl '[3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2]';
  my $s = pdl '[0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]';
  my $a = pdl '[0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]';
  my $b = pdl '[0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]';
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%ans_mixed);
}
{ # anova_rptd mixed bad
  # with the "bad" ie removed subject and data removed, in R:
  # library(data.table)
  # library(rstatix)
  # tdata <- data.frame(
  #  stringsAsFactors = FALSE,
  #  dv = c(3.0,2.0,1.0,5.0,2.0,1.0,5.0,3.0,1.0,4.0,1.0,2.0,3.0,5.0,5.0,3.0,4.0,2.0,1.0,5.0,4.0,3.0,2.0,2),
  #  id = c(0L,1L,2L,3L,0L,1L,2L,3L,0L,1L,2L,3L,0L,1L,2L,3L,0L,1L,2L,3L,0L,1L,2L,3L),
  #  w = c(0L,0L,0L,0L,0L,0L,0L,0L,1L,1L,1L,1L,1L,1L,1L,1L,2L,2L,2L,2L,2L,2L,2L,2L),
  #  b = c(0L,0L,0L,0L,1L,1L,1L,1L,0L,0L,0L,0L,1L,1L,1L,1L,0L,0L,0L,0L,1L,1L,1L,1L)
  # )
  # as.data.table(tdata)
  # tdata <- tdata %>% convert_as_factor(id, w, b)
  # as.data.table(tdata)
  # res.aov <- anova_test(
  #   data = tdata, dv = dv, wid = id,
  #   within = c(w), between = c(b), detailed = TRUE
  #   )
  # get_anova_table(res.aov, correction = "none")
  #        Effect DFn DFd     SSn    SSd      F        p p<.05   ges
  # 1 (Intercept)   1   6 198.375 16.583 71.774 0.000148     * 0.831
  # 2           b   1   6   2.042 16.583  0.739 0.423000       0.048
  # 3           w   2  12   0.250 23.667  0.063 0.939000       0.006
  # 4         b:w   2  12   6.083 23.667  1.542 0.253000       0.131
  my $d = pdl '[3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2 1 1 1 1]';
  my $s = pdl '[0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 4 4 4 4]';
  my $a = pdl '[0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 0 0 0 0]';
  my $b = pdl '[0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 BAD]';
  # any missing value causes all data from the subject (4) to be dropped
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],btwn=>[1],plot=>0, v=>0});
  test_stats_cmp(\%m, \%ans_mixed);
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
  my $b = effect_code([ (0,1)x 6 ]);
  my $c = effect_code([ (0,0,1,1,2,2)x 2 ]);
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
