#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 46;
      # 1
    use_ok( 'PDLA::Stats::Distr' );
}

use PDLA::LiteF;

sub tapprox {
  my($a,$b) = @_;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDLA' and $diff = $diff->max;
  return $diff < 1.0e-6;
}
  # 2-11
{
  my $a = sequence 5;
  $a /= 10;
  is( tapprox( sum(pdl($a->mme_beta) - pdl(1.4, 5.6)), 0 ), 1 );
  is( tapprox( $a->pdf_beta(1, 3)->sum, 9.9 ), 1 );
}
{
  my $a = sequence 5;
  $a %= 2;
  is( tapprox( sum(pdl($a->mme_binomial) - pdl(1, .4)), 0 ), 1 );
  is( tapprox( $a->pmf_binomial(2,.4)->sum, 2.04 ), 1 );
}
{
  my $a = sequence 5;
  is( tapprox( $a->mle_exp, .5 ), 1 );
  is( tapprox( $a->pdf_exp(2.5)->sum, 2.72355357480724 ), 1 );
}
{
  my $a = sequence 5;
  is( tapprox( sum(pdl($a->mle_gaussian) - pdl(2,2)), 0 ), 1 );
  is( tapprox( $a->pdf_gaussian(1,2)->sum, 0.854995527902657 ), 1 );
}
{
  my $a = sequence 5;
  is( tapprox( $a->mle_geo, 0.333333333333333 ), 1 );
  is( tapprox( $a->pmf_geo(.5)->sum, 0.96875 ), 1 );
}
  # 12-22
{
  my $a = sequence 5;
  $a += 1;
  is( tapprox( $a->mle_geosh, 0.333333333333333 ), 1 );
  is( tapprox( $a->pmf_geosh(.5)->sum, 0.96875 ), 1 );
}
{
  my $a = sequence(5) + 1;
  is( tapprox( sum(pdl($a->mle_lognormal) - pdl(0.957498348556409, 0.323097797388514)), 0 ), 1 );
  is( tapprox( sum(pdl($a->mme_lognormal) - pdl(2.19722457733622, 0.200670695462151)), 0 ), 1 );
  is( tapprox( $a->pdf_lognormal(1,2)->sum, 0.570622216518612 ), 1 );
}
{
  my $a = sequence 5;
  $a *= $a;
  is( tapprox( sum(pdl($a->mme_nbd) - pdl(1.25, 0.172413793103448)), 0 ), 1 );
  is( tapprox( $a->pmf_nbd(2, .4)->sum, 0.472571655494828 ), 1 );
}
{
  my $a = sequence 5;
  $a += 1;
  is( tapprox( sum(pdl($a->mme_pareto) - pdl(1.4, 0.857142857142857)), 0 ), 1 );
  is( tapprox( $a->pdf_pareto(2, .4)->sum, 0.379411851851852 ), 1 );
}
{
  my $a = sequence 5;
  $a %= 2;
  is( tapprox( $a->mle_poisson, .4 ), 1 );
  is( tapprox( $a->pmf_poisson(.4)->sum, 2.54721617493543 ), 1 );
}
  # 23-32
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a /= 10;
  is( tapprox( sum(pdl($a->mme_beta) - pdl(1.4, 5.6)), 0 ), 1 );
  is( tapprox( $a->pdf_beta(1, 3)->sum, 9.9 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a %= 2;
  is( tapprox( sum(pdl($a->mme_binomial) - pdl(1, .4)), 0 ), 1 );
  is( tapprox( $a->pmf_binomial(2,.4)->sum, 2.04 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  is( tapprox( $a->mle_exp, .5 ), 1 );
  is( tapprox( $a->pdf_exp(2.5)->sum, 2.72355357480724 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  is( tapprox( sum(pdl($a->mle_gaussian) - pdl(2,2)), 0 ), 1 );
  is( tapprox( $a->pdf_gaussian(1,2)->sum, 0.854995527902657 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  is( tapprox( $a->mle_geo, 0.333333333333333 ), 1 );
  is( tapprox( $a->pmf_geo(.5)->sum, 0.96875 ), 1 );
}
  # 33-43
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a += 1;
  is( tapprox( $a->mle_geosh, 0.333333333333333 ), 1 );
  is( tapprox( $a->pmf_geosh(.5)->sum, 0.96875 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a += 1;
  is( tapprox( sum(pdl($a->mle_lognormal) - pdl(0.957498348556409, 0.323097797388514)), 0 ), 1 );
  is( tapprox( sum(pdl($a->mme_lognormal) - pdl(2.19722457733622, 0.200670695462151)), 0 ), 1 );
  is( tapprox( $a->pdf_lognormal(1,2)->sum, 0.570622216518612 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a *= $a;
  is( tapprox( sum(pdl($a->mme_nbd) - pdl(1.25, 0.172413793103448)), 0 ), 1 );
  is( tapprox( $a->pmf_nbd(2, .4)->sum, 0.472571655494828 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a += 1;
  is( tapprox( sum(pdl($a->mme_pareto) - pdl(1.4, 0.857142857142857)), 0 ), 1 );
  is( tapprox( $a->pdf_pareto(2, .4)->sum, 0.379411851851852 ), 1 );
}
{
  my $a = sequence 6;
  $a->setbadat(-1);
  $a %= 2;
  is( tapprox( $a->mle_poisson, .4 ), 1 );
  is( tapprox( $a->pmf_poisson(.4)->sum, 2.54721617493543 ), 1 );
  is( tapprox( $a->pmf_poisson_factorial(.4)->sum, 2.54721617493543 ), 1 );
  is( tapprox( $a->pmf_poisson_stirling(.4)->sum, 2.5470618950599 ), 1 );

  $a += 171;
  ok( $a->pmf_poisson_stirling(10)->sum );  # the result is so close to 0 it's pointless to test with tapprox
}
