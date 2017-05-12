# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Statistics::OLS;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

eval {
  # see pod for the source of the example
  @xydata = qw (   
		.77 2.57	.74 2.5 	.72 2.35
		.73 2.3		.76 2.25	.75 2.2
		1.08 2.11	1.81 1.94	1.39 1.97
		1.2 2.06	1.17e+00 2.02E0
	       );

  # create the least squares object
  $ls = Statistics::OLS->new;
  
  # register the data set with the regression object
  $ls->setData (\@xydata) or die $ls->error();

  # do the computation
  $ls->regress() or die $ls->error();

  # get the statistics 
  ($intercept, $slope) = $ls->coefficients();
  $R_squared = $ls->rsq();
  ($tstat_intercept, $tstat_slope) = $ls->tstats();
  $sigma = $ls->sigma();
  $sample_size = $ls->size();
  
  ($avX, $avY) = $ls->av();
  ($varX, $varY, $covXY) = $ls->var();
  ($xmin, $xmax, $ymin, $ymax) = $ls->minMax(); 
  
  @predictedYs = $ls->predicted();
  @residuals = $ls->residuals();      

#  these are the results on my machine

#  ($my_intercept, $my_slope) = (2.69112393863717, -0.479529075990007);
#  $my_R_squared = 0.662757189178281;
#  ($my_tstat_intercept, $my_tstat_slope) = (22.1268635416728, -4.20559190653145);
#  $my_sigma = 0.128702809019511;
#  $my_sample_size = 11;
#
#  ($my_avX, $my_avY) = (1.01090909090909, 2.20636363636364);
#  ($my_varX, $my_varY, $my_covXY) 
#    = (0.127409090909091, 0.044205454545456, -0.0610963636363632);
#  ($my_xmin, $my_xmax, $my_ymin, $my_ymax) = (.72, 1.81, 1.94, 2.57);
#
#  @my_predictedYs = qw (
#			 .77 2.32188655012486 .74 2.33627242240456 
#			 .72 2.34586300392437 .73 2.34106771316447 
#			 .76 2.32668184088476 .75 2.33147713164466 
#			 1.08 2.17323253656796 1.81 1.82317631109526 
#			 1.39 2.02457852301106 1.2 2.11568904744916 
#			 1.17 2.13007491972886
#			);
#
#  @my_residuals = qw (
#		       .77 0.248113449875135 .74 0.163727577595435 
#		       .72 0.004136996075635 .73 -0.0410677131644652 
#		       .76 -0.0766818408847648 .75 -0.131477131644665 
#		       1.08 -0.0632325365679627 1.81 0.116823688904742 
#		       1.39 -0.0545785230110606 1.2 -0.0556890474491618 
#		       1.17 -0.110074919728862  
#		       );

};
$_ = ($@ ? "Not ok 2: $@\n" : "ok 2\n");
print;
