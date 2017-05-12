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
# LATEST REVISION        September, 1989
#
# PURPOSE                To provide a simple demonstration of the
#                        use of BIVAR and CONPACK together as a
#                        temporary replacement for CONRAN.
#
# PRECISION              Single.
#
# REQUIRED LIBRARY       BIVAR, CONPACK.
# FILES
#
# LANGUAGE               FORTRAN.
#
# HISTORY                Written September, 1989, by Dave Kennison.
#
# ALGORITHM              At each of nine points scattered "at random"
#                        in a portion of the x/y plane, a mathematical
#                        function is evaluated to obtain a value of z.
#                        The resulting triplets approximately describe
#                        the surface which is defined exactly by the
#                        function.  The routine BIVAR is then called to
#                        obtain an array of interpolated values of z on
#                        a regular grid, approximating the same surface,
#                        and this data is used as input to CONPACK to
#                        draw two different contour plots.
#
#                        On the first plot, contours are shown in a
#                        rectangular area containing the x/y positions
#                        of the original nine data points and those
#                        positions are marked on the plot.
#
#                        On the second plot, capabilities of CONPACK
#                        and AREAS are used to limit the drawing of
#                        contours to the convex hull of the original
#                        nine x/y positions.
#
# PORTABILITY            ANSI standard.
#
#
# Define arrays to be used below.  XRAN, YRAN, and ZRAN are used for
# the "random data".  XCNV and YCNV are used to define the convex hull
# of the x/y positions of this data.  XDAT, YDAT, and ZDAT are used for
# the regular grid of data returned by BIVAR.  IWRK and RWRK are used
# as integer and real workspace arrays, both in calls to BIVAR and in
# calls to CONPACK.
#
my $ZDAT = zeroes float, 11, 12;;
my $IWRK = zeroes long, 1000;
my $RWRK = zeroes float, 1000;
#
# Define, in a labelled common block, quantities which must be available
# to the routines CPCHHL and CPCHLL.  The flag ICLL is used to turn
# on and off the culling of labels which these routines do (it is off
# while drawing the first plot and on while drawing the second).  The
# array IAMA is the area map array.
#
my $ICLL;
my $IAMA = zeroes long, 10000;
#
# Define a temporary character variable for use below.
#
my $ICHR;
#
# Declare the routine which will draw contour lines, avoiding labels.
#
#       EXTERNAL CPDRPL
#
# Specify the X and Y input data values.
#
my $XRAN = float [ 0.4, 2.0, 2.8, 5.0, 4.8, 8.8, 5.1, 6.2, 9.1 ];
my $YRAN = float [ 5.4, 1.1, 3.7, 6.8, 9.5, 9.8, 0.7, 2.7, 3.0 ];
my $ZRAN = zeroes float, 9;
#
# Specify the Z input data values.
#
for my $I ( 1 .. 9 ) {
#         ZRAN(I)=0.2+0.4*XRAN(I)*XRAN(I)+.6*YRAN(I)*YRAN(I)
  my $xran = at( $XRAN, $I-1 );
  my $yran = at( $YRAN, $I-1 );
  set( $ZRAN, $I-1, 
       exp(-($xran-3.)*($xran-3.)/9.-($yran-5.)*($yran-5.)/25.)
     - exp(-($xran-6.)*($xran-6.)/9.-($yran-5.)*($yran-5.)/25.)
  );
}
#
# Specify the points defining the convex hull.
#
my $XCNV = float [ map { at( $XRAN, $_-1 ) } qw( 1 2 7 9 6 5 1 ) ];
my $YCNV = float [ map { at( $YRAN, $_-1 ) } qw( 1 2 7 9 6 5 1 ) ];
#
# Specify the X and Y coordinates of the points on the regular grid.
#
my $XDAT = float [ map { $_-1 } ( 1 .. 11 ) ];
my $YDAT = float [ map { $_-1 } ( 1 .. 12 ) ];
#
# Call IDSFFT to obtain a regular grid of values on the fitted surface.
#
&NCAR::idsfft (1,9,$XRAN,$YRAN,$ZRAN,11,12,11,$XDAT,$YDAT,$ZDAT,$IWRK,$RWRK);
#
# Turn off clipping.
#
&NCAR::gsclip (0);
#
# Define a set of colors to use.
#
&DFCLRS();
#
# Tell CONPACK to position labels using the "regular" scheme.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',2);
#
# Tell CONPACK to put the informational label in a different place.
#
&NCAR::cpseti ('ILP - INFORMATIONAL LABEL POSITIONING',-2);
&NCAR::cpsetr ('ILX - INFORMATIONAL LABEL X COORDINATE',.98);
&NCAR::cpsetr ('ILY - INFORMATIONAL LABEL Y COORDINATE',.02);
#
# Provide a little more room below the viewport; otherwise, the labels
# on AUTOGRAPH's X axis get squashed.
#
&NCAR::cpsetr ('VPB - VIEWPORT BOTTOM EDGE',.08);
#
# Tell CONPACK in what ranges to generate X and Y coordinates.
#
&NCAR::cpsetr ('XC1 - X COORDINATE AT I=1',0.);
&NCAR::cpsetr ('XCM - X COORDINATE AT I=M',10.);
&NCAR::cpsetr ('YC1 - Y COORDINATE AT J=1',0.);
&NCAR::cpsetr ('YCN - Y COORDINATE AT J=N',11.);
#
# Turn off the culling of labels by CPCHHL and CPCHLL.
#
$ICLL=0;
#
# Dump the polyline buffer and change the polyline color to white.
# Change the text color to orange.  CONPACK will use these colors.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (1);
&NCAR::gstxci (12);
#
# Initialize the drawing of the first contour plot.
#
&NCAR::cprect ($ZDAT,11,11,12,$RWRK,1000,$IWRK,1000);
#
# Initialize the area map which will be used to keep contour lines from
# passing through labels.
#
&NCAR::arinam ($IAMA,10000);
#
# Put label boxes in the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Draw the contour lines, masked by the area map.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&NCAR::cpdrpl);
#
# Draw all the labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Dump the polyline buffer and change the polyline color to orange.
# Change the text color to orange, too, so that the AUTOGRAPH background
# will come out entirely in that color.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (12);
&NCAR::gstxci (12);
#
# Use AUTOGRAPH to produce a background for the contour plot, forcing
# it to pick up appropriate values from CONPACK's SET call.
#
&NCAR::agseti ('SET.',4);
&NCAR::agstup (float([]),1,1,1,1,float([]),1,1,1,1);
&NCAR::agback;
#
# Dump the polyline buffer and change the polyline color to green.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (9);
#
# Change the aspect ratio of the characters drawn by PLCHMQ to make
# them approximately square.
#
&NCAR::pcsetr ('HW',1.);
#
# At each of the "random" data positions, put the index of the point
# and a starburst to set it off.
#
for my $I ( 1 .. 9 ) {
   my $ICHR=chr(ord('0')+$I);
   my $xran = at( $XRAN, $I-1 );
   my $yran = at( $YRAN, $I-1 );
   &NCAR::plchmq ($xran,$yran,$ICHR,.0175,0.,0.);
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)-.02),
      &NCAR::cfuy(&NCAR::cufy($yran)-.02),
      &NCAR::cfux(&NCAR::cufx($xran)-.01),
      &NCAR::cfuy(&NCAR::cufy($yran)-.01)
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)+.01),
      &NCAR::cfuy(&NCAR::cufy($yran)+.01),
      &NCAR::cfux(&NCAR::cufx($xran)+.02),
      &NCAR::cfuy(&NCAR::cufy($yran)+.02)
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)-.02),
      &NCAR::cfuy(&NCAR::cufy($yran)+.02),
      &NCAR::cfux(&NCAR::cufx($xran)-.01),
      &NCAR::cfuy(&NCAR::cufy($yran)+.01)
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)+.01),
      &NCAR::cfuy(&NCAR::cufy($yran)-.01),
      &NCAR::cfux(&NCAR::cufx($xran)+.02),
      &NCAR::cfuy(&NCAR::cufy($yran)-.02)
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)-.02828),
      &NCAR::cfuy(&NCAR::cufy($yran)),
      &NCAR::cfux(&NCAR::cufx($xran)-.01414),
      &NCAR::cfuy(&NCAR::cufy($yran))
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)+.01414),
      &NCAR::cfuy(&NCAR::cufy($yran)),
      &NCAR::cfux(&NCAR::cufx($xran)+.02828),
      &NCAR::cfuy(&NCAR::cufy($yran))
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)),
      &NCAR::cfuy(&NCAR::cufy($yran)-.02828),
      &NCAR::cfux(&NCAR::cufx($xran)),
      &NCAR::cfuy(&NCAR::cufy($yran)-.01414)
   );
   &NCAR::line (
      &NCAR::cfux(&NCAR::cufx($xran)),
      &NCAR::cfuy(&NCAR::cufy($yran)+.01414),
      &NCAR::cfux(&NCAR::cufx($xran)),
      &NCAR::cfuy(&NCAR::cufy($yran)+.02828)
   );
}
#
# Dump the polyline buffer and switch the polyline color to yellow.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (11);
#
# Put a label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq (.5,.975,'DEMONSTRATING THE USE OF BIVAR AND CONPACK',.012,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
# Do another frame.  First, turn on the culling of labels by the
# routines CPCHHL and CPCHLL (which see, below).
#
$ICLL=1;
#
# Dump the polyline buffer and switch the polyline color back to white.
# Force the text color index to orange.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (1);
&NCAR::gstxci (12);
#
# Initialize the drawing of the second contour plot.
#
&NCAR::cprect ($ZDAT,11,11,12,$RWRK,1000,$IWRK,1000);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,10000);
#
# Put the convex hull of the "random" data in the area map, using group
# identifier 4, an area identifier of 0 inside the hull, and an area
# identifier of -1 outside the hull.
#
&NCAR::aredam ($IAMA,$XCNV,$YCNV,7,4,0,-1);
#
# Put label boxes in the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Draw contour lines, masked by the area map.

&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&NCAR::cpdrpl);
#
# Draw labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Dump the polyline buffer and switch the polyline color to orange.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (12);
#
# Use AUTOGRAPH to draw a background.
#
&NCAR::agseti ('SET.',4);
&NCAR::agstup (float([]),1,1,1,1,float([]),1,1,1,1);
&NCAR::agback;
#
# Dump the polyline buffer and switch the polyline color to yellow.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gsplci (11);
#
# Draw a label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq (.5,.975,'DEMONSTRATING THE USE OF BIVAR AND CONPACK',.012,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();

sub DFCLRS {
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
  &NCAR::gscr (1,0,0.,0.,0.);
#
  for my $I ( 1 .. 15 ) {
    &NCAR::gscr (1,$I-1,@{ $RGBV[$I-1] });
  }
#
# Done.
#
}


sub NCAR::cpchhl {
  my ($IFLG) = @_;
#
# This version of CPCHHL, if and only if ICLL is non-zero, examines a
# high/low label which is about to be drawn.  If that label would fall
# in an area outside the convex hull defined by edge group 4, the text
# of the label is changed to a blank, so that the label is effectively
# deleted.
#
  my $IAAI = zeroes long, 10;
  my $IAGI = zeroes long, 10;
  if( $ICLL == 0 ) { return; }
  if( ( ( $IFLG >= 2 ) && ( $IFLG <= 4 ) ) ||
      ( ( $IFLG >= 6 ) && ( $IFLG <= 8 ) ) ) {
    &NCAR::cpgetr ('LBX',my $XPOS);
    &NCAR::cpgetr ('LBY',my $YPOS);
    &NCAR::argtai ($IAMA,$XPOS,$YPOS,$IAAI,$IAGI,10,my $NAIR,1);
    my $IVIS=1;
    for my $I ( 1 .. $NAIR ) {
      if( ( at( $IAGI, $I-1 ) == 4 ) && ( at( $IAAI, $I-1 ) < 0 ) ) { $IVIS=0; }
    }
    if( $IVIS == 0 ) {
      &NCAR::cpsetc ('CTM',' ');
    }
  }
}


sub NCAR::cpchll {
  my ($IFLG) = @_;
#
# This version of CPCHLL, if and only if ICLL is non-zero, examines a
# contour-line label which is about to be drawn.  If that label would
# fall in an area outside the convex hull defined by edge group 4, the
# text of the label is changed to a blank, so that it is effectively
# deleted.
#
  my $IAAI = zeroes long, 10;
  my $IAGI = zeroes long, 10;
  if( $ICLL == 0 ) { return; }
  if( ( $IFLG >= 2 ) && ( $IFLG <= 4 ) ) { 
    &NCAR::cpgetr ('LBX',my $XPOS);
    &NCAR::cpgetr ('LBY',my $YPOS);
    &NCAR::argtai ($IAMA,$XPOS,$YPOS,$IAAI,$IAGI,10,my $NAIR,1);
    my $IVIS=1;
    for my $I ( 1 .. $NAIR ) {
      if( ( at( $IAGI, $I-1 ) == 4 ) && ( at( $IAAI, $I-1 ) < 0 ) ) { $IVIS=0; }
    }
    if( $IVIS == 0 ) {
      &NCAR::cpsetc ('CTM',' ');
    }
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/cbex01.ncgm';
