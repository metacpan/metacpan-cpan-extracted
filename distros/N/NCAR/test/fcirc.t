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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Demonstrate different GKS fill types
#
my ( $NPTS, $MAPSIZ, $NGRPS, $NC ) = ( 101, 5000, 3, 200 );
my $MAP = zeroes long, $MAPSIZ;
my $IAREA = zeroes long, $NGRPS;
my $IGRP = zeroes long, $NGRPS;
my $X1 = zeroes float, $NPTS;
my $Y1 = zeroes float, $NPTS;
my $X2 = zeroes float, $NPTS;
my $Y2 = zeroes float, $NPTS;
my $X3 = zeroes float, $NPTS;
my $Y3 = zeroes float, $NPTS;
my $XC = zeroes float, $NC;
my $YC = zeroes float, $NC;

#     EXTERNAL FILL
#
# Convert from degrees to radians.
#
my $D2R = .017453292519943;
#
# Generate three intersecting circles of radius 1.
#
for my $I ( 1 .. $NPTS ) {
  my $ANG=$D2R*3.6*($I-1);
  my $X=cos($ANG);
  my $Y=sin($ANG);
  set( $X1, $I-1, $X - .5 );
  set( $X2, $I-1, $X + .5 );
  set( $X3, $I-1, $X      );
  set( $Y1, $I-1, $Y + .5 );
  set( $Y2, $I-1, $Y + .5 );
  set( $Y3, $I-1, $Y - .5 );
}
#
# Define the entire viewport and
# a window from -2. to 2 with linear scaling.
#
&NCAR::set(0.,1.,0.,1.,-2.,2.,-2.,2.,1);
#
# Initialize the area map
#
&NCAR::arinam($MAP,$MAPSIZ);
#
# Add the three objects as 3 edge groups
#
&NCAR::aredam($MAP,$X1,$Y1,$NPTS,1,1,0);
&NCAR::aredam($MAP,$X2,$Y2,$NPTS,2,2,0);
&NCAR::aredam($MAP,$X3,$Y3,$NPTS,3,4,0);
#
# Fill the different regions
#
&NCAR::arscam($MAP,$XC,$YC,$NC,$IAREA,$IGRP,$NGRPS,\&FILL);

print STDERR "
WARNING:
fcirc.ncgm generates an error message when viewed.
";

sub FILL {
  my ($XC, $YC, $NC, $AREA, $IGRP, $NGRPS) = @_;

  my $ICOLOR=0;
  for my $I ( 1 .. $NGRPS ) {
    $ICOLOR = $ICOLOR + at( $IAREA, $I-1 );
  }
#
#  FILL THE REGION WITH THE APPROPRIATE COLOR
#
  if( $ICOLOR > 0 ) {
    &NCAR::gsfais( $ICOLOR % 4 );
    &NCAR::gfa($NC-1,$XC,$YC);
  }
}




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fcirc.ncgm';
