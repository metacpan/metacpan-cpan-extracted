# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
ok(1); # If we made it this far, we're ok.;

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
unlink( 'gmeta' );

use PDL;
use NCAR::Test qw( bndary gendat drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# Produce a Mercator projection of the whole globe, using
# simplified continental outlines.  See the routine MAPEOD,
# below.
#
#
# Define the label for the top of the map.
#
my $PLBL = 'SIMPLIFIED CONTINENTS ON A MERCATOR PROJECTION';
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Draw the map.
#
&NCAR::supmap (9,0.,0.,0.,
               float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       float( [ 0., 0 ] ),
	       1,15,2,0,my $IERR);
#
# Put the label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.975,$PLBL,46,2,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();
#
# Advance the frame.
#
&NCAR::frame();

sub NCAR::mapeod {
  my ($NOUT,$NSEG,$IDLS,$IDRS,$NPTS,$PNTS) = @_;
#
# This version of MAPEOD uses area identifiers for the outline
# dataset 'CO' to suppress all but the major global land masses.
# In honor of Cicely Ridley, the British Isles are included.
#
# Cull the segment if there's no ocean on either side of it ...
#
  if( ( $IDLS != 2 ) && ( $IDRS != 2 ) ) { $NPTS = 0; }
#
# or if it's not an edge of any of the desired areas.
#
  if(
     ( $IDLS !=   1 ) && ( $IDRS !=   1 ) && 
     ( $IDLS !=   3 ) && ( $IDRS !=   3 ) && 
     ( $IDLS !=  11 ) && ( $IDRS !=  11 ) && 
     ( $IDLS !=  79 ) && ( $IDRS !=  79 ) && 
     ( $IDLS !=  99 ) && ( $IDRS !=  99 ) && 
     ( $IDLS != 104 ) && ( $IDRS != 104 ) && 
     ( $IDLS != 107 ) && ( $IDRS != 107 ) && 
     ( $IDLS != 163 ) && ( $IDRS != 163 ) 
    ) { $NPTS=0; }
  $_[4] = $NPTS;
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex03.ncgm';
