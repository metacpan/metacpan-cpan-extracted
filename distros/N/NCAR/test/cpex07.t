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
use NCAR::Test qw( bndary gendat drawcl dfclrs capsap labtop );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

print STDERR "\n";


my $ZDAT = zeroes float, 23, 14;
my $RWRK = zeroes float, 1000;
my $IWRK = zeroes long, 1000;
my $IAMA = zeroes long, 20000;
my $IASF = long [ ( 1 ) x 13 ];
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
my $IAIA = zeroes long, 10;
my $IGIA = zeroes long, 10;
#
# Declare arrays to hold the list of indices and the list of labels
# required by the label-bar routine.
#

#
# Declare the routine which will color the areas.
#
#       EXTERNAL COLRAM;
#
#
# Define the list of indices required by the label-bar routine.
#
my $LIND = long [ 2,3,4,5,6,7,8,9,10,11,12,13,14,15 ];
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Set all aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define color indices.
#
&dfclrs(1);
#
# Generate an array of test data.
#
&gendat ($ZDAT,23,23,14,20,20,-136.148,451.834);
#
# Force the plot into the upper portion of the frame.
#
&NCAR::cpsetr( 'VPB - VIEWPORT BOTTOM', .25 );
#
# Disallow the trimming of trailing zeroes.
#
&NCAR::cpseti( 'NOF - NUMERIC OMISSION FLAGS', 0 );
#
# Tell CONPACK to use 13 contour levels, splitting the range into 14
# equal bands, one for each of the 14 colors available.
#
&NCAR::cpseti( 'CLS - CONTOUR LEVEL SELECTOR', -13 );
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,23,23,14,$RWRK,1000,$IWRK,1000);
#
# Initialize the area map and put the contour lines into it.
#
&NCAR::arinam ($IAMA,20000);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IAIA,$IGIA,10,\&colram);
#
# Put black contour lines over the colored map.
#
&NCAR::gsplci (0);
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
&NCAR::gsplci (1);
#
# Draw a label bar for the plot, relating colors to values.
#
&NCAR::cpgetr( 'ZMN', my $ZMIN );
&NCAR::cpgetr( 'ZMX', my $ZMAX );
#

my @LLBS;

for my $I ( 1 .. 15 ) {
&NCAR::cpsetr( 'ZDV - Z DATA VALUE', $ZMIN+($I-1)*($ZMAX-$ZMIN)/14. );
&NCAR::cpgetc( 'ZDV - Z DATA VALUE', $LLBS[$I-1] );
}
#
&NCAR::lbseti( 'CBL - COLOR OF BOX LINES', 0 );
&NCAR::lblbar (0,.05,.95,.15,.25,14,1.,.5,$LIND,0,\@LLBS,15,1);
#
# Compute and print statistics for the plot, label it, and put a
# boundary line at the edge of the plotter frame.
#
&capsap ('EXAMPLE 7',$IAMA,12000);
&labtop ('EXAMPLE 7',.017);
&bndary;

sub colram {
  my ($XCRA,$YCRA,$NCRA,$IAIA,$IGIA,$NAIA) = @_;
#
# The arrays XCRA and YCRA, for indices 1 to NCRA, contain the X and Y
# coordinates of points defining a polygon.  The area identifiers in
# the array IAIA, each with an associated group identifier in the array
# IGIA, tell us whether the polygon is to be color-filled or not.
#
#
# Assume the polygon will be filled until we find otherwise.
#
  my $IFLL=1;
#
# If any of the area identifiers is negative, don't fill the polygon.
#
  for my $I ( 1 .. $NAIA ) {
    if( at( $IAIA, $I - 1 ) < 0 ) { $IFLL = 0; }
  }
#
# Otherwise, fill the polygon in the color implied by its area
# identifier relative to edge group 3 (the contour-line group).
#
  if( $IFLL != 0 ) {
    $IFLL = 0;
    for my $I ( 1 .. $NAIA ) {
      if( at( $IGIA, $I - 1 ) == 3 ) { $IFLL = at( $IAIA, $I - 1 ); }
    }
    if( ( $IFLL > 0 ) && ( $IFLL < 15 ) ) {
      &NCAR::gsfaci ($IFLL+1);
      &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
    }
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex07.ncgm';
