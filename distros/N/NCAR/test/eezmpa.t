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

print STDERR "\n";

my $IAM = zeroes long, 400000;
#
# Dimension the arrays needed by ARSCAM for edges.
#
my $XCS = zeroes float, 10000;
my $YCS = zeroes float, 10000;
#
# Dimension the arrays needed by ARSCAM and ARDRLN for area and group
# ids.
#
my $IAI = zeroes long, 10;
my $IAG = zeroes long, 10;
#
# Define an array for aspect source flags.
#
my $IF = zeroes long, 13;
#
# Declare the routine which will color the areas and the one which
# will draw the lines of latitude and longitude over water.
#
#       EXTERNAL COLRAM,COLRLN
#
# Define the required RGB triples and indices.
#
   my @RGB = (
   [ 0.70,0.70,0.70 ],
   [ 0.75,0.50,1.00 ],
   [ 0.50,0.00,1.00 ],
   [ 0.00,0.00,1.00 ],
   [ 0.00,0.50,1.00 ],
   [ 0.00,1.00,1.00 ],
   [ 0.00,1.00,0.60 ],
   [ 0.00,1.00,0.00 ],
   [ 0.70,1.00,0.00 ],
   [ 1.00,1.00,0.00 ],
   [ 1.00,0.75,0.00 ],
   [ 1.00,0.38,0.38 ],
   [ 1.00,0.00,0.38 ],
   [ 1.00,0.00,0.00 ],
   );
#
my @IOC = ( 6,2,5,12,10,11,1,3,4,8,9,7,13,14 );
#
# Re-set certain aspect source flags to "individual".
#
&NCAR::gqasf (my $IE,$IF);
set( $IF, 10, 1 );
set( $IF, 11, 1 );
&NCAR::gsasf ($IF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define 15 different color indices.  The first 14 are spaced through
# the color spectrum and the final one is black.
#
for my $J ( 1 .. 14 ) {
  my $I=$IOC[$J-1];
  &NCAR::gscr(1,$J,@{ $RGB[$I-1] });
}
#
&NCAR::gscr(1,15,0.,0.,0.);
#
# Set up EZMAP, but don't draw anything.
#
&NCAR::mapstc ('OU','PO');
&NCAR::maproj ('ME',0.,0.,0.);
&NCAR::mapset ('MA',
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] ),
                float( [ 0., 0. ] )
		);
#
# Set the number of vertical strips and the group identifiers to
# be used by MAPBLA.
#
&NCAR::mapsti ('VS',150);
&NCAR::mapsti ('G1',1);
&NCAR::mapsti ('G2',2);
#
# Initialize EZMAP.
#
&NCAR::mapint;
#
# Initialize the area map.
#
&NCAR::arinam ($IAM,400000);
#
# Add edges to the area map.
#
&NCAR::mapbla ($IAM);
#
# Pre-process the area map.
#
&NCAR::arpram ($IAM,0,0,0);
#
# Compute and print the amount of space used in the area map.
#
my $ISU=400000-(at( $IAM, 5 )-at( $IAM, 4 )-1);
print STDERR "SPACE USED IN AREA MAP IS $ISU\n";
#
# Set the background color.
#
&NCAR::gscr (1,0,1.,1.,1.);
#
# Color the map.
#
&NCAR::arscam ($IAM,$XCS,$YCS,10000,$IAI,$IAG,10,\&COLRAM);
#
# In black, draw a perimeter and outline all the countries.  We turn
# off the labels (since they seem to detract from the appearance of
# the plot) and we reduce the minimum vector length so as to include
# all of the points in the boundaries.
#
# Flush PLOTIT's buffers and set polyline color index to black.
#
&NCAR::plotit(0,0,0);
&NCAR::gsplci(15);
#
&NCAR::mapsti ('LA',0);
&NCAR::mapsti ('MV',1);
&NCAR::maplbl;
&NCAR::maplot;
#
# Draw lines of latitude and longitude over water.  They will be in
# black because of the GSPLCI call above.
#
&NCAR::mapgrm ($IAM,$XCS,$YCS,10000,$IAI,$IAG,10,\&COLRLN);

#
sub COLRAM {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# For each area, one gets a set of points (using normalized device
# coordinates), two group identifiers and their associated area
# identifiers.  If both of the area identifiers are zero or negative,
# the area need not be color-filled; otherwise, it is filled with
# a color obtained from MAPACI.  If the area is defined by more than
# 150 points, we'd like to know about it.  (I'm assuming that the
# device being used won't handle polygons defined by more points than
# that.)
#
  if( ( at( $IAI, 0 ) >= 0 ) && ( at( $IAI, 1 ) >= 0 ) ) {
    my $ITM=&NCAR::Test::max(at($IAI,0),at($IAI,1));
    if( $ITM > 0 ) {
      if( $NCS > 150 ) { print STDERR "COLRAM - NCS TOO BIG - $NCS\n"; }
#
# Set area fill color index.
#
      &NCAR::gsfaci(&NCAR::mapaci($ITM));
#
      &NCAR::gfa ($NCS-1,$XCS,$YCS);
    }
  }
#
# Done.
#
}
#
sub COLRLN {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# For each line segment, one gets a set of points (using normalized
# device coordinates), two group identifiers and their associated
# area identifiers.  If both of the area identifiers are zero or
# negative, the segment is not drawn; otherwise, we use MAPACI to
# see if the segment is over water and, if so, we draw the segment.
# If the segment is defined by more than 150 points, we'd like to
# know about it.
#
  if( ( at( $IAI, 0 ) >= 0 ) && ( at( $IAI, 1 ) >= 0 ) ) {
    my $ITM=&NCAR::Test::max(at($IAI,0),at($IAI,1));
    if( &NCAR::mapaci( $ITM ) == 1 ) {
      if( $NCS > 150 ) { print STDERR "COLRLN - NCS TOO BIG - $NCS\n"; }
      &NCAR::gpl ($NCS,$XCS,$YCS);
   }
  }
#
# Done.
#
}



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/eezmpa.ncgm';
