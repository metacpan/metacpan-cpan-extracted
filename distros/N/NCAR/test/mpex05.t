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
# The program MPEX05 produces a single frame with maximal-area
# views of all the EZMAP projections of the globe.
#
#
# Define the label for the top of the map.
#
my $PLBL = 'MAXIMAL-AREA PROJECTIONS OF ALL TYPES';
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU','CO');
#
# Put meridians and parallels every 15 degrees.
#
&NCAR::mapsti ('GR',15);
#
# Reduce the label size.
#
&NCAR::mapsti ('LS',0);
#
# Lambert conformal conic.
#
&NCAR::mappos (.025,.24375,.63125,.85);
&NCAR::maproj ('LC',30.,0.,45.);
&NCAR::mapdrw();
#
# Stereographic.
#
&NCAR::mappos (.26875,.4875,.63125,.85);
&NCAR::maproj ('ST',0.,0.,0.);
&NCAR::mapdrw();
#
# Orthographic.
#
&NCAR::mappos (.5125,.73125,.63125,.85);
&NCAR::maproj ('OR',0.,0.,0.);
&NCAR::mapdrw();
#
# Lambert equal-area.
#
&NCAR::mappos (.75625,.975,.63125,.85);
&NCAR::maproj ('LE',0.,0.,0.);
&NCAR::mapdrw();
#
# Gnomonic.
#
&NCAR::mappos (.025,.24375,.3875,.60625);
&NCAR::maproj ('GN',0.,0.,0.);
&NCAR::mapdrw();
#
# Azimuthal equidistant.
#
&NCAR::mappos (.26875,.4875,.3875,.60625);
&NCAR::maproj ('AE',0.,0.,0.);
&NCAR::mapdrw;
#
# Satellite-view.
#
&NCAR::mappos (.5125,.73125,.3875,.60625);
&NCAR::maproj ('SV',0.,0.,0.);
&NCAR::mapstr ('SA',2.);
&NCAR::mapdrw();
#
# Mercator.
#
&NCAR::mappos (.75625,.975,.3875,.60625);
&NCAR::maproj ('ME',0.,0.,0.);
&NCAR::mapdrw();
#
# Cylindrical equidistant.
#
&NCAR::mappos (.025,.4875,.13125,.3625);
&NCAR::maproj ('CE',0.,0.,0.);
&NCAR::mapdrw();
#
# Mollweide type.
#
&NCAR::mappos (.5125,.975,.13125,.3625);
&NCAR::maproj ('MO',0.,0.,0.);
&NCAR::mapdrw();
#
# Put the label at the top of the plot ...
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.925,$PLBL,37,2,0,0);
#
# and the labels under each sub-plot.
#
&NCAR::pwrit (.134375,.61875,'LAMBERT CONFORMAL CONIC',23,0,0,0);
&NCAR::pwrit (.378125,.61875,'STEREOGRAPHIC',13,0,0,0);
&NCAR::pwrit (.621875,.61875,'ORTHOGRAPHIC',12,0,0,0);
&NCAR::pwrit (.865625,.61875,'LAMBERT EQUAL-AREA',18,0,0,0);
&NCAR::pwrit (.134375,.375,'GNOMONIC',8,0,0,0);
&NCAR::pwrit (.378125,.375,'AZIMUTHAL EQUIDISTANT',21,0,0,0);
&NCAR::pwrit (.621875,.375,'SATELLITE-VIEW',14,0,0,0);
&NCAR::pwrit (.865625,.375,'MERCATOR',8,0,0,0);
&NCAR::pwrit (.25625,.11875,'CYLINDRICAL EQUIDISTANT',23,0,0,0);
&NCAR::pwrit (.74375,.11875,'MOLLWEIDE TYPE',14,0,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();

sub NCAR::mapeod {
  my ($NOUT,$NSEG,$IDLS,$IDRS,$NPTS,$PNTS) = @_;
#
# This version of MAPEOD uses area identifiers for the outline
# dataset 'CO' to suppress all but the major global land masses.
#
 if( ( $IDLS != 2 ) && ( $IDRS != 2 ) ) { $NPTS = 0; }
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
   ) { $NPTS = 0; }
  
  $_[4] = $NPTS;
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex05.ncgm';
