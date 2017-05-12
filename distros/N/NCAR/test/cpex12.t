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

#
# This program demonstrates the use of the new dashed-line package
# DASHPACK, which became a part of NCAR Graphics in August, 1994.
#
# Define error file, Fortran unit number, workstation type, and
# workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Declare an array to hold the data to be contoured.
#
my $ZDAT = zeroes float, 37, 27;
#
# Declare the required real and integer workspaces.
#
my $RWRK = zeroes float, 5000;
my $IWRK = zeroes long, 1000;
#
# Declare an array to hold an area map.
#
my $IAMA = zeroes long, 25000;
#
# Declare the routine which will draw contour lines but avoid drawing
# them through labels.
#
#       EXTERNAL CPDRPL
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Generate an array of test data.
#
my @t;
open DAT, "<data/cpex12.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 27 ) {
  for my $I ( 1 .. 37 ) {
    set( $ZDAT, $I-1, $J-1, shift( @t ) );
  }
}  
#
# Change the range of the data somewhat.
#
for my $I ( 1 .. 37 ) {
  for my $J ( 1 .. 27 ) {
    set( $ZDAT, $I-1, $J-1, at( $ZDAT, $I-1, $J-1 ) + 10000 );
  }
}
#
# Put explanatory labels at the top and bottom of the plot.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.930),'A CONPACK EXAMPLE',.018,0.,0.);
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.897),'Using the New Dashed-Line Package DASHPACK',.015,0.,0.);
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.093),
'Note that contour labels are written by PLCHHQ and that they can be made to:C:bend with the line (which works best when, as here, the lines are very smooth).',
.010,0.,0.);
#
# Tell CONPACK to choose contour levels for itself and to use more than
# the usual number of them.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTOR',32);
#
# Tell CONPACK to use characters a little smaller than the default size
# in the contour-line labels.
#
&NCAR::cpsetr ('DPS - DASH PATTERN CHARACTER SIZE',.0075);
#
# Tell CONPACK to use the new dash package (because 'DPU' is negative)
# and to use 1 repetition of the dash pattern between each line label
# and the next (because the absolute value of 'DPU' is 1).
#
&NCAR::cpseti ('DPU - DASH PACKAGE USE FLAG',-1);
#
# Tell CONPACK to use gaps and solids that are half the default size
# when drawing the contour lines.
#
&NCAR::cpsetr ('DPV - DASH PATTERN VECTOR SIZE',.0025);
#
# Turn on the drawing of the high and low label boxes.
#
&NCAR::cpseti ('HLB - HIGH/LOW LABEL BOX FLAG',1);
#
# Tell CONPACK to delete high/low labels which overlap the informational
# label, another high/low label, or the edge.
#
&NCAR::cpseti ('HLO - HIGH/LOW LABEL OVERLAP FLAG',7);
#
# Force the use of an exponent form in all numeric labels.
#
&NCAR::cpseti ('NEU - NUMERIC EXPONENT USE FLAG',0);
#
# Tell CONPACK to smooth the contour lines.
#
&NCAR::cpsetr ('T2D - TENSION ON 2D SPLINES',2.5);
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,37,37,27,$RWRK,5000,$IWRK,1000);
#
# Force the selection of contour levels and numeric labels for them,
# so that the labels can be manipulated as required by DASHPACK.
#
&NCAR::cppklb ($ZDAT,$RWRK,$IWRK);
#
# Find out how many levels were chosen and loop through all the levels.
#
&NCAR::cpgeti ('NCL - NUMBER OF CONTOUR LEVELS', my $NOCL);
#
for my $IOCL ( 1 .. $NOCL ) {
#
# Set 'PAI' to the index of the next level.
#
  &NCAR::cpseti ('PAI - PARAMETER ARRAY INDEX',$IOCL);
#
# Pick up the contour level value and use it to determine whether to
# use a dashed line, indicating a value below 10000, or a solid line,
# indicating a value above 10000.
#
  &NCAR::cpgetr ('CLV - CONTOUR LEVEL',my $CLEV);
#
  if( $CLEV < 10000 ) {
    &NCAR::cpsetc ('CLD - CONTOUR LEVEL DASH PATTERN','$_$_$_$_$_$_$_$_$_$_$_$_$_$_$');
  } else {
    &NCAR::cpsetc ('CLD - CONTOUR LEVEL DASH PATTERN','$$$$$$$$$$$$$$$$$$$$$$$$$$$$$');
  }
#
# Retrieve the chosen numeric label for the level and preprocess it to
# include characters that tell DASHPACK where it is permitted to break
# the label.  (Each piece is written with a separate call to PLCHHQ and
# the overall effect is to make the label bend with the curve.)  This
# is done in such a way as to leave function codes with the characters
# they affect.  This code assumes that the default function-code control
# character (a colon) is being used by PLOTCHAR and that the default
# break character (a vertical bar) is being used by DASHPACK; it could
# be made more general by interrogating PLOTCHAR and DASHPACK to see
# what characters are really in use.
#
  &NCAR::cpgetc ('LLT - LINE LABEL TEXT',my $CTM1);
#
  if( $CTM1 ne ' ' ) {
#
# J is the index of the last character examined in the input string, K
# is the index of the last character stored in the output string, and
# L is a flag indicating whether or not a '10:S:' has been seen in the
# input (so we can avoid putting break characters in the middle of the
# exponent).
#
    my $J=0;
    my $K=0;
    my $L=0;
#
# What follows is a simple loop to copy characters from the input
# string to the output string, inserting break characters where they
# are needed.
#
    my $CTM2;
L103:
    if( $J <= 64 ) {
      if( substr( $CTM1, $J, 5 ) eq ':L1:4' ) {
        substr( $CTM2, $K, 6, ':L1:4|' );
        $J=$J+5;
        $K=$K+6;
        goto L103;
      } elsif( substr( $CTM1, $J, 5 ) eq '10:S:' ) {
        substr( $CTM2, $K, 6, '1|0:S:' );
        $J=$J+5;
        $K=$K+6;
        $L=1;
        goto L103;
      } elsif( substr( $CTM1, $J, 3 ) eq ':N:' ) {
        substr( $CTM2, $K, 3, ':N:' );
        $J=$J+3;
        $K=$K+3;
      } elsif( substr( $CTM1, $J, 1 ) ne ' ' ) {
        substr( $CTM2, $K, 1, substr( $CTM1, $J, 1 ) );
        $J=$J+1;
        $K=$K+1;
        if( ( $L == 0 ) && ( substr( $CTM1, $J, 1 ) ne ' ' ) ) {
          substr( $CTM2, $K, 1, '|' );
          $K=$K+1;
        }
        goto L103;
      }
    }
#
# Done - pass the string with break characters in it back to CONPACK.
#
    &NCAR::cpsetc ('LLT - LINE LABEL TEXT',substr( $CTM2, 0, $K ) );
#
  }
#
# End of loop through contour levels.
#
}
#
# Draw the default background.
#
&NCAR::cpback ($ZDAT,$RWRK,$IWRK);
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,25000);
#
# Put label boxes into the area map.
#
&NCAR::cplbam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Draw contour lines, omitting parts inside label boxes.
#
&NCAR::cpcldm ($ZDAT,$RWRK,$IWRK,$IAMA, \&NCAR::cpdrpl );
#
# Add high, low, and informational labels.
#
&NCAR::cplbdr ($ZDAT,$RWRK,$IWRK);
#
# Advance the frame.
#
&NCAR::frame;
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#


rename 'gmeta', 'ncgm/cpex12.ncgm';
