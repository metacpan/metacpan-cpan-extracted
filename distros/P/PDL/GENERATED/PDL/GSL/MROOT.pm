#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::MROOT;

our @EXPORT_OK = qw(gslmroot_fsolver gslmroot_fsolver );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::MROOT ;







#line 68 "gsl_mroot.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::MROOT - PDL interface to multidimensional root-finding routines in GSL

=head1 DESCRIPTION

This is an interface to the multidimensional root-finding package present in the
GNU Scientific Library.

At the moment there is a single function B<gslmroot_fsolver> which provides an interface
to the algorithms in the GSL library that do not use derivatives.

=head1 SYNOPSIS

   use PDL;
   use PDL::GSL::MROOT;

   my $init = pdl (-10.00, -5.0);
   my $epsabs = 1e-7;

  $res = gslmroot_fsolver($init, \&rosenbrock,
                          {Method => 0, EpsAbs => $epsabs});

  sub rosenbrock{
     my ($x) = @_;
     my $c = 1;
     my $d = 10;
     my $y = zeroes($x);

     my $y0 = $y->slice(0);
     $y0 .=  $c * (1 - $x->slice(0));

     my $y1 = $y->slice(1);
     $y1 .=  $d * ($x->slice(1) - $x->slice(0)**2);

     return $y;
  }
#line 68 "MROOT.pm"


=head1 FUNCTIONS

=cut






=head2 gslmroot_fsolver

=for sig

  Signature: (double [io]xfree(n);   double epsabs(); int method(); SV* function1)

=for ref

Multidimensional root finder without using derivatives

This function provides an interface to the multidimensional root finding algorithms
in the GSL library. It takes a minimum of two arguments: an ndarray $init with an
initial guess for the roots of the system and a reference to a function. The latter
function must return an ndarray whose i-th element is the i-th equation evaluated at
the vector x (an ndarray which is the sole input to this function). See the example in
the Synopsis above for an illustration. The function returns an ndarray with the roots
for the system of equations.

Two optional arguments can be specified as shown below. One is B<Method>, which can
take the values 0,1,2,3. They correspond to the 'hybrids', 'hybrid', 'dnewton' and
'broyden' algorithms respectively (see GSL documentation for details). The other
optional argument is B<Epsabs>, which sets the absolute accuracy to which the roots
of the system of equations are required. The default value for Method is 0 ('hybrids'
algorithm) and the default for Epsabs is 1e-3.

=for usage

   $res = gslmroot_fsolver($init, $function_ref,
                           [{Method => $method, Epsabs => $epsabs}]);

=for bad

gslmroot_fsolver does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub gslmroot_fsolver {
	my ($x, $f_vect) = @_;
        my $opt = ref($_[-1]) eq 'HASH' ? pop @_ : {Method => 0, EpsAbs => 1e-3};
        if( (ref($x) ne 'PDL')){
           barf("Have to pass ndarray as first argument to fsolver\n");
        }
	my $res = $x->copy;
	_gslmroot_fsolver_int($res, $$opt{'EpsAbs'}, $$opt{'Method'}, $f_vect);
	return $res;
}



*gslmroot_fsolver = \&PDL::GSL::MROOT::gslmroot_fsolver;







#line 114 "gsl_mroot.pd"

=head1 SEE ALSO

L<PDL>

The GSL documentation is online at

  http://www.gnu.org/software/gsl/manual/

=head1 AUTHOR

This file copyright (C) 2006 Andres Jordan <ajordan@eso.org>
and Simon Casassus <simon@das.uchile.cl>
All rights reserved. There is no warranty. You are allowed to redistribute this
software/documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

=cut
#line 161 "MROOT.pm"

# Exit with OK status

1;
