
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSL::MROOT;

@EXPORT_OK  = qw(  gslmroot_fsolver PDLA::PP fsolver_meat );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSL::MROOT ;






=head1 NAME
                                                                    
PDLA::GSL::MROOT - PDLA interface to multidimensional root-finding routines in GSL
                                                                                
=head1 DESCRIPTION
       
This is an interface to the multidimensional root-finding package present in the 
GNU Scientific Library.

At the moment there is a single function B<gslmroot_fsolver> which provides an interface
to the algorithms in the GSL library that do not use derivatives.  


=head1 SYNOPSIS                                      
            
   use PDLA;
   use PDLA::GSL::MROOT;

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






=head1 FUNCTIONS



=cut





sub gslmroot_fsolver{	
 	my ($x, $f_vect) = @_;	
        my $opt;	
	if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }	
	else{ $opt = {Method => 0, EpsAbs => 1e-3}; }
        if( (ref($x) ne 'PDLA')){
           barf("Have to pass piddle as first argument to fsolver\n");
         }
	my $res = $x->copy;
	fsolver_meat($res, $$opt{'EpsAbs'}, $$opt{'Method'}, $f_vect);
        return $res;
}




=head2 fsolver_meat

=for sig

  Signature: (double  xfree(n);   double epsabs(); int method(); SV* function1)


=for ref

info not available


=for bad

fsolver_meat does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*fsolver_meat = \&PDLA::GSLMROOT::fsolver_meat;



;

=head2 gslmroot_fsolver

Multidimensional root finder without using derivatives

This function provides an interface to the multidimensional root finding algorithms
in the GSL library. It takes a minimum of two argumennts: a piddle $init with an 
initial guess for the roots of the system and a reference to a function. The latter
function must return a piddle whose i-th element is the i-th equation evaluated at
the vector x (a piddle which is the sole input to this function). See the example in
the Synopsis above for an illustration. The function returns a piddle with the roots
for the system of equations.

Two optional arguments can be specified as shown below. One is B<Method>, which can
take the values 0,1,2,3. They correspond to the 'hybrids', 'hybrid', 'dnewton' and
'broyden' algorithms respectively (see GSL documentation for details). The other
optional argument is B<Epsabs>, which sets the absolute accuracy to which the roots
of the system of equations are required. The default value for Method is 0 ('hybrids'
algorithm) and the default for Epsabs is 1e-3.

=for usage

Usage:
   
   $res = gslmroot_fsolver($init, $function_ref,
                           [{Method => $method, Epsabs => $epsabs}]);

=for ref

=head1 SEE ALSO

L<PDLA>

The GSL documentation is online at

  http://www.gnu.org/software/gsl/manual/


=head1 AUTHOR

This file copyright (C) 2006 Andres Jordan <ajordan@eso.org> 
and Simon Casassus <simon@das.uchile.cl>
All rights reserved. There is no warranty. You are allowed to redistribute this 
software/documentation under certain conditions. For details, see the file
COPYING in the PDLA distribution. If this file is separated from the
PDLA distribution, the copyright notice should be included in the file.

=cut





# Exit with OK status

1;

		   