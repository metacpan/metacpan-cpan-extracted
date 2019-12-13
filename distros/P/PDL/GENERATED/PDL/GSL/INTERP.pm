
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSL::INTERP;

@EXPORT_OK  = qw(  );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSL::INTERP ;




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


=head1 FUNCTIONS

=head2 init()

=for ref

The init method initializes a new instance of INTERP. It needs as
input an interpolation type and two piddles holding the x and y
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

=head2 eval()

=for ref

The function eval returns the interpolating function at a given point. By default
it will barf if you try to extrapolate, to comply silently if the point to be
evaluated is out of range pass the option {Extrapolate => 1}

=for usage

Usage:

    $result = $spl->eval($points,$opt);

=for example

Example:

    my $res = $spl->eval($x)
    $res = $spl->eval($x,{Extrapolate => 0}) #same as above

    # silently comply if $x is out of range
    $res = $spl->eval($x,{Extrapolate => 1})

=head2 deriv()

=for ref

The deriv function returns the derivative of the
interpolating function at a given point. By default
it will barf if you try to extrapolate, to comply silently if the point to be
evaluated is out of range pass the option {Extrapolate => 1}

=for usage

Usage:

    $result = $spl->deriv($points,$opt);

=for example

Example:

    my $res = $spl->deriv($x)
    $res = $spl->deriv($x,{Extrapolate => 0}) #same as above

    # silently comply if $x is out of range
    $res = $spl->deriv($x,{Extrapolate => 1})


=head2 deriv2()

=for ref

The deriv2 function returns the second derivative
of the interpolating function at a given point. By default
it will barf if you try to extrapolate, to comply silently if the point to be
evaluated is out of range pass the option {Extrapolate => 1}


=for usage

Usage:

    $result = $spl->deriv2($points,$opt);

=for example

Example:

    my $res = $spl->deriv2($x)
    $res = $spl->deriv2($x,{Extrapolate => 0}) #same as above

    # silently comply if $x is out of range
    $res = $spl->deriv2($x,{Extrapolate => 1})

=head2 integ()

=for ref

The integ function returns the integral
of the interpolating function between two points.
By default it will barf if you try to extrapolate,
to comply silently if one of the integration limits
is out of range pass the option {Extrapolate => 1}


=for usage

Usage:

    $result = $spl->integ($la,$lb,$opt);

=for example

Example:

    my $res = $spl->integ($la,$lb)
    $res = $spl->integ($x,$y,{Extrapolate => 0}) #same as above

    # silently comply if $la or $lb are out of range
    $res = $spl->eval($la,$lb,{Extrapolate => 1})

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









sub init{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Sort => 1}; }
  my ($class,$type,$x,$y) = @_;
  if( (ref($x) ne 'PDL') || (ref($y) ne 'PDL') ){
    barf("Have to pass piddles as arguments to init method\n");
  }
  if($$opt{Sort} != 0){
    my $idx = PDL::Ufunc::qsorti($x);
    $x = $x->index($idx);
    $y = $y->index($idx);
  }
  my $ene = nelem($x);
  my $obj1 = new_spline($type,$ene);
  my $obj2 = new_accel();
  init_meat($x,$y,$$obj1);
  my @ret_a = ($obj1,$obj2);
  return bless(\@ret_a, $class);
}




*init_meat = \&PDL::GSL::INTERP::init_meat;




sub eval{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Extrapolate => 0}; }
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  if($$opt{Extrapolate} == 0){
    return eval_meat($x,$$s_obj,$$a_obj);
  }
  else{
    return eval_meat_ext($x,$$s_obj,$$a_obj);
  }
}




*eval_meat = \&PDL::GSL::INTERP::eval_meat;





*eval_meat_ext = \&PDL::GSL::INTERP::eval_meat_ext;




sub deriv{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Extrapolate => 0}; }
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  if($$opt{Extrapolate} == 0){
    return  eval_deriv_meat($x,$$s_obj,$$a_obj);
  }
  else{
    return  eval_deriv_meat_ext($x,$$s_obj,$$a_obj);
  }
}




*eval_deriv_meat = \&PDL::GSL::INTERP::eval_deriv_meat;





*eval_deriv_meat_ext = \&PDL::GSL::INTERP::eval_deriv_meat_ext;




sub deriv2{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Extrapolate => 0}; }
  my ($obj,$x) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  if($$opt{Extrapolate} == 0){
    return  eval_deriv2_meat($x,$$s_obj,$$a_obj);
  }
  else{
    return  eval_deriv2_meat_ext($x,$$s_obj,$$a_obj);
  }
}




*eval_deriv2_meat = \&PDL::GSL::INTERP::eval_deriv2_meat;





*eval_deriv2_meat_ext = \&PDL::GSL::INTERP::eval_deriv2_meat_ext;




sub integ{
  my $opt;
  if (ref($_[$#_]) eq 'HASH'){ $opt = pop @_; }
  else{ $opt = {Extrapolate => 0}; }
  my ($obj,$la,$lb) = @_;
  my $s_obj = $$obj[0];
  my $a_obj = $$obj[1];
  if($$opt{Extrapolate} == 0){
    return eval_integ_meat($la,$lb,$$s_obj,$$a_obj);
  }
  else{
    return eval_integ_meat_ext($la,$lb,$$s_obj,$$a_obj);
  }
}




*eval_integ_meat = \&PDL::GSL::INTERP::eval_integ_meat;





*eval_integ_meat_ext = \&PDL::GSL::INTERP::eval_integ_meat_ext;



;



# Exit with OK status

1;

		   