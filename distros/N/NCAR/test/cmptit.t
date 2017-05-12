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
   
#
# The program EXMPL5 produces a single frame with maximal-area
# views of all the EZMAP projections of the globe.
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Define area map array and size for area fill applications
#
my ( $LMAP, $MCS, $NIDS ) = ( 250000, 10000, 2 );
my $MAP = zeroes long, $LMAP;
my $IAREA = zeroes long, $NIDS;
my $IGRP = zeroes long, $NIDS;
my $XCS = zeroes float, $MCS;
my $YCS = zeroes float, $MCS;
#
# Declare masking and area shading routines external
#
#     EXTERNAL MASK
#     EXTERNAL SHADE1
#     EXTERNAL SHADE2
#     EXTERNAL CFILL
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
# Set up color table and dash pattern
# 
&COLOR($IWKID);
&NCAR::dashdb(65535);
#
# Set the outline-dataset parameter.
#
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','CO');
&NCAR::mapsti ('LA - LABEL FLAG',0);
#
# Put meridians and parallels every 15 degrees.
#
&NCAR::mapsti ('GR - GRID SPACING',15);
#
# Don't draw labels
#
&NCAR::mapsti ('LA - LABEL FLAG',0);
#
# Do draw elliptical perimeter
#
&NCAR::mapsti ('EL - ELLIPTICAL-PERIMETER SELECTOR',1);
#
# Lambert conformal conic.
#
&NCAR::mappos (.025,.24375,.63125,.85);
&NCAR::maproj ('LC',30.,0.,45.);
&NCAR::mapint();
#
# Yellow Grid
#
&NCAR::gsplci (13);
&NCAR::mapgrd();
&NCAR::maplbl();
#
# Green Contenental Outline
#
&NCAR::gsplci (6);
&NCAR::maplot();
#
# Stereographic.
#
&NCAR::mappos (.26875,.4875,.63125,.85);
&NCAR::maproj ('ST',0.,0.,0.);
#
# Aqua
#
&NCAR::mapint();
&NCAR::gsplci (8);
&NCAR::mapgrd();
&NCAR::maplbl();
#
# Chartreuse
#
&NCAR::gsplci (2);
&NCAR::maplot();
#
# Orthographic.
#
&NCAR::mappos (.5125,.73125,.63125,.85);
&NCAR::maproj ('OR',0.,0.,0.);
#
# Orchid
#
&NCAR::mapint();
&NCAR::gsplci (15);
&NCAR::mapgrd();
&NCAR::maplbl();
#
# SlateBlue
#
&NCAR::gsplci (8);
&NCAR::maplot();
#
# Lambert equal-area.
#
&NCAR::mappos (.75625,.975,.63125,.85);
&NCAR::maproj ('LE',0.,0.,0.);
#
# Red
#
&NCAR::mapint();
&NCAR::gsplci (3);
&NCAR::mapgrd();
&NCAR::maplbl();
#
# Yellow
#
&NCAR::gsplci (6);
&NCAR::maplot();
#
# Gnomonic.
#
# Draw lat/lon lines only over the oceans
#
&NCAR::gsplci (1);
&NCAR::mappos (.025,.24375,.3875,.60625);
&NCAR::maproj ('GN',0.,0.,0.);
&NCAR::arinam ($MAP, $LMAP);
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::mapgrm ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&MASK);
&NCAR::maplbl();
&NCAR::maplot();
#
# Azimuthal equidistant.
#
&NCAR::arinam ($MAP, $LMAP);
&NCAR::mappos (.26875,.4875,.3875,.60625);
&NCAR::maproj ('AE',0.,0.,0.);
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::mapgrm ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&MASK);
&NCAR::gsplci (2);
&NCAR::maplbl();
&NCAR::maplot() ;
#
# Satellite-view.
#
# Do this plot in white with Softfill over the water and no lat/lon
# lines
#
&NCAR::arinam ($MAP, $LMAP);
&NCAR::gsplci (1);
&NCAR::mappos (.5125,.73125,.3875,.60625);
&NCAR::maproj ('SV',0.,0.,0.);
&NCAR::mapstr ('SA - SATELLITE DISTANCE',2.);
&NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::arscam ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&SHADE1);
&NCAR::maplbl();
&NCAR::maplot();
#
# Mercator.
#
&NCAR::arinam ($MAP, $LMAP);
&NCAR::gsplci (1);
&NCAR::mappos (.75625,.975,.3875,.60625);
&NCAR::maproj ('ME',0.,0.,0.);
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::arscam ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&SHADE2);
&NCAR::maplbl();
&NCAR::maplot();
#
# Cylindrical equidistant.
#
&NCAR::arinam ($MAP, $LMAP);
&NCAR::gsplci (1);
&NCAR::mappos (.025,.4875,.13125,.3625);
&NCAR::maproj ('CE',0.,0.,0.);
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::arscam ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&CFILL);
&NCAR::maplbl();
&NCAR::maplot();
#
# Mollweide type.
#
&NCAR::arinam ($MAP, $LMAP);
&NCAR::gsplci (1);
&NCAR::mappos (.5125,.975,.13125,.3625);
&NCAR::maproj ('MO',0.,0.,0.);
&NCAR::mapint();
&NCAR::mapbla ($MAP);
&NCAR::arscam ($MAP, $XCS, $YCS, $MCS, $IAREA, $IGRP, $NIDS, \&CFILL);
&NCAR::maplbl();
&NCAR::maplot();
#
# and the labels under each sub-plot.
#
&NCAR::gslwsc(2.);
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::plchhq (.134375,.61875,'LAMBERT CONFORMAL CONIC',.0085,0.,0.);
&NCAR::plchhq (.378125,.61875,'STEREOGRAPHIC',.0085,0.,0.);
&NCAR::plchhq (.621875,.61875,'ORTHOGRAPHIC', .0085,0.,0.);
&NCAR::plchhq (.865625,.61875,'LAMBERT EQUAL-AREA',.0085,0.,0.);
&NCAR::plchhq (.134375,.375,'GNOMONIC',.0085,0.,0.);
&NCAR::plchhq (.378125,.375,'AZIMUTHAL EQUIDISTANT',.0085,0.,0.);
&NCAR::plchhq (.621875,.375,'SATELLITE-VIEW',.0085,0.,0.);
&NCAR::plchhq (.865625,.375,'MERCATOR', .0085,0.,0.);
&NCAR::plchhq (.25625,.11875,'CYLINDRICAL EQUIDISTANT',.0085,0.,0.);
&NCAR::plchhq (.74375,.11875,'MOLLWEIDE TYPE',.0085,0.,0.);
#
# Draw a boundary around the edge of the plotter frame.
#
#      CALL BNDARY
#
# Advance the frame.
#
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#

sub MASK {
  my ($XC,$YC,$MCS,$AREAID,$GRPID,$IDSIZE) = @_;
#
# Retrieve area id for geographical area
#
  my $ID;
  for my $I ( 1 .. $IDSIZE )  {
    if( at( $GRPID, $I-1 ) == 1 ) { $ID = at( $AREAID, $I-1 ); }
  }
#
# If the line is over water, and has 2 or more points draw it.
#
  if( ( &NCAR::mapaci( $ID ) == 1 ) && ( $MCS >= 2 ) ) {
    &NCAR::curved($XC,$YC,$MCS);
  }
#
# Otherwise, don't draw the line - mask it.
#
}
sub SHADE1 {
  my ($XC, $YC, $NPTS, $AREAID, $GRPID, $IDSIZE) = @_;
#
# Fill area map
#
  my $IWRK = zeroes long, 5000;
  my $RWRK = zeroes float, 5000;

  my $IAID = 0;
  for my $I ( 1 .. $IDSIZE ) {
    if( at( $GRPID, $I-1 ) == 1 ) { $IAID = at( $AREAID, $I-1 ); }
  }
#
# Fill Areas over land using softfill
#
# Areas over water have area color indices of 1 so we use that to 
# distinguish them.
#
  if( ( $IAID > 0 ) && ( &NCAR::mapaci( $IAID ) == 1 ) ) {
    &NCAR::sfsetr('SP',.005);
    &NCAR::sfsetr('ANGLE', 45.);
    &NCAR::sfwrld($XC, $YC, $NPTS-1, $RWRK, 5000, $IWRK, 5000);
  }

}
sub SHADE2 {
  my ($XC, $YC, $NPTS, $AREAID, $GRPID, $IDSIZE) = @_;
#
# Fill area map
#
  my $IWRK = zeroes long, 10000;
  my $RWRK = zeroes float, 10000;
      
  &NCAR::gsfais (1);
  my $IAID = 0;
  for my $I ( 1 .. $IDSIZE ) {
    if( at( $GRPID, $I-1 ) == 1 ) { $IAID = at( $AREAID, $I-1 ); }
  }
#
# Fill Areas over land using softfill
#
# Areas over water have area color indices of 1 so we use that to 
# distinguish them.
#
  if( $IAID > 0 ) {
    if( &NCAR::mapaci( $IAID ) == 1 ) {
      &NCAR::sfsetr('SP',.005);
      &NCAR::sfsetr('ANGLE', 45.);
      &NCAR::sfwrld($XC, $YC, $NPTS-1, $RWRK, 10000, $IWRK, 10000);
    } else {
      &NCAR::gsfaci (&NCAR::mapaci( $IAID ));
      &NCAR::gfa ($NPTS, $XC, $YC);
    }
  }

}

sub CFILL {
  my ($XC, $YC, $NPTS, $AREAID, $GRPID, $IDSIZE) = @_;
#
# Fill area map
#
      
  my $ICOL = 0;
  my $IAREA;
  for my $I ( 1 .. $IDSIZE ) {
    if( at( $GRPID, $I-1 ) == 1 ) { $IAREA = at( $AREAID, $I-1 ) };
  }
   
  if( $IAREA >= 1 ) { 
    $ICOL = &NCAR::mapaci($IAREA);
    if( $ICOL == 1 ) {
#
# Color the ocean blue.
#
      &NCAR::gsfaci(2);
      &NCAR::gfa($NPTS-1, $XC, $YC);
    } else {
#
# If the area is over land, fill it using the country color id.
#
      &NCAR::gsfaci($ICOL+2);
      &NCAR::gfa($NPTS-1, $XC, $YC);
    }
  }
      
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
  &NCAR::gscr($IWKID,  1, 1.0, 1.0, 1.0);
#
# Aqua
#
  &NCAR::gscr($IWKID,  2, 0.0, 0.9, 1.0);
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
# Yellow
#
  &NCAR::gscr($IWKID,  6, 1.0, 1.0, 0.0);
#
# GreenYellow
#
  &NCAR::gscr($IWKID,  7, 0.7, 1.0, 0.2);
#
# Chartreuse
#
  &NCAR::gscr($IWKID,  8, 0.5, 1.0, 0.0);
#
# Celeste
#
  &NCAR::gscr($IWKID,  9, 0.2, 1.0, 0.5);
#
# Green
#
  &NCAR::gscr($IWKID, 10, 0.2, 0.8, 0.2);
#
# DeepSkyBlue
#
  &NCAR::gscr($IWKID, 11, 0.0, 0.75, 1.0);
#
# RoyalBlue
#
  &NCAR::gscr($IWKID, 12, 0.25, 0.45, 0.95);
#
# SlateBlue
#
  &NCAR::gscr($IWKID, 13, 0.4, 0.35, 0.8);
#
# DarkViolet
#
  &NCAR::gscr($IWKID, 14, 0.6, 0.0, 0.8);
#
# Orchid
#
  &NCAR::gscr($IWKID, 15, 0.85, 0.45, 0.8);
#
# Lavender
#
  &NCAR::gscr($IWKID, 16, 0.8, 0.8, 1.0);
#
# Gray
#
  &NCAR::gscr($IWKID, 17, 0.7, 0.7, 0.7);
#
# Done.
#
}


rename 'gmeta', 'ncgm/cmptit.ncgm';
