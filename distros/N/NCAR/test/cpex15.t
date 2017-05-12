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
# This program demonstrates how user-supplied versions of the "user
# callback" routines CPCHHL and CPCHLL may be used to change various
# aspects of individual high/low labels and contour-line labels on a
# contour plot.  In particular, it shows how to prevent such labels
# from appearing in a portion of the plotter frame where contour lines
# are suppressed (by masking against the contents of an area map).
#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 70, 70;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# Declare an array to hold an area map.  Put in a common block so we
# can get at it from the routines CPCHHL and CPCHLL.
#
my $IAMA = zeroes long, 200000;
#
# Declare the arrays needed by ARSCAM and MAPGRM for x/y coordinates.
#
my $XCRA = zeroes float, 10000;
my $YCRA = zeroes float, 10000;
#
# Declare the arrays needed by ARSCAM and MAPGRM for area and group
# identifiers.
#
my $IARA = zeroes long, 10;
my $IGRA = zeroes long, 10;
#
# Declare the routine that draws contour lines, avoiding labels.
#
#       EXTERNAL DRAWCL
#
# Declare the routine that does the shading of a contour band.
#
#       EXTERNAL SHADER
#
# Declare the routine that fills the EZMAP background.
#
#       EXTERNAL FILLEB
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Define colors to use for various purposes.
#
&NCAR::gscr   (1,2,.5,.5,1.);  #  light blue (for labels)
&NCAR::gscr   (1,3,1.,1.,.5);  #  light yellow (for labels)
&NCAR::gscr   (1,4,1.,.5,.5);  #  light red (for labels)
&NCAR::gscr   (1,5,1.,1.,1.);  #  white (for land areas)
&NCAR::gscr   (1,6,.6,.6,.6);  #  gray (for ocean areas)
#
# Generate an array of test data.
#
my @t;
open DAT, "<data/cpex15.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 70 ) {
  for my $I ( 1 .. 70 ) {
    set( $ZDAT, $I-1, $J-1, shift( @t ) );
  }
}
#
# Put some labels at the top of the plot.
#
&NCAR::plchhq (.5,.982,'CONPACK EXAMPLE 15',.018,0.,0.);
#
&NCAR::plchhq (.5,.952,'The routines CPCHHL and CPCHLL are used below to suppress labels over land.',.012,0.,0.);
#
&NCAR::plchhq (.5,.928,'They are also used to modify colors and line widths used for the labels.',.012,0.,0.);
#
# Initialize EZMAP.
#
&NCAR::mapsti ('LA - LABELS',0);  #  no labels
&NCAR::mapsti ('PE - PERIMETER',0);  #  no perimeter
&NCAR::mappos (.05,.95,.01,.91);  #  positions the map;
&NCAR::maproj ('OR - ORTHOGRAPHIC',40.,-135.,0.);  #  projection
&NCAR::mapset ('MA - MAXIMAL AREA',
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] ),
               float( [ 0., 0. ] )
	       );  #  map portion
#
&NCAR::mapint();  #  initialize;
#
# Tell CONPACK to do no SET call (EZMAP has done it).
#
&NCAR::cpseti ('SET - DO-SET-CALL FLAG',0);
#
# Tell CONPACK to use more contour levels.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTOR',32);
#
# Tell CONPACK to position labels using the "regular" scheme.
#
&NCAR::cpseti ('LLP - LINE LABEL POSITIONING',2);
#
# Tweak constants so as to get more labels on each labeled contour.
#
&NCAR::cpsetr ('RC1 - REGULAR SCHEME CONSTANT 1',.05);
&NCAR::cpsetr ('RC2 - REGULAR SCHEME CONSTANT 2',.1);
&NCAR::cpsetr ('RC3 - REGULAR SCHEME CONSTANT 3',0.);
#
# Provide a little more workspace for X and Y coordinates defining
# contour lines, so as not to have labels right next to each other
# on a contour line.
#
&NCAR::cpseti ('RWC - REAL WORKSPACE FOR CONTOURS',200);
#
# Turn on drawing and filling of the high and low label boxes.
#
&NCAR::cpseti ('HLB - HIGH/LOW LABEL BOX FLAG',3);
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label or another high/low label, but to move those which overlap the
# edge inward a little.
#
&NCAR::cpseti ('HLO - HIGH/LOW LABEL OVERLAP FLAG',11);
#
# Turn on drawing and filling of the contour line label boxes.
#
&NCAR::cpseti ('LLB - LINE LABEL BOX FLAG',3);
#
# Make all CONPACK-written characters a little smaller.
#
&NCAR::cpsetr ('CWM - CHARACTER WIDTH MULTIPLIER',.8);
#
# Turn on the drawing of the grid edge ("contour line number -1") and
# thicken it somewhat.
#
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',-1);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',1);
&NCAR::cpsetr ('CLL - CONTOUR LEVEL LINE WIDTH',2.);
#
# Tell CONPACK to use EZMAP for mapping and what the out-of-range
# signal is.
#
&NCAR::cpseti ('MAP - MAPPING FUNCTION',1);
&NCAR::cpsetr ('ORV - OUT-OF-RANGE VALUE',1.E12);
#
# Tell CONPACK what range of coordinates to use.
#
&NCAR::cpsetr ('XC1 - LONGITUDE AT I = 1',-230.);
&NCAR::cpsetr ('XCM - LONGITUDE AT I = M',- 40.);
&NCAR::cpsetr ('YC1 - LATITUDE AT J = 1' ,- 35.);
&NCAR::cpsetr ('YCN - LATITUDE AT J = N' ,  75.);
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,70,70,70,$RWRK,5000,$IWRK,1000);
#
# Force the selection of contour levels so that associated quantities
# may be tweaked.
#
&NCAR::cppkcl ($ZDAT,$RWRK,$IWRK);
#
# Increase the line width for labelled levels and turn off the area
# identifiers for all levels.
#
&NCAR::cpgeti ('NCL - NUMBER OF CONTOUR LEVELS',my $NCLV);
#
for my $ICLV ( 1 .. $NCLV ) {
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$ICLV);
  &NCAR::cpgeti ('CLU - CONTOUR LEVEL USE FLAG',my $ICLU);
  if( $ICLU == 3) {
    &NCAR::cpseti ('CLL - CONTOUR-LINE LINE WIDTH',2);
  }
  &NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',0);
  &NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',0);
}
#
# Add two new levels for which no contour lines are to be drawn, but
# between which shading is to be done.
#
$NCLV=$NCLV+2;
&NCAR::cpseti ('NCL - NUMBER OF CONTOUR LEVELS',$NCLV);
#
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$NCLV-1);
&NCAR::cpsetr ('CLV - CONTOUR LEVEL VALUE',-.15);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',0);
&NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',1);
&NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',2);
#
&NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$NCLV);
&NCAR::cpsetr ('CLV - CONTOUR LEVEL VALUE',+.15);
&NCAR::cpseti ('CLU - CONTOUR LEVEL USE FLAG',0);
&NCAR::cpseti ('AIA - AREA IDENTIFIER ABOVE LEVEL',3);
&NCAR::cpseti ('AIB - AREA IDENTIFIER BELOW LEVEL',1);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,200000);
#
# Put EZMAP boundary lines into the area map (in edge group 1).
#
&NCAR::mapbla ($IAMA);
#
# Put label boxes into the area map (in edge group 3).  One of the first
# things this routine does is generate a list of labels (high/low and
# contour line labels).  For each such label, one of the routines CPCHHL
# or CPCHLL is called, giving the user an opportunity to suppress the
# positioning of a label there.  The versions of these routines supplied
# later in this file use the contents of the area map array IAMA to
# suppress labels that are over land areas.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Fill land and ocean areas in different shades, avoiding label boxes.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,10000,$IARA,$IGRA,10,\&FILLEB);
#
# Set the polyline color index to zero, so that lines drawn from this
# point on will be drawn in black over the filled background.
#
&NCAR::gsplci (0);
#
# Draw the EZMAP grid lines (lines of constant latitude and longitude)
# over the oceans.
#
&NCAR::mapgrm ($IAMA,$XCRA,$YCRA,10000,$IARA,$IGRA,10,\&DRAWCL);
#
# Put the contour lines at contour levels -.15 and +.15 into the area
# map.
#
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Cross-hatch the area between contour levels -.15 and +.15.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,10000,$IARA,$IGRA,10,\&SHADER);
#
# Draw contour lines over the oceans.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA,\&DRAWCL);
#
# Draw labels.  Because the versions of the routines CPCHHL and CPCHLL
# supplied later in this file are used instead of the default ones in
# CONPACK, the appearance of the labels is changed in various ways.
# See the commenting in those routines for further information.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);

sub DRAWCL {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This subroutine is used to draw EZMAP grid lines and contour lines
# over the ocean only.  It draws the polyline defined by the points
# ((XCS(I),YCS(I)),I=1,NCS) if and only if none of the area identifiers
# for the area containing the polyline are negative and it's over ocean.
#
# The dash package routine CURVED is called to do the drawing so that
# the grid lines will be properly dashed as specified by internal
# parameters of EZMAP.
#
#
# Find the area identifiers of the polyline relative to group 1 (EZMAP
# background) and group 3 (CONPACK-supplied edges).
#
  my $IA1=-1;
  my $IA3=-1;
#
  for my $I ( 1 .. $NAI ) {
    if( at( $IAG, $I-1 ) == 1 ) { $IA1 = at( $IAI, $I-1 ); }
    if( at( $IAG, $I-1 ) == 3 ) { $IA3 = at( $IAI, $I-1 ); }
  }
#
# Draw the polyline if and only if neither area identifier is negative
# and it's over the ocean.
#
  if( ( $IA1 >= 0 ) && ( $IA3 >= 0 ) && ( &NCAR::mapaci( $IA1 ) == 1 ) ) {
    &NCAR::curved ($XCS,$YCS,$NCS);
  }
#
# Done.
#
}

sub FILLEB {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This version of FILLEB fills the polygon whose edge is defined by
# the points ((XCS(I),YCS(I)),I=1,NCS-1) if it's a land area (in which
# case color index 6 is used) or an ocean area (in which case color
# index 7 is used), but it avoids filling areas for which, relative
# to edge group 3, the area identifier is negative (CONPACK label
# boxes).  The GKS routine GFA is used to do the fills.
#
#
# Find the area identifiers of the polygon relative to group 1 (EZMAP
# background) and group 3 (CONPACK-supplied edges).
#
  my $IA1=-1;
  my $IA3=-1;
#
  for my $I ( 1 .. $NAI ) {
    if( at( $IAG, $I-1 ) == 1 ) { $IA1 = at( $IAI, $I-1 ); }
    if( at( $IAG, $I-1 ) == 3 ) { $IA3 = at( $IAI, $I-1 ); }
  }
#
# Fill land areas in white, using GFA and color index 6.
#
  if( ( $IA1 > 0 ) && ( &NCAR::mapaci( $IA1 ) == 2 ) && ( $IA3 >= 0 ) ) {
    &NCAR::gsfaci (5);
    &NCAR::gfa    ($NCS-1,$XCS,$YCS);
  }
#
# Fill ocean areas in gray, using GFA and color index 7.
#
  if( ( $IA1 > 0 ) && ( &NCAR::mapaci( $IA1 ) == 1 ) && ( $IA3 >= 0 ) ) {
    &NCAR::gsfaci (6);
    &NCAR::gfa    ($NCS-1,$XCS,$YCS);
  }
#
# Done.
#
}

sub SHADER {
  my ($XCS,$YCS,$NCS,$IAI,$IAG,$NAI) = @_;
#
# This version of SHADER shades the polygon whose edge is defined by
# the points ((XCS(I),YCS(I)),I=1,NCS-1) if and only if it's over ocean
# and, relative to edge group 3, its area identifier is a 1 (the area
# between contours at levels -.15 and .15).  The package SOFTFILL is
# used to do the shading.
#
#
# Define workspaces for the shading routine.
#
  my $DST = zeroes float, 2200;
  my $IND = zeroes long, 2400;
#
# Find the area identifiers of the polygon relative to group 1 (EZMAP
# background) and group 3 (CONPACK-supplied edges).
#
  my $IA1=-1;
  my $IA3=-1;
#
  for my $I ( 1 .. $NAI ) {
    if( at( $IAG, $I-1 ) == 1 ) { $IA1 = at( $IAI, $I-1 ); }
    if( at( $IAG, $I-1 ) == 3 ) { $IA3 = at( $IAI, $I-1 ); }
  }
#
# If appropriate, crosshatch the area.
#
  if( ( $IA1 > 0 ) && ( &NCAR::mapaci( $IA1 ) == 1 ) && ( $IA3 == 1 ) ) {
    &NCAR::sfseti ('ANGLE',45);
    &NCAR::sfsetr ('SPACING',.003);
    &NCAR::sfwrld ($XCS,$YCS,$NCS-1,$DST,2200,$IND,2400);
    &NCAR::sfseti ('ANGLE',135);
    &NCAR::sfnorm ($XCS,$YCS,$NCS-1,$DST,2200,$IND,2400);
  }
#
# Done.
#
}

sub NCAR::cpchhl {
  my ($IFLG) = @_;
#
# This routine is called just before and just after each action
# involving a high/low label.  A user version may take action to change
# the label.  This version also looks to see if the label is in an
# allowed position and, if not, blanks it out.
#
# IFLG is positive if an action is about to be taken, negative if the
# action has just been completed.  The action in question is implied
# by the absolute value of IFLG, as follows:
#
#   1 - deciding whether to put a high label at a given point
#   2 - filling the box around the label for a high
#   3 - drawing the label for a high
#   4 - outlining the box around the label for a high
#   5 - deciding whether to put a low label at a given point
#   6 - filling the box around the label for a low
#   7 - drawing the label for a low
#   8 - outlining the box around the label for a low
#
# CPCHHL may retrieve the value of the internal parameter 'ZDV', which
# is the value associated with the high or low being labelled.
#
# CPCHHL may retrieve the values of the internal parameters 'LBX' and
# 'LBY', which are the coordinates of the center point of the label,
# in the current user coordinate system.
#
# When IFLG is 1, 3, 5, or 7, CPCHHL is permitted to change the value
# of the internal parameter 'CTM' (a character string); if IFLG is 1 or
# 5 and 'CTM' is made blank, the label is suppressed; otherwise, the
# new value of 'CTM' will replace whatever CONPACK was about to use.
# If this is done for either IFLG = 1 or IFLG = 3, it must be done for
# both, and the same replacement label must be supplied in both cases.
# Similarly, if it is done for either IFLG = 5 or IFLG = 7, it must be
# done for both, and the same replacement label must be specified in
# both cases.
#
# When IFLG = 2, 3, 4, 6, 7, or 8, CPCHHL may make GKS calls to change
# color or line width; during the following call with IFLG = -2, -3,
# -4, -6, -7, or -8, such changes should be undone.
#
# Declare the common block containing the area map array that will be
# used in deciding where labels ought to be suppressed.
#
#
  my $IAAI = zeroes long, 10;
  my $IAGI = zeroes long, 10;
#
# Define quantities that will be used to generate the coordinates of
# five points to be tested in making the decision whether a label is
# over land or water.
#
  my @XSTP = ( 0., -.01, .01,   0.,  0. );
  my @YSTP = ( 0.,   0.,  0., -.01, .01 );
#
# If IFLG = 1, we have to decide whether we want a label at the point
# ('LBX','LBY') or not, and, if not, reset the value of 'CTM' to a
# single blank to signal that fact to the calling routine.  The decision
# is made by looking at an area map previously created in the array
# IAMA to see if the label point is over land or water.  We actually
# test the point itself and four other points around it; it any of
# the five is over land, we suppress the label (by setting 'CTM'=' ').
#
  if( ( $IFLG == 1 ) || ( $IFLG == 5 ) ) {
    &NCAR::cpgetr ('LBX',my $RLBX);
    &NCAR::cpgetr ('LBY',my $RLBY);
    
    my $FLBX=&NCAR::cufx($RLBX);
    my $FLBY=&NCAR::cufy($RLBY);
    for my $I ( 1 .. 5 ) {
      &NCAR::argtai (
        $IAMA,
        &NCAR::cfux($FLBX+$XSTP[$I-1]),
        &NCAR::cfuy($FLBY+$YSTP[$I-1]),
        $IAAI,$IAGI,10,my $NIDS,1);
        my $IAID=-1;
        for my $J ( 1 .. $NIDS ) {
          if( at( $IAGI, $J-1 ) == 1 ) { $IAID = at( $IAAI, $J-1 ); }
        }
        if( &NCAR::mapaci( $IAID ) == 2 ) {
          &NCAR::cpsetc ('CTM - CHARACTER TEMPORARY',' ');
          return;
        }
    }
  }
#
# Now, if the label box is being filled, make the fill color depend
# on whether the label is for a high or a low.
#
  if( ( abs( $IFLG ) == 2 ) || ( abs( $IFLG ) == 6 ) ) {
    if( $IFLG > 0 ) {
      if( $IFLG == 2 ) {
        &NCAR::gsfaci (4);
      } else {
        &NCAR::gsfaci (2);
      }
    } else {
      &NCAR::gsfaci (1);
    }
    return;
  }
#
# Put the text on the filled background in a contrasting color.
#
  if( ( abs( $IFLG ) == 3 ) || ( abs( $IFLG ) == 7 ) ) {
    if( $IFLG > 0 ) {
      if( $IFLG == 3 ) {
        &NCAR::pcseti ('CC', 0);
      } else {
        &NCAR::pcseti ('CC', 1);
      }
    } else {
      &NCAR::pcseti ('CC',-1);
    }
    return;
  }
#
# If the box is being outlined, do it in a contrasting color and widen
# the lines.
#
  if( ( abs( $IFLG ) == 4 ) || ( abs( $IFLG ) == 8 ) ) {
    if( $IFLG > 0 ) {
      if( $IFLG == 4 ) {
#             CALL GSPLCI (2)
        &NCAR::gsplci (0);
      } else {
#             CALL GSPLCI (4)
        &NCAR::gsplci (0);
      }
      &NCAR::gslwsc (2.);
    } else {
      &NCAR::gsplci (1);
      &NCAR::gslwsc (1.);
    }
    return;
  }
#
# In all other cases, just return.
#
}

sub NCAR::cpchll {
  my ($IFLG) = @_;
#
# This routine is called just before and just after each action
# involving a contour line label.  A user version may take action to
# change the label.  This version also looks to see if the label is
# in an allowed position and, if not, blanks it out.
#
# IFLG is positive if an action is about to be taken, negative if an
# action has just been completed.  The action in question is implied
# by the absolute value of IFLG, as follows:
#
#   1 - deciding whether to put a line label at a given point
#   2 - filling the box around a line label
#   3 - drawing a line label
#   4 - outlining the box around a line label
#
# When CPCHLL is called, the internal parameter 'PAI' will have been
# set to the index of the appropriate contour level.  Thus, parameters
# associated with that level may easily be retrieved by calls to CPGETx.
#
# CPCHLL may retrieve the value of the internal parameter 'ZDV', which
# is the contour level associated with the contour line being labelled.
#
# CPCHLL may retrieve the values of the internal parameters 'LBX' and
# 'LBY', which are the coordinates of the center point of the label,
# in the current user coordinate system.
#
# When IFLG is 1 or 3, CPCHLL is permitted to change the value of the
# internal parameter 'CTM' (a character string); if IFLG is 1 and 'CTM'
# is made blank, the label is suppressed; otherwise, the new value of
# 'CTM' will replace whatever CONPACK was about to use.  If this is
# done for either IFLG = 1 or IFLG = 3, it must be done for both, and
# the same replacement label must be supplied in both cases.
#
# When IFLG = 2, 3, or 4, CPCHLL may make GKS calls to change color
# or line width; during the following call with IFLG = -2, -3, or -4,
# such changes should be undone.
#
# Declare the common block containing the area map array that will be
# used in deciding where labels ought to be suppressed.
#
#
  my $IAAI = zeroes long, 10;
  my $IAGI = zeroes long, 10;
#
# Define quantities that will be used to generate the coordinates of
# five points to be tested in making the decision whether a label is
# over land or water.
#
  my @XSTP = ( 0., -.01, .01,   0.,  0. );
  my @YSTP = ( 0.,   0.,  0., -.01, .01 );
#
# If IFLG = 1, we have to decide whether we want a label at the point
# ('LBX','LBY') or not, and, if not, reset the value of 'CTM' to a
# single blank to signal that fact to the calling routine.  The decision
# is made by looking at an area map previously created in the array
# IAMA to see if the label point is over land or water.  We actually
# test the point itself and four other points around it; it any of
# the five is over land, we suppress the label (by setting the value
# of 'CTM' to ' ').
#
  if( $IFLG == 1 ) {
    &NCAR::cpgetr ('LBX',my $RLBX);
    &NCAR::cpgetr ('LBY',my $RLBY);
    my $FLBX=&NCAR::cufx($RLBX);
    my $FLBY=&NCAR::cufy($RLBY);
    for my $I ( 1 .. 5 ) {
      &NCAR::argtai (
         $IAMA,
         &NCAR::cfux($FLBX+$XSTP[$I-1]),
         &NCAR::cfuy($FLBY+$YSTP[$I-1]),
         $IAAI,$IAGI,10,my $NIDS,1
      );
      my $IAID=-1;
      for my $J ( 1 .. $NIDS ) {
        if( at( $IAGI, $J-1 ) == 1 ) { $IAID = at( $IAAI, $J-1 ); }
      }
      if( &NCAR::mapaci( $IAID ) == 2 ) {
        &NCAR::cpsetc ('CTM - CHARACTER TEMPORARY',' ');
        return;
      }
    }
  }
#
# Otherwise, see what the contour value is on the line being labelled
# and, if it's zero, reset the value of 'CTM' to 'Z' so that will be
# used as the label.
#
  &NCAR::cpgetr ('ZDV - Z DATA VALUE',my $CLEV);
  if( $CLEV == 0 ) {
    &NCAR::cpsetc ('CTM - CHARACTER TEMPORARY','Z');
  }
#
# Now, if the label box is being filled, make the fill color depend
# on the contour level.
#
  if( abs( $IFLG ) == 2 ) {
    if( $IFLG > 0 ) {
      if( $CLEV < 0 ) {
        &NCAR::gsfaci (2);
      } elsif( $CLEV == 0 ) {
        &NCAR::gsfaci (3);
      } else {
        &NCAR::gsfaci (4);
      }
    } else {
      &NCAR::gsfaci (1);
    }
    return;
  }
#
# Put the text on the filled background in a contrasting color.
#
  if( abs( $IFLG ) == 3 ) {
    if( $IFLG > 0 ) {
      if( $CLEV < 0 ) {
        &NCAR::pcseti ('CC', 1);
      } elsif( $CLEV == 0 ) {
        &NCAR::pcseti ('CC', 0);
      } else {
        &NCAR::pcseti ('CC', 0);
      }
     } else {
       &NCAR::pcseti ('CC',-1);
    }
    return;
  }
#
# If the box is being outlined, do it in a contrasting color and widen
# the lines.
#
  if( abs( $IFLG ) == 4 ) {
    if( $IFLG > 0 ) {
      if( $CLEV < 0 ) {
#             CALL GSPLCI (4)
        &NCAR::gsplci (0);
      } elsif( $CLEV == 0 ) {
        &NCAR::gsplci (0);
      } else {
#             CALL GSPLCI (2)
         &NCAR::gsplci (0);
      }
      &NCAR::gslwsc (2.);
    } else {
      &NCAR::gsplci (1);
      &NCAR::gslwsc (1.);
    }
    return;
  }
#
# In all other cases, just return.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/cpex15.ncgm';
