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
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Declare required data arrays and workspace arrays.
#
my ( $LMAP, $LWRK, $M, $N ) = ( 100000, 1000, 40, 40 );
my $ZDAT = zeroes float, $M, $N;
my $RWRK = zeroes float, $LWRK;
my $XCRA = zeroes float, $LWRK;
my $YCRA = zeroes float, $LWRK;
my $IWRK = zeroes long, $LWRK;
my $IAMA = zeroes long, $LMAP;
my $IAREA = zeroes long, 2;
my $IGRP = zeroes long, 2;
#
# Declare the routine which will color the areas.
#
#     EXTERNAL FILL
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Force solid fill.
#
&NCAR::gsfais (1);
#
# Define color indices.
#
&COLOR($IWKID);
#
# Retrieve an array of test data.
#
my @t;
open DAT, "<data/ccpila.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;

for my $I ( 1 .. $M ) {
  for my $J ( 1 .. $N ) {
    set( $ZDAT, $I-1, $J-1, shift( @t ) );
  }
}
#
# Tell CONPACK to use 12 contour levels, splitting the range into 13
# equal bands, one for each of the 13 colors available.
#
&NCAR::cpseti ('CLS - CONTOUR LEVEL SELECTION FLAG',-12);
#
# Draw smoothed plot to the right
#
&NCAR::cpsetr ('VPL - VIEWPORT LEFT',.51);
&NCAR::cpsetr ('VPR - VIEWPORT RIGHT',1.0);
#
# Set smoothing so that lines are very smooth
#
&NCAR::cpsetr ('T2D - TENSION ON 2D SPLINES',.0001);
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,$M,$M,$N,$RWRK,$LWRK,$IWRK,$LWRK);
#
# Initialize the area map and put the contour lines into it.
#
&NCAR::arinam ($IAMA,$LMAP);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,$LWRK,$IAREA,$IGRP,2,\&FILL);
#
# Put black contour lines over the colored map.
#
&NCAR::gsplci (0);
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Draw unsmoothed plot to the left
#
&NCAR::cpsetr ('VPL - VIEWPORT LEFT',0.0);
&NCAR::cpsetr ('VPR - VIEWPORT RIGHT',0.49);
# 
# Tell Conpack that we want no smoothing
#
&NCAR::cpsetr ('T2D - TENSION ON 2D SPLINES',0.);
#
# Initialize the drawing of the contour plot.
#
&NCAR::cprect ($ZDAT,$M,$M,$N,$RWRK,$LWRK,$IWRK,$LWRK);
#
# Initialize the area map and put the contour lines into it.
#
&NCAR::arinam ($IAMA,$LMAP);
&NCAR::cpclam ($ZDAT,$RWRK,$IWRK,$IAMA);
#
# Color the map.
#
&NCAR::arscam ($IAMA,$XCRA,$YCRA,$LWRK,$IAREA,$IGRP,2,\&FILL);
#
# Put black contour lines over the colored map.
#
&NCAR::gsplci (0);
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Draw titles in white
#
&NCAR::getset( my ( $VPL,$VPR,$VPB,$VPT,$WL,$WR,$WB,$WT,$LOG ) );
&NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::gsplci (0);
&NCAR::plchhq (.3,$VPT+.015,'Unsmoothed Contours',.015,0.,0.);
&NCAR::plchhq (.75,$VPT+.015,'Over Smoothed Contours',.015,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;
#
# Done.
#
sub FILL {
  my ($XCRA,$YCRA,$NCRA,$IAREA,$IGRP,$NGRPS) = @_;
#
# Get area identifiers for contour levels and vertical strips.
#
  my $IFILL=0;
  for my $I ( 1 .. $NGRPS ) {
    if( at( $IGRP, $I-1 ) == 3 ) { $IFILL = at( $IAREA, $I-1 ); }
  }
#
# Fill 
#
  if( $IFILL > 0 ) {
    &NCAR::gsfaci ($IFILL+2);
    &NCAR::gfa ($NCRA-1,$XCRA,$YCRA);
  }
#
# Done.
#
}


sub COLOR {
  my ($IWKID) = @_;
#
# Background color
# Black
#
  &NCAR::gscr($IWKID,0,0.,0.,0.);
#
# Foreground colors
# White
#
  &NCAR::gscr($IWKID, 1, 1.0, 1.0, 1.0);
#
# Aqua
#
  &NCAR::gscr($IWKID, 2, 0.0, 0.9, 1.0);
#
# Red1
#
  &NCAR::gscr($IWKID, 3, 0.9, 0.25, 0.0);
#
# OrangeRed1
#
  &NCAR::gscr($IWKID, 4, 1.0, 0.0, 0.2);
#
# Orange1
#
  &NCAR::gscr($IWKID, 5, 1.0, 0.65, 0.0);
#
# Yellow1
#
  &NCAR::gscr($IWKID, 6, 1.0, 1.0, 0.0);
#
# GreenYellow1
#
  &NCAR::gscr($IWKID, 7, 0.7, 1.0, 0.2);
#
# Chartreuse1
#
  &NCAR::gscr($IWKID, 8, 0.5, 1.0, 0.0);
#
# Celeste1
#
  &NCAR::gscr($IWKID, 9, 0.2, 1.0, 0.5);
#
# Green1
#
  &NCAR::gscr($IWKID, 10, 0.2, 0.8, 0.2);
#
# DeepSkyBlue1
#
  &NCAR::gscr($IWKID, 11, 0.0, 0.75, 1.0);
#
# RoyalBlue1
#
  &NCAR::gscr($IWKID, 12, 0.25, 0.45, 0.95);
#
# SlateBlue1
#
  &NCAR::gscr($IWKID, 13, 0.4, 0.35, 0.8);
#
# DarkViolet1
#
  &NCAR::gscr($IWKID, 14, 0.6, 0.0, 0.8);
#
# Orchid1
#
  &NCAR::gscr($IWKID, 15, 0.85, 0.45, 0.8);

}
   
rename 'gmeta', 'ncgm/ccpt2d.ncgm';
