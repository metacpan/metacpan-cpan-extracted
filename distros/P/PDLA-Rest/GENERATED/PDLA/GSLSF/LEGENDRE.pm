
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::LEGENDRE;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_legendre_Pl PDLA::PP gsl_sf_legendre_Pl_array PDLA::PP gsl_sf_legendre_Ql PDLA::PP gsl_sf_legendre_Plm PDLA::PP gsl_sf_legendre_array PDLA::PP gsl_sf_legendre_array_index PDLA::PP gsl_sf_legendre_sphPlm PDLA::PP gsl_sf_conicalP_half PDLA::PP gsl_sf_conicalP_mhalf PDLA::PP gsl_sf_conicalP_0 PDLA::PP gsl_sf_conicalP_1 PDLA::PP gsl_sf_conicalP_sph_reg PDLA::PP gsl_sf_conicalP_cyl_reg_e PDLA::PP gsl_sf_legendre_H3d PDLA::PP gsl_sf_legendre_H3d_array );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::LEGENDRE ;




=head1 NAME

PDLA::GSLSF::LEGENDRE - PDLA interface to GSL Special Functions

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






*gsl_sf_legendre_Pl = \&PDLA::gsl_sf_legendre_Pl;





=head2 gsl_sf_legendre_Pl_array

=for sig

  Signature: (double x(); double [o]y(num); int l=>num)

=for ref

P_l(x) from 0 to n-1.

=for bad

gsl_sf_legendre_Pl_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Pl_array = \&PDLA::gsl_sf_legendre_Pl_array;





=head2 gsl_sf_legendre_Ql

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

Q_l(x)

=for bad

gsl_sf_legendre_Ql does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Ql = \&PDLA::gsl_sf_legendre_Ql;





=head2 gsl_sf_legendre_Plm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x)

=for bad

gsl_sf_legendre_Plm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_Plm = \&PDLA::gsl_sf_legendre_Plm;





=head2 gsl_sf_legendre_array

=for sig

  Signature: (double x(); double [o]y(n); double [t]work(wn); char norm;  int lmax; int csphase)

=for ref

Calculate all normalized associated Legendre polynomials.

=for usage

$Plm = gsl_sf_legendre_array($x,'P',4,-1);

The calculation is done for degree 0 <= l <= lmax and order 0 <= m <= l on the range abs(x)<=1.

The parameter norm should be:

=over 3

=item 'P' for unnormalized associated Legendre polynomials P_l^m(x),

=item 'S' for Schmidt semi-normalized associated Legendre polynomials S_l^m(x),

=item 'Y' for spherical harmonic associated Legendre polynomials Y_l^m(x), or

=item 'N' for fully normalized associated Legendre polynomials N_l^m(x).

=back

lmax is the maximum degree l.
csphase should be (-1) to INCLUDE the Condon-Shortley phase factor (-1)^m, or (+1) to EXCLUDE it.

See L<gsl_sf_legendre_array_index> to get the value of C<l> and C<m> in the returned vector.



=for bad

gsl_sf_legendre_array processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_array = \&PDLA::gsl_sf_legendre_array;





=head2 gsl_sf_legendre_array_index

=for sig

  Signature: (int [o]l(n); int [o]m(n); int lmax)

=for ref

Calculate the relation between gsl_sf_legendre_arrays index and l and m values.

=for usage
($l,$m) = gsl_sf_legendre_array_index($lmax);

Note that this function is called differently than the corresponding GSL function, to make it more useful for PDLA: here you just input the maximum l (lmax) that was used in C<gsl_sf_legendre_array> and it calculates all l and m values.

=for bad

gsl_sf_legendre_array_index does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_array_index = \&PDLA::gsl_sf_legendre_array_index;





=head2 gsl_sf_legendre_sphPlm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x), normalized properly for use in spherical harmonics

=for bad

gsl_sf_legendre_sphPlm does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_sphPlm = \&PDLA::gsl_sf_legendre_sphPlm;





=head2 gsl_sf_conicalP_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Irregular Spherical Conical Function P^{1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_half does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_half = \&PDLA::gsl_sf_conicalP_half;





=head2 gsl_sf_conicalP_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_mhalf does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_mhalf = \&PDLA::gsl_sf_conicalP_mhalf;





=head2 gsl_sf_conicalP_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{0}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_0 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_0 = \&PDLA::gsl_sf_conicalP_0;





=head2 gsl_sf_conicalP_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{1}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_1 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_1 = \&PDLA::gsl_sf_conicalP_1;





=head2 gsl_sf_conicalP_sph_reg

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2-l}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_sph_reg does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_sph_reg = \&PDLA::gsl_sf_conicalP_sph_reg;





=head2 gsl_sf_conicalP_cyl_reg_e

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int m; double lambda)

=for ref

Regular Cylindrical Conical Function P^{-m}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_cyl_reg_e does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_conicalP_cyl_reg_e = \&PDLA::gsl_sf_conicalP_cyl_reg_e;





=head2 gsl_sf_legendre_H3d

=for sig

  Signature: (double [o]y(); double [o]e(); int l; double lambda; double eta)

=for ref

lth radial eigenfunction of the Laplacian on the 3-dimensional hyperbolic space.

=for bad

gsl_sf_legendre_H3d does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_H3d = \&PDLA::gsl_sf_legendre_H3d;





=head2 gsl_sf_legendre_H3d_array

=for sig

  Signature: (double [o]y(num); int l=>num; double lambda; double eta)

=for ref

Array of H3d(ell), for l from 0 to n-1.

=for bad

gsl_sf_legendre_H3d_array does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_legendre_H3d_array = \&PDLA::gsl_sf_legendre_H3d_array;



;


=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDLA distribution. If this file is separated from the
PDLA distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut






# Exit with OK status

1;

		   