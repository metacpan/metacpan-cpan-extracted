
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::ZETA;

@EXPORT_OK  = qw( PDL::PP gsl_sf_zeta PDL::PP gsl_sf_hzeta PDL::PP gsl_sf_eta );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::ZETA ;




=head1 NAME

PDL::GSLSF::ZETA - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_zeta

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Riemann Zeta Function zeta(x) = Sum[ k^(-s), {k,1,Infinity} ], s != 1.0

=for bad

gsl_sf_zeta does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_zeta = \&PDL::gsl_sf_zeta;





=head2 gsl_sf_hzeta

=for sig

  Signature: (double s(); double [o]y(); double [o]e(); double q)

=for ref

Hurwicz Zeta Function zeta(s,q) = Sum[ (k+q)^(-s), {k,0,Infinity} ]

=for bad

gsl_sf_hzeta does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_hzeta = \&PDL::gsl_sf_hzeta;





=head2 gsl_sf_eta

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Eta Function eta(s) = (1-2^(1-s)) zeta(s)

=for bad

gsl_sf_eta does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_eta = \&PDL::gsl_sf_eta;



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

		   