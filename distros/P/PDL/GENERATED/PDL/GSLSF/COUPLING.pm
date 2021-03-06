
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::COUPLING;

@EXPORT_OK  = qw( PDL::PP gsl_sf_coupling_3j PDL::PP gsl_sf_coupling_6j PDL::PP gsl_sf_coupling_9j );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::COUPLING ;




=head1 NAME

PDL::GSLSF::COUPLING - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_coupling_3j

=for sig

  Signature: (ja(); jb(); jc(); ma(); mb(); mc(); double [o]y(); double [o]e())

=for ref

3j Symbols:  (ja jb jc) over (ma mb mc).



=cut






*gsl_sf_coupling_3j = \&PDL::gsl_sf_coupling_3j;





=head2 gsl_sf_coupling_6j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); double [o]y(); double [o]e())

=for ref

6j Symbols:  (ja jb jc) over (jd je jf).



=cut






*gsl_sf_coupling_6j = \&PDL::gsl_sf_coupling_6j;





=head2 gsl_sf_coupling_9j

=for sig

  Signature: (ja(); jb(); jc(); jd(); je(); jf(); jg(); jh(); ji(); double [o]y(); double [o]e())

=for ref

9j Symbols:  (ja jb jc) over (jd je jf) over (jg jh ji).



=cut






*gsl_sf_coupling_9j = \&PDL::gsl_sf_coupling_9j;



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

		   