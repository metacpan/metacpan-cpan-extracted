package Statistics::Robust::Scale;

use strict;
use warnings;
use Carp;

use POSIX qw(floor);
use Math::CDF qw(qnorm pbeta);
use Math::Round qw(round_even);
use Statistics::Robust::Location qw(median);

use base qw(Statistics::Robust);

our @EXPORT = ();
our @EXPORT_OK = (qw(
variance
MAD
MADN
idealf
winvar
trimvar
msmedse
pbvar
));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# We need to implement variance since Statistics::Basic
# currently is messing up the unbiased variance implementation.
sub
variance
{
 my($x) = @_;

 my $length = scalar @$x;
 my $sum = Statistics::Robust::_sum($x);
 my $mean = $sum/$length;

 my $var = 0;
 for(my $i=0;$i<@$x;$i++)
 {
  $var += ($mean-$x->[$i])**2;
 }

 return $var/($length-1);
}

# The Median Absolute Deviation
sub
MAD
{
 my($x) = @_;

 my @ad = ();

 my($median) = Statistics::Robust::Location::median($x);

 foreach my $xi (@$x)
 {
  my($adi) = abs($xi - $median);
  push(@ad,$adi);
 }

 my($mad) = Statistics::Robust::Location::median(\@ad) + 0.0;


 return $mad;
}

# The rescaled Median Absolute Deviation
sub
MADN
{
 my($x) = @_;
 
 my $mad = MAD($x);
 $mad /= qnorm(0.75);

 return $mad;
}

sub
idealf
{
#
# Compute the ideal fourths for data in x
# and return the lower and upper quartiles
#
 my($x) = @_;

 my $n = scalar @$x;

 my $j = floor($n/4 + 5/12) - 1;
 my @y = sort {$a <=> $b} @$x;
 my $g = ($n/4) - $j + (5/12) - 1;
 my $ql = (1-$g)*$y[$j] + $g*$y[$j+1];
 my $k = $n - $j - 1;
 my $qu = (1-$g)*$y[$k] + $g*$y[$k-1];

 return ($ql,$qu); 
}

sub
winvar
{
 my($x,$tr) = @_;

 if ( not defined $tr )
 {
  $tr = 0.2;
 }
 my @y = sort {$a <=> $b} @$x;

 my $n = scalar @$x;
 my $ibot = floor($tr*$n);# + 1;
 my $itop = $n - $ibot;# + 1;
 my $xbot = $y[$ibot]; 
 my $xtop = $y[$itop]; 
 for(my $i=0;$i<$n;$i++)
 {
  if ( $y[$i] <= $xbot )
  {
   $y[$i] = $xbot;
  }
  if ( $y[$i] >= $xtop )
  {
   $y[$i] = $xtop;
  }
 }
 my $winvar = variance(\@y);

 return $winvar;
}

# The variance of the trimmed mean
sub
trimvar
{
 my($x,$tr) = @_;

 if ( not defined $tr )
 {
  $tr = 0.2;
 }

 my $n = scalar @$x;
 my $winvar = winvar($x,$tr);
 my $trimvar = $winvar/((1-2*$tr)**2*$n);

 return $trimvar;
}

# Given an array, estimate the standard error of the sample median from pg. 65
# of Wilcox, "Introduction to Robust Estimation and Hypothesis Testing", 2005

sub
msmedse
{
 my($x) = @_;
 
 my @sorted = sort {$a <=> $b} @$x;
 unshift @sorted, 0.0;
 my $n = @sorted -1;
 my $av = round_even(($n+1)/2.0 - 2.575829*sqrt($n/4.0));
 if ( $av == 0 )
 {
  $av = 1.0; 
 }
 my $top = ($n - $av + 1);
 my $sqse = (($sorted[$top] - $sorted[$av])/(2*2.575829))**2;
 $sqse = sqrt($sqse);

 return $sqse;
}

# The percentage bend midvariance
sub
pbvar
{
 my($x,$beta) = @_;

 if ( not defined $beta )
 {
  $beta = 0.2;
 }
 my $pbvar = 0;
 my $n = scalar @$x;
 my $median = Statistics::Robust::Location::median($x) + 0.0;

 my @w = ();
 for(my $i=0;$i<@$x;$i++)
 {
  $w[$i] = ($x->[$i] - $median);
 }

 my @sorted = sort {abs($a) <=> abs($b)} @w;
 my $m = floor((1-$beta)*$n + 0.5); 
 my $omega = $sorted[$m];

 if ( $omega > 0 )
 {
  my @z=0;
  my $np = 0;

  for(my $i=0;$i<@w;$i++)
  {
   my $y = $w[$i]/$omega; 
   if ( $y >= 1.0 )
   {
    $y = 1.0;
   }
   elsif ( $y <= -1 )
   {
    $y = -1.0;
   }
   else
   {
    $np++;
   }
   $z[$i] = $y**2;
  }
  
  $pbvar = $n*$omega**2*Statistics::Robust::_sum(\@z)/($np**2);
 }

 return $pbvar;
}

1;

=head1 NAME

Statistics::Robust::Scale - Robust Measures of Scale

=head1 SYNOPSIS

 my @x = (1,4,5,3,7,2,4);

 my($mad) = MAD(\@x);
 my($madn) = MADN(\@x);
 my($ql,qu) = idealf(\@x);
 my($winvar) = winvar(\@x);

=head1 FUNCTIONS

=head2 MAD

 my($mad) = MAD(\@x);

 Return the non-normalized Median Absolute Deviation.

=head2 MADN

 my($madn) = MADN(\@x);

 Return the Median Absolute Deviation normalized by the 0.75 quartile of the normal distribution.

=head2 idealf

 my($ql,$qu) = idealf(\@x); 

 Return the Ideal Fourths estimate of the lower and upper quartiles (in that order).

=head2 winvar

 my($winvar) = winvar(\@x,$tr);

 Return the Winsorized variance.  If the amount of trimming ($tr) is not specified, it defaults to 0.2.

=head2 trimvar

 my($trimvar) = trimvar(\@x,$tr);

 Return the variance for the trimmed mean with $tr trimming.  If the amount of trimming is not specified,
 it defaults to 0.2.

=head2 variance

 my($var) = variance(\@x);

 The unbiased sample variance.

=head2 msmedse

 my($mse) = msmedse(\@x);

 An estimate of the standard error of the median.

=head2 pbvar

 my($pb) = pbvar(\@x, $beta);

 The percentage-bend midvariance

=head1 AUTHOR

Walter Szeliga C<< <walter@geology.cwu.edu> >>

=cut
