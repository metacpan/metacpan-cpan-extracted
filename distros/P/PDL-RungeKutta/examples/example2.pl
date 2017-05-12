#!/usr/bin/perl -w
use PDL;
use PDL::Math;
use PDL::NiceSlice;
use PDL::RungeKutta;

# y'' + y = 0, Solution: y = sin(x)

$Y0=pdl(0,1);           # y(0)=0, y'(0)=1   ( Y=(f,g), f=y, g=y' )
@esargs=();             # extra arguments for error evaluation function
$t0=0;                  # initial moment
$dt0=0.1;               # initial time step
$t1=10;                 # final moment
$eps=1.e-6;             # error
$verbose=1;

# integration
($evt,$evy,$evd,$i,$j) = 
rkevolve($t0,$Y0,$dt0,\&DE,$t1,$eps,\&error,\@esargs,$verbose);

$check=sin($evt);
wcols $evt,$evy((0)),$check,'test.dat';

sub DE {                # differential eq
  my ($t,$y)= @_;
  my $yd=zeroes(2);			# Y'    ( = (f',g') = (y',y'') )
  $yd(0).=$y(1);     			# f'=g  ( = y' )
  $yd(1).=-$y(0);             		# g'=-f ( =-y )
  return $yd;
}

sub error {             # error scale 
  my ($t,$Y) = @_;
  my $es=ones(2);	# constant scale
  return $es;
}
