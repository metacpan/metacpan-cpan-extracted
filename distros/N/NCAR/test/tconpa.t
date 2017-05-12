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
use NCAR::Test;
use strict;
   
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# PURPOSE               To provide a simple demonstration of the use of
#                       CONPACK to contour regularly-spaced rectangular
#                       data.
#
# USAGE                 CALL TCONPA (IERR)
#
# ARGUMENTS (OUTPUT)    IERR
#
#                         An integer variable
#                         = 0, if the test was successful,
#                         = 1, otherwise
#
# I/O                   If the test is successful, the message "CONPACK
#                       TEST EXECUTED--SEE PLOTS TO CERTIFY" is printed
#                       on unit 6.  In addition, three frames are drawn
#                       on the graphics device.  In order to determine
#                       if the test was successful, it is necessary to
#                       examine these frames.
#
# PRECISION             Single.
#
# LANGUAGE              FORTRAN 77.
#
# REQUIRED ROUTINES     The AREAS, CONPACK, LABELBAR, SOFTFILL, and
#                       SPPS packages.
#
# REQUIRED GKS LEVEL    0A.
#
# ALGORITHM             The function
#
#                         Z(X,Y) = X + Y + 1./((X-.1)**2+Y**2+.09)
#                                         -1./((X+.1)**2+Y**2+.09)
#
#                       for X = -1. to 1. in increments of .1, and Y =
#                       -1.2 to 1.2 in increments of .1, is computed.
#                       Then, entries CPEZCT and CPCNRC are called to
#                       generate contour plots of Z.
#
# ZDAT contains the values to be plotted.
#
my $ZDAT = zeroes float, 21, 25;
#
# Define real and integer work spaces and an area-map array.
#
my $RWRK = zeroes float, 1000;
my $IWRK = zeroes long, 1000;
my $IAMA = zeroes long, 20000;
#
# Define arrays for use by ARSCAM.
#
my $XCRA = zeroes float, 1000;
my $YCRA = zeroes float, 1000;
my $IAIA = zeroes long, 10;
my $IGIA = zeroes long, 10;
#
# Declare the routine which will color the areas.
#
#       EXTERNAL CPCOLR
#
# Initialize the values in the aspect-source-flag array.
#
my $IASF  = long [ ( 1 ) x 13 ];
#
# Define the list of indices and the list of labels required by the
# label-bar routine.
#
my $LIND = long [ 6,7,8,9,10,11,12,13,14,15 ];
#
my @LLBS = ( '-4','-3','-2','-1',' 0',' 1',' 2',' 3',' 4' );
#
# Initialize the error parameter.
#
my $IERR = 0;
#
# Fill the 2D array to be plotted.
#
for my $I ( 1 .. 21 ) {
  my $X=.1*($I-11);
  for my $J ( 1 .. 25 ) {
    my $Y = .1*($J-13);
    set( $ZDAT, $I-1, $J-1, $X+$Y+1./(($X-.10)*($X-.10)+$Y*$Y+.09)-1./(($X+.10)*($X+.10)+$Y*$Y+.09) );
  }
}
#
# Frame 1 -- CPEZCT.
#
# The routine CPEZCT requires only the array name and dimensions.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::wtstr (.5,.9765,'DEMONSTRATION PLOT FOR CONPACK ROUTINE CPEZCT',2,0,0);
#
&NCAR::cpezct ($ZDAT,21,25);
#
# Frame 2 -- CPCNRC.
#
# The routine CPCNRC is called just like the old routine CONREC.
#
# In this example, the lowest contour level (-4.5), the highest contour
# level (4.5), and the increment between contour levels (0.3) are set.
# Line labels are positioned using the penalty scheme and the smoother
# is turned on.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::wtstr (.5,.9765,'DEMONSTRATION PLOT FOR CONPACK ROUTINE CPCNRC',2,0,0);
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',3);
&NCAR::cpsetr ('T2D - TENSION ON 2D SPLINES',3.6);
&NCAR::cpcnrc ($ZDAT,21,21,25,-4.5,4.5,.3,0,0,0);
&NCAR::frame;
#
# Frame 3 - A solid-filled contour plot.
#
# Set all the GKS aspect source flags to "individual".
#
&NCAR::gsasf ($IASF);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Define a bunch of color indices.
#
&CPCLRS($IWKID);
#
# Put a label at the top of the frame.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::wtstr (.5,.9765,'DEMONSTRATION PLOT FOR BASIC CONPACK ROUTINES',2,0,0);
#
# Force the plot into the left side of the frame.
#
&NCAR::cpsetr ('VPR - VIEWPORT RIGHT',.75);
#
# Force the use of exactly 9 contour levels, specify those levels, and
# define exactly what is to be done at each level.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTOR',0);
&NCAR::cpseti ('NCL - NUMBER OF CONTOUR LEVELS',9);
#
for my $I ( 1 .. 9 ) {
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$I);
&NCAR::cpsetr ('CLV - CONTOUR LEVEL',($I-5));
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE',1);
&NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',$I);
&NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',$I+1);
}
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,21,21,25,$RWRK,1000,$IWRK,1000);
#
# Initialize the area map and put the contour lines into it.
#
&NCAR::arinam ($IAMA,20000);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,1000,$IAIA,$IGIA,10,\&CPCOLR);
#
# Put black contour lines over the colored map.
#
&NCAR::gsplci (0);
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
&NCAR::gsplci (1);
#
# Draw a color bar for the plot.
#
&NCAR::lbseti ('CBL - COLOR OF BOX LINES',2);
&NCAR::pcsetr ('CS - CONSTANT SPACING FLAG',1.25);
&NCAR::lblbar (1,.80,.95,.05,.95,10,.5,1.,$LIND,0,\@LLBS,9,1);
#
# Advance the frame.
#
&NCAR::frame();
#
# Log a successful-completion message and return to the caller.
#
print STDERR "\n CONPACK TEST EXECUTED--SEE PLOTS TO CERTIFY\n";


sub CPCLRS {
  my ($IWKID) = @_;
#
# Define the RGB color triples needed below.
#
  my @RGBV = (
     [ 1.00 , 1.00 , 1.00 ],
     [ 0.70 , 0.70 , 0.70 ],
     [ 0.75 , 0.50 , 1.00 ],
     [ 0.50 , 0.00 , 1.00 ],
     [ 0.00 , 0.00 , 1.00 ],
     [ 0.00 , 0.50 , 1.00 ],
     [ 0.00 , 1.00 , 1.00 ],
     [ 0.00 , 1.00 , 0.60 ],
     [ 0.00 , 1.00 , 0.00 ],
     [ 0.70 , 1.00 , 0.00 ],
     [ 1.00 , 1.00 , 0.00 ],
     [ 1.00 , 0.75 , 0.00 ],
     [ 1.00 , 0.38 , 0.38 ],
     [ 1.00 , 0.00 , 0.38 ],
     [ 1.00 , 0.00 , 0.00 ],
  );
#
# Define 16 different color indices, for indices 0 through 15.  The
# color corresponding to index 0 is black and the color corresponding
# to index 1 is white.
#
  &NCAR::gscr ($IWKID,0,0.,0.,0.);
#
  for my $I ( 1 .. 15 ) {
    &NCAR::gscr ($IWKID, $I-1,@{ $RGBV[$I-1] } );
  }
#
# Done.
#
}


sub CPCOLR {
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
    if( at( $IAIA, $I-1 ) < 0 ) { $IFLL = 0; }
  }
#
# Otherwise, fill the polygon in the color implied by its area
# identifier relative to edge group 3 (the contour-line group).
#
  if( $IFLL != 0 ) {
    $IFLL=0;
    for my $I ( 1 .. $NAIA ) {
      if( at( $IGIA, $I-1 ) == 3 ) { $IFLL = at( $IAIA, $I-1 ); }
    }
    if( ( $IFLL >= 1 ) && ( $IFLL <= 10 ) ) {
      &NCAR::gsfaci ($IFLL+5);
      &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
    }
  }
#
# Done.
#
}
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
 
   
rename 'gmeta', 'ncgm/tconpa.ncgm';
