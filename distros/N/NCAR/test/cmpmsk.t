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
#   $Id: cmpmsk.f,v 1.4 1995/06/14 14:07:12 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT,, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );



my $PLIM1 = float [ 0., 0. ];
my $PLIM2 = float [ 0., 0. ];
my $PLIM3 = float [ 0., 0. ];
my $PLIM4 = float [ 0., 0. ];
#
# Open GKS, Turn Clipping off
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Invoke demo driver
#
CMPMSK('SV',40.,-50.,0.,'PO','MA',$PLIM1,$PLIM2,$PLIM3,$PLIM4,10.);
#
# Advance the frame.
#
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();

sub CMPMSK {
  my ($PROJ, $PLAT, $PLON, $ROTA, $OUTLN,$JLIM, 
      $PLIM1, $PLIM2, $PLIM3, $PLIM4, $GRD) = @_;

#     EXTERNAL MASK
  my ( $LMAP, $NWRK, $ISIZ ) = ( 150000, 1000, 5 );
  my $MAP = zeroes long, $LMAP;
  my $IAREA = zeroes long, $ISIZ;
  my $IGRP = zeroes long, $ISIZ;
  my $XWRK = zeroes float, $NWRK;
  my $YWRK = zeroes float, $NWRK;
#
# CMPLOT demonstrates MAPLOT drawing continental and political outlines
#
# Use solid lines for grid
#
  &NCAR::dashdb(65535);
#
# Draw Continental, political outlines 
#
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR',$OUTLN);
#
# Set grid spacing
#
  &NCAR::mapstr ('GR - GRID SPACING',$GRD);
#
# Set up projection
#
  &NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# If it's a satellite projection, choose a satellite distance
#
  if( $PROJ eq ' SV' ) { &NCAR::mapstr('SA - SATELLITE DISTANCE',7.); }
#
# Set limits of map
#
  &NCAR::mapset ($JLIM,$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Initialize Maps and Areas
#
  &NCAR::mapint();
  &NCAR::arinam ($MAP,$LMAP);
  &NCAR::mapbla ($MAP);
#
# Draw Masked Grid Lines
#
  &NCAR::mapgrm ($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $ISIZ, \&MASK);
#
# Draw Continental Outlines and Elliptical Perimeter
#
  &NCAR::mapsti('LA - LABEL FLAG',0);
  &NCAR::mapsti('EL - ELLIPTICAL-PERIMETER SELECTOR',1);
  &NCAR::maplbl();
  &NCAR::maplot();
#
# Done.
#
}

sub MASK {
  my ($XC,$YC,$MCS,$AREAID,$GRPID,$IDSIZE) = @_;
#
# Retrieve area id for geographical area
#
  my $ID;
  for my $I ( 1 .. $IDSIZE ) {
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

   
rename 'gmeta', 'ncgm/cmpmsk.ncgm';
