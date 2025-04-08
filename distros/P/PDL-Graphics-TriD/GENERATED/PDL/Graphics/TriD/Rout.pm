#
# GENERATED WITH PDL::PP from lib/PDL/Graphics/TriD/Rout.pd! Don't modify!
#
package PDL::Graphics::TriD::Rout;

our @EXPORT_OK = qw(vrmlcoordsvert );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::TriD::Rout ;








#line 4 "lib/PDL/Graphics/TriD/Rout.pd"

use strict;
use warnings;

=head1 NAME

PDL::Graphics::TriD::Rout - Helper routines for Three-dimensional graphics

=head1 DESCRIPTION

This module is for miscellaneous PP-defined utility routines for
the PDL::Graphics::TriD module.
#line 40 "lib/PDL/Graphics/TriD/Rout.pm"


=head1 FUNCTIONS

=cut






=head2 vrmlcoordsvert

=for sig

 Signature: (vertices(n=3); char* space; PerlIO *fp)
 Types: (float double)

=for usage

 vrmlcoordsvert($vertices, $space, $fp); # all arguments given
 $vertices->vrmlcoordsvert($space, $fp); # method call

=for ref

info not available

=pod

Broadcasts over its inputs.

=for bad

C<vrmlcoordsvert> does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*vrmlcoordsvert = \&PDL::vrmlcoordsvert;







#line 40 "lib/PDL/Graphics/TriD/Rout.pd"

=head1 AUTHOR

Copyright (C) 2000 James P. Edwards
Copyright (C) 1997 Tuomas J. Lukka.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 103 "lib/PDL/Graphics/TriD/Rout.pm"

# Exit with OK status

1;
