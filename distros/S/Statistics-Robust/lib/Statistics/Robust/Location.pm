package Statistics::Robust::Location;

use strict;
use warnings;
use Carp;

use Math::CDF qw(pbeta);
use POSIX qw(floor);

use base 'Statistics::Robust';

our @EXPORT = ();
our @EXPORT_OK = (qw(
median
win
tmean
mean
hd
));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# Implement the median to avoid needing Statistics::Basic
# which has silly Number::Format requirements (Version 1.6004)
sub
median
{
 my($x) = @_;

 my @y = sort {$a <=> $b} @$x;
 my $length = scalar @y;

 my $median = undef;
 if ( $length % 2 ) 
 {
  my $half = int ($length/2);
  $median = $y[$half];  
 } 
 else
 {
  my $lower_half = int (($length-1)/2);
  my $upper_half = int  ($length/2);

  $median = ($y[$lower_half] + $y[$upper_half])/2;
 }

 return $median; 
}


# The gamma Winsorized mean
sub
win
{
 my($x,$gamma) = @_;

 if ( not defined $gamma )
 {
  $gamma = 0.2;
 } 

 my @y = sort {$a <=> $b} @$x;
 my $n = scalar @y;
 my $ibot = floor($gamma*$n) + 1;
 my $itop = $n - $ibot + 1;
 my $xbot = $y[$ibot];
 my $xtop = $y[$itop];

 for(my $i=0;$i<@y;$i++)
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
 
 my $win = mean(\@y);
 return $win;
}

# The trimmed mean
sub
tmean
{
 my($x,$tr) = @_;

 if ( not defined $tr )
 {
  $tr = 0.2;
 }

 my @y = sort {$a <=> $b} @$x;
 my $n = scalar @y;
 my $g = floor($tr*$n);

 my $tmean = 0.0; 
 for(my $i=$g;$i<($n-$g);$i++)
 {
  $tmean += $y[$i];
 } 
 $tmean = $tmean/($n - 2*$g);

 return $tmean; 
}

# The Harrel-Davis Estimator for quantiles
sub
hd
{
 my($x,$q) = @_;
 
 if ( not defined $q )
 {
  $q = 0.5;
 }
 my $n = scalar @$x;
 my $m1 = ($n+1)*$q;
 my $m2 = ($n+1)*(1-$q);
 my @y = sort  {$a <=> $b} @$x;

 my @wy = ();
 for(my $i=1;$i<=$n;$i++)
 {
  my $w = pbeta(($i/$n),$m1,$m2) - pbeta(($i-1)/$n, $m1,$m2);
  $wy[$i-1] = $w*$y[$i-1]; 
 }

 my $hd = Statistics::Robust::_sum(\@wy);

 return $hd;
}

sub
mean
{
 my($x) = @_;

 my $n = scalar @$x;
 if ( $n == 0 ) { return undef;}
 my $sum = Statistics::Robust::_sum($x);
 my $mean = $sum/$n;

 return $mean; 
}

1;

=head1 NAME

Statistics::Robust::Location - Robust Location Estimators

=head1 SYNOPSIS

 my @x = (1,4,5,3,7,2,4);

 my($tmean) = tmean(\@x);

 my($win) = win(\@x);

=head1 FUNCTIONS

=head2 win

 my($win) = win(\@x,$gamma);

 Return the gamma Winsorized mean.  If gamma is not specified, it defaults to 0.2.

=head2 tmean

 my($tmean) = tmean(\@x,$tr);

 Return the trimmed mean.  If $tr is not specified, it defaults to 0.2.

=head2 mean

 my($mean) = mean(\@x);

 Although not a robust measure of location, it is useful for comparison as well as used internally in the computation
 of some robust methods. This returns the mean of the array @x.

=head2 hd

 my($est) = hd(\@x, $q)

 The Harell-Davis Estimator for the quantile $q.

=head2 median

 my($median) = median(\@x);

 Return the median

=head1 AUTHOR

Walter Szeliga C<< <walter@geology.cwu.edu> >>

=cut
