package Statistics::GaussHelmert;

=head1 NAME

Statistics::GaussHelmert - General weighted least squares estimation

=head1 VERSION

This document refers to version 0.03

=head1 SYNOPSIS

 use Statistics::GaussHelmert;

 # create an empty model
 my $estimation = new Statistics::GaussHelmert;

 # setup the model given observations $y, covariance matrices
 # $Sigma_yy, an initial guess $b0 for the unknown parameters.
 $estimation->observations($y);
 $estimation->covariance_observations($Sigma_yy);
 $estimation->initial_guess($b0);

 # specify the implicit model function and its Jacobians by using
 # closures. 
 $estimation->observation_equations(sub { ... });
 $estimation->Jacobian_unknowns(sub { ... });
 $estimation->Jacobian_observations(sub { ... });

 # Maybe we want to impose some constraints on the unknown
 # parameters, this is not mandatory
 $estimation->constraints(sub { ... });
 $estimation->Jacobian_constraints(sub { ... });

 # start estimation
 $estimation->start(verbose => 1);

 # print result
 print $estimation->estimated_unknown(),
    $estimation->covariance_unknown();

=head1 DESCRIPTION

This module is a flexible tool for estimating model parameters given a
set of observations. The module provides function for a linear
estimation model, the underlying model is called Gauss-Helmert model.

Statistics::GaussHelmert is different to modules such as
Statistics::OLS in the sense that it may fit arbitrary functions to
data of any dimensions. You have to specify an implicit minimization
function (in contrast to explicit functions as in traditional
regression methods) and its derivatives with respects to the unknown
and the observations. You may also specify constraint function on the
unknowns (with its derivative). Furthermore you already need an
approximate solution. For some problems it is easy finding approximate
solutions by directly solving for the unknown parameters with some
well chosen observations.

=head2 Setting up the model

Assume you have a some measurements (or observations) which are
related to some unknown parameters that you want to know. For example,
you measure points in 2D which should lie on an unknown line. 

The points that you measure in 2D will be put in a L<PDL::Matrix>
object $y (a so-called multipiddle i.e. multi-PDL object, a vector of
vectors). The unknown parameter vector $b is again a L<PDL::Matrix>
object, just a vector. Additionally, you should have an idea on how
precise your measurements are and specify this in a covariance matrix
- actually again a multipiddle: a vector of matrices.

Before you use this module to solve your problem, you first have to
sit down and calculate the equations which relate your observations
with the unknown parameters. The Gauss-Helmert model requires that you
specify this equation in the form w($y,$b) = 0, where $y are the
observations (lined up in a L<PDL::Matrix> vector of vectors, see
below) and $b is the unknown parameter vector. This equation w($y,$b)
= 0 is called "observation equation". Note that in general this is a
"vector equation", i.e. a set of scalar equations.

Then you have to think about, what constraints you want to impose on
the unkown parameter vector $b. It could be that you want it to have
the (euclidean) length 1, or you want to set one parameter to a
certain value. So you specify a function of the form h($b) = 0, again
in general being a "vector equation".

To do the minimization according to the model w($y,$b)=0 and h($b) =
0, you also need to specify the Jacobians of the observation function
w($y,$b) and the constraint function h($b). We need the Jacobians with
respect to the observation vector $y and the unknown vector $b. Right
now it is not possible to do numerical differentiation - in that case
the Jacobians wouldn't be needed.

=head2 Coding the model

Let us say you have an array @y of n different observation vectors,
each of the vectors being a PDL::Matrix vector, for example generated
by the special constructor vpdl from L<PDL::Matrix>. To put then in the
estimation, you have line them up in a multipiddle $y using $y =
PDL::cat(@y).

The same applies for the set of covariance matrices @Sigma_yy for the
elements of the array @y.

The observation function and its Jacobians (also the constraints on
the unknown and its Jacobians) may be defined as closures. The
Jacobian closures return L<PDL::Matrix> matrices, the dimensions
depend on the dimensions of the vectors in @y and $b. 

You may want to look at some examples in the t/ directory or the
example/ directory for more detailed information.

Furthermore you may pass some options to the estimation:

=over

=item verbose() ; verbose(2) ; verbose("/path/to/my/logfile")

If this variable is set to 1, a short protocol is printed on STDOUT,
If it is set to 2, a more elaborated output is written to the file
"./GaussHelmert.log". You may also pass a filename to verbose so the
elaborated output will go to this file.

The value of verbose() defaults to 0, i.e. no output at all.

=item max_iteration() ; max_iteration(10)

returns or sets the maximum number of iteration which may be reached
if the abort criteria is not met. Default is 15.

=item eps() ; eps($small_number)

Returns or sets a small number which is used for the abort criteria of
the iteration. This refers to the largest difference of change that is
allowed in the unknown vector divided by its standard deviation. It
defaults to 10^(-2), this means we want to be within a precision of 1%
of the standard deviation.

=back

=head2 Estimation results

You may now start and retrieve the results:

=over 

=item start() ; start(verbose => 2) 

Starts the estimation and returns the object itself. 

=item estimated_unknown() 

returns the estimated unknown parameter vector as a PDL::Matrix
object.

=item sigma0_squared()

returns the estimated covariance factor.

=item covariance_unknown()

returns the estimated covariance matrix, without the covariance factor.

=item estimated_observations()

returns the fitted observations as a multipiddle.

=item estimated_unknowns_iterations()

returns a list of estimated unknown parameter vectors for each iteration.

=item number_of_iterations()

returns the used number of iterations.

=back

=head1 EXAMPLE USAGE

See t/ and example/ folder (to be expanded).

=head1 NOT YET DOCUMENTED

There is a subclass Statistics::GaussHelmertBlocks, which can deal
with blocks of observation vectors. This is not documented yet, but
used in L<Math::UncertainGeometry>.

=head1 LITERATURE

=over

=item Press et al. (1992) Numerical Recipes in C, 2nd Ed., Cambridge
University Press, Chapter 15.

Chapter 15, "Modeling of Data", deals with general weighted least
squares estimation, though it describes the Levenber-Marquardt method
in more detail. Additionally, it is assumed that only one maesurement
is observed.

=item Mikhail, E.M. and Ackermann, F. (1976): Observations and Least
Squares University Press of America

This book covers the classical Gauss-Helmert model.

=item Koch, K. (1999) Parameter Estimation and Hypothesis Testing in
Linear Models, Springer Verlag, 2nd edition

This book covers the Gauss-Markoff model, a cousin of the
Gauss-Helmert model, but modelling explicit functions.

=back

=head1 DIAGNOSTICS

Not really done yet, meanwhile check the output with the verbose flag.

=head1 BUGS

Probably there are some, but this function has been extensively and
succesfully tested in conjunction with the Math::UncertainGeometry
library.

=head1 TODO

=over

=item numerical differentiation instead of explicit Jacobians

=item Better diagnostics, more examples

=item Speed Optimization not done at all. 

=item More examples

=item A more complete TODO list

=back

=head1 SEE ALSO

This module uses the Perl Data Language, L<PDL>, especially
L<PDL::Matrix>, to perform matrix operations.

For a complex example on how this module is used, see
L<Math::UncertainGeometry::Estimation> for estimating points, lines
and planes in 2D and 3D.

=head1 AUTHOR

Stephan Heuel
(perl@heuel.org)

=head1 COPYRIGHT

Copyright (C) 2000/2001 Stephan Heuel and Institute for
Photogrammetry, University of Bonn. All rights reserved. There is no
warranty. You are allowed to redistribute this software /
documentation under certain conditions, see the GNU Public License,
GPL for details, http://www.gnu.org/copyleft/gpl.html.

=cut

use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use 5.6.0;

use Exporter;
$VERSION = 0.05;
@ISA = qw(Exporter);

@EXPORT = qw(); # symbols to autoexport, will be filled later on
@EXPORT_OK = qw(); #symbols to export on request
%EXPORT_TAGS = ( );

use PDL;
use PDL::Matrix;
use PDL::Math;
use PDL::Slatec;

# this may be accessed from outside, but it is more advisable to use
# the OO interface and the verbose method
our $OUTPUT = 0;

# default number of iterations
my $number_of_iteration=15;

# default abort criteria. This refers to the largest difference of
# change in the estimated vector divided by its standard deviation
my $eps = 1e-2;

#################################################
## OO wrapper for GaussHelmertBlocks:
##

# build lookup table for input data
my %input_data =  map { ($_,1) } 
  qw/observations initial_guess covariance_observations
  observation_equations Jacobian_unknowns Jacobian_observations
  constraints Jacobian_constraints constraints_observations noblocks
  Jacobian_constraints_observations maximal_no_iterations epsilon
  verbose/;

# build lookup table for output data
my %output_data = map { ($_,1) } 
  qw/estimated_unknown sigma0_squared covariance_unknown
  estimated_observations estimated_unknowns_iterations
  number_of_iterations/;

# constructor
sub new {
  my ($protoverse, %arg) = @_;
  my $class = ref($protoverse) || $protoverse;
  
  my $self = { };
  set_all($self,%arg);

  # this parameter will determine whether we specify blocks of
  # observation vectors or just one single observation vector
  $self->{_noblocks} = 1;

  bless $self,$class;
}

# set member variables by passing a hash
sub set_all {
  my ($self,%arg) = @_;

  # store all passed keys
  foreach my $arg_key (keys %arg) {
    defined $input_data{$arg_key} or 
      warn "*** Unknown input argument $arg_key for constructing ".__PACKAGE__." object\n";
    $self->{"_$arg_key"} =   $arg{$arg_key};
  }
}

# declare all member functions such that members may access and change
# object data 
foreach my $input_data (keys %input_data) {
  no strict 'refs';
  *$input_data = sub {           # closures are cool !
    my ($self,$value) = @_;
    return $self->{"_$input_data"} unless defined $value;
    $self->{"_$input_data"} = $value;
  }
}

# output data can only be accessed by read-only member functions
foreach my $output_data (keys %output_data) {
  no strict 'refs';
  *$output_data = sub { $_[0]->{"_$output_data"}; }
}

# do the actual estimation 
sub start {
  my $self = shift; 
  $self->set_all(@_);

  # copy data to temporary hash, uhm... well... I should get around
  # this.
  my %arg;
  $arg{$_} = $self->{"_$_"} for (keys %input_data);

  # call the actual estimation procedure
  my $result = GaussHelmertBlocks(\%arg);

  # and now copy the result to myself
  $self->{"_$_"} = $result->{$_} for (keys %$result);
  
  return $self;
}

# this is needed when GaussHelmertBlocks is called, but actually we
# only have one block of observations and therefore we don't want to
# get into the hassle of expressing the functions (and Jacobians) in
# blocks. This function wraps a single call (&$function) to a block
# call
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

##########################################################################
# This is the actual function for estimating 
#
# there is some experimental code included which may let the
# observations $y constrained in a second stage by the constraint
# g($y$) and its Jacobian $G$. This part of the code has been not
# tested.
sub GaussHelmertBlocks {
  my ($args) = @_;

  warn "I expect only one hash argument to GaussHelmertBlocks" if @_>1;

  # decode hash arguments;
  my $y  =             delete $args->{observations};
  my $b0 =             delete $args->{initial_guess};
  my $Sigma_yy =       delete $args->{covariance_observations};
  my $func_w_in =      delete $args->{observation_equations};
  my $func_A_in =      delete $args->{Jacobian_unknowns};
  my $func_B_in =      delete $args->{Jacobian_observations};
  my $func_h_in =      delete $args->{constraints};
  my $func_H_in =      delete $args->{Jacobian_constraints};
  my $func_g =         delete $args->{constraints_observations};
  my $func_G =         delete $args->{Jacobian_constraints_observations};
  my $max_iterations = delete $args->{maximal_no_iterations};
  my $epsilon        = delete $args->{epsilon} || $eps;
  my $noblocks       = delete $args->{noblocks};
  my $verbose        = delete $args->{verbose};

  my $logfile = "./GaussHelmert.log";

  # if verbose is defined and nonempty and does not only contain
  # numbers, then we assume it's the string for the filename of the
  # logfile. 
  if (defined $verbose and $verbose ne "" and $verbose !~ /^\d+$/) {
    $logfile=$verbose;
    $verbose=2;
  }

  # set for verbosity
  my $tmp = $OUTPUT; # so that I can restore the global variable
                     # $OUTPUT, should be changed since $OUTPUT must
                     # not be global
  $OUTPUT = $verbose if defined $verbose;


  # warn for unknown options in argument hash
  foreach (keys %$args) {
    warn "*** Warning: Unknown option to GaussHelmertBlocks: $_\n";
  }


  my ($func_w,$func_A,$func_B,$func_h,$func_H);
  if (defined $noblocks and $noblocks) {
    $func_A = sub { wrap_single_function_to_block_function($_[0],$_[1],$func_A_in); };
    $func_B = sub { wrap_single_function_to_block_function($_[0],$_[1],$func_B_in); };
    $func_w = sub { wrap_single_function_to_block_function($_[0],$_[1],$func_w_in); };
    if (defined $func_h_in) {
      $func_h = sub { wrap_single_function_to_block_function($_[0],$_[1],$func_h_in); };
      $func_H = sub { wrap_single_function_to_block_function($_[0],$_[1],$func_H_in); };
    }
    # wrap observations etc in an array
    $Sigma_yy = [ $Sigma_yy ];
    $y = [ $y ];
  }
  else {
    $func_w = $func_w_in;
    $func_A = $func_A_in;
    $func_B = $func_B_in;
    if (defined $func_h_in) {
      $func_h = $func_h_in;
      $func_H = $func_H_in;
    }
  }

  ################################################################################
  #
  # some preperations needed

  # set the maximum number of iterations
  $max_iterations ||= $number_of_iteration;

  # initialize $y^\hat$ and $b^\hat$.
  my @y_observed  = @$y; # these are my observations!
  # in @y will be the estimated observations
  my @y = map { defined($_) ? $_->copy : undef } @y_observed;
  # now we set up variables such as unknowns $b, we keep track of the
  # unknowns per iteration (@b_iterations), the offerenc between two
  # consecutive unknowns $delta_b, the error $e and the coariance
  # matrix $Sigma_bb for the unknowns
  my ($b,@b_iterations,$delta_b,$e,$Sigma_bb);

  # check if we get the number of contradictions from the funtion w
  # itself. 
  my ($nU,$nW,$nH) = (0,0,0);

  # iteration 0
  my $i=0;

  # if the initial guess $b0 for the unknown is not defined and
  # therefore the Jacobian $A$ not defined either, we assume that only
  # the observations are supposed to be estimated.
  my ($only_observations,@A_init)=(0,undef);
  if (!defined($b0) && !defined($func_A)) {
    $only_observations=1;
    # build dummy observation and dummy Jacobian so that we do not
    # have to change too much code (for the sake of less
    # efficiency).
    $b0 = vpdl([0]); # the shortest unknown possible
    @A_init = map { (my $x = ~$y[$_]->copy) .= 0; $x; } (0..$#y);
    $nU=0;
    $nH=0;
  }
  else {
    $b  = $b0->copy;
    @b_iterations = ($b); # here I store all iterations of the
                          # unknown vector b
    $nU = ($b0->mdims())[0];	
    if (defined $func_h) {
      my $ch_dummy = &$func_h($b);
      # the number of constraints are equal to the number of elements
      # in the resulting vector of constraint function &$func_h
      $nH = ($ch_dummy->clump(-1)->dims)[0];
    } else {
      $nH=0;
    }
  }

  # determine number of contradictions
  my @cw_dummy = &$func_w([@y],$b0);
  # sum up the list of contradictions for each block
  $nW += ($_->clump(-1)->dims)[0] foreach (@cw_dummy);

  # assume Sigma_yy to be identity if it is not defined
  if (!defined($Sigma_yy)) {
    $Sigma_yy = [ map { my ($dim,undef,$no) = $y[$_]->mdims();
			my $Id = mzeroes($dim,$dim,$no);
			(my $tmp = $Id->diagonal(0,1)) .= 1;
			$Id;
		      } (0..$#y) ];
  }
  
  if ($nW + $nH < $nU) {
    warn "*** Warning: ",
      __FILE__," line ",__LINE__,"\n",
      "    # of unknowns ($nU) is larger than # of obs. ($nW) + # of constraints ($nH)\n";
    return undef;
  }
  my $Omega_last_iteration = 0;
  my (@w,$sigma_hat);  

  if ($OUTPUT>1) {
    print "Generating logfile in $logfile\n";
    open LOG,">$logfile" or warn "**** cannot open logfile $logfile: $!\n";
    print LOG "generated on ",scalar(localtime),"\n";
    print LOG "nW = $nW; nH = $nH; nU = $nU\n";
    
    print LOG "Sigma_yy ",join(",",@$Sigma_yy);
  }
  
  ################################################################################
  #
  # now start iterations!
  while ($i++ < $max_iterations) {
    if ($OUTPUT) {
      print LOG "Iteration $i\n" if $OUTPUT > 1;
      print "Iteration $i\n";
    } 
    my @A  = ($only_observations) ? @A_init : &$func_A([@y],$b);
    my @B  = &$func_B([@y],$b);
    my $H  = ($only_observations || !defined($func_H)) ? undef : &$func_H($b);
    
    if ($OUTPUT>1) { 
      print LOG "y$i part $_ ".$y[$_]->clump(3)."\n" for (0..$#y);
    } 

    # compute $c_w$.
    my @dy = map { $y_observed[$_] - $y[$_] } (0 .. $#y);
    my @cw = &$func_w([@y],$b);
    $cw[$_] += $B[$_] x $dy[$_] for (0..$#y);

    if ($OUTPUT>1) {
      print LOG "A($i)",join(",",@A);
      print LOG "B($i)",join(",",@B);
      print LOG "H($i)",$H if defined $H;
    }
    

    # $Sigma_ww^{-1}$.
#    print @B; print @$Sigma_yy;
    print LOG "\@B x ~\@B", join(",",map { ($B[$_] x $Sigma_yy->[$_] x ~$B[$_]) } (0 .. $#y)) if $OUTPUT>1;
    my @Sigma_ww_inv = map { ($B[$_] x $Sigma_yy->[$_] x ~$B[$_])->matinv } (0 .. $#y);

    if ($OUTPUT>1) { 
      @w = &$func_w([@y_observed],$b);	# new calculation of w for output purposes
      foreach (0..$#w) { 
	print LOG "cw(b$i,y$i) part $_ ".$cw[$_]->clump(3)."\n";
	print LOG "w(b$i,y) part $_ ".$w[$_]->clump(3)."\n";
	print LOG "Sigma_ww_inv(b$i,y) part $_ ".$Sigma_ww_inv[$_]."\n";
      } 
    } 

    if (!$only_observations) {
      my $ch = defined($func_h) ? &$func_h($b) : undef;
      
      # building and solving normal equation system
      my $AtSwwA = mzeroes($nU,$nU);
      for (0..$#y) { $AtSwwA += msumover(~$A[$_] x $Sigma_ww_inv[$_] x $A[$_]) }
      my $M;
      if (defined $H) {
	$M = ~append(~append($AtSwwA,~$H              ),
		     ~append($H    ,mzeroes($nH,$nH)));
      }
      else {
	$M = $AtSwwA;
      }
      
      my $AtSwwcw  = mzeroes($nU);
      for (0..$#y) { $AtSwwcw += msumover(~$A[$_] x $Sigma_ww_inv[$_] x $cw[$_]) }
      
      my $s     = defined($ch) ? ~append( transpose(-$AtSwwcw),
					  transpose(-$ch)      )
                               : -$AtSwwcw  ;
      my $Minv  = $M->matinv;
      my $x     = $Minv x $s;
      
      # now compute the corrections to $\beta$.
      $delta_b = $x->slice("0:".($nU-1));
      $b	     = $b + $delta_b;
      push @b_iterations,$b;

      $Sigma_bb = $Minv->slice("0:".($nU-1).",0:".($nU-1));
    }
    else {
      $delta_b = vpdl([0]);
    }
    
    my @lambda = map { $Sigma_ww_inv[$_] x ($cw[$_]  + $A[$_] x $delta_b   ) } (0..$#y);
    my @e      = map { $Sigma_yy->[$_]   x  ~$B[$_]           x $lambda[$_]  } (0..$#y);

    if ( $OUTPUT>1 ) {
      print LOG "lambda($i) part $_ ".$lambda[$_]->clump(3)."\n" foreach (0..$#lambda);
    }

    @y = map { $y_observed[$_] - $e[$_] } (0..$#y);

    # do we have to correct the observations y ?
    if (defined($func_g) && defined($func_G)) {

      my @ytmp = map { $_->copy } @y;

      if ( $OUTPUT>1 ) {
	print LOG "-------> before correction of observations:\n";
	foreach (0..$#y) { 
	  print LOG "y($i) part $_ ".$y[$_]->clump(3)."\n";
	}
      }
      
      my $tmp = $OUTPUT;
      $OUTPUT=0;
      my $tmpresult= 
	GaussHelmertBlocks({
			    observations => [@ytmp],
			    observation_equations => $func_g,
			    Jacobian_observations => $func_G,
			    maximal_no_iterations => 5
			   });


      $OUTPUT=$tmp;
      my $y_est = $tmpresult->{estimated_observations};
      @y = @$y_est;

      if ( $OUTPUT>1 ) {
	print LOG "-------->after correction of observations:\n";
	foreach (0..$#y) { 
	  print LOG "y($i) part $_ ".$y[$_]->clump(3)."\n";
	}
      }

      if ( $OUTPUT>1 ) {
	print LOG "-------> division of before/after::\n";
	foreach (0..$#y) { 
	  print LOG "y($i) part $_ ".($y[$_]->clump(3)/$ytmp[$_]->clump(3))."\n";
	}
      }
    }

    # almost done ...
    my $Omega = 0;  
    $Omega += sum(~$e[$_] x ~$B[$_] x $lambda[$_]) foreach (0..$#y);

    $sigma_hat = (($nW + $nH - $nU) > 0) ? ($Omega / ($nW + $nH - $nU)) : 1;

    # compute criteria for a premature abortion of the iteration.
    # This is \delta(\beta)/sqrt(\sigma_\beta\beta) < 1e-2 means that the
    # corrections to the estimation is less than 1% w.r.t. to its
    # standard deviation.
    my ($abort_criterion,$abort_p);
    if (!$only_observations) {
      # only look at those entries where \sigma_\beta\beta is
      # significantly larger than 0
      my ($db_s,$sigma_bb_s) = where(abs($delta_b->clump(2)),
				     sqrt($Sigma_bb->diagonal(0,1)),
				     $Sigma_bb->diagonal(0,1) > 1e-16);
      if ( $OUTPUT>1) {
	print LOG "|db| (selected)",$db_s,"\n"; 
	print LOG "sqrt(sigma_bb^2) (selected)",$sigma_bb_s,"\n"; 
      }
      $abort_criterion = max($db_s/$sigma_bb_s);
      $abort_p = ($abort_criterion < $epsilon);
    }
    else {
      $abort_p = 0; # TODO: needs to be defined properly
    }



    # that's all computation for this iteration, but maybe we want to
    # output some of the results....
    if ( $OUTPUT) {
      my $Omega1 = 0;  
      foreach (0..$#y) { 
	$Omega1 += sum(~$e[$_] x ~$B[$_] x $Sigma_ww_inv[$_] x $B[$_] x $e[$_]);
      };
      
      # proof if Omega is equal to ...
      print LOG "Omega e^T B \\lambda : $Omega\n" if $OUTPUT > 1;
      print LOG "Omega1 e^T B^T \\Sigma B e : $Omega1\n" if $OUTPUT > 1;
      print "Omega = ($Omega | $Omega1 )\n";

      if ($sigma_hat<0) {
	print "*** Warning: sigma0^2 = $sigma_hat < 0, taking absolute value\n";
#	print "$Omega,$Omega1\n";
#	die;
	print LOG "*** Warning: sigma0^2 = $sigma_hat < 0, taking absolute value\n" if $OUTPUT > 1;
      }
      print LOG "sigma0 : ",sqrt(abs($sigma_hat)),"\n" if $OUTPUT > 1;
      print "sigma0 : ",sqrt(abs($sigma_hat)),"\n";

      
      my $test=0;
      foreach (0..$#y) { 
#	print "-->".$lambda[$_].$B[$_].$y[$_]."\n";
	$test += sum(~$lambda[$_] x $B[$_] x $y[$_]); 
      };
#      print LOG "e^T x Cyy^-1 x y^\\hat => $test\n";
#      print "e^T x Cyy^-1 x y^\\hat => $test\n";
      print LOG "\\lambda^T x B x y^\\hat => $test\n" if $OUTPUT > 1;
      print "\\lambda^T x B x y^\\hat => $test\n";


      @w = &$func_w([@y_observed],$b);	
      foreach (0..$#y) { 
	my $tmp = PDL::max(abs(($B[$_] x $e[$_]) - $w[$_]->clump(3))); 
	print LOG " max |B*e - w(b$i,y) | ($_)  : $tmp\n" if $OUTPUT > 1;
	print "max |B*e - w(b$i,y) | ($_)  : $tmp\n";
      };

      @w = &$func_w([@y],$b);	# new calculation of w for output purposes
      foreach (0..$#w) { 
	print LOG "w(b$i,y$i) part ($_) ".$w[$_]->clump(3)."\n" if $OUTPUT > 1;
	print LOG "max | w(b$i,y$i) | ($_) ".PDL::max(abs($w[$_]->clump(3)))."\n" if $OUTPUT > 1;
 	print "max | w(b$i,y$i) | ($_) ".PDL::max(abs($w[$_]->clump(3)))."\n";
	
      } 

      if (!$only_observations && defined($func_h)) {
	my $h = &$func_h($b);	# new calculation of h
	print LOG "h(b$i) ".$h->slice(",(0)")."\n" if $OUTPUT > 1;
 	print LOG "max | h(b$i) | ".PDL::max(abs($h->clump(2)))."\n" if $OUTPUT > 1;
 	print "max | h(b$i) |  ".PDL::max(abs($h->clump(2)))."\n";
      }

      if (!$only_observations) {
	print LOG "db($i) ".$delta_b->slice(",(0)")."\n" if $OUTPUT > 1;
	print LOG "b($i) ".$b->slice(",(0)")."\n" if $OUTPUT > 1;
	print LOG "b($i) (spherical)",($b->slice(",(0)")/sqrt(sum($b**2))),"\n" if $OUTPUT > 1;
	print "b($i) ".$b->slice(",(0)")."\n";
	print "b($i) (spherical)",($b->slice(",(0)")/sqrt(sum($b**2))),"\n";
      }

      foreach (0..$#e) { 
	print LOG "e($i) part $_ ".$e[$_]->clump(3)."\n" if $OUTPUT > 1;
      } 


      foreach (0..$#y) { 
	print LOG "y($i) part $_ ".$y[$_]->clump(3)."\n" if $OUTPUT > 1;
      }
      
      print LOG "max(db(i)/sigma_b(i)) $abort_criterion\n" if $OUTPUT > 1;
      print "max(db(i)/sigma_b(i)) $abort_criterion\n";

      print LOG "--------------------------------------------------\n" if $OUTPUT > 1;
      print "--------------------------------------------------\n";

    }
    
    # check if we can leave this estimation earlier
    last if ($abort_p); 
    $Omega_last_iteration=$Omega;
  }
  
  close LOG if ($OUTPUT>1);

  # restore global $OUTPUT
  $OUTPUT = $tmp;

  # return the unknown and its covariance matrix, the estimated
  # observations.  Furthermore return an array with the unknown vector
  # for each iteration step and the number of iterations
  return { "estimated_unknown" => $b,
	   "sigma0_squared" => $sigma_hat,
	   "covariance_unknown" => $Sigma_bb, # without sigma_0 !
	   "estimated_observations" => [@y],
	   "estimated_unknowns_iterations" => [@b_iterations],
	   "number_of_iterations" => $i,
	 };
}
push @EXPORT_OK,"GaussHelmertBlocks";

1;

# make a class which can deal with blocks. This inherits from
# GaussHelmert,
package Statistics::GaussHelmertBlocks;

use base qw/Statistics::GaussHelmert/;

sub new {
  my $self = Statistics::GaussHelmert::new(@_);
  $self->noblocks(0); # we want to have blocks!
  return $self;
}

1;


__END__

