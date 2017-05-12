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

my ( $MREG, $NREG ) = ( 50, 50 );
my $XREG = zeroes float, $MREG;
my $YREG = zeroes float, $MREG;
my $ZREG = zeroes float, $MREG, $NREG;
#
# Get data array
#
&GETDAT($XREG,$YREG,$ZREG,$MREG,$NREG);
#
# Call Conpack color fill routine
#
&CSFILL($ZREG,$MREG,$NREG,-15);
#
# Close frame and close GKS
#
&NCAR::frame();


sub CSFILL {
  my ($ZREG,$MREG,$NREG,$NCL) = @_;
  my ( $LRWK, $LIWK, $LMAP, $NWRK, $NOGRPS ) = ( 5000, 5000, 50000, 5000, 5 );
  my $RWRK  = zeroes float, $LRWK;
  my $XWRK  = zeroes float, $NWRK;
  my $YWRK  = zeroes float, $NWRK;
  my $IWRK  = zeroes  long, $LIWK;
  my $MAP   = zeroes  long, $LMAP;
  my $IAREA = zeroes  long, $NOGRPS;
  my $IGRP  = zeroes  long, $NOGRPS;
#     EXTERNAL SFILL
#
# Set up color table
#
  &COLOR();
#
# First draw B&W plot to left
#
&NCAR::cpsetr('VPL - VIEWPORT LEFT',0.);
&NCAR::cpsetr('VPR - VIEWPORT RIGHT',.49);
#
# Set number of contour levels and initialize Conpack
#
&NCAR::cpseti('CLS - CONTOUR LEVEL SELECTION FLAG',$NCL);
&NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
#
# Set up B&W fill options
#
&NCAR::sfseti('TY - TYPE OF FILL',-4);
#
# Draw Perimeter
#
&NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Initialize Areas
#
&NCAR::arinam($MAP, $LMAP);
#
# Add contours to area map
#
&NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#
# Fill contours
#
&NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&SFILL);
#
# Draw contours, masking label boxes
#
&NCAR::gsplci(0);
&NCAR::cpcldr($ZREG, $RWRK, $IWRK);
&NCAR::gsplci(1);
#
# Second draw color plot to left
#
&NCAR::cpsetr('VPL - VIEWPORT LEFT',.51);
&NCAR::cpsetr('VPR - VIEWPORT RIGHT',1.);
&NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
#
# Set up color fill options
#
&NCAR::gsfais(1);
&NCAR::sfseti('TY - TYPE OF FILL',0);
#
# Draw Perimeter
#
&NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Initialize Areas
#
&NCAR::arinam($MAP, $LMAP);
#
# Add contours to area map
#
&NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#     
# Fill contours
#
&NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&SFILL);
#     
# Draw contours, masking label boxes
#
&NCAR::gsplci(0);
&NCAR::cpcldr($ZREG, $RWRK, $IWRK);
}

sub SFILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS) = @_;    
#
  my $ISCR = zeroes  long, 5000;
  my $RSCR = zeroes float, 5000;
  my $IAREA3;
  for my $I ( 1 .. $NGRPS ) {
    if( at( $IGRP, $I-1 ) == 3 ) { $IAREA3 = at( $IAREA, $I-1 ); }
  }
  if( $IAREA3 >= 1 ) {
#
# If the area is defined by 3 or more points, fill it
#
    &NCAR::sfsgfa($XWRK,$YWRK,$NWRK,$RSCR,5000,$ISCR,5000,$IAREA3+1);
  }
#
# Otherwise, do nothing
#
}

sub GETDAT {
  my ($XREG,$YREG,$ZREG,$MREG,$NREG) = @_;
  my ( $NRAN, $LRWK, $LIWK ) = ( 30, 5000, 5000 );
  my $ZRAN = zeroes float, $NRAN;
  my $RWRK = zeroes float, $LRWK;
  my $IWRK = zeroes  long, $LIWK;
  my $XRAN = float [    
      12., 60., 14., 33.,  8., 12., 43., 57., 22., 15.,
      19., 12., 64., 19., 15., 55., 31., 32., 33., 29.,
      18.,  1., 18., 42., 56.,  9.,  6., 12., 44., 19. 
  ];
  my $YRAN = float [
      1.,  2.,  3., 53.,  7., 11., 13., 17., 19., 49.,
      1., 31., 37.,  5.,  7., 47., 61., 17.,  5., 23.,
      29.,  3.,  5., 41., 43.,  9., 13., 59.,  1., 67.
  ];
  my $ZRAN  = float [
     1.0, 1.5, 1.7, 1.4, 1.9, 1.0, 1.5, 1.2, 1.8, 1.4,
     1.8, 1.7, 1.9, 1.5, 1.2, 1.1, 1.3, 1.7, 1.2, 1.6,
     1.9, 1.0, 1.6, 1.3, 1.4, 1.8, 1.7, 1.5, 1.1, 1.0
  ];
#
#  Set the min and max data values.
#
  my $XMIN = 0.0;
  my $XMAX = 65.0;
  my $YMIN =  0.0;
  my $YMAX = 68.0;
#
# Choose the X and Y coordinates for interpolation points on the 
# regular grid.
#
  for my $I ( 1 .. $MREG ) {
     set( $XREG, $I-1, $XMIN + ($XMAX - $XMIN)* ($I-1)/$MREG );
  }
#
  for my $I ( 1 .. $NREG ) {
     set( $YREG, $I-1, $YMIN + ($YMAX - $YMIN)* ($I-1)/$NREG );
  }
#
# Interpolate data onto a regular grid
#
  &NCAR::idsfft (1,$NRAN,$XRAN,$YRAN,$ZRAN,$MREG,
                 $NREG,$MREG,$XREG,$YREG,$ZREG,$IWRK,$RWRK);
}
sub COLOR {
#
# BACKGROUND COLOR
# BLACK
#
&NCAR::gscr(1,0,0.,0.,0.);
#
# FORGROUND COLORS
# White
#
&NCAR::gscr(1,  1, 1.0, 1.0, 1.0);
# 
&NCAR::gscr(1,  2, 0.85, 0.45, 0.4);
#
# Red
#
&NCAR::gscr(1,  3, 0.9, 0.25, 0.0);
#
# OrangeRed
#
&NCAR::gscr(1,  4, 1.0, 0.0, 0.2);
#
# Orange
#
&NCAR::gscr(1,  5, 1.0, 0.65, 0.0);
#
# Gold
#
&NCAR::gscr(1,  6, 1.0, 0.85, 0.0);
#
# Yellow
#
&NCAR::gscr(1,  7, 1.0, 1.0, 0.0);
#
# GreenYellow
#
&NCAR::gscr(1,  8, 0.7, 1.0, 0.2);
#
# Chartreuse
#
&NCAR::gscr(1,  9, 0.5, 1.0, 0.0);
#
# Green
#
&NCAR::gscr(1, 10, 0.2, 0.8, 0.2);
#
# Celeste
#
&NCAR::gscr(1, 11, 0.2, 1.0, 0.7);
#
# Aqua
#
&NCAR::gscr(1, 12, 0.0, 0.9, 1.0);
#
# DeepSkyBlue
#
&NCAR::gscr(1, 13, 0.0, 0.75, 1.0);
#
# RoyalBlue
#
&NCAR::gscr(1, 14, 0.25, 0.45, 0.95);
#
# SlateBlue
#
&NCAR::gscr(1, 15, 0.4, 0.35, 0.8);
#
# DarkViolet
#
&NCAR::gscr(1, 16, 0.6, 0.0, 0.8);
#
# Lavender
#
&NCAR::gscr(1, 17, 0.8, 0.8, 1.0);
#
# Sienna
#
&NCAR::gscr(1, 18, 0.63, 0.32, 0.18);
#
# Done.
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fsfsgfa.ncgm';
