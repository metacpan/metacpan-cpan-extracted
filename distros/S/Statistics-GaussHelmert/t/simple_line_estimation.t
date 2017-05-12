# -*- cperl -*-

# do a simple 2D line estimation

use strict;
use warnings;
use Test;

BEGIN { $| = 1; plan tests => 2 }

use Statistics::GaussHelmert;
use PDL::Matrix;


# standard deviation of coordinates

my $estimation = new Statistics::GaussHelmert;

# register observations, see the example in Statistics::OLS for the
# data
my @y = (vpdl([.77, 2.57]),
	 vpdl([.74, 2.5]),
	 vpdl([.72, 2.35]),
	 vpdl([.73, 2.3]),
	 vpdl([.76, 2.25]),
	 vpdl([.75, 2.2]),
	 vpdl([1.08, 2.11]),
	 vpdl([1.81, 1.94]),
	 vpdl([1.39, 1.97]),
	 vpdl([1.2, 2.06]),
	 vpdl([1.17e+00, 2.02E0]));

# create multipiddle with cat and do the registration
my $y = PDL::cat(@y);
$estimation->observations($y);

# I guess the standard deviation of the numbers above is around that
# number:
my $sd = 0.01287;

# register covariances for observations 
my @Sigma_yy;
push @Sigma_yy, $sd**2*mpdl([[1,0],[0,1]]) for (0..$#y);

my $Sigma_yy = PDL::cat(@Sigma_yy);
$estimation->covariance_observations($Sigma_yy);

# initial guess, take the first and the last point:
# a = (y1-yn)/(x1-xn) , b = (xn*y1 - x1*yn)/(x1-xn)
my $b0 = vpdl(( $y[0]->at(1) - $y[-1]->at(1) ) / ( $y[0]->at(0) - $y[-1]->at(0) ),
	      ( ( $y[0]->at(0)*$y[-1]->at(1) -  $y[-1]->at(0)*$y[0]->at(1) ) /
		( $y[0]->at(0)-$y[-1]->at(0) ) ) 
	     ); 
$estimation->initial_guess($b0);

# closure returns an array for the funcion 
#  w(x,y;a,b) = a*x+b-y = 0
$estimation->observation_equations(sub { # closures are cool!
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0)*$y->at(0)+$b->at(1)-$y->at(1)]]);
				   });


# closure returns an array for the derivative dw/db
#   A = ( x, 1 )
$estimation->Jacobian_unknowns(sub { 
				 my ($y,$b) = @_;
				 mpdl([[$y->at(0),1]]);
			       });

# closure returns an array for the derivative dw/db
#   B = ( a, -1 )
$estimation->Jacobian_observations(sub {
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0),-1]]);
				   });


# number of contradictions
$estimation->start(verbose => 1);

# print result
print "initial unknown: $b0\n";
print $estimation->estimated_unknown(),
  $estimation->covariance_unknown();

ok(ref($estimation->estimated_unknown),"PDL::Matrix");
ok(ref($estimation->covariance_unknown),"PDL::Matrix");



__END__



