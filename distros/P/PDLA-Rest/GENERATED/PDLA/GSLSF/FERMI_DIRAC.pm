
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::FERMI_DIRAC;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_fermi_dirac_int PDLA::PP gsl_sf_fermi_dirac_mhalf PDLA::PP gsl_sf_fermi_dirac_half PDLA::PP gsl_sf_fermi_dirac_3half PDLA::PP gsl_sf_fermi_dirac_inc_0 );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::FERMI_DIRAC ;




=head1 NAME

PDLA::GSLSF::FERMI_DIRAC - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 
Please note that:

Complete Fermi-Dirac Integrals:

 F_j(x)   := 1/Gamma[j+1] Integral[ t^j /(Exp[t-x] + 1), {t,0,Infinity}]


Incomplete Fermi-Dirac Integrals:

 F_j(x,b) := 1/Gamma[j+1] Integral[ t^j /(Exp[t-x] + 1), {t,b,Infinity}]

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_fermi_dirac_int

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); int j)

=for ref

Complete integral F_j(x) for integer j

=for bad

gsl_sf_fermi_dirac_int does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_fermi_dirac_int = \&PDLA::gsl_sf_fermi_dirac_int;





=head2 gsl_sf_fermi_dirac_mhalf

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{-1/2}(x)

=for bad

gsl_sf_fermi_dirac_mhalf does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_fermi_dirac_mhalf = \&PDLA::gsl_sf_fermi_dirac_mhalf;





=head2 gsl_sf_fermi_dirac_half

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{1/2}(x)

=for bad

gsl_sf_fermi_dirac_half does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_fermi_dirac_half = \&PDLA::gsl_sf_fermi_dirac_half;





=head2 gsl_sf_fermi_dirac_3half

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

Complete integral F_{3/2}(x)

=for bad

gsl_sf_fermi_dirac_3half does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_fermi_dirac_3half = \&PDLA::gsl_sf_fermi_dirac_3half;





=head2 gsl_sf_fermi_dirac_inc_0

=for sig

  Signature: (double x(); double [o]y(); double [o]e(); double b)

=for ref

Incomplete integral F_0(x,b) = ln(1 + e^(b-x)) - (b-x)

=for bad

gsl_sf_fermi_dirac_inc_0 does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_fermi_dirac_inc_0 = \&PDLA::gsl_sf_fermi_dirac_inc_0;



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

		   