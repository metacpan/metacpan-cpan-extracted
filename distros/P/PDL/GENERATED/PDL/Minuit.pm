#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Minuit;

our @EXPORT_OK = qw(mn_init mn_def_pars mn_excm mn_pout mn_stat mn_err mn_contour mn_emat mninit mn_abre mn_cierra mnparm mnexcm mnpout mnstat mnemat mnerrs mncont );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Minuit ;







#line 14 "minuit.pd"

=head1 NAME

PDL::Minuit -- a PDL interface to the Minuit library

=head1 DESCRIPTION

This package implements an interface to the Minuit minimization routines (part
of the CERN Library)

=head1 SYNOPSIS

A basic fit with Minuit will call three functions in this package. First, a basic
initialization is done with mn_init(). Then, the parameters are defined via
the function mn_def_pars(), which allows setting upper and lower bounds. Then
the function mn_excm() can be used to issue many Minuit commands, including simplex
and migrad minimization algorithms (see Minuit manual for more details).

See the test file minuit.t in the test (t/) directory for a basic example.

=cut
#line 48 "Minuit.pm"

=head1 FUNCTIONS

=cut





#line 37 "minuit.pd"

use strict;
use warnings;

# Package variable
my $mn_options;
sub mn_init{
  my $fun_ref = shift;

  $mn_options = { Log => undef,
		  Title => 'Minuit Fit',
		  N => undef,
                  Unit => undef,
                  Function => $fun_ref,
		};

  if ( @_ ){
    my $args = $_[0];
    for my $key (qw/ Log Title Unit/){
	$mn_options->{$key} = $args->{$key} if exists $args->{$key};
    }
  }
	
  # Check if there was a valid F77 available and barf
  # if there was not and the user is trying to pass Log

  if (defined($mn_options->{Log})) { 
    $mn_options->{Unit} = 88 unless defined $mn_options->{Unit};
  }
  else { $mn_options->{Unit} = 6; }
           
  if (defined (my $logfile = $mn_options->{Log})){ 
    if (-e $logfile) { unlink $logfile; }   
    PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'new');
  }

  PDL::Minuit::mninit(5,$mn_options->{Unit},$mn_options->{Unit});
  PDL::Minuit::mnseti($mn_options->{Title});

  if (defined (my $logfile = $mn_options->{Log})){
    PDL::Minuit::mn_cierra($mn_options->{Unit});
  }

}
#line 103 "Minuit.pm"

=head2 mninit

=for sig

  Signature: (longlong a();longlong b(); longlong c())

=for ref

info not available

=for bad

mninit does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mninit = \&PDL::Minuit::mninit;






=head2 mn_abre

=for sig

  Signature: (longlong l(); char* nombre; char* mode)

=for ref

info not available

=for bad

mn_abre does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mn_abre = \&PDL::Minuit::mn_abre;






=head2 mn_cierra

=for sig

  Signature: (longlong l())

=for ref

info not available

=for bad

mn_cierra does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mn_cierra = \&PDL::Minuit::mn_cierra;





#line 108 "minuit.pd"

sub mn_def_pars{
  my $pars  = shift;
  my $steps = shift;

  my $n = nelem($pars);
  $mn_options->{N} = $n;

  #print "Unit :".$mn_options->{Unit}."\n";

  my @names = map "Par_$_", 0..$n-1;
  my $lo_bounds = zeroes($n);
  my $up_bounds = zeroes($n);

  if ( @_ ) {
     my $opts = $_[0];
     $lo_bounds = $opts->{Lower_bounds} if defined $opts->{Lower_bounds};
     $up_bounds = $opts->{Upper_bounds} if defined $opts->{Upper_bounds};
     if (defined($opts->{Names})){
	my $names_t = $opts->{Names};
	barf "Names has to be an array reference" unless ref($names_t) eq 'ARRAY';
	@names = @$names_t;
	barf "Names has to have as many elements as there are parameters " unless ( @names == $n);
     }
  }

  my $iflag = 0;

  if (defined (my $logfile = $mn_options->{Log})){
    PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
  }

  foreach my $i ( 0..(nelem($pars)-1) ){
     my $ii = $i + 1;
     $iflag = PDL::Minuit::mnparm($ii,$pars->slice("($i)"),
		       $steps->slice("($i)"),
		       $lo_bounds->slice("($i)"),
		       $up_bounds->slice("($i)"),
		       $names[$i]);
     barf "Problem initializing parameter $i in Minuit, got $iflag" unless ($iflag == 0);
  }
  
  if (defined (my $logfile = $mn_options->{Log})){
     PDL::Minuit::mn_cierra($mn_options->{Unit});
  }
}
#line 232 "Minuit.pm"

=head2 mnparm

=for sig

  Signature: (longlong a(); double b(); double c(); double d(); double e(); longlong [o] ia(); char* str)

=for ref

info not available

=for bad

mnparm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnparm = \&PDL::Minuit::mnparm;





#line 164 "minuit.pd"

sub mn_excm{
  my $command = shift;
  
  my $fun_ref = $mn_options->{Function};

  my ($arglis,$narg);
  if ( @_ ) { $arglis = shift; $narg = nelem($arglis);}
  else { $arglis = pdl(0); $narg = 0; }
   
  if ( @_ ) { barf "Usage : mn_excm($command, [$arglis]) \n"; }

  if (defined (my $logfile = $mn_options->{Log})){
    PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
  }

  my $iflag = pdl(0);

  $iflag = PDL::Minuit::mnexcm($arglis, $narg, $command, $fun_ref,$mn_options->{N});
  warn "Problem executing command '$command' " unless ($iflag == 0);

  if (defined (my $logfile = $mn_options->{Log})){
    PDL::Minuit::mn_cierra($mn_options->{Unit});
  }

  return $iflag;
}
#line 288 "Minuit.pm"

=head2 mnexcm

=for sig

  Signature: (double a(n); longlong ia(); longlong [o] ib(); char* str; SV* function; IV numelem)

=for ref

info not available

=for bad

mnexcm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnexcm = \&PDL::Minuit::mnexcm;





#line 205 "minuit.pd"

  sub mn_pout{
    barf "Usage: mn_pout(par_number)" unless ($#_ == 0);
    my $par_num = shift;
    my $n = $mn_options->{N};
    if (($par_num < 1) || ($par_num > $n)) { barf "Parameter numbers range from 1 to $n "; }

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
    }

    my $val = pdl(0);
    my $err = pdl(0);
    my $bnd1 = pdl(0);
    my $bnd2 = pdl(0);
    my $ivarbl = pdl(0);
    my $par_name = "          ";
    PDL::Minuit::mnpout($par_num,$val,$err,$bnd1,$bnd2,$ivarbl,\$par_name);

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_cierra($mn_options->{Unit});
    }

    return ($val,$err,$bnd1,$bnd2,$ivarbl,$par_name);    
  }
#line 342 "Minuit.pm"

=head2 mnpout

=for sig

  Signature: (longlong ia(); double [o] a(); double [o] b(); double [o] c(); double [o] d();longlong [o] ib(); SV* str)

=for ref

info not available

=for bad

mnpout does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnpout = \&PDL::Minuit::mnpout;





#line 242 "minuit.pd"

  sub mn_stat{
     if (defined (my $logfile = $mn_options->{Log})){
       PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
     }

     my ($fmin,$fedm,$errdef,$npari,$nparx,$istat) = PDL::Minuit::mnstat();

     if (defined (my $logfile = $mn_options->{Log})){
       PDL::Minuit::mn_cierra($mn_options->{Unit});
     }

     return ($fmin,$fedm,$errdef,$npari,$nparx,$istat);
  }
#line 385 "Minuit.pm"

=head2 mnstat

=for sig

  Signature: (double [o] a(); double [o] b(); double [o] c(); longlong [o] ia(); longlong [o] ib(); longlong [o] ic())

=for ref

info not available

=for bad

mnstat does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnstat = \&PDL::Minuit::mnstat;





#line 264 "minuit.pd"

  sub mn_emat{
   
    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
    }

    my ($fmin,$fedm,$errdef,$npari,$nparx,$istat) = PDL::Minuit::mnstat();
    my $n = $npari->sum->at;
    my $mat = zeroes($n,$n);

    PDL::Minuit::mnemat($mat);

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_cierra($mn_options->{Unit});
    }
    
    return $mat;

  }
#line 434 "Minuit.pm"

=head2 mnemat

=for sig

  Signature: (double [o] mat(n,n))

=for ref

info not available

=for bad

mnemat does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnemat = \&PDL::Minuit::mnemat;





#line 292 "minuit.pd"

  sub mn_err{

    barf "Usage: mn_err(par_number)" unless ($#_ == 0);
    my $par_num = shift;

    my $n = $mn_options->{N};
    if (($par_num < 1) || ($par_num > $n)) { barf "Parameter numbers range from 1 to $n "; }

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_abre($mn_options->{Unit},$logfile,'old');
    }

    my ($eplus,$eminus,$eparab,$globcc) = PDL::Minuit::mnerrs($par_num);

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_cierra($mn_options->{Unit});
    }

    return ($eplus,$eminus,$eparab,$globcc);
  }
#line 484 "Minuit.pm"

=head2 mnerrs

=for sig

  Signature: (longlong ia(); double [o] a(); double [o] b(); double [o] c(); double [o] d())

=for ref

info not available

=for bad

mnerrs does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mnerrs = \&PDL::Minuit::mnerrs;





#line 320 "minuit.pd"

  sub mn_contour{
    barf "Usage: mn_contour(par_number_1,par_number_2,npt)" unless ($#_ == 2);
    my $par_num_1 = shift;
    my $par_num_2 = shift;
    my $npt = shift;

    my $fun_ref = $mn_options->{Function};

    my $n = $mn_options->{N};
    if (($par_num_1 < 1) || ($par_num_1 > $n)) { barf "Parameter numbers range from 1 to $n "; }
    if (($par_num_2 < 1) || ($par_num_2 > $n)) { barf "Parameter numbers range from 1 to $n "; }
    if ($npt < 5) { barf "Have to specify at least 5 points in routine contour "; }

    my $xpt = zeroes($npt);
    my $ypt = zeroes($npt);
    my $nfound = pdl->new;

    PDL::Minuit::mncont($par_num_1,$par_num_2,$npt,$xpt,$ypt,$nfound,$fun_ref,$n);

    if (defined (my $logfile = $mn_options->{Log})){
      PDL::Minuit::mn_cierra($mn_options->{Unit});
    }

    return ($xpt,$ypt,$nfound);
  }
#line 539 "Minuit.pm"

=head2 mncont

=for sig

  Signature: (longlong ia(); longlong ib(); longlong ic(); double [o] a(n); double [o] b(n); longlong [o] id(); SV* function; IV numelem)

=for ref

info not available

=for bad

mncont does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*mncont = \&PDL::Minuit::mncont;





#line 358 "minuit.pd"

=head2 mn_init()

=for ref

The function mn_init() does the basic initialization of the fit. The first argument
has to be a reference to the function to be minimized. The function
to be minimized has to receive five arguments
($npar,$grad,$fval,$xval,$iflag). The first is the number
of parameters currently variable. The second is the gradient
of the function (which is not necessarily used, see 
the Minuit documentation). The third is the current value of the
function. The fourth is an ndarray with the values of the parameters. 
The fifth is an integer flag, which indicates what
the function is supposed to calculate. The function has to
return the  values ($fval,$grad), the function value and 
the function gradient. 

There are three optional arguments to mn_init(). By default, the output of Minuit
will come through STDOUT unless a filename $logfile is given
in the Log option. Note that this will mercilessly erase $logfile
if it already exists. Additionally, a title can be given to the fit
by the Title option, the default is 'Minuit Fit'. If the output is
written to a logfile, this is assigned Fortran unit number 88. If for
whatever reason you want to have control over the unit number
that Fortran associates to the logfile, you can pass the number 
through the Unit option.

=for usage

Usage:

 mn_init($function_ref,{Log=>$logfile,Title=>$title,Unit=>$unit})

=for example

Example:

 mn_init(\&my_function);

 #same as above but outputting to a file 'log.out'.
 #title for fit is 'My fit'
 mn_init(\&my_function,
	 {Log => 'log.out', Title => 'My fit'});

 sub my_function{
    # the five variables input to the function to be minimized
    # xval is an ndarray containing the current values of the parameters
    my ($npar,$grad,$fval,$xval,$iflag) = @_;

    # Here is code computing the value of the function
    # and potentially also its gradient
    # ......

    # return the two variables. If no gradient is being computed
    # just return the $grad that came as input
    return ($fval, $grad);
 }

=head2 mn_def_pars()

=for ref

The function mn_def_pars() defines the initial values of the parameters of the function to 
be minimized and the value of the initial steps around these values that the 
minimizer will use for the first variations of the parameters in the search for the minimum.
There are several optional arguments. One allows assigning names to these parameters which 
otherwise get names (Par_0, Par_1,....,Par_n) by default. Another two arguments can give
lower and upper bounds for the parameters via two ndarrays. If the lower and upper bound for a 
given parameter are both equal to 0 then the parameter is unbound. By default these lower and
upper bound ndarrays are set to  zeroes(n), where n is the number of parameters, i.e. the 
parameters are unbound by default. 

The function needs two input variables: an ndarray giving the initial values of the
parameters and another ndarray giving the initial steps. An optional reference to a 
perl array with the  variable names can be passed, as well as ndarrays
with upper and lower bounds for the parameters (see example below).

It returns an integer variable which is 0 upon success.

=for usage

Usage:

 $iflag = mn_def_pars($pars, $steps,{Names => \@names, 
			Lower_bounds => $lbounds,
			Upper_bounds => $ubounds})

=for example

Example:

 #initial parameter values
 my $pars = pdl(2.5,3.0);          

 #steps
 my $steps = pdl(0.3,0.5);     

 #parameter names    
 my @names = ('intercept','slope');

 #use mn_def_pars with default parameter names (Par_0,Par_1,...)
 my $iflag = mn_def_pars($pars,$steps);

 #use of mn_def_pars explicitly specify parameter names
 $iflag = mn_def_pars($pars,$steps,{Names => \@names});

 # specify lower and upper bounds for the parameters. 
 # The example below leaves parameter 1 (intercept) unconstrained
 # and constrains parameter 2 (slope) to be between 0 and 100
 my $lbounds = pdl(0, 0);
 my $ubounds = pdl(0, 100);

 $iflag = mn_def_pars($pars,$steps,{Names => \@names, 
			Lower_bounds => $lbounds,
			Upper_bounds => $ubounds}});

 #same as above because $lbounds is by default zeroes(n)
 $iflag = mn_def_pars($pars,$steps,{Names => \@names, 
			Upper_bounds => $ubounds}});

=head2 mn_excm()

The function mn_excm() executes a Minuit command passed as
a string. The first argument is the command string and an optional
second argument is an ndarray with arguments to the command.
The available commands are listed in Chapter 4 of the Minuit 
manual (see url below).

It returns an integer variable which is 0 upon success.

=for usage

Usage:

 $iflag = mn_excm($command_string, {$arglis})

=for example

Example:

  #start a simplex minimization
  my $iflag = mn_excm('simplex');

  #same as above but specify the maximum allowed numbers of
  #function calls in the minimization 
  my $arglist = pdl(1000);
  $iflag = mn_excm('simplex',$arglist);

  #start a migrad minimization
  $iflag = mn_excm('migrad')

  #set Minuit strategy in order to get the most reliable results
  $arglist = pdl(2)
  $iflag = mn_excm('set strategy',$arglist);

  # each command can be specified by a minimal string that uniquely
  # identifies it (see Chapter 4 of Minuit manual). The comannd above
  # is equivalent to:
  $iflag = mn_excm('set stra',$arglis);

=head2 mn_pout()

The function mn_pout() gets the current value of a parameter. It 
takes as input the parameter number and returns an array with the
parameter value, the current estimate of its uncertainty (0 if
parameter is constant), lower bound on the parameter, if any 
(otherwise 0), upper bound on the parameter, if any (otherwise 0),
integer flag (which is equal to the parameter number if variable,
zero if the parameter is constant and negative if parameter is
not defined) and the parameter name.

=for usage

Usage:

     ($val,$err,$bnd1,$bnd2,$ivarbl,$par_name) = mn_pout($par_number);

=head2 mn_stat()

The function mn_stat() gets the current status of the minimization.
It returns an array with the best function value found so far,
the estimated vertical distance remaining to minimum, the value
of UP defining parameter uncertainties (default is 1), the number
of currently variable parameters, the highest parameter defined
and an integer flag indicating how good the covariance matrix is
(0=not calculated at all; 1=diagonal approximation, not accurate;
2=full matrix, but forced positive definite; 3=full accurate matrix)

=for usage

Usage:

    ($fmin,$fedm,$errdef,$npari,$nparx,$istat) = mn_stat();

=head2 mn_emat()

The function mn_emat returns the covariance matrix as an ndarray.

=for usage

Usage:

  $emat = mn_emat();

=head2 mn_err()

The function mn_err() returns the current existing values for 
the error in the fitted parameters. It returns an array
with the positive error, the negative error, the "parabolic" 
parameter error from the error matrix and the global correlation
coefficient, which is a number between 0 and 1 which gives
the correlation between the requested parameter and that linear
combination of all other parameters which is most strongly 
correlated with it. Unless the command 'MINOS' has been issued via
the function mn_excm(), the first three values will be equal.

=for usage

Usage:

  ($eplus,$eminus,$eparab,$globcc) = mn_err($par_number);

=head2 mn_contour()

The function mn_contour() finds contours of the function being minimized
with respect to two chosen parameters. The contour level is given by 
F_min + UP, where F_min is the minimum of the function and UP is the ERRordef
specified by the user, or 1.0 by default (see Minuit manual). The contour
calculated by this function is dynamic, in the sense that it represents the
minimum of the function being minimized with respect to all the other NPAR-2 parameters
(if any).

The function takes as input the parameter numbers with respect to which the contour
is to be determined (two) and the number of points $npt required on the contour (>4).
It returns an array with ndarrays $xpt,$ypt containing the coordinates of the contour 
and a variable $nfound indicating the number of points actually found in the contour.
If all goes well $nfound will be equal to $npt, but it can be negative if the input
arguments are not valid, zero if less than four points have been found or <$npt if the
program could not find $npt points.

=for usage

Usage: 

  ($xpt,$ypt,$nfound) = mn_contour($par_number_1,$par_number_2,$npt)

=head1 SEE ALSO

L<PDL>

The Minuit documentation is online at

  http://wwwasdoc.web.cern.ch/wwwasdoc/minuit/minmain.html

=head1 AUTHOR

This file copyright (C) 2007 Andres Jordan <ajordan@eso.org>.
All rights reserved. There is no warranty. You are allowed to redistribute this 
software/documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

=cut
#line 832 "Minuit.pm"

# Exit with OK status

1;
