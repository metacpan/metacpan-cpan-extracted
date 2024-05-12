#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::TriD::Rout;

our @EXPORT_OK = qw(combcoords repulse attract vrmlcoordsvert );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::TriD::Rout ;







#line 4 "rout.pd"

use strict;
use warnings;

=head1 NAME

PDL::Graphics::TriD::Rout - Helper routines for Three-dimensional graphics

=head1 DESCRIPTION

This module is for miscellaneous PP-defined utility routines for
the PDL::Graphics::TriD module. Currently, there are
#line 39 "Rout.pm"


=head1 FUNCTIONS

=cut






=head2 combcoords

=for sig

  Signature: (x(); y(); z();
		float [o]coords(tri=3);)

=for ref

Combine three coordinates into a single ndarray.

Combine x, y and z to a single ndarray the first dimension
of which is 3. This routine does dataflow automatically.

=for bad

combcoords does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*combcoords = \&PDL::combcoords;






=head2 repulse

=for sig

  Signature: (coords(nc,np);
		 [o]vecs(nc,np);
		 int [t]links(np);; 
		double boxsize;
		int dmult;
		double a;
		double b;
		double c;
		double d;
	)

=for ref

Repulsive potential for molecule-like constructs.

C<repulse> uses a hash table of cubes to quickly calculate
a repulsive force that vanishes at infinity for many
objects. For use by the module L<PDL::Graphics::TriD::MathGraph>.
For definition of the potential, see the actual function.

=for bad

repulse does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*repulse = \&PDL::repulse;






=head2 attract

=for sig

  Signature: (coords(nc,np);
		int from(nl);
		int to(nl);
		strength(nl);
		[o]vecs(nc,np);; 
		double m;
		double ms;
	)

=for ref

Attractive potential for molecule-like constructs.

C<attract> is used to calculate
an attractive force for many
objects, of which some attract each other (in a way
like molecular bonds).
For use by the module L<PDL::Graphics::TriD::MathGraph>.
For definition of the potential, see the actual function.

=for bad

attract does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*attract = \&PDL::attract;






=head2 vrmlcoordsvert

=for sig

  Signature: (vertices(n=3); char* space; PerlIO *fp)

=for ref

info not available

=for bad

vrmlcoordsvert does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*vrmlcoordsvert = \&PDL::vrmlcoordsvert;







#line 214 "rout.pd"

=head1 AUTHOR

Copyright (C) 2000 James P. Edwards
Copyright (C) 1997 Tuomas J. Lukka.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 205 "Rout.pm"

# Exit with OK status

1;
