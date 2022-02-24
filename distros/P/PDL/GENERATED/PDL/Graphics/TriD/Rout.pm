#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::TriD::Rout;

our @EXPORT_OK = qw(combcoords repulse attract vrmlcoordsvert contour_segments_internal );
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
#line 38 "Rout.pm"






=head1 FUNCTIONS

=cut




#line 1058 "../../../blib/lib/PDL/PP.pm"



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
#line 79 "Rout.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*combcoords = \&PDL::combcoords;
#line 86 "Rout.pm"



#line 1058 "../../../blib/lib/PDL/PP.pm"



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
#line 128 "Rout.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*repulse = \&PDL::repulse;
#line 135 "Rout.pm"



#line 1058 "../../../blib/lib/PDL/PP.pm"



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
#line 177 "Rout.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*attract = \&PDL::attract;
#line 184 "Rout.pm"



#line 1058 "../../../blib/lib/PDL/PP.pm"



=head2 vrmlcoordsvert

=for sig

  Signature: (vertices(n=3); char* space; PerlIO *fp)


=for ref

info not available


=for bad

vrmlcoordsvert does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 211 "Rout.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*vrmlcoordsvert = \&PDL::vrmlcoordsvert;
#line 218 "Rout.pm"



#line 227 "rout.pd"


=head2 contour_segments

=for ref

This is the interface for the pp routine contour_segments_internal
- it takes 3 ndarrays as input

C<$c> is a contour value (or a list of contour values)

C<$data> is an [m,n] array of values at each point

C<$points> is a list of [3,m,n] points, it should be a grid
monotonically increasing with m and n.  

contour_segments returns a reference to a Perl array of 
line segments associated with each value of C<$c>.  It does not (yet) handle
missing data values. 

=over 4

=item Algorithm

The data array represents samples of some field observed on the surface described 
by points.  For each contour value we look for intersections on the line segments
joining points of the data.  When an intersection is found we look to the adjoining 
line segments for the other end(s) of the line segment(s).  So suppose we find an
intersection on an x-segment.  We first look down to the left y-segment, then to the
right y-segment and finally across to the next x-segment.  Once we find one in a 
box (two on a point) we can quit because there can only be one.  After we are done
with a given x-segment, we look to the leftover possibilities for the adjoining y-segment.
Thus the contours are built as a collection of line segments rather than a set of closed
polygons.          

=back

=cut

use strict;
sub PDL::Graphics::TriD::Contours::contour_segments {
	my($this,$c,$data,$points) = @_;
# pre compute space for output of pp routine

  my $segdim = ($data->getdim(0)-1)*($data->getdim(1)-1)*4;
#  print "segdim = $segdim\n"; 
  my $segs = zeroes(3,$segdim,$c->nelem);
  my $cnt = zeroes($c->nelem);
  contour_segments_internal($c,$data,$points,$segs,$cnt);

#  print "contour segments done ",$points->info,"\n";

  $this->{Points} = pdl->null;

  my $pcnt=0;
  my $ncnt;
  for(my $i=0; $i<$c->nelem; $i++){
	   $ncnt = $cnt->slice("($i)");
      next if($ncnt==-1);

		$pcnt = $pcnt+$ncnt;
			      
		$this->{ContourSegCnt}[$i] =  $pcnt;
		$pcnt=$pcnt+1;    
		$this->{Points} = $this->{Points}->append($segs->slice(":,0:$ncnt,($i)")->transpose);
	}
	$this->{Points} = $this->{Points}->transpose;
	
}
#line 292 "Rout.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*contour_segments_internal = \&PDL::contour_segments_internal;
#line 299 "Rout.pm"





#line 469 "rout.pd"


=head1 AUTHOR

Copyright (C) 2000 James P. Edwards
Copyright (C) 1997 Tuomas J. Lukka.
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 319 "Rout.pm"




# Exit with OK status

1;
