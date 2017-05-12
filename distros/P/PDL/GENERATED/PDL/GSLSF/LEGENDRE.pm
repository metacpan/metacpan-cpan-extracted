
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::LEGENDRE;

@EXPORT_OK  = qw( PDL::PP gsl_sf_legendre_Pl PDL::PP gsl_sf_legendre_Pl_array PDL::PP gsl_sf_legendre_Ql PDL::PP gsl_sf_legendre_Plm PDL::PP gsl_sf_legendre_Plm_array PDL::PP gsl_sf_legendre_sphPlm_array PDL::PP gsl_sf_legendre_sphPlm PDL::PP gsl_sf_conicalP_half PDL::PP gsl_sf_conicalP_mhalf PDL::PP gsl_sf_conicalP_0 PDL::PP gsl_sf_conicalP_1 PDL::PP gsl_sf_conicalP_sph_reg PDL::PP gsl_sf_conicalP_cyl_reg_e PDL::PP gsl_sf_legendre_H3d PDL::PP gsl_sf_legendre_H3d_array );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::LEGENDRE ;




=head1 NAME

PDL::GSLSF::LEGENDRE - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_legendre_Pl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

P_l(x)

=for bad

gsl_sf_legendre_Pl does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Pl = \&PDL::gsl_sf_legendre_Pl;





=head2 gsl_sf_legendre_Pl_array

=for sig

  Signature: (double x(); double [o]y(num); int l=>num)

=for ref

P_l(x) from 0 to n-1.

=for bad

gsl_sf_legendre_Pl_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Pl_array = \&PDL::gsl_sf_legendre_Pl_array;





=head2 gsl_sf_legendre_Ql

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

Q_l(x)

=for bad

gsl_sf_legendre_Ql does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Ql = \&PDL::gsl_sf_legendre_Ql;





=head2 gsl_sf_legendre_Plm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x)

=for bad

gsl_sf_legendre_Plm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Plm = \&PDL::gsl_sf_legendre_Plm;





=head2 gsl_sf_legendre_Plm_array

=for sig

  Signature: (double x(); double [o]y(num); int l=>num; int m)

P_lm(x) for l from 0 to n-2+m.
gsl_sf_legendre_Plm_array has been deprecated in GSL version 2.0. It is included here for backwards compatability and may be removed in a future release.  New code should use L<gsl_sf_legendre_array> instead.

=for bad

gsl_sf_legendre_Plm_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Plm_array = \&PDL::gsl_sf_legendre_Plm_array;





=head2 gsl_sf_legendre_sphPlm_array

=for sig

  Signature: (double x(); double [o]y(num); int n=>num; int m)

P_lm(x), normalized properly for use in spherical harmonics for l from 0 to n-2+m.
gsl_sf_legendre_sphPlm_array has been deprecated in GSL version 2.0. It is included here for backwards compatability and may be removed in a future release.  New code should use L<gsl_sf_legendre_array> instead.

=for bad

gsl_sf_legendre_sphPlm_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_sphPlm_array = \&PDL::gsl_sf_legendre_sphPlm_array;





=head2 gsl_sf_legendre_sphPlm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x), normalized properly for use in spherical harmonics

=for bad

gsl_sf_legendre_sphPlm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_sphPlm = \&PDL::gsl_sf_legendre_sphPlm;





=head2 gsl_sf_conicalP_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Irregular Spherical Conical Function P^{1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_half does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_half = \&PDL::gsl_sf_conicalP_half;





=head2 gsl_sf_conicalP_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_mhalf does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_mhalf = \&PDL::gsl_sf_conicalP_mhalf;





=head2 gsl_sf_conicalP_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{0}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_0 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_0 = \&PDL::gsl_sf_conicalP_0;





=head2 gsl_sf_conicalP_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{1}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_1 = \&PDL::gsl_sf_conicalP_1;





=head2 gsl_sf_conicalP_sph_reg

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2-l}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_sph_reg does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_sph_reg = \&PDL::gsl_sf_conicalP_sph_reg;





=head2 gsl_sf_conicalP_cyl_reg_e

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int m; double lambda)

=for ref

Regular Cylindrical Conical Function P^{-m}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_cyl_reg_e does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_cyl_reg_e = \&PDL::gsl_sf_conicalP_cyl_reg_e;





=head2 gsl_sf_legendre_H3d

=for sig

  Signature: (double [o]y(); double [o]e(); int l; double lambda; double eta)

=for ref

lth radial eigenfunction of the Laplacian on the 3-dimensional hyperbolic space.

=for bad

gsl_sf_legendre_H3d does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_H3d = \&PDL::gsl_sf_legendre_H3d;





=head2 gsl_sf_legendre_H3d_array

=for sig

  Signature: (double [o]y(num); int l=>num; double lambda; double eta)

=for ref

Array of H3d(ell), for l from 0 to n-1.

=for bad

gsl_sf_legendre_H3d_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_H3d_array = \&PDL::gsl_sf_legendre_H3d_array;



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

		   