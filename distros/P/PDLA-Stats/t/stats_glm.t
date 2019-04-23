#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'PDLA::Stats::Basic' );
    use_ok( 'PDLA::Stats::GLM' );
}

use PDLA::LiteF;
use PDLA::NiceSlice;

eval { require PDLA::Slatec; };
if ($@) {
  warn "No PDLA::Slatec. Fall back on PDLA::MatrixOps.\n";
}

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDLA' and $diff = $diff->max;
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

is( tapprox( $a->dev_m->avg, 0 ), 1, "dev_m replaces values with deviations from the mean on $a");
is( tapprox( $a->stddz->avg, 0 ), 1, "stddz standardizes data on $a");

is( tapprox( $a->sse($b), 18), 1, "sse gives sum of squared errors between actual and predicted values between $a and $b");
is( tapprox( $a->mse($b), 3.6), 1, "mse gives mean of squared errors between actual and predicted values between $a and $b");
is( tapprox( $a->rmse($b), 1.89736659610103 ), 1, "rmse gives root mean squared error, ie. stdv around predicted value between $a and $b");

is( tapprox( $b->glue(1,ones(5))->pred_logistic(pdl(1,2))->sum, 4.54753948757851 ), 1, "pred_logistic calculates predicted probability value for logistic regression");

my $y = pdl(0, 1, 0, 1, 0);
is( tapprox( $y->d0(), 6.73011667009256 ), 1, 'd0');
is( tapprox( $y->dm( ones(5) * .5 ), 6.93147180559945 ), 1, 'dm' );
is( tapprox( sum($y->dvrs(ones(5) * .5) ** 2), 6.93147180559945 ), 1, 'dvrs' );

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
  is( tapprox( sum( abs($m{R2} - $rsq) ), 0 ), 1, 'ols_t R2' );
  is( tapprox( sum( abs($m{b} - $coeff) ), 0 ), 1, 'ols_t b' );

  my %m0 = $a->ols_t(sequence(5), {CONST=>0});
  my $b0 = pdl ([ 0.2 ], [ 0.23333333 ]);

  is( tapprox( sum( abs($m0{b} - $b0) ), 0 ), 1, 'ols_t, const=>0' );
}

is( tapprox( t_ols(), 0 ), 1, 'ols' );
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
  my $sum;
  $sum += sum(abs($a{$_} - $m{$_}))
    for (keys %a);
  return $sum;
}

is( tapprox( t_ols_bad(), 0 ), 1, 'ols with bad value' );
sub t_ols_bad {
  my $a = sequence 6;
  my $b = pdl(0,0,0,1,1,1);
  $a->setbadat(5);
  my %m = $a->ols($b, {plot=>0});
  is( $b->sumover, 3, "ols with bad value didn't change caller value" );
  ok( $a->check_badflag, "ols with bad value didn't remove caller bad flag" );
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
  my $sum;
  $sum += sum(abs($a{$_} - $m{$_}))
    for (keys %a);
  return $sum;
}

is( tapprox( t_r2_change(), 0 ), 1, 'r2_change' );
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
  my $sum;
  $sum += sum($a{$_} - $m{$_})
    for (keys %a);
  return $sum;
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
eigenvector	=> pdl(
    # v1       v2        v3
 [qw(  0.58518141   0.58668657   0.55978709)],  # comp1
 [qw( -0.41537629  -0.37601061   0.82829859)],  # comp2
 [qw( -0.69643754   0.71722722 -0.023661276)],  # comp3
),

loadings	=> pdl(
 [qw(   0.97686463    0.97937725    0.93447296)],
 [qw(  -0.17853319    -0.1616134    0.35601163)],
 [qw(  -0.11773439    0.12124893 -0.0039999937)],
),

pct_var	=> pdl( qw(0.92889468 0.06157909 0.0095262297) ),
  );
  for (keys %a) {
    is(tapprox(sum($a{$_}->abs - $p{$_}->abs),0, 1e-5), 1, $_);
  }

  %p = $a->pca({CORR=>0, PLOT=>0});
  %a = (
eigenvalue => pdl( qw[ 22.0561695 1.581758022 0.202065959 ] ),
eigenvector => pdl(
 [qw(-0.511688 -0.595281 -0.619528)],
 [qw( 0.413568  0.461388  -0.78491)],
 [qw( 0.753085 -0.657846 0.0101023)],
),

loadings    => pdl(
 [qw(-0.96823408  -0.9739215 -0.94697802)],
 [qw( 0.20956865  0.20214966 -0.32129495)],
 [qw( 0.13639532 -0.10301693 0.001478041)],
),

pct_var => pdl( qw[0.925175 0.0663489 0.00847592] ),
  );
  for (keys %a) {
    is(tapprox(sum($a{$_}->abs - $p{$_}->abs),0, 1e-4), 1, "corr=>0, $_");
  }
}

is( tapprox( t_pca_sorti(), 0 ), 1, "pca_sorti - principal component analysis output sorted to find which vars a component is best represented");
sub t_pca_sorti {
  my $a = sequence 10, 5;
  $a = lvalue_assign_detour( $a, which($a % 7 == 0), 0 );

  my %m = $a->pca({PLOT=>0});

  my ($iv, $ic) = $m{loadings}->pca_sorti;

  return sum($iv - pdl(qw(4 1 0 2 3))) + sum($ic - pdl(qw( 0 1 2 )));
}

SKIP: {
  eval { require PDLA::Fit::LM; };
  skip 'no PDLA::Fit::LM', 1 if $@;

  is( tapprox( t_logistic(), 0 ), 1, 'logistic' );
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

is( tapprox( $a_bad->dev_m->avg, 0 ), 1, "dev_m with bad values $a_bad");
is( tapprox( $a_bad->stddz->avg, 0 ), 1, "stdz with bad values $a_bad");

is( tapprox( $a_bad->sse($b_bad), 23), 1, "sse with bad values between $a_bad and $b_bad");
is( tapprox( $a_bad->mse($b_bad), 5.75), 1, "mse with badvalues between $a_bad and $b_bad");
is( tapprox( $a_bad->rmse($b_bad), 2.39791576165636 ), 1, "rmse with bad values between $a_bad and $b_bad");

is( tapprox( $b_bad->glue(1,ones(6))->pred_logistic(pdl(1,2))->sum, 4.54753948757851 ), 1, "pred_logistic with bad values");

is( tapprox( $b_bad->d0(), 6.73011667009256 ), 1, "null deviance with bad values on $b_bad");
is( tapprox( $b_bad->dm( ones(6) * .5 ), 6.93147180559945 ), 1, "model deviance with bad values on $b_bad");
is( tapprox( sum($b_bad->dvrs(ones(6) * .5) ** 2), 6.93147180559945 ), 1, "deviance residual with bad values on $b_bad");

{
  my @a = qw( a a a b b b b c c BAD );
  my $a = effect_code(\@a);
  my $ans = pdl [
   [qw( 1   1   1   0   0   0   0  -1  -1 -99 )],
   [qw( 0   0   0   1   1   1   1  -1  -1 -99 )]
  ];
  $ans = $ans->setvaltobad(-99);
  is( sum(abs(which($a->isbad) - pdl(9,19))), 0, 'effect_code got bad value' );
  is( tapprox( sum(abs($a - $ans)), 0 ), 1, 'effect_code coded with bad value' );
}

is( tapprox( t_effect_code_w(), 0 ), 1, 'effect_code_w' );
sub t_effect_code_w {
  my @a = qw( a a a b b b b c c c );
  my $a = effect_code_w(\@a);
  return sum($a->sumover - pdl byte, (0, 0));
}

is( tapprox( t_anova(), 0 ), 1, 'anova_3w' );
sub t_anova {
  my $d = sequence 60;
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  my $b = $d % 3;
  my $c = $d % 2;
  $d = lvalue_assign_detour( $d, 20, 10 );
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0});
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_F = pdl(165.252100840336, 0.0756302521008415);
  my $ans_m = pdl([qw(8 18 38 53)], [qw(8 23 38 53)]);
  return  sum( pdl( @m{'| A | F', '| A ~ B ~ C | F'} ) - $ans_F )
        + sum( $m{'# A ~ B ~ C # m'}->(,2,)->squeeze - $ans_m )
  ;
}

is( tapprox( t_anova_1way(), 0 ), 1, 'anova_1w' );
sub t_anova_1way {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 );
  my $a = qsort sequence(15) % 3;
  my %m = $d->anova($a, {plot=>0});
  my $ans_F  = 0.160919540229886;
  my $ans_ms = 0.466666666666669;
  my $ans_m = pdl(qw( 2.6 2.8 3.2 ));
  return  ($m{F} - $ans_F)
        + ($m{ms_model} - $ans_ms )
        + sum( $m{'# IV_0 # m'}->squeeze - $ans_m )
  ;
}

is( tapprox( t_anova_bad_dv(), 0 ), 1, 'anova_3w bad dv' );
sub t_anova_bad_dv {
  my $d = sequence 60;
  $d = lvalue_assign_detour( $d, 20, 10 );
  $d->setbadat(1);
  $d->setbadat(10);
  my @a = map {$a = $_; map { $a } 0..14 } qw(a b c d);
  my $b = sequence(60) % 3;
  my $c = sequence(60) % 2;
  my %m = $d->anova(\@a, $b, $c, {IVNM=>[qw(A B C)], plot=>0, v=>0});
  my $ans_F = pdl( 150.00306433446, 0.17534855325553 );
  my $ans_m = pdl([qw( 4 22 37 52 )], [qw( 10 22 37 52 )]);
  my $ans_se = pdl([qw( 0 6 1.7320508 3.4641016 )], [qw( 3 3 3.4641016 1.7320508 )]);

  return sum(abs(pdl( @m{'| A | F', '| A ~ B ~ C | F'} ) - $ans_F))
       + sum(abs($m{'# A ~ B ~ C # m'}->(,1,)->squeeze - $ans_m))
       + sum(abs($m{'# A ~ B ~ C # se'}->(,1,)->squeeze - $ans_se))
  ;
}

is( tapprox( t_anova_bad_dv_iv(), 0 ), 1, 'anova_3w bad dv iv' );
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
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_F = pdl(165.252100840336, 0.0756302521008415);
  my $ans_m = pdl([qw(8 18 38 53)], [qw(8 23 38 53)]);
  return  sum( pdl( @m{'| A | F', '| A ~ B ~ C | F'} ) - $ans_F )
        + sum( $m{'# A ~ B ~ C # m'}->(,2,)->squeeze - $ans_m )
  ;
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

is( tapprox( t_anova_rptd_1way(), 0 ), 1, 'anova_rptd_1w' );
sub t_anova_rptd_1way {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 );
  my $s = sequence(5)->dummy(1,3)->flat;
  my $a = qsort sequence(15) % 3;
  my %m = $d->anova_rptd($s, $a, {plot=>0});
#print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_F  = 0.145077720207254;
  my $ans_ms = 0.466666666666667;
  my $ans_m = pdl(qw( 2.6 2.8 3.2 ));
  return  ($m{'| IV_0 | F'} - $ans_F)
        + ($m{'| IV_0 | ms'} - $ans_ms )
        + sum( $m{'# IV_0 # m'}->squeeze - $ans_m )
  ;
}

is( tapprox( t_anova_rptd_2way_bad_dv(), 0 ), 1, 'anova_rptd_2w bad dv' );
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
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_a_F  = 0.351351351351351;
  my $ans_a_ms = 0.722222222222222;
  my $ans_ab_F = 5.25;
  my $ans_ab_m = pdl(qw( 3  1.3333333  3.3333333 3.3333333  3.6666667  2.6666667  ))->reshape(3,2);
  return  ($m{'| a | F'} - $ans_a_F)
        + ($m{'| a | ms'} - $ans_a_ms)
        + ($m{'| a ~ b | F'} - $ans_ab_F)
        + sum( $m{'# a ~ b # m'} - $ans_ab_m )
  ;
}

is( tapprox( t_anova_rptd_2way_bad_iv(), 0 ), 1, 'anova_rptd_2w bad iv' );
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
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_a_F  = 0.351351351351351;
  my $ans_a_ms = 0.722222222222222;
  my $ans_ab_F = 5.25;
  my $ans_ab_m = pdl(qw( 3  1.3333333  3.3333333 3.3333333  3.6666667  2.6666667  ))->reshape(3,2);
  return  ($m{'| a | F'} - $ans_a_F)
        + ($m{'| a | ms'} - $ans_a_ms)
        + ($m{'| a ~ b | F'} - $ans_ab_F)
        + sum( $m{'# a ~ b # m'} - $ans_ab_m )
  ;
}

is( tapprox( t_anova_rptd_3way(), 0 ), 1, 'anova_rptd_3w' );
sub t_anova_rptd_3way {
  my $d = pdl( qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2 ),
               qw( 5 5 1 1 4 4 1 4 4 2 3 3 5 1 1 2 4 4 4 5 5 1 1 2 )
  );
  my $s = sequence(4)->dummy(0,12)->flat;
  my $a = sequence(2)->dummy(0,6)->flat->dummy(1,4)->flat;
  my $b = sequence(2)->dummy(0,3)->flat->dummy(1,8)->flat;
  my $c = sequence(3)->dummy(1,16)->flat;
  my %m = $d->anova_rptd($s, $a, $b, $c, {ivnm=>['a','b', 'c'],plot=>0});
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_a_F  = 0.572519083969459;
  my $ans_a_ms = 0.520833333333327;
  my $ans_ac_F = 3.64615384615385;
  my $ans_bc_ems = 2.63194444444445;
  my $ans_abc_F = 1.71299093655589;
  my $ans_abc_m = pdl(qw( 4 2.75 2.75 2.5 3.25 4.25 3.5 1.75 2 3.5 2.75 2.25 ))->reshape(2,2,3);
  my $ans_ab_se = ones(2, 2) * 0.55014729;
  return  ($m{'| a | F'} - $ans_a_F)
        + ($m{'| a | ms'} - $ans_a_ms)
        + ($m{'| a ~ c | F'} - $ans_ac_F)
        + ($m{'| b ~ c || err ms'} - $ans_bc_ems)
        + ($m{'| a ~ b ~ c | F'} - $ans_abc_F)
        + sum( $m{'# a ~ b ~ c # m'} - $ans_abc_m )
        + sum( $m{'# a ~ b # se'} - $ans_ab_se )
  ;
}

is( tapprox( t_anova_rptd_mixed(), 0 ), 1, 'anova_rptd mixed' );
sub t_anova_rptd_mixed {
  my $d = pdl qw( 3 2 1 5 2 1 5 3 1 4 1 2 3 5 5 3 4 2 1 5 4 3 2 2);
  my $s = sequence(4)->dummy(1,6)->flat;
# [0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3]
  my $a = qsort sequence(24) % 3;
# [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2]
  my $b = (sequence(8) > 3)->dummy(1,3)->flat;
# [0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1]
  my %m = $d->anova_rptd($s, $a, $b, {ivnm=>['a','b'],btwn=>[1],plot=>0, v=>0});
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_a_F  = 0.0775862068965517;
  my $ans_a_ms = 0.125;
  my $ans_ab_F = 1.88793103448276;
  my $ans_b_F  = 0.585657370517928;
  my $ans_b_ems = 3.48611111111111;
  my $ans_ab_se = ones(3,2) * 0.63464776;
  return  ($m{'| a | F'} - $ans_a_F)
        + ($m{'| a | ms'} - $ans_a_ms)
        + ($m{'| a ~ b | F'} - $ans_ab_F)
        + ($m{'| b | F'} - $ans_b_F)
        + ($m{'| b || err ms'} - $ans_b_ems)
        + sum( $m{'# a ~ b # se'} - $ans_ab_se )
  ;
}

# Tests for mixed anova thanks to Erich Greene

is( tapprox( t_anova_rptd_mixed_l2ord2(), 0,      ), 1, 'anova_rptd mixed with 2 btwn-subj var levels, data grouped by subject'    );
SKIP: {
    skip "yet to be fixed", 3;
    is( tapprox( t_anova_rptd_mixed_l2ord1(), 0,      ), 1, 'anova_rptd mixed with 2 btwn-subj var levels, data grouped by within var' );
    is( tapprox( t_anova_rptd_mixed_l3ord1(), 0, .001 ), 1, 'anova_rptd mixed with 3 btwn-subj var levels, data grouped by within var' );
    is( tapprox( t_anova_rptd_mixed_l3ord2(), 0, .001 ), 1, 'anova_rptd mixed with 3 btwn-subj var levels, data grouped by subject'    );
};
sub t_anova_rptd_mixed_backend {
    my ($d,$s,$w,$b,$ans) = @_;
    my %m = $d->anova_rptd($s,$w,$b,{ivnm=>['within','between'],btwn=>[1],plot=>0, v=>0});
    my $error;
    $error += $m{$_} - $$ans{$_} foreach keys %$ans;
    return $error;
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


is( tapprox( t_anova_rptd_mixed_bad(), 0 ), 1, 'anova_rptd mixed bad' );
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
# print "$_\t$m{$_}\n" for (sort keys %m);
  my $ans_a_F  = 0.0775862068965517;
  my $ans_a_ms = 0.125;
  my $ans_ab_F = 1.88793103448276;
  my $ans_b_F  = 0.585657370517928;
  my $ans_b_ems = 3.48611111111111;
  my $ans_ab_se = ones(3,2) * 0.63464776;
  return  ($m{'| a | F'} - $ans_a_F)
        + ($m{'| a | ms'} - $ans_a_ms)
        + ($m{'| a ~ b | F'} - $ans_ab_F)
        + ($m{'| b | F'} - $ans_b_F)
        + ($m{'| b || err ms'} - $ans_b_ems)
        + sum( $m{'# a ~ b # se'} - $ans_ab_se )
  ;
}

is( tapprox( t_anova_rptd_mixed_4w(), 0 ), 1, 'anova_rptd_mixed_4w' );
sub t_anova_rptd_mixed_4w {
  my ($data, $idv, $subj) = rtable \*DATA, {v=>0};
  my ($age, $aa, $beer, $wings, $dv) = $data->dog;
  my %m = $dv->anova_rptd( $subj, $age, $aa, $beer, $wings, { ivnm=>[qw(age aa beer wings)], btwn=>[0,1], v=>0, plot=>0 } );
#  print STDERR "$_\t$m{$_}\n" for (sort keys %m);

  my $ans_aa_F = 0.0829493087557666;
  my $ans_age_aa_F = 2.3594470046083;
  my $ans_beer_F = 0.00943396226415362;
  my $ans_aa_beer_F = 0.235849056603778;
  my $ans_age_beer_wings_F = 0.0303030303030338;
  my $ans_beer_wings_F = 2.73484848484849;
  my $ans_4w_F = 3.03030303030303;

  return  ($m{'| aa | F'} - $ans_aa_F)
        + ($m{'| age ~ aa | F'} - $ans_age_aa_F)
        + ($m{'| beer | F'} - $ans_beer_F)
        + ($m{'| aa ~ beer | F'} - $ans_aa_beer_F)
        + ($m{'| age ~ beer ~ wings | F'} - $ans_age_beer_wings_F)
        + ($m{'| beer ~ wings | F'} - $ans_beer_wings_F)
        + ($m{'| age ~ aa ~ beer ~ wings | F'} - $ans_4w_F)
  ;
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
