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
#   $Id: cezmap1.f,v 1.6 1999/03/09 22:11:59 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS, Turn Clipping off
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Invoke demo driver
#
&CEZMAP('SV',40.,-50.,0.);
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub CEZMAP {
  my ($PROJ,$PLAT,$PLON,$ROTA) = @_;
  
  my $PLIM1 = float [ 0.,0. ];
  my $PLIM2 = float [ 0.,0. ];
  my $PLIM3 = float [ 0.,0. ];
  my $PLIM4 = float [ 0.,0. ];
#
# CMPLOT demonstrates MAPLOT drawing continental and political outlines
#
# Set up Maps.
#
#
# Draw Continental, political outlines 
#
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR','PO');
#
# Set up projection
#
  &NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# If it's a satellite projection, choose a satellite distance
#
  if( $PROJ eq 'SV' ) { &NCAR::mapstr( 'SA - SATELLITE DISTANCE',5. ); }
#
# Set limits of map
#
  &NCAR::mapset ('MA',$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Draw map
#
  &NCAR::mapdrw();
#
# Advance the frame.
#
  &NCAR::frame();
#
# Done.
#
}
   
rename 'gmeta', 'ncgm/cezmap1.ncgm';
