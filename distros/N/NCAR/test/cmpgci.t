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
#	$Id: cmpgci.f,v 1.4 1995/06/14 14:07:04 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my $IGRD = 2;
my ( $M, $N ) = ( int( 180/$IGRD ), int( 360/$IGRD ) );
my $RLAT = zeroes float, 100;
my $RLON = zeroes float, 100;
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Draw a map
#
&NCAR::supmap(8,0.,-50.,0.,
              float( [   0., 0 ] ),
	      float( [ -80., 0 ] ),
	      float( [  90., 0 ] ),
	      float( [  10., 0 ] ),
	      2,0.,0,0,my $IERR);
#
# Get data values defining a great circle between Washinton DC and
# London
#
&NCAR::mapgci(38.,-77.,51.,0.,100,$RLAT,$RLON);
#
# Draw the great circle
#
&NCAR::mapit(38.,-77.,0);
for my $I ( 1 .. 100 ) {
  &NCAR::mapit(at( $RLAT, $I-1 ),at( $RLON, $I-1 ),1);
}
&NCAR::mapit(51.,0.,1);
&NCAR::mapiq();
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


rename 'gmeta', 'ncgm/cmpgci.ncgm';
