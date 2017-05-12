#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 4;
}

use PDLA::LiteF;
use PDLA::GSL::CDF;

sub tapprox {
  my($a,$b) = @_;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDLA' and $diff = $diff->max;
  return $diff < 1.0e-6;
}
{
  my $a = sequence 5;
  my $a_bad = sequence 6;
  $a_bad->setbadat(-1);
  is( tapprox( $a->gsl_cdf_tdist_P(1999)->sum, 4.31706715604714 ), 1 );
  is( tapprox( $a_bad->gsl_cdf_tdist_P(1999)->sum, 4.31706715604714 ), 1 );
  is( tapprox( $a->gsl_cdf_fdist_P(1,1999)->sum, 3.39605941459337 ), 1 );
  is( tapprox( $a_bad->gsl_cdf_fdist_P(1,1999)->sum, 3.39605941459337 ), 1 );
}
