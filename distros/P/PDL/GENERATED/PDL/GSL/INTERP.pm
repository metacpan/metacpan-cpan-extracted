#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::INTERP;

our @EXPORT_OK = qw( );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::INTERP ;







#line 6 "gsl_interp.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSL::INTERP - PDL interface to Interpolation routines in GSL

=head1 DESCRIPTION

This is an interface to the interpolation package present in the
GNU Scientific Library.

=head1 SYNOPSIS

   use PDL;
   use PDL::GSL::INTERP;

   my $x = sequence(10);
   my $y = exp($x);

   my $spl = PDL::GSL::INTERP->init('cspline',$x,$y);

   my $res = $spl->eval(4.35);
   $res = $spl->deriv(4.35);
   $res = $spl->deriv2(4.35);
   $res = $spl->integ(2.1,7.4);

=head1 NOMENCLATURE

Throughout this documentation we strive to use the same variables that
are present in the original GSL documentation (see L<See
Also|"SEE-ALSO">). Oftentimes those variables are called C<a> and
C<b>. Since good Perl coding practices discourage the use of Perl
variables C<$a> and C<$b>, here we refer to Parameters C<a> and C<b>
as C<$pa> and C<$pb>, respectively, and Limits (of domain or
integration) as C<$la> and C<$lb>.
#line 64 "INTERP.pm"


=head1 FUNCTIONS

=cut






=head2 init

=for sig

  Signature: (double x(n); double y(n); gsl_spline *spl)

=for ref

The init method initializes a new instance of INTERP. It needs as
input an interpolation type and two ndarrays holding the x and y
values to be interpolated. The GSL routines require that x be
monotonically increasing and a quicksort is performed by default to
ensure that. You can skip the quicksort by passing the option
{Sort => 0}.

The available interpolation types are :

=over 2

=item linear

=item polynomial

=item cspline (natural cubic spline)

=item cspline_periodic  (periodic cubic spline)

=item akima (natural akima spline)

=item akima_periodic  (periodic akima spline)

=back

Please check the GSL documentation for more information.

=for usage

Usage:

    $blessed_ref = PDL::GSL::INTERP->init($interp_method,$x,$y,$opt);

=for example

Example:

    $x = sequence(10);
    $y = exp($x);

    $spl = PDL::GSL::INTERP->init('cspline',$x,$y)
    $spl = PDL::GSL::INTERP->init('cspline',$x,$y,{Sort => 1}) #same as above

    # no sorting done on x, user is certain that x is monotonically increasing
    $spl = PDL::GSL::INTERP->init('cspline',$x,$y,{Sort => 0});

=for bad

init does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub init {
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Sort => 1}; }
  my ($class,$type,$x,$y) = @_;
  if( (ref($x) ne 'PDL') || (ref($y) ne 'PDL') ){
    barf("Have to pass ndarrays as arguments to init method\n");
  }
  if($$opt{Sort} != 0){
    my $idx = PDL::Ufunc::qsorti($x);
    $x = $x->index($idx);
    $y = $y->index($idx);
  }
  my $ene = nelem($x);
  my $obj1 = new_spline($type,$ene);
  my $obj2 = new_accel();
  _init_int($x,$y,$$obj1);
  my @ret_a = ($obj1,$obj2);
  return bless(\@ret_a, $class);
}



*init = \&PDL::GSL::INTERP::init;






=head2 eval

=for sig

  Signature: (double x(); double [o] out(); gsl_spline *spl;gsl_interp_accel *acc)

=for ref

The function eval returns the interpolating function at a given point.
It will barf with an "input domain error" if you try to extrapolate.

=for usage

Usage:

    $result = $spl->eval($points);

=for example

Example:

    my $res = $spl->eval($x)

=for bad

eval processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub eval {
  my $opt;
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  _eval_int($x,my $o=PDL->null,$$s_obj,$$a_obj);
  $o;
}



*eval = \&PDL::GSL::INTERP::eval;






=head2 deriv

=for sig

  Signature: (double x(); double [o] out(); gsl_spline *spl;gsl_interp_accel *acc)

=for ref

The deriv function returns the derivative of the
interpolating function at a given point.
It will barf with an "input domain error" if you try to extrapolate.

=for usage

Usage:

    $result = $spl->deriv($points);

=for example

Example:

    my $res = $spl->deriv($x)

=for bad

deriv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub deriv {
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  _deriv_int($x,my $o=PDL->null,$$s_obj,$$a_obj);
  $o;
}



*deriv = \&PDL::GSL::INTERP::deriv;






=head2 deriv2

=for sig

  Signature: (double x(); double [o] out(); gsl_spline *spl;gsl_interp_accel *acc)

=for ref

The deriv2 function returns the second derivative
of the interpolating function at a given point.
It will barf with an "input domain error" if you try to extrapolate.

=for usage

Usage:

    $result = $spl->deriv2($points);

=for example

Example:

    my $res = $spl->deriv2($x)

=for bad

deriv2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub deriv2 {
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  _deriv2_int($x,my $o=PDL->null,$$s_obj,$$a_obj);
  $o;
}



*deriv2 = \&PDL::GSL::INTERP::deriv2;






=head2 integ

=for sig

  Signature: (double a(); double b(); double [o] out(); gsl_spline *spl;gsl_interp_accel *acc)

=for ref

The integ function returns the integral
of the interpolating function between two points.
It will barf with an "input domain error" if you try to extrapolate.

=for usage

Usage:

    $result = $spl->integ($la,$lb);

=for example

Example:

    my $res = $spl->integ($la,$lb)

=for bad

integ does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




sub integ {
  my ($obj,$la,$lb) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  _integ_int($la,$lb,my $o=PDL->null,$$s_obj,$$a_obj);
  $o;
}



*integ = \&PDL::GSL::INTERP::integ;







#line 45 "gsl_interp.pd"

=head1 BUGS

Feedback is welcome.

=head1 SEE ALSO

L<PDL>

The GSL documentation for interpolation is online at
L<https://www.gnu.org/software/gsl/doc/html/interp.html>

=head1 AUTHOR

This file copyright (C) 2003 Andres Jordan <andresj@physics.rutgers.edu>
All rights reserved. There is no warranty. You are allowed to redistribute this
software/documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL interpolation module was written by Gerard Jungman.

=cut
#line 399 "INTERP.pm"

# Exit with OK status

1;
