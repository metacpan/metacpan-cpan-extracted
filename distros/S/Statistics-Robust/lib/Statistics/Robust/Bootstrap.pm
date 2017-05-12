package Statistics::Robust::Bootstrap;

use strict;
use warnings;
use Carp;

use POSIX qw(floor);
use Math::Round;
use Math::Random;

use base 'Statistics::Robust';

our @EXPORT = ();
our @EXPORT_OK = (qw(
onesample
sample_wr
sample_wor
));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# The percentile bootstrap
sub
onesample
{
 my($x,$func,$alpha,$n) = @_;

 my @b_vec = ();
 for(my $i=0;$i<$n;$i++)
 {
  my($y) = sample_wr($x);
  my $val = $func->($y);
  push(@b_vec,$val);
 }

 @b_vec = sort {$a <=> $b} @b_vec;
 my $low = round(($alpha/2)*$n);
 my $up = $n-$low;
 $low++;
 
 my $cl = $b_vec[$low];
 my $ch = $b_vec[$up];

 return $cl,$ch;
}

# Sampling with replacement

sub
sample_wr
{
 my($x) = @_;

 my $n = scalar @$x;
 my @result = ();
 my(@j) = random_uniform_integer($n,0,($n-1));
 for(my $i=0;$i<$n;$i++)
 {
  $result[$i] = $x->[$j[$i]];
 }

 return \@result;
}

# Sampling without replacement
# Algorithm 3.4.2S from Knuth's Seminumeric Algorithms

sub
sample_wor
{
 my($x,$n) = @_;
 
 my $N = scalar @$x; # Population Size
 # $n is the sample size

 my @samples = (); # Indices of selected items
 my $t = 0; # total input records dealt with
 my $m = 0; # number of items selected so far

 while ( $m < $n )
 {
  my $u = random_uniform();

  if ( ($N - $t)*$u >= ($n-$m) )
  {
   $t++;
  }
  else
  {
   $samples[$m] = $x->[$t];
   $t++;
   $m++;
  }
 }
 
 return \@samples;
}

1;

=head1 NAME

Statistics::Robust::Bootstrap - Bootstrap Estimation

=head1 SYNOPSIS

 my @x = (1,4,5,3,7,2,4);

 my($low,$high) = onesample(\@x, \&func, $alpha, $n);

 my($wr) = sample_wr(\@x);
 
 my($wor) = sample_wor(\@x,$n);

=head2 onesample

 my($low,$high) = onesample(\@x, \&mean, $alpha, $n);

Compute a bootstrap estimate of the alpha confidence interval for a measure of
location func using a percentile bootstrap method.

=head2 sample_wr

 my($resamp) = sample_wr(\@x);

Sample with replacement from a vector

=head2 sample_wor

 my($resamp) = sample_wor(\@x,$n);

Sample $n values without replacement from a vector

=head1 AUTHOR

Walter Szeliga C<< <walter@geology.cwu.edu> >>

=cut
