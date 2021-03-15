
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::BESSEL;

@EXPORT_OK  = qw( PDL::PP gsl_sf_bessel_Jn PDL::PP gsl_sf_bessel_J_array PDL::PP gsl_sf_bessel_Yn PDL::PP gsl_sf_bessel_Y_array PDL::PP gsl_sf_bessel_In PDL::PP gsl_sf_bessel_I_array PDL::PP gsl_sf_bessel_In_scaled PDL::PP gsl_sf_bessel_I_scaled_array PDL::PP gsl_sf_bessel_Kn PDL::PP gsl_sf_bessel_K_array PDL::PP gsl_sf_bessel_Kn_scaled PDL::PP gsl_sf_bessel_K_scaled_array PDL::PP gsl_sf_bessel_jl PDL::PP gsl_sf_bessel_j_array PDL::PP gsl_sf_bessel_yl PDL::PP gsl_sf_bessel_y_array PDL::PP gsl_sf_bessel_il_scaled PDL::PP gsl_sf_bessel_i_scaled_array PDL::PP gsl_sf_bessel_kl_scaled PDL::PP gsl_sf_bessel_k_scaled_array PDL::PP gsl_sf_bessel_Jnu PDL::PP gsl_sf_bessel_Ynu PDL::PP gsl_sf_bessel_Inu_scaled PDL::PP gsl_sf_bessel_Inu PDL::PP gsl_sf_bessel_Knu_scaled PDL::PP gsl_sf_bessel_Knu PDL::PP gsl_sf_bessel_lnKnu );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::BESSEL ;




=head1 NAME

PDL::GSLSF::BESSEL - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_bessel_Jn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Bessel Function J_n(x).

=for bad

gsl_sf_bessel_Jn does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Jn = \&PDL::gsl_sf_bessel_Jn;





=head2 gsl_sf_bessel_J_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of Regular Bessel Functions J_{s}(x) to J_{s+n-1}(x).

=for bad

gsl_sf_bessel_J_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_J_array = \&PDL::gsl_sf_bessel_J_array;





=head2 gsl_sf_bessel_Yn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Bessel Function Y_n(x).

=for bad

gsl_sf_bessel_Yn does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Yn = \&PDL::gsl_sf_bessel_Yn;





=head2 gsl_sf_bessel_Y_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of Regular Bessel Functions Y_{s}(x) to Y_{s+n-1}(x).

=for bad

gsl_sf_bessel_Y_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Y_array = \&PDL::gsl_sf_bessel_Y_array;





=head2 gsl_sf_bessel_In

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Modified Bessel Function I_n(x).

=for bad

gsl_sf_bessel_In does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_In = \&PDL::gsl_sf_bessel_In;





=head2 gsl_sf_bessel_I_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of Regular Modified Bessel Functions I_{s}(x) to I_{s+n-1}(x).

=for bad

gsl_sf_bessel_I_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_I_array = \&PDL::gsl_sf_bessel_I_array;





=head2 gsl_sf_bessel_In_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled Regular Modified Bessel Function exp(-|x|) I_n(x).

=for bad

gsl_sf_bessel_In_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_In_scaled = \&PDL::gsl_sf_bessel_In_scaled;





=head2 gsl_sf_bessel_I_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of Scaled Regular Modified Bessel Functions exp(-|x|) I_{s}(x) to exp(-|x|) I_{s+n-1}(x).

=for bad

gsl_sf_bessel_I_scaled_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_I_scaled_array = \&PDL::gsl_sf_bessel_I_scaled_array;





=head2 gsl_sf_bessel_Kn

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Modified Bessel Function K_n(x).

=for bad

gsl_sf_bessel_Kn does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Kn = \&PDL::gsl_sf_bessel_Kn;





=head2 gsl_sf_bessel_K_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of IrRegular Modified Bessel Functions K_{s}(x) to K_{s+n-1}(x).

=for bad

gsl_sf_bessel_K_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_K_array = \&PDL::gsl_sf_bessel_K_array;





=head2 gsl_sf_bessel_Kn_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled IrRegular Modified Bessel Function exp(-|x|) K_n(x).

=for bad

gsl_sf_bessel_Kn_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Kn_scaled = \&PDL::gsl_sf_bessel_Kn_scaled;





=head2 gsl_sf_bessel_K_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int s; int n=>num)

=for ref

Array of Scaled IrRegular Modified Bessel Functions exp(-|x|) K_{s}(x) to exp(-|x|) K_{s+n-1}(x).

=for bad

gsl_sf_bessel_K_scaled_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_K_scaled_array = \&PDL::gsl_sf_bessel_K_scaled_array;





=head2 gsl_sf_bessel_jl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Regular Sphericl Bessel Function J_n(x).

=for bad

gsl_sf_bessel_jl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_jl = \&PDL::gsl_sf_bessel_jl;





=head2 gsl_sf_bessel_j_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Spherical Regular Bessel Functions J_{0}(x) to J_{n-1}(x).

=for bad

gsl_sf_bessel_j_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_j_array = \&PDL::gsl_sf_bessel_j_array;





=head2 gsl_sf_bessel_yl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

IrRegular Spherical Bessel Function y_n(x).

=for bad

gsl_sf_bessel_yl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_yl = \&PDL::gsl_sf_bessel_yl;





=head2 gsl_sf_bessel_y_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Regular Spherical Bessel Functions y_{0}(x) to y_{n-1}(x).

=for bad

gsl_sf_bessel_y_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_y_array = \&PDL::gsl_sf_bessel_y_array;





=head2 gsl_sf_bessel_il_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled Regular Modified Spherical Bessel Function exp(-|x|) i_n(x).

=for bad

gsl_sf_bessel_il_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_il_scaled = \&PDL::gsl_sf_bessel_il_scaled;





=head2 gsl_sf_bessel_i_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Scaled Regular Modified Spherical Bessel Functions exp(-|x|) i_{0}(x) to exp(-|x|) i_{n-1}(x).

=for bad

gsl_sf_bessel_i_scaled_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_i_scaled_array = \&PDL::gsl_sf_bessel_i_scaled_array;





=head2 gsl_sf_bessel_kl_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int n)

=for ref

Scaled IrRegular Modified Spherical Bessel Function exp(-|x|) k_n(x).

=for bad

gsl_sf_bessel_kl_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_kl_scaled = \&PDL::gsl_sf_bessel_kl_scaled;





=head2 gsl_sf_bessel_k_scaled_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num)

=for ref

Array of Scaled IrRegular Modified Spherical Bessel Functions exp(-|x|) k_{s}(x) to exp(-|x|) k_{s+n-1}(x).

=for bad

gsl_sf_bessel_k_scaled_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_k_scaled_array = \&PDL::gsl_sf_bessel_k_scaled_array;





=head2 gsl_sf_bessel_Jnu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Regular Cylindrical Bessel Function J_nu(x).

=for bad

gsl_sf_bessel_Jnu does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Jnu = \&PDL::gsl_sf_bessel_Jnu;





=head2 gsl_sf_bessel_Ynu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

IrRegular Cylindrical Bessel Function J_nu(x).

=for bad

gsl_sf_bessel_Ynu does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Ynu = \&PDL::gsl_sf_bessel_Ynu;





=head2 gsl_sf_bessel_Inu_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) I_nu(x).

=for bad

gsl_sf_bessel_Inu_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Inu_scaled = \&PDL::gsl_sf_bessel_Inu_scaled;





=head2 gsl_sf_bessel_Inu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Modified Cylindrical Bessel Function I_nu(x).

=for bad

gsl_sf_bessel_Inu does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Inu = \&PDL::gsl_sf_bessel_Inu;





=head2 gsl_sf_bessel_Knu_scaled

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Scaled Modified Cylindrical Bessel Function exp(-|x|) K_nu(x).

=for bad

gsl_sf_bessel_Knu_scaled does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Knu_scaled = \&PDL::gsl_sf_bessel_Knu_scaled;





=head2 gsl_sf_bessel_Knu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Modified Cylindrical Bessel Function K_nu(x).

=for bad

gsl_sf_bessel_Knu does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_Knu = \&PDL::gsl_sf_bessel_Knu;





=head2 gsl_sf_bessel_lnKnu

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double n)

=for ref

Logarithm of Modified Cylindrical Bessel Function K_nu(x).

=for bad

gsl_sf_bessel_lnKnu does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_bessel_lnKnu = \&PDL::gsl_sf_bessel_lnKnu;



;


=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut






# Exit with OK status

1;

		   