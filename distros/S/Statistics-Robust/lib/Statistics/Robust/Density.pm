package Statistics::Robust::Density;

use strict;
use warnings;
use Carp;

use Math::CDF qw(qnorm);
use Statistics::Robust::Location qw(mean);
use Statistics::Robust::Scale qw(variance);

use base 'Statistics::Robust';

our @EXPORT = ();
our @EXPORT_OK = (qw(
rdplot
akerd
));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# Expected Frequency Curve
sub
rdplot
{
 my($x,$fr) = @_;

 if ( not defined $fr )
 {
  $fr = 0.8;
 }

 my $n = scalar @$x;
 my @y = sort {$a <=> $b} @$x;
 my $mad = Statistics::Robust::Scale::MADN(\@y);
 my @rmd = ();

 for(my $i=0;$i<$n;$i++)
 {
  my $near = _near(\@y,$y[$i],$mad,$fr);
  $rmd[$i] = Statistics::Robust::_sum($near);
 } 
 if ( $mad != 0 )
 {
  for(my $i=0;$i<$n;$i++)
  {
   $rmd[$i] = $rmd[$i]/(2*$fr*$mad);
  }
 }
 for(my $i=0;$i<$n;$i++)
 {
  $rmd[$i] = $rmd[$i]/$n;
 }

 return \@y,\@rmd;
}

# Adaptive kernel density estimate
sub
akerd
{
 my($xx,$fr,$aval) = @_;

 # Set the variance calculation to use the un-biased estimate
 my $prior_value = 0;
 if ( defined $ENV{UNBIAS} )
 {
  $prior_value = $ENV{UNBIAS};
 }
 $ENV{UNBIAS} = 1; 

 if ( not defined $fr )
 {
  $fr = 0.8;
 }
 if ( not defined $aval )
 {
  $aval = 0.5;
 }

 my @x = sort {$a <=> $b} @$xx;

 # First, a measure of dispersion
 my $m = 0;
 $m = Statistics::Robust::Scale::MADN(\@x);
 if ($m == 0)
 {
  my($ql,$qu) = Statistics::Robust::Scale::idealf(\@x);
  $m = ($qu - $ql)/(qnorm(0.75) - qnorm(0.25));
 }
 if ( $m == 0 )
 {
  $m = sqrt(Statistics::Robust::Scale::winvar(\@x)/0.4129);
 }
 if ( $m == 0 )
 {
  carp "All measures of dispersion are equal to 0\n";
  return undef;
 }

 # Estimate the density using the Expected Frequency Curve 
 my(undef,$fhat) = rdplot(\@x);
 if ( $m > 0 )
 {
  for(my $i=0;$i<@$fhat;$i++)
  { 
   $fhat->[$i] = $fhat->[$i]/(2*$fr*$m);
  }
 }

 # Calculate the span
 my $n = scalar @x;
 my $sig = sqrt(variance(\@x));
 my($ql,$qu) = Statistics::Robust::Scale::idealf(\@x);
 my $iqr = ($qu-$ql)/1.34;
 my $A = Statistics::Robust::_min($sig,$iqr);
 if( $A == 0 )
 {
  $A = sqrt(Statistics::Robust::Scale::winvar(\@x))/0.64;
 }
 my $hval = 1.06*$A/($n**0.2);
 # See Silverman, 1986, pp. 47-48

 my @log_fhat = ();
 my @alam = ();
 for(my $i=0;$i<scalar @$fhat;$i++)
 {
  if ( $fhat > 0 )
  {
   $log_fhat[$i] = log($fhat->[$i]);
  }
 }
 my $gm = exp(mean(\@log_fhat));
 for(my $i=0;$i<scalar @$fhat;$i++)
 {
  $alam[$i] = ($fhat->[$i]/$gm)**(0.0-$aval);
 }

 my @dhat = ();
 my @temp = ();
 for(my $j=0;$j<$n;$j++)
 { 
  # Calculate t
  for(my $i=0;$i<$n;$i++)
  {
   $temp[$i] = ($x[$j]-$x[$i])/($hval*$alam[$i]);
  }
 
  # Calculate the Epanechnikov kernel
  for(my $i=0;$i<$n;$i++)
  {
   my $epan = 0;
   if ( abs($temp[$i]) < sqrt(5) )
   {
    $epan = 0.75*(1-0.2*$temp[$i]**2)/sqrt(5);
   }
   else
   {
    $epan = 0.0;
   }
   $temp[$i] = ($epan/($alam[$i]*$hval));
  }
  $dhat[$j] = mean(\@temp) + 0.0;
 }

 # Principal of least surprise
 $ENV{UNBIAS} = $prior_value; 
 
 return \@x,\@dhat;
}

# Determine which values in $x are near $pt
sub
_near
{
 my($x,$pt,$m,$fr) = @_;

 if ( not defined $fr )
 {
  $fr = 1;
 }
 if ( $m == 0 )
 {
  my($ql,$qu) = idealf($x);
  $m = ($qu-$ql)/(qnorm(0.75) - qnorm(0.25));
 }
 if ( $m == 0 )
 {
  $m = $m = sqrt(winvar($x)/0.4129);
 }
 if ( $m == 0 )
 {
  carp "All measures of dispersion are equal to 0\n";
 }

 my @dflag = ();
 for(my $i=0;$i<scalar @$x;$i++)
 {
  my $dis = abs($x->[$i]-$pt);
  push(@dflag, ($dis <= $fr*$m));
 }

 return \@dflag;
}

1;

=head1 NAME

Statistics::Robust::Density - Robust Probability Density Estimators

=head1 SYNOPSIS

 my @x = (1,4,5,3,7,2,4);
 
 my($pts,$akerd) = akerd(\@x);

=head1 FUNCTIONS

=head2 rdplot

 my($pts,$rdplot) = rdplot(\@x);

 Return the expected frequency curve for the data in \@x.

=head2 akerd

 my($pts,$akerd) = akerd(\@x);

 Return the adaptive kernel density estimate for the data in \@x.

=head1 AUTHOR

Walter Szeliga C<< <walter@geology.cwu.edu> >>

=cut
