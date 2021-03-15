
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::ELLJAC;

@EXPORT_OK  = qw( PDL::PP gsl_sf_elljac );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::ELLJAC ;




=head1 NAME

PDL::GSLSF::ELLJAC - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 

=head1 SYNOPSIS

=cut








=head1 FUNCTIONS



=cut






=head2 gsl_sf_elljac

=for sig

  Signature: (double u(); double m(); double [o]sn(); double [o]cn(); double [o]dn())

=for ref

Jacobian elliptic functions sn, dn, cn by descending Landen transformations

=for bad

gsl_sf_elljac does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gsl_sf_elljac = \&PDL::gsl_sf_elljac;



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

		   