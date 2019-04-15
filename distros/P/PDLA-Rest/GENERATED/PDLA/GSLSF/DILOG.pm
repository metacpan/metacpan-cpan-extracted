
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::GSLSF::DILOG;

@EXPORT_OK  = qw( PDLA::PP gsl_sf_dilog PDLA::PP gsl_sf_complex_dilog );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::GSLSF::DILOG ;




=head1 NAME

PDLA::GSLSF::DILOG - PDLA interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_dilog

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

/* Real part of DiLogarithm(x), for real argument. In Lewins notation, this is Li_2(x). Li_2(x) = - Re[ Integrate[ Log[1-s] / s, {s, 0, x}] ]

=for bad

gsl_sf_dilog does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_dilog = \&PDLA::gsl_sf_dilog;





=head2 gsl_sf_complex_dilog

=for sig

  Signature: (double r(); double t(); double [o]re(); double [o]im(); double [o]ere(); double [o]eim())

=for ref

DiLogarithm(z), for complex argument z = r Exp[i theta].

=for bad

gsl_sf_complex_dilog does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_complex_dilog = \&PDLA::gsl_sf_complex_dilog;



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

		   