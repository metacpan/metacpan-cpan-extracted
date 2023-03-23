#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GSLSF::TRANSPORT;

our @EXPORT_OK = qw(gsl_sf_transport_2 gsl_sf_transport_3 gsl_sf_transport_4 gsl_sf_transport_5 );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GSLSF::TRANSPORT ;






#line 4 "gsl_sf_transport.pd"

use strict;
use warnings;

=head1 NAME

PDL::GSLSF::TRANSPORT - PDL interface to GSL Special Functions

=head1 DESCRIPTION

This is an interface to the Special Function package present in the GNU Scientific Library. 


Transport function:
  J(n,x) := Integral[ t^n e^t /(e^t - 1)^2, {t,0,x}]

=cut
#line 43 "TRANSPORT.pm"






=head1 FUNCTIONS

=cut




#line 958 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_transport_2

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(2,x)

=for bad

gsl_sf_transport_2 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 78 "TRANSPORT.pm"



#line 960 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_transport_2 = \&PDL::gsl_sf_transport_2;
#line 85 "TRANSPORT.pm"



#line 958 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_transport_3

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(3,x)

=for bad

gsl_sf_transport_3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 110 "TRANSPORT.pm"



#line 960 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_transport_3 = \&PDL::gsl_sf_transport_3;
#line 117 "TRANSPORT.pm"



#line 958 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_transport_4

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(4,x)

=for bad

gsl_sf_transport_4 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 142 "TRANSPORT.pm"



#line 960 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_transport_4 = \&PDL::gsl_sf_transport_4;
#line 149 "TRANSPORT.pm"



#line 958 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"



=head2 gsl_sf_transport_5

=for sig

  Signature: (double x(); double [o]y(); double [o]e())

=for ref

J(5,x)

=for bad

gsl_sf_transport_5 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 174 "TRANSPORT.pm"



#line 960 "/home/osboxes/pdl-code/blib/lib/PDL/PP.pm"

*gsl_sf_transport_5 = \&PDL::gsl_sf_transport_5;
#line 181 "TRANSPORT.pm"





#line 80 "gsl_sf_transport.pd"

=head1 AUTHOR

This file copyright (C) 1999 Christian Pellegrin <chri@infis.univ.trieste.it>
All rights reserved. There
is no warranty. You are allowed to redistribute this software /
documentation under certain conditions. For details, see the file
COPYING in the PDL distribution. If this file is separated from the
PDL distribution, the copyright notice should be included in the file.

The GSL SF modules were written by G. Jungman.

=cut
#line 201 "TRANSPORT.pm"




# Exit with OK status

1;
