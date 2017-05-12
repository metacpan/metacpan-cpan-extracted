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
#	$Id: cmptra.f,v 1.4 1995/06/14 14:07:18 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );


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
&CMPTRA('OR',35.,-105.,0.,'PO','CO',
        float( [   22., 0 ] ),
	float( [ -120., 0 ] ),
	float( [   47., 0 ] ),
	float( [  -65., 0 ] )
	);
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub CMPTRA {
  my ($PROJ, $PLAT, $PLON, $ROTA, $OUTLN,$JLIM, 
      $PLIM1, $PLIM2, $PLIM3, $PLIM4) = @_;

#
# CMPTRA demonstrates marking points on a map
#
# Draw Continental, political outlines 
#
  &NCAR::mapstc ('OU - OUTLINE DATASET SELECTOR',$OUTLN);
#
# Set up projection
#
  &NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
#
# If it's a satellite projection, choose a satellite distance
#
  if( $PROJ eq 'SV' ) { &NCAR::mapstr('SA - SATELLITE DISTANCE',5.); }
#
# Set limits of map
#
  &NCAR::mapset ($JLIM,$PLIM1,$PLIM2,$PLIM3,$PLIM4);
#
# Turn off Grid lines
#
  &NCAR::mapstr ('GR',0.);
#
# Draw map
#
  &NCAR::mapdrw();
#
# Draw a star over Boulder Colorado
#
  &NCAR::maptra(40.,-105.15,my ( $X,$Y ));
  if( $X != 1E12 ) { &NCAR::points(float([$X]), float([$Y]), 1, -3, 0); }
#
# Draw the state of Colorado in
#
  &NCAR::mapit (37.,-109.,0);
  &NCAR::mapit (41.,-109.,1);
  &NCAR::mapit (41.,-102.,1);
  &NCAR::mapit (37.,-102.,1);
  &NCAR::mapit (37.,-109.,1);
  &NCAR::mapiq();
#
# Advance the frame.
#
  &NCAR::frame();
#
# Done.
#
}
   
rename 'gmeta', 'ncgm/cmptra.ncgm';
