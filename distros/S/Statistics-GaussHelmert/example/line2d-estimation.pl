#!/usr/bin/perl

# -*- cperl -*-

# This is a simple example on how to use Statistics::GaussHelmert. We
# assume some 2D points (xi,yi) in 2D given, which should satisfy the
# line equations yi = a*xi + b

# The output on my machine is after the __END__. The result on your
# machine should be the same as I fixed the seed for Math::Random.

# Stephan Heuel Mon Jan 28 15:19:07 2002

use strict;
use warnings;

use Math::Random;
use PDL::Matrix;
use Statistics::GaussHelmert;


# initialize Math::Random, so that I know what to expect
random_set_seed_from_phrase("Mmmh, how do you like Statistics::GaussHelmert?");

# standard deviation of coordinates
my $sd = 0.01;
# ideal parameters: slope a and shift b for the line
my ($ideal_a,$ideal_b) = (0.1,3);
# number of points from which I want to estimate the line.
my $no_points = 10;

# generate xy coordinates and store them in one big array. Usually I
# get this data from some measurements.
my @xydata = map { ( random_normal(1,$_,$sd)   ,
		     random_normal(1,$ideal_a*$_+$ideal_b,$sd) ) 
		 } (1..$no_points);

# construct an empty GaussHelmert object
my $estimation = new Statistics::GaussHelmert;

# generate $y: this is a multipiddle, i.e. it is a PDL::Matrix of
# 2-vectors. The 2-vectors are the coordinate vectors for the points
#
# Note that $y is _not_ an y-coordinate, but a vector of
# observations. In this example there is a "namespace clash" between
# the general GaussHelmert model (see literature in manpage) and the
# simple linear equation.
my @y;
for (my $i=0; $i < @xydata ;$i+=2) {
  # every element of @y has a pdl with the (x,y) coordinates
  push @y, vpdl([$xydata[$i],$xydata[$i+1]]);
} 
my $y  = PDL::cat(@y);
# fill our object with the observations:
$estimation->observations($y);

# build covariances for observations 
my @Sigma_yy;
push @Sigma_yy, $sd**2*mpdl([[1,0],[0,1]]) for (1..$no_points);
my $Sigma_yy = PDL::cat(@Sigma_yy);
# again, insert the covariances in the GaussHelmert model
$estimation->covariance_observations($Sigma_yy);

# initial guess, the unknown parameters are \beta = (a, b)^T,
# we take the first and the last point to compute the initial guess:
# a = (y1-yn)/(x1-xn) , b = (xn*y1 - x1*yn)/(x1-xn)
# this gets a bit compliated in PDL notation:
my $b0 = vpdl(( $y[0]->at(1) - $y[-1]->at(1) ) / ( $y[0]->at(0) - $y[-1]->at(0) ),
	      ( ( $y[0]->at(0)*$y[-1]->at(1) -  $y[-1]->at(0)*$y[0]->at(1) ) /
		( $y[0]->at(0)-$y[-1]->at(0) ) ) 
	     ); 
# register the initial guess
$estimation->initial_guess($b0);

# Now we need to set the implicit observation equations as 
#
# w(x,y;a,b) = a*x+b-y = 0 
#
# We generate a closure which returns a PDL::Matrix object (!). This
# is actually a vector which is supposed to be zero. In our case, it's
# only a 1-vector, since we have only one equation per observed point.
$estimation->observation_equations(sub { # closures are cool!
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0) * $y->at(0) +
					    $b->at(1) - $y->at(1)]]);
				   });


# This is again a closure for the Jacobian A=d(w(y,beta))/d(beta)
#   A = ( x, 1 )
$estimation->Jacobian_unknowns(sub { 
				 my ($y,$b) = @_;
				 mpdl([[$y->at(0),1]]);
			       });

# This is again a closure for the Jacobian B=d(w(y,beta))/d(y)
#   B = ( a, -1 )
$estimation->Jacobian_observations(sub {
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0),-1]]);
				   });


print "Start the estimation for yi = a*xi +b!\n\n";
print "Observations are : ".$estimation->observations()."\n";

$estimation->start(verbose => "./testlog.log");
print "Done with estimation.\n\n";
my ($estimated_a,$estimated_b) = ($estimation->estimated_unknown()->at(0),
				  $estimation->estimated_unknown()->at(1));

print "* estimated a = $estimated_a\n  estimated b = $estimated_b\n\n";
print "* Covariance matrix for (a,b)^T:";
print $estimation->covariance_unknown."\n";

print "* The estimated covariance factor (sigma0^2) is  ".
  $estimation->sigma0_squared."\n\n";

print "* The fitted observations are ".
  $estimation->estimated_observations->[0]."\n\n";


__END__
# Here's the output:

Start the estimation for yi = a*xi +b!

Observations are : 
[
 [
  [0.99857135]
  [ 3.0977909]
 ]
 [
  [ 2.0115272]
  [ 3.2069471]
 ]
 [
  [ 3.0049479]
  [ 3.2961774]
 ]
 [
  [ 4.0143548]
  [   3.39218]
 ]
 [
  [ 5.0060976]
  [ 3.4844157]
 ]
 [
  [ 5.9898272]
  [ 3.5944169]
 ]
 [
  [  7.005609]
  [ 3.7072351]
 ]
 [
  [ 8.0084446]
  [  3.785342]
 ]
 [
  [ 9.0163171]
  [ 3.9001294]
 ]
 [
  [ 10.001671]
  [ 4.0072095]
 ]
]

Done with estimation.

* estimated a = 0.100208540891802
  estimated b = 2.99546257832081

* Covariance matrix for (a,b)^T:
[
 [1.2237447e-06 -6.737616e-06]
 [-6.737616e-06 4.7195956e-05]
]

* The estimated covariance factor (sigma0^2) is  0.796417043883086

* The fitted observations are 
[
 [
  [0.99879586]
  [ 3.0955505]
 ]
 [
  [ 2.0125106]
  [ 3.1971333]
 ]
 [
  [ 3.0049075]
  [   3.29658]
 ]
 [
  [ 4.0138036]
  [   3.39768]
 ]
 [
  [ 5.0048376]
  [   3.49699]
 ]
 [
  [ 5.9897004]
  [ 3.5956817]
 ]
 [
  [ 7.0065764]
  [ 3.6975814]
 ]
 [
  [  8.007191]
  [ 3.7978515]
 ]
 [
  [ 9.0164317]
  [  3.898986]
 ]
 [
  [ 10.002613]
  [ 3.9978098]
 ]
]
