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
use NCAR::Test qw( bndary min max gendat labtop capsap shader drawcl );
use strict;
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
# This program produces a detailed picture of the contents of a typical
# CONPACK-produced area map.  It then shows three different situations
# that tend to cause problems.  This example is intended to be viewed
# while reading the text from the programmer document for CONPACK that
# describes each of the four frames.
#
#
# Define various local parameters.
#
my ( $LRWK, $LIWK, $LAMA, $NCLV ) = ( 5000, 5000, 20000, 4 );
#
# Declare the basic data array, a real workspace array, and an integer
# workspace array.
#
my $ZDAT = zeroes float, 7, 7;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
#
# Declare a bigger data array to use for rho/theta data.
#
my $RHTH = zeroes float, 10, 25;
#
# Declare an area-map array.
#
my $IAMA = zeroes long, $LAMA;
#
# Define the contour levels at which contours are to be generated.
#
my @CLEV = ( .25,.52,.90,1.40 );
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Set internal parameters of AREAS that affect the appearance of the
# debug plots produced by ARDBPX.
#
&NCAR::arsetr ('ID - IDENTIFIER DISTANCE',.008);
&NCAR::arsetr ('IS - IDENTIFIER SIZE',.008);
&NCAR::arsetr ('AL - ARROWHEAD LENGTH',0.);
&NCAR::arsetr ('AW - ARROWHEAD WIDTH',0.);
#
# Tell the dash package to use alternating solids and gaps.  This
# pattern will be used for the circles on frame 3.
#
&NCAR::dpsetc ('DPT - DASH PATTERN','$_');
#
# Tell PLOTCHAR to use font number 25 (a filled font) and to outline
# each character.
#
&NCAR::pcseti ('FN - FONT NUMBER',25);
&NCAR::pcseti ('OF - OUTLINE FLAG',1);
#
# Tell PLOTCHAR to tell the Bezier package to reproduce the curves
# outlining the characters with a little less fidelity.  This cuts
# down on the size of the metafile.
#
&NCAR::pcsetr ('FB - FIDELITY OF BEZIER CURVES',.00015);
#
#
# ***** FIRST FRAME BEGINS ********************************************
#
# Put a label at the top of the first frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.98),
   'A DETAILED VIEW OF A CONPACK AREA MAP (EDGE GROUP 3)',
   .015,0.,0.);
#
# Put informative labels at the top and bottom of the frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.95),
   'This is a simple case that demonstrates all the essential features of a CONPACK area map.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.926),
   'All the edge segments in group 3 are shown, each with its own left and right area identifiers.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.062),
   'See the CONPACK programmer document for a complete description of this area map.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.038),
   'Also see the frames that follow for examples of situations in which problems can arise.',
  .012,0.,0.);
#
# Define the mapping from the "user" system to the fractional system.
#
&NCAR::set    (.05,.95,.05,.95,-.1,1.1,-.1,1.1,1);
#
# Tell CONPACK not to call SET.
#
&NCAR::cpseti ('SET - DO-SET-CALL FLAG',0);
#
# Tell CONPACK to map output coordinates.  Included below is a special
# version of CPMPXY that, when 'MAP' = 1, does an identity mapping, but
# generates some out-of-range values.
#
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
#
# Tell CONPACK what to expect as an out-of-range value in the output
# from CPMPXY.
#
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
# Tell CONPACK not to select contour levels.  We'll do it.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTION METHOD',0);
#
# Tell CONPACK how many contour levels to use and exactly what those
# levels are.
#
&NCAR::cpseti ('NCL - NUMBER OF CONTOUR LEVELS',$NCLV);

for my $ICLV ( 1 .. $NCLV ) {
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$ICLV);
  &NCAR::cpsetr ('CLV - CONTOUR LEVEL',$CLEV[$ICLV-1]);
  &NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',3);
}
#
# Tell CONPACK to position line labels using the regular scheme and
# modify a few parameters so as to get labels in particular places.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',2);
#
&NCAR::cpsetr ('RC1 - REGULAR SCHEME CONSTANT 1',.55);
&NCAR::cpsetr ('RC2 - REGULAR SCHEME CONSTANT 2',.85);
&NCAR::cpsetr ('RC3 - REGULAR SCHEME CONSTANT 3',0.);
#
&NCAR::cpsetr ('CWM - CHARACTER WIDTH MULTIPLIER',3.);
#
# Get rid of the informational label.
#
&NCAR::cpsetc ('ILT - INFORMATIONAL LABEL TEXT',' ');
#
# Tell CONPACK how to map the data grid into coordinates to be
# delivered to CPMPXY.
#
&NCAR::cpsetr ('XC1 - X COORDINATE FOR I = 1',0.);
&NCAR::cpsetr ('XCM - X COORDINATE FOR I = M',1.);
&NCAR::cpsetr ('YC1 - Y COORDINATE FOR J = 1',0.);
&NCAR::cpsetr ('YCN - Y COORDINATE FOR J = N',1.);
#
# Tell CONPACK what value is used in the data as a special value.
#
&NCAR::cpsetr ('SPV - SPECIAL VALUE',1.E36);
#
# Generate a simple two-dimensional data field.
#
for my $I ( 1 .. 7 ) {
  my $XCRD = ($I-1)/6.;
  for my $J ( 1 .. 7 ) {
     my $YCRD=($J-1)/6.;
     set( $ZDAT, $J-1, $I-1, $XCRD*$XCRD + $YCRD*$YCRD );
  }
}
#
# Put some special values in the lower left corner of the data field.
#
set( $ZDAT, 0, 0, 1.E36 );
set( $ZDAT, 0, 1, 1.E36 );
set( $ZDAT, 1, 0, 1.E36 );
set( $ZDAT, 1, 1, 1.E36 );
#
# Tell CONPACK the dimensions of its data array, the real workspace
# array, and the integer workspace array, so that it can initialize
# itself to work with those arrays.
#
&NCAR::cprect ($ZDAT,7,7,7,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Put into the area map the viewport perimeter, the boundary of the
# "invisible" area (the area in which CPMPXY returns the value 'ORV'),
# the edge of the grid, the edges of the special-value areas, and the
# contour lines.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Put the label boxes into the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Call a modified version of the AREAS routine ARDBPA to draw the
# contents of the area map.
#
&ARDBPX ($IAMA,3);
#
# Label features of interest on the plot.
#
&NCAR::plchhq (
   &NCAR::cfux(.90),
   &NCAR::cfuy(.11),
   'EDGE OF PLOTTER FRAME  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.86),
   &NCAR::cfuy(.15),
   'EDGE OF VIEWPORT  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.32),
   'EDGE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.30),
   'OF',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.28),
   'GRID',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.34),
   'THIS IS A',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.32),
   'SPECIAL-VALUE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.30),
   'AREA, IN WHICH ALL',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.28),
   'DATA VALUES ARE ',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.26),
   'EQUAL TO \'SPV\'',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.83),
   'IN THIS AREA,',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.81),
   'CPMPXY RETURNS',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.79),
   'COORDINATE VALUES',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.77),
   'EQUAL TO \'ORV\'; AREA',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.75),
   'IS INVISIBLE UNDER',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.73),
   'MAPPING',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.505),
   &NCAR::cfuy(.61),
   'HERE ARE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.505),
   &NCAR::cfuy(.59),
   'TWO',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.505),
   &NCAR::cfuy(.57),
   'LABEL BOXES',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.28),
   &NCAR::cfuy(.43),
   'CONTOUR BAND 1',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.53),
   'CONTOUR BAND 2',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.36),
   &NCAR::cfuy(.67),
   'CONTOUR BAND 3',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.52),
   &NCAR::cfuy(.75),
   'CONTOUR BAND 4',
    .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.48),
   &NCAR::cfuy(.30),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.48),
   &NCAR::cfuy(.28),
   '(LEVEL 1)',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.62),
   &NCAR::cfuy(.31),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.62),
   &NCAR::cfuy(.29),
   '(LEVEL 2)',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.73),
   &NCAR::cfuy(.40),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.73),
   &NCAR::cfuy(.38),
   '(LEVEL 3)',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.745),
   &NCAR::cfuy(.615),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.745),
   &NCAR::cfuy(.596),
   '(LEVEL 4)',
   .008,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
#
# ***** SECOND FRAME BEGINS *******************************************
#
# Put a label at the top of the second frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.98),
   'CONPACK AREA MAPS - FRAME 2',
   .015,0.,0.);
#
# Put informative labels at the top and bottom of the frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.95),
   'This frame shows what happens when CPMPXY can\'t do inverses (or incorrectly says it can\'t).',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.926),
   'The algorithm that generates the edge of the invisible area doesn\'t work so well then.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.062),
   'In this case, the effects aren\'t too bad; more serious effects are sometimes seen.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.038),
   'See the CONPACK programmer document for a complete discussion of this problem.',
   .012,0.,0.);
#
# Change to mapping function 2 to illustrate the problem with a CPMPXY
# that doesn't do inverses.  'MAP' = 2 is just like 'MAP' = 1 except
# that it doesn't do inverses.
#
&NCAR::cpseti ('MAP - MAPPING FLAG',2);
#
# Tell CONPACK the dimensions of its data array, the real workspace
# array, and the integer workspace array, so that it can initialize
# itself to work with those arrays.
#
&NCAR::cprect ($ZDAT,7,7,7,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Put into the area map the viewport perimeter, the boundary of the
# "invisible" area (the area in which CPMPXY returns the value 'ORV'),
# the edge of the grid, the edges of the special-value areas, and the
# contour lines.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Put the label boxes into the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Call a modified version of the AREAS routine ARDBPA to draw the
# contents of the area map.
#
&ARDBPX ($IAMA,3);
#
# Label features of interest on the plot.
#
&NCAR::plchhq (
   &NCAR::cfux(.90),
   &NCAR::cfuy(.11),
   'EDGE OF PLOTTER FRAME  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.86),
   &NCAR::cfuy(.15),
   'EDGE OF VIEWPORT  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.32),
   'EDGE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.30),
   'OF',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.28),
   'GRID',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.31),
   'SPECIAL-VALUE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.29),
   'AREA',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.78),
   'INVISIBLE AREA',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.505),
   &NCAR::cfuy(.59),
   'LABEL BOXES',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.28),
   &NCAR::cfuy(.43),
   'CONTOUR BAND 1',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.53),
   'CONTOUR BAND 2',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.36),
   &NCAR::cfuy(.67),
   'CONTOUR BAND 3',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.52),
   &NCAR::cfuy(.75),
   'CONTOUR BAND 4',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.48),
   &NCAR::cfuy(.30),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.48),
   &NCAR::cfuy(.28),
   'AT LEVEL 1',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.62),
   &NCAR::cfuy(.31),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.62),
   &NCAR::cfuy(.29),
   'AT LEVEL 2',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.73),
   &NCAR::cfuy(.40),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.73),
   &NCAR::cfuy(.38),
   'AT LEVEL 3',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.745),
   &NCAR::cfuy(.615),
   'CONTOUR',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.745),
   &NCAR::cfuy(.596),
   'AT LEVEL 4',
   .008,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
#
# ***** THIRD FRAME BEGINS ********************************************
#
# Put a label at the top of the third frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.98),
   'CONPACK AREA MAPS - FRAME 3',
   .015,0.,0.);
#
# Put informative labels at the top and bottom of the frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.95),
   'Sometimes a segment of a contour line is parallel to and just barely inside the edge of the grid.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.926),
   'The dashed circles in the area map below show the locations of two such contour-line segments.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.074), 
   'Prior to version 4, the outer area identifier for such a segment could "leak" outside the grid.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.050),
   'Now, conflicting information from near-coincident segments is resolved in such a way as to avoid problems.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.026),
   'See the CONPACK programmer document for a complete discussion of this problem.',
    .012,0.,0.);
#
# Change the mapping back to what it was on the first frame.
#
&NCAR::cpseti ('MAP - MAPPING FLAG',1);
#
# Generate data. The value "4.984615" has been carefully chosen to
# create the problem.
#
for my $I ( 1 .. 7 ) {
  my $XCRD=($I-1)/6.;
  for my $J ( 1 .. 7 ) {
    my $YCRD=($J-1)/6.;
    set( $ZDAT, $J-1, $I-1, 
          4.984615*(
             ($XCRD-.58333333)*($XCRD-.58333333)
            +($YCRD-.58333333)*($YCRD-.58333333)
          )
    );
  }
}
#
# Salt in some special values.
#
set( $ZDAT, 0, 0, 1.E36 );
set( $ZDAT, 0, 1, 1.E36 );
set( $ZDAT, 1, 0, 1.E36 );
set( $ZDAT, 1, 1, 1.E36 );
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Tell CONPACK the dimensions of its data array, the real workspace
# array, and the integer workspace array, so that it can initialize
# itself to work with those arrays.
#
&NCAR::cprect ($ZDAT,7,7,7,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Put into the area map the viewport perimeter, the boundary of the
# "invisible" area (the area in which CPMPXY returns the value 'ORV'),
# the edge of the grid, the edges of the special-value areas, and the
# contour lines.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Call a modified version of the AREAS routine ARDBPA to draw the
# contents of the area map.
#
&ARDBPX ($IAMA,3);
#
# Draw a couple of circles around the problem areas.
#
&CIRCLE (.1+.8*&NCAR::cufx(.58333333),.1+.8*&NCAR::cufy(1.),.065);
&CIRCLE (.1+.8*&NCAR::cufx(1.),.1+.8*&NCAR::cufy(.58333333),.065);
#
# Label features of interest on the plot.
#
&NCAR::plchhq (
   &NCAR::cfux(.90),
   &NCAR::cfuy(.11),
   'EDGE OF PLOTTER FRAME  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.86),
   &NCAR::cfuy(.15),
   'EDGE OF VIEWPORT  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.31),
   'EDGE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.29),
   'OF',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.80),
   &NCAR::cfuy(.27),
   'GRID',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.31),
   'SPECIAL-VALUE',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.30),
   &NCAR::cfuy(.29),
   'AREA',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.77),
   &NCAR::cfuy(.78),
   'INVISIBLE AREA',
   .008,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
#
# ***** FOURTH FRAME BEGINS *******************************************
#
# Put a label at the top of the fourth frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.98),
   'CONPACK AREA MAPS - FRAME 4',
   .015,0.,0.);
#
# Put informative labels at the top and bottom of the frame.
#
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.95),
   'Some mappings transform two different parts of the grid to the same place in user coordinate space.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.926),
   'The :F33:r/q:F: mapping used here maps the grid into a doughnut; left and right edges map to the same line.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.074),
   'Similarly, EZMAP frequently maps the left and right edges of the grid into the same great circle.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.050), 
   'This can sometimes cause area identifiers for the outside of the grid to appear to apply to the inside.',
   .012,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.5),
   &NCAR::cfuy(.026),
   'See the CONPACK programmer document for a complete discussion of this problem.',
   .012,0.,0.);
#
# Redefine the mapping from the user system to the fractional system.
#
&NCAR::set    (.05,.95,.05,.95,-1.1,1.1,-1.1,1.1,1);
#
# Change the mapping function to be used.  For 'MAP' = 3, we get a
# standard rho/theta mapping.
#
&NCAR::cpseti ('MAP - MAPPING FLAG',3);
#
# Tell CONPACK that no out-of-range values will be returned.
#
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',0.);
#
# Change the X and Y values assumed to correspond to the edges of the
# data grid.
#
&NCAR::cpsetr ('XC1 - X COORDINATE FOR I = 1',.3);
&NCAR::cpsetr ('XCM - X COORDINATE FOR I = M',1.);
&NCAR::cpsetr ('YC1 - Y COORDINATE FOR J = 1',  0.);
&NCAR::cpsetr ('YCN - Y COORDINATE FOR J = N',360.);
#
# Generate rho/theta data.
#
for my $I ( 1 .. 10 ) {
  my $RHO=.3+.07*$I;
  for my $J ( 1 .. 25 ) {
    my $THETA=.017453292519943*(15*$J-15);
    set( $RHTH, $I-1, $J-1, 2.*$RHO*cos($THETA)*cos($THETA)+$RHO*sin($THETA)*sin($THETA) );
  }
}
#
# Tell CONPACK the dimensions of its data array, the real workspace
# array, and the integer workspace array, so that it can initialize
# itself to work with those arrays.
#
&NCAR::cprect ($RHTH,10,10,25,$RWRK,$LRWK,$IWRK,$LIWK);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$LAMA);
#
# Put into the area map the viewport perimeter, the  edge of the grid,
# the edges of the special-value areas, and the contour lines.
#
&NCAR::cpclam ($RHTH,$RWRK,$IWRK,$IAMA);
#
# Call a modified version of the AREAS routine ARDBPA to draw the
# contents of the area map.
#
&ARDBPX ($IAMA,3);
#
# Label features of interest on the plot.
#
&NCAR::plchhq (
   &NCAR::cfux(.90),
   &NCAR::cfuy(.11),
   'EDGE OF PLOTTER FRAME  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.86),
   &NCAR::cfuy(.15),
   'EDGE OF VIEWPORT  ',
   .008,0.,1.);
#
&NCAR::plchhq (
   &NCAR::cfux(.24),
   &NCAR::cfuy(.83),
   'UPPER EDGE OF',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.24),
   &NCAR::cfuy(.81),
   'DATA GRID MAPS',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.24),
   &NCAR::cfuy(.79),
   'TO OUTER CIRCLE',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.50),
   &NCAR::cfuy(.52),
   'LOWER EDGE OF',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.50),
   &NCAR::cfuy(.50),
   'DATA GRID MAPS',
    .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.50),
   &NCAR::cfuy(.48),
   'TO INNER CIRCLE',
   .008,0.,0.);
#
&NCAR::plchhq (
   &NCAR::cfux(.76),
   &NCAR::cfuy(.83),
   'LEFT AND RIGHT EDGES',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.76),
   &NCAR::cfuy(.81),
   'OF DATA GRID MAP TO',
   .008,0.,0.);
&NCAR::plchhq (
   &NCAR::cfux(.76),
   &NCAR::cfuy(.79),
   'HORIZONTAL LINE',
    .008,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();



sub NCAR::cpmpxy {
  my ($IMAP,$XINP,$YINP,$XOTP,$YOTP) = @_;
#
# When 'MAP' = 1, this version of CPMPXY just does the identity mapping
# and its inverse except in the upper right corner, in which it returns
# the out-of-range value (for illustrative purposes).
#
# Using 'MAP' = 2 is the same except that the routine says that it can't
# do the inverse mapping (IMAP = 0 and XINP = 1 gives YINP = 1 instead
# of 3).  This is used to show the adverse effects on the generation of
# the edge of the area invisible under the mapping.
#
# Using 'MAP' = 3 gives the polar coordinate transformation and its
# inverse.  No out-of-range values can be returned.
#
  if( $IMAP == 0 ) {
    if( $XINP == 1 ) {
      $YINP = 3.;
    } elsif( $XINP == 2 ) {
      $YINP = 1.;
    } elsif( $XINP == 2 ) {
      $YINP=1.;
    } elsif( $XINP == 3 ) {  
      $YINP=3.;
    } else {
      $YINP=3.;
    }
  } elsif( ( abs( $IMAP ) == 1 ) || ( abs( $IMAP ) == 2 ) ) {
    if( ( ($XINP-1.)*($XINP-1.)+($YINP-1.)*($YINP-1.) ) > .0625 ) { 
      $XOTP=$XINP;
      $YOTP=$YINP;
    } else {
      $XOTP=1.E12;
      $YOTP=1.E12;
    }
  } elsif( abs( $IMAP ) == 3 ) {
    if( $IMAP > 0 ) {
      $XOTP=$XINP*cos(.017453292519943*$YINP);
      $YOTP=$XINP*sin(.017453292519943*$YINP);
    } else {
      $XOTP=sqrt($XINP*$XINP+$YINP*$YINP);
      $YOTP=57.2957795130823*atan2($YINP,$XINP);
    }
  } else {
     $XOTP=$XINP;
     $YOTP=$YINP;
  }
  RETURN:
  ( $_[1], $_[2], $_[3], $_[4] ) = 
  ( $XINP, $YINP, $XOTP, $YOTP );  
  return;
#
# Done.
#
}

sub ARDBPX {
  my ($IAMA,$IGIP) = @_;
#
# The routine ARDBPX produces a picture of that part of the contents of
# the area map IAMA that belongs to the group IGIP; if IGIP is zero or
# negative, all groups of edges are shown.  This is a modified version
# of the AREAS routine ARDBPA.  No label is written at the top.  All
# color-setting and error-recovery code has been removed.  The code
# computing RXCN and RYCN has been changed to force the picture into
# a smaller square than the whole plotter frame (so that labels near
# the edge are readable and there is room for additional labels at top
# and bottom).
#
# The common block ARCOM1 is used to communicate with the arrow-drawing
# routine ARDBDA.
#
  use NCAR::COMMON qw( %ARCOM1 );
#
# Bump the line width by a factor of two.
#
  &NCAR::gslwsc (2.);
#
# Extract the length of the area map.
#
  my $LAMA= at( $IAMA, 0 );
#
# Save the current state of the SET call and switch to the fractional
# coordinate system.
#
  &NCAR::getset ( my ( $XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG ) );
  &NCAR::set (  0.,  1.,  0.,  1.,  0.,  1.,  0.,  1.,   1);
#
# Trace the edges in the area map, drawing arrows as we go.
#
  $ARCOM1{DT}=0.;
  my $INDX=8;
  my $RXCN=.5;
  my $RYCN=.5;
#
L101:
  my $RXCO=$RXCN;
  my $RYCO=$RYCN;
#
  $RXCN=.1+.8*(at( $IAMA, $INDX  ))/1000000.;
  $RYCN=.1+.8*(at( $IAMA, $INDX+1))/1000000.;
#
  if( at( $IAMA, $INDX+6 ) != 0 ) {
    my $IGID=abs(at( $IAMA, $INDX+6));
    if( $IGID < at( $IAMA, 5 ) ) {
      $IGID=at( $IAMA, at( $IAMA, 0 ) - $IGID - 1 )/2;
    } else {
      $IGID=at( $IAMA, $IGID - 1 )/2;
    }
    if( ( $IGIP <= 0 ) || ( $IGID == $IGIP ) ) {
      my $IAIL = at( $IAMA, $INDX+7 );
      if( $IAIL > 0 ) { $IAIL = at( $IAMA, $IAIL-1 ) / 2; }
      my $IAIR = at( $IAMA, $INDX+8 );
      if( $IAIR > 0 ) { $IAIR = at( $IAMA, $IAIR-1 ) / 2; }
      &NCAR::ardbda ($RXCO,$RYCO,$RXCN,$RYCN,$IAIL,$IAIR,$IGIP,$IGID);
    }
  } else {
    $ARCOM1{DT} = 0.;
  }
#
  if( at( $IAMA, $INDX+2 ) != 0 ) {
     $INDX = at( $IAMA, $INDX+2 );
     goto L101;
  }
#
# Restore the original SET call.
#
  &NCAR::set ($XVPL,$XVPR,$YVPB,$YVPT,$XWDL,$XWDR,$YWDB,$YWDT,$LNLG);
#
# Set the line width back to normal.
#
  &NCAR::gslwsc (1.);
#
# Done.
#
}


sub CIRCLE {
  my ($XCEN,$YCEN,$RADC) = @_;
#
# This routine draws a circle with center (XCEN,YCEN) and radius RADC.
# All input variables are stated in the fractional system.
#
  &NCAR::dpdraw ($XCEN+$RADC,$YCEN,0);
#
  for my $I ( 1 .. 90 ) {
    my $ANGR=.017453292519943*(4*$I);
    &NCAR::dpdraw ($XCEN+$RADC*cos($ANGR),$YCEN+$RADC*sin($ANGR),1);
  }
#
  &NCAR::dpdraw (0.,0.,2);
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/cpex13.ncgm';
