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


my $USAV = zeroes float, 1000;
my $VSAV = zeroes float, 1000;


#
# The program MPEX09 produces a set of plots showing the numbers
# of all the segments in a chosen EZMAP outline dataset.  Certain
# variables must be set in data statements at the beginning of
# the program.  In each of the seven places marked off by rows of
# dashes, un-comment the first card to do outline dataset 'CO',
# the second to do 'US', the third to do 'PO', and the fourth to
# do 'PS'.
#
#
# The common block LIMITS communicates values between TESTIT and
# the routines MAPEOD and MOVEIT.
#
my ( $ICSZ,$ULEW,$UREW,$VBEW,$VTEW,$DELU,$DELV,$NSAV );
#
# Select the outline dataset.
#
#-----------------------
my $OUTD = 'CO';
#     DATA OUTD / 'US' /
#     DATA OUTD / 'PO' /
#     DATA OUTD / 'PS' /
#-----------------------
#
# Select the projection type.
#
#-----------------------
my $PROJ = 'ME';
#     DATA PROJ / 'LC' /
#     DATA PROJ / 'ME' /
#     DATA PROJ / 'ME' /
#-----------------------
#
# Select the appropriate values of PLAT, PLON, and ROTA.
#
#------------------------------------------
my ( $PLAT,$PLON,$ROTA ) = ( 0., 0., 0. );
#     DATA PLAT,PLON,ROTA / 30.,-100.,45. /
#     DATA PLAT,PLON,ROTA /  0.,   0., 0. /
#     DATA PLAT,PLON,ROTA /  0.,   0., 0. /
#------------------------------------------
#
# Select the parameter saying how the map limits are chosen.
#
#-----------------------
my $LMTS = 'MA';
#     DATA LMTS / 'CO' /
#     DATA LMTS / 'MA' /
#     DATA LMTS / 'MA' /
#-----------------------
#
# Select the values to be put in the limits arrays.
#
#---------------------------------------------------------------
#     DATA PL1(1),PL2(1),PL3(1),PL4(1) /   0.,   0.,  0.,   0. /;
#     DATA PL1(1),PL2(1),PL3(1),PL4(1) / 22.6,-120.,46.9,-64.2 /
#     DATA PL1(1),PL2(1),PL3(1),PL4(1) /   0.,   0.,  0.,   0. /
#     DATA PL1(1),PL2(1),PL3(1),PL4(1) /   0.,   0.,  0.,   0. /
#---------------------------------------------------------------
#
#---------------------------------------------------------------
#     DATA PL1(2),PL2(2),PL3(2),PL4(2) /   0.,   0.,  0.,   0. /;
#     DATA PL1(2),PL2(2),PL3(2),PL4(2) /   0.,   0.,  0.,   0. /
#     DATA PL1(2),PL2(2),PL3(2),PL4(2) /   0.,   0.,  0.,   0. /
#     DATA PL1(2),PL2(2),PL3(2),PL4(2) /   0.,   0.,  0.,   0. /
#---------------------------------------------------------------
my $PL1 = float [ 0., 0. ];
my $PL2 = float [ 0., 0. ];
my $PL3 = float [ 0., 0. ];
my $PL4 = float [ 0., 0. ];
#
# Select values determining how the whole map is to be carved
# up into little maps.  ILIM is the number of divisions of the
# horizontal axis, JLIM the number of divisions of the vertical
# axis.  (If all the labels are put on a single map, the result
# is confusing.)
#
#---------------------------
my ( $ILIM, $JLIM ) = ( 2,2 );
#     DATA ILIM,JLIM / 3,2 /
#     DATA ILIM,JLIM / 2,2 /
#     DATA ILIM,JLIM / 6,6 /
#---------------------------
#
# Define the plot label.
#
my $PLBL = 'SEGMENT NUMBERS FOR OUTLINE DATASET XX';
#
# Finish the plot label.
#
substr( $PLBL, 36, 2, $OUTD );
#
# Set the character size; 6 is about the smallest usable value.
#
$ICSZ=6;
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU',$OUTD);
#
# Set the projection-type parameters.
#
&NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# Set the limits parameters.
#
&NCAR::mapset ($LMTS,$PL1,$PL2,$PL3,$PL4);
#
# Initialize EZMAP.
#
&NCAR::mapint();
#
# Retrieve the values with which MAPINT called SET.
#
&NCAR::getset (my ( $FLEM,$FREM,$FBEM,$FTEM,$ULEM,$UREM,$VBEM,$VTEM,$LNLG ) );
my $ILEM=&NCAR::kfpx($FLEM);
my $IREM=&NCAR::kfpx($FREM);
my $IBEM=&NCAR::kfpy($FBEM);
my $ITEM=&NCAR::kfpy($FTEM);
#
# Now, plot a set of maps which are subsets of the whole map.
#
for my $I ( 1 .. $ILIM ) {
  for my $J ( 1 .. $JLIM ) { 
    &NCAR::mapset ('LI',
         float( [ $ULEM+($UREM-$ULEM)*($I-1)/($ILIM), 0 ] ),
         float( [ $ULEM+($UREM-$ULEM)*($I  )/($ILIM), 0 ] ),
         float( [ $VBEM+($VTEM-$VBEM)*($J-1)/($JLIM), 0 ] ),
         float( [ $VBEM+($VTEM-$VBEM)*($J  )/($JLIM), 0 ] )
    );
#
# Re-initialize EZMAP with the new limits.
#
    &NCAR::mapint();
#
# Retrieve the values with which MAPINT called SET.
#
    &NCAR::getset (my $FLEW, my $FREW, my $FBEW, my $FTEW,
                   $ULEW,$UREW,$VBEW,$VTEW,$LNLG );
    my $ILEW=&NCAR::kfpx($FLEW);
    my $IREW=&NCAR::kfpx($FREW);
    my $IBEW=&NCAR::kfpy($FBEW);
    my $ITEW=&NCAR::kfpy($FTEW);
#
# Compute quantities required by MAPEOD and MOVEIT to position
# labels.
#
    $DELU=3.5*(($ICSZ)/($IREW-$ILEW))*($UREW-$ULEW);
    $DELV=2.0*(($ICSZ)/($ITEW-$IBEW))*($VTEW-$VBEW);
    $NSAV=0;
#
# Draw the outlines.
#
    &NCAR::maplot();
#
# Put a label at the top of the plot.
#
    &NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
    &NCAR::pwrit (.5,.975,$PLBL,38,2,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
    &NCAR::Test::bndary();
#
# Advance the frame.
#
    &NCAR::frame();
#
  }
}

sub Log10 {
  my $x = shift;
  return log( $x ) / log( 10 );
}

sub NCAR::mapeod {
  my ($NOUT,$NSEG,$IDLS,$IDRS,$NPTS,$PNTS) = @_;
#
# This version of MAPEOD marks each segment of the map with its
# segment number.  The resulting map may be used to set up other
# versions of MAPEOD which plot selected segments.
#
# The common block LIMITS communicates values between TESTIT and
# the routines MAPEOD and MOVEIT.
#
#     COMMON /LIMITS/ ICSZ,ULEW,UREW,VBEW,VTEW,DELU,DELV,NSAV;
#
# Define local variables to hold the character-string form of the
# segment number.
#
#
# Find out where on the map the center of the segment is.
#
  my $MPTS=int($NPTS/2+1);
  &NCAR::maptrn (at( $PNTS, 2*$MPTS-2 ),at( $PNTS, 2*$MPTS-1 ),my ( $UCEN,$VCEN ));
#
# If the center is visible, label it.
#
  if( ( $UCEN >= $ULEW ) && ( $UCEN <= $UREW ) &&
      ( $VCEN >= $VBEW ) && ( $VCEN <= $VTEW ) ) {
#
# Generate a character string representing the value of the
# segment number.
#
    my $CSG2 = sprintf( '%4d', $NSEG );
    my $NFCH=4-int(&Log10(($NSEG)+.5));
    my $NCHS=5-$NFCH;
    my $CSG1= substr( $CSG2, $NFCH-1, 4 - $NFCH + 1 );
#
# Find out where the two points on either side of the center are.
#
    $MPTS=&NCAR::Test::max(int($NPTS/2),1);
    &NCAR::maptrn (at( $PNTS, 2*$MPTS-2 ),at( $PNTS, 2*$MPTS-1 ),my ( $UCM1,$VCM1 ) );
#
    $MPTS=&NCAR::Test::min(int($NPTS/2)+2,$NPTS);
    &NCAR::maptrn (at( $PNTS, 2*$MPTS-2 ),at( $PNTS, 2*$MPTS-1 ),my ( $UCP1,$VCP1 ) );
#
# Compute the preferred position of the label, with one corner
# of its enclosing box at the center of the segment.
#
    my $ULAB=$UCEN-&NCAR::Test::sign(.1428*$DELU*($NCHS),$UCM1+$UCP1-2*$UCEN);
    my $VLAB=$VCEN-&NCAR::Test::sign(.3333*$DELV,$VCM1+$VCP1-2*$VCEN);
#
# Move the label as necessary to avoid its being on top of any
# previous label.
#
    &MOVEIT ($ULAB,$VLAB);
#
# Write out the character string and connect it to the segment
# with a straight line.
#
    &NCAR::line (
        $UCEN,
        $VCEN,
        $ULAB-&NCAR::Test::sign(.1428*$DELU*($NCHS),$ULAB-$UCEN),
        $VLAB-&NCAR::Test::sign(.3333*$DELV,$VLAB-$VCEN)
    );
#
    &NCAR::pwrit ($ULAB,$VLAB,$CSG1,$NCHS,$ICSZ,0,0);
#
   }
}


sub MOVEIT {
  my ($ULAB,$VLAB) = @_;
#
# The object of this routine is to avoid putting segment labels
# on top of each other.  (ULAB,VLAB), on entry, is the most
# desirable position for a segment label.  MOVEIT modifies this
# position as necessary to make sure the label will not be on top
# of any previous label.
#
# The common block LIMITS communicates values between TESTIT and
# the routines MAPEOD and MOVEIT.
#
# ULEW, UREW, VBEW, and VTEW specify the u/v limits of the window
# in which the map was drawn.  DELU and DELV are the minimum
# allowable distances between segment-label centers in the u
# and v directions, respectively.  NSAV is the number of label
# positions saved in the arrays USAV and VSAV.
#
#     COMMON /LIMITS/ ICSZ,ULEW,UREW,VBEW,VTEW,DELU,DELV,NSAV;
#
# Previous label positions are saved in the arrays USAV and VSAV.
#
#
# USAV and VSAV must maintain their values between calls.
#
#
# Zero the variables which control the generation of a spiral.
#
  my $IGN1=0;
  my $IGN2=2;
#
# Check for overlap at the current position.
#
L101:
  for my $I ( 1 .. $NSAV ) {
    if( ( abs( $ULAB - at( $USAV, $I-1 ) ) < $DELU ) &&
        ( abs( $VLAB - at( $VSAV, $I-1 ) ) < $DELV ) ) { goto L103; }
  }
#
# No overlap.  Save the new label position and return to caller.
#
  $NSAV=$NSAV+1;
  if( $NSAV > 1000 ) { exit( 1 ); }
  set( $USAV, $NSAV-1, $ULAB );
  set( $VSAV, $NSAV-1, $VLAB );
#
  goto RETURN;
#
# Overlap.  Try a new point.  The points tried form a spiral.
#
L103:
  $IGN1=$IGN1+1;
  if( $IGN1 <= int( $IGN2 / 2 ) ) {
    $ULAB=$ULAB+&NCAR::Test::sign($DELU,-.5+( (int($IGN2/2) % 2)));
  } else {
    $VLAB=$VLAB+&NCAR::Test::sign($DELV,-.5+( (int($IGN2/2) % 2)));
  }
  if( $IGN1 == $IGN2 ) {
    $IGN1=0;
    $IGN2=$IGN2+2;
  }
  if( ( $ULAB < $ULEW ) || ( $ULAB > $UREW ) ||
      ( $VLAB < $VBEW ) || ( $VLAB > $VTEW ) ) { goto L103; }
  goto L101;
  
  RETURN:
  ( $_[0], $_[1] ) = ( $ULAB, $VLAB );
  return;
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex09.ncgm';
