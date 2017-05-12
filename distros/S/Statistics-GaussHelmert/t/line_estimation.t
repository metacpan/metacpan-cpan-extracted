# -*- cperl -*-


use strict;
use warnings;
use Test;

BEGIN { $| = 1; plan tests => 4 }

use Statistics::GaussHelmert;
use PDL::Matrix;
use Math::Random;

# my  @xydata = qw (   
# 		  .77 2.57        .74 2.5         .72 2.35
# 		  .73 2.3         .76 2.25        .75 2.2
# 		  1.08 2.11       1.81 1.94       1.39 1.97
# 		  1.2 2.06        1.17e+00 2.02E0
# 		 );
# my $sd = 0.01287;

#############################################################
# 1.) test if regular estimation works, this is the simpler case 

# so that I know what to expect
random_set_seed_from_phrase("Ich möchte Transformationen schätzen.");

my $meansigma0 =0;
my $n = 100; # number of tests, theoretically it should be 100000 or
             # something, but we don't have time for this

# standard deviation of coordinates
my $sd = 0.001;
my ($ideal_a,$ideal_b) = (0.1,3);
my $no_points = 10;

my $estimation = new Statistics::GaussHelmert;

# build covariances for observations 
my @Sigma_yy;
push @Sigma_yy, $sd**2*mpdl([[1,0],[0,1]]) for (1..$no_points);

my $Sigma_yy = PDL::cat(@Sigma_yy);
$estimation->covariance_observations($Sigma_yy);

# initial guess, the unknown parameters are \beta = (a, b)^T
my $b0 = vpdl([random_normal(1,$ideal_a,0.1),
	       random_normal(1,$ideal_b,0.1)]); 
#my $b0 = vpdl([-0.5,2.9]); 
$estimation->initial_guess($b0);

# returns an array for the funcion 
#  w(x,y;a,b) = a*x+b-y = 0
$estimation->observation_equations(sub { # closures are cool!
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0)*$y->at(0)+$b->at(1)-$y->at(1)]]);
				   });


# returns an array for the derivative dw/db
#   A = ( x, 1 )
$estimation->Jacobian_unknowns(sub { 
				 my ($y,$b) = @_;
				 mpdl([[$y->at(0),1]]);
			       });

# returns an array for the derivative dw/db
#   B = ( a, -1 )
$estimation->Jacobian_observations(sub {
				     my ($y,$b) = @_;
				     mpdl([[$b->at(0),-1]]);
				   });

for (0..$n) {
  # generate observations
  my $y = setup_observations($ideal_a,$ideal_b,$no_points,$sd);
  # number of contradictions
  $estimation->observations($y);
  $estimation->start(verbose => 0);
  print "."; # sqrt($estimation->sigma0_squared())."\n";
  $meansigma0 += $estimation->sigma0_squared();
}
$meansigma0 = sqrt($meansigma0/$n);
print "\nsqrt(mean)   = $meansigma0\n";

ok(ref($estimation->estimated_unknown),"PDL::Matrix");
ok(($meansigma0 > 0.5 and
    $meansigma0 < 1.5),1);


#############################################################
# 2.) test if an estimation with blocks works. This is not really
# worth looking at if you just want to have a first glance of the system
my $blockestim = new Statistics::GaussHelmertBlocks;
$meansigma0 = 0;

$blockestim->initial_guess($b0);
$blockestim->covariance_observations([$Sigma_yy]);
$blockestim->observation_equations(sub { wrap_single_function_to_block_function($_[0],$_[1],
										$estimation->observation_equations); 
				       });
$blockestim->Jacobian_observations(sub { wrap_single_function_to_block_function($_[0],$_[1],
										$estimation->Jacobian_observations); 
				       });
$blockestim->Jacobian_unknowns(sub { wrap_single_function_to_block_function($_[0],$_[1],
									    $estimation->Jacobian_unknowns); 
				   });

for (0..$n) {
  # generate observations
  my ($y,$nW) = setup_observations($ideal_a,$ideal_b,$no_points,$sd);
  $blockestim->observations([$y]);
  $blockestim->start(verbose => 0);
  print "."; # sqrt($estimation->sigma0_squared())."\n";
  $meansigma0 += $estimation->sigma0_squared();
}
$meansigma0 = sqrt($meansigma0/$n);
print "\nsqrt(mean)   = $meansigma0\n";


ok(ref($blockestim->estimated_unknown),"PDL::Matrix");
ok(($meansigma0 > 0.5 and
    $meansigma0 < 1.5),1);

# this is a local copy of the corresponding function in
# Statistics::GaussHelmert. 
sub wrap_single_function_to_block_function {
  my ($y,$b,$function) = @_;

  my @ygroup = PDL::dog( $y->[0] ); # dog is the opposite of PDL::cat
  
  my @Jgroup;
  # this could be a PP function as well.
  @Jgroup = map {
    &$function($_,$b);
  } @ygroup ;
  
  return (PDL::cat(@Jgroup));
}

# this is to setup the observation vectors and give me the overall
# number of contradictions
sub setup_observations {
  my ($ideal_a,$ideal_b,$no_points,$sd) = @_;
  my @y;

  my $xs = 1;
  my $xe = $no_points;

  my @xydata = map { ( random_normal(1,$_,$sd)   ,
		       random_normal(1,$ideal_a*$_+$ideal_b,$sd) ) } ($xs..$xe);

  for (my $i=0; $i < @xydata ;$i+=2) {
    # every element of @y has a pdl with the (x,y) coordinates
    push @y, vpdl([$xydata[$i],$xydata[$i+1]]);
  } 
  return PDL::cat(@y);
}

__END__



