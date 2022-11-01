#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::LEGENDRE;

our @EXPORT_OK = qw(gsl_sf_legendre_Pl gsl_sf_legendre_Pl_array gsl_sf_legendre_Ql gsl_sf_legendre_Plm gsl_sf_legendre_array gsl_sf_legendre_array_index gsl_sf_legendre_sphPlm gsl_sf_conicalP_half gsl_sf_conicalP_mhalf gsl_sf_conicalP_0 gsl_sf_conicalP_1 gsl_sf_conicalP_sph_reg gsl_sf_conicalP_cyl_reg_e gsl_sf_legendre_H3d gsl_sf_legendre_H3d_array );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::LEGENDRE ;






#line 5 "gsl_sf_legendre.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::LEGENDRE - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=cut
#line 39 "LEGENDRE.pm"






=head1 FUNCTIONS

=cut




#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_Pl

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

P_l(x)

=for bad

gsl_sf_legendre_Pl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 74 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_Pl = \&PDL::gsl_sf_legendre_Pl;
#line 81 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_Pl_array

=for sig

  Signature: (double x(); double [o]y(num); int l=>num)

=for ref

P_l(x) from 0 to n-1.

=for bad

gsl_sf_legendre_Pl_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 106 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_Pl_array = \&PDL::gsl_sf_legendre_Pl_array;
#line 113 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_Ql

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l)

=for ref

Q_l(x)

=for bad

gsl_sf_legendre_Ql does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 138 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_Ql = \&PDL::gsl_sf_legendre_Ql;
#line 145 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_Plm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x)

=for bad

gsl_sf_legendre_Plm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 170 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_Plm = \&PDL::gsl_sf_legendre_Plm;
#line 177 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



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

=item 'S' for Schmidt semi-normalized associated Legendre polynomials S_l^m(x),

=item 'Y' for spherical harmonic associated Legendre polynomials Y_l^m(x), or

=item 'N' for fully normalized associated Legendre polynomials N_l^m(x).

=item 'P' (or any other) for unnormalized associated Legendre polynomials P_l^m(x),

=back

lmax is the maximum degree l.
csphase should be (-1) to INCLUDE the Condon-Shortley phase factor (-1)^m, or (+1) to EXCLUDE it.

See L</gsl_sf_legendre_array_index> to get the value of C<l> and C<m> in the returned vector.


=for bad

gsl_sf_legendre_array processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 228 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_array = \&PDL::gsl_sf_legendre_array;
#line 235 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_array_index

=for sig

  Signature: (int [o]l(n); int [o]m(n); int lmax)

=for ref

Calculate the relation between gsl_sf_legendre_arrays index and l and m values.

=for usage
($l,$m) = gsl_sf_legendre_array_index($lmax);

Note that this function is called differently than the corresponding GSL function, to make it more useful for PDL: here you just input the maximum l (lmax) that was used in C<gsl_sf_legendre_array> and it calculates all l and m values.

=for bad

gsl_sf_legendre_array_index does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 265 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_array_index = \&PDL::gsl_sf_legendre_array_index;
#line 272 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_sphPlm

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; int m)

=for ref

P_lm(x), normalized properly for use in spherical harmonics

=for bad

gsl_sf_legendre_sphPlm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 297 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_sphPlm = \&PDL::gsl_sf_legendre_sphPlm;
#line 304 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Irregular Spherical Conical Function P^{1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_half does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 329 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_half = \&PDL::gsl_sf_conicalP_half;
#line 336 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_mhalf does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 361 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_mhalf = \&PDL::gsl_sf_conicalP_mhalf;
#line 368 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{0}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 393 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_0 = \&PDL::gsl_sf_conicalP_0;
#line 400 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_1

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double lambda)

=for ref

Conical Function P^{1}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 425 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_1 = \&PDL::gsl_sf_conicalP_1;
#line 432 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_sph_reg

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int l; double lambda)

=for ref

Regular Spherical Conical Function P^{-1/2-l}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_sph_reg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 457 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_sph_reg = \&PDL::gsl_sf_conicalP_sph_reg;
#line 464 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_conicalP_cyl_reg_e

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int m; double lambda)

=for ref

Regular Cylindrical Conical Function P^{-m}_{-1/2 + I lambda}(x)

=for bad

gsl_sf_conicalP_cyl_reg_e does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 489 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_conicalP_cyl_reg_e = \&PDL::gsl_sf_conicalP_cyl_reg_e;
#line 496 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_H3d

=for sig

  Signature: (double [o]y(); double [o]e(); int l; double lambda; double eta)

=for ref

lth radial eigenfunction of the Laplacian on the 3-dimensional hyperbolic space.

=for bad

gsl_sf_legendre_H3d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 521 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_H3d = \&PDL::gsl_sf_legendre_H3d;
#line 528 "LEGENDRE.pm"



#line 949 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_legendre_H3d_array

=for sig

  Signature: (double [o]y(num); int l=>num; double lambda; double eta)

=for ref

Array of H3d(ell), for l from 0 to n-1.

=for bad

gsl_sf_legendre_H3d_array does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 553 "LEGENDRE.pm"



#line 951 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_legendre_H3d_array = \&PDL::gsl_sf_legendre_H3d_array;
#line 560 "LEGENDRE.pm"





#line 302 "gsl_sf_legendre.pd"


=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 581 "LEGENDRE.pm"




# Exit with OK status

1;
