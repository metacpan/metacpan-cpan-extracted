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

my ( $MREG, $NREG ) = ( 50, 50 );
# 
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
# 
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my $XREG = zeroes float, $MREG;
my $YREG = zeroes float, $NREG;
my $ZREG = zeroes float, $MREG, $NREG;
      
#     EXTERNAL COLOR
#      
# Get data array
#
my @t;
open DAT, "<data/ccpfil.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $I ( 1 .. $MREG ) {
  set( $XREG, $I-1, shift( @t ) );
}
for my $J ( 1 .. $NREG ) {
  set( $YREG, $J-1, shift( @t ) );
}
for my $J ( 1 .. $NREG ) {
  for my $I ( 1 .. $MREG ) {
    set( $ZREG, $I-1, $J-1, shift( @t ) );
  }
}
# 
# Open GKS, open and activate a workstation.
# 
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#      
# Call Conpack color fill routine
#      
&CCPFIL($ZREG,$MREG,$NREG,-15,\&COLOR,$IWKID);
#      
# Close frame
#      
&NCAR::frame();
# 
# Deactivate and close workstation, close GKS.
# 
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
      
sub CCPFIL {
  my ($ZREG,$MREG,$NREG,$NCL,$COLOR,$IWKID) = @_;
  my ( $LRWK, $LIWK, $LMAP, $NWRK, $NOGRPS ) = ( 5000, 5000, 50000, 5000, 5 );      
  my $RWRK = zeroes float, $LRWK;
  my $XWRK = zeroes float, $NWRK;
  my $YWRK = zeroes float, $NWRK;
  my $IWRK = zeroes long, $LIWK;
  my $MAP = zeroes long, $LMAP;
  my $IAREA = zeroes long, $NOGRPS;
  my $IGRP = zeroes long, $NOGRPS;
      
#     EXTERNAL FILL
#     EXTERNAL COLOR
#      
# Set up color table
#      
  $COLOR->($IWKID);
#      
# Initialize Areas
#      
  &NCAR::arinam($MAP, $LMAP);
#      
# Set number of contour levels and initialize Conpack
#      
  &NCAR::cpseti('CLS - CONTOUR LEVEL SELECTION FLAG',$NCL);
  &NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
#      
# Add contours to area map
#      
  &NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#      
# Set fill style to solid, and fill contours
#      
  &NCAR::gsfais(1);
  &NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&FILL);
#      
# Draw Perimeter
#      
  &NCAR::cpback($ZREG, $RWRK, $IWRK);
#      
# Draw Labels
#      
  &NCAR::cplbdr($ZREG,$RWRK,$IWRK);
#      
# Draw Contours
#      
  &NCAR::cpcldr($ZREG,$RWRK,$IWRK);
      
}      

sub FILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS) = @_;

  my $IAREA3;
  for my $I ( 1 .. $NGRPS ) { 
    if( at( $IGRP, $I-1 ) == 3 ) { $IAREA3 = at( $IAREA, $I-1 ); } 
  }
    
  if( $IAREA3 > 0 ) {  
#      
# If the area is defined by 3 or more points, fill it
#      
    &NCAR::gsfaci($IAREA3+1);
    &NCAR::gfa($NWRK,$XWRK,$YWRK);
  }
#      
# Otherwise, do nothing
#      
}      
      
sub COLOR {
  my ($IWKID) = @_;
# 
# BACKGROUND COLOR
# BLACK
#
  &NCAR::gscr($IWKID,0,0.,0.,0.);
# 
# FORGROUND COLORS
# White
#
  &NCAR::gscr($IWKID,  1, 1.0, 1.0, 1.0);
#      
# Orchid
#      
  &NCAR::gscr($IWKID,  2, 0.85, 0.45, 0.8);
#      
# Red
#      
  &NCAR::gscr($IWKID,  3, 0.9, 0.25, 0.0);
#      
# OrangeRed
#      
  &NCAR::gscr($IWKID,  4, 1.0, 0.0, 0.2);
#      
# Orange
#      
  &NCAR::gscr($IWKID,  5, 1.0, 0.65, 0.0);
#      
# Gold
#      
  &NCAR::gscr($IWKID,  6, 1.0, 0.85, 0.0);
#      
# Yellow
#      
  &NCAR::gscr($IWKID,  7, 1.0, 1.0, 0.0);
#      
# GreenYellow
#      
  &NCAR::gscr($IWKID,  8, 0.7, 1.0, 0.2);
#      
# Chartreuse
#      
  &NCAR::gscr($IWKID,  9, 0.5, 1.0, 0.0);
#      
# Celeste
#      
  &NCAR::gscr($IWKID, 10, 0.2, 1.0, 0.5);
#      
# Green
#      
  &NCAR::gscr($IWKID, 11, 0.2, 0.8, 0.2);
#      
# Aqua
#      
  &NCAR::gscr($IWKID, 12, 0.0, 0.9, 1.0);
#      
# DeepSkyBlue
#      
  &NCAR::gscr($IWKID, 13, 0.0, 0.75, 1.0);
#      
# RoyalBlue
#      
  &NCAR::gscr($IWKID, 14, 0.25, 0.45, 0.95);
#      
# SlateBlue
#      
  &NCAR::gscr($IWKID, 15, 0.4, 0.35, 0.8);
#      
# DarkViolet
#      
  &NCAR::gscr($IWKID, 16, 0.6, 0.0, 0.8);
#      
# Lavender
#      
  &NCAR::gscr($IWKID, 17, 0.8, 0.8, 1.0);
#      
# Done.
# 
}      

   
rename 'gmeta', 'ncgm/ccpfil.ncgm';
