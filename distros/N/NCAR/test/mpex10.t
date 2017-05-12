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

#
# Assume you have a FORTRAN function that, given the position of a
# point on the surface of the earth, returns the real value of some
# physical quantity there.  You would like to split the full range of
# values of the quantity into intervals, associate a different color
# with each interval, and then draw a colored map of the resulting
# globe.  One way to do this is to use the contouring package CONPACK;
# another way to do it is given below.
#
# This program constructs a rectangular cell array covering the part
# of the plotter frame occupied by a selected map of the globe.  Each
# element of the cell array occupies a small rectangular portion of
# the plotter frame.  The EZMAP routine MAPTRI, which does the inverse
# transformations, is used to find the values of latitude and longitude
# associated with each cell; these can be used to obtain the value of
# the physical quantity and therefore the color index associated with
# the cell.  When the cell array is complete, it is drawn by a call to
# the GKS routine GCA.
#
#
# Define an integer array in which to build the cell array.
#
my $ICRA = zeroes long, 1000, 1000;
#
# NCLS specifies the number of cells along each edge of the cell array.
# Use a positive value less than or equal to 1000.
#
my $NCLS = 300;
#
# NCLR specifies the number of different colors to be used.
#
my $NCLR = 64;
#
# PROJ is the desired projection type.  Use one of 'LC', 'ST', 'OR',
# 'LE', 'GN', 'AE', 'SV', 'CE', 'ME', or 'MO'.
#
my $PROJ = 'OR';
#
# PLAT and PLON are the desired latitude and longitude of the center of
# the projection, in degrees.
#
my ( $PLAT, $PLON ) = ( 40. , -105. );
#
# ROTA is the desired final rotation of the map, in degrees.
#
my $ROTA = 0.;
#
# SALT, ALFA, and BETA are the desired values of the parameters 'SA',
# 'S1', and 'S2', which are only used with a satellite-view projection.
# SALT is the distance of the satellite from the center of the earth,
# in units of earth radii.  ALFA is the angle, in degrees, between the
# line of sight and the line to the center of the earth.  BETA is used
# only when ALFA is non-zero; it is the angle, in degrees, measured
# counterclockwise, from the plane passing through the satellite, the
# center of the earth, and the point which is due east on the horizon
# to the plane in which the line of sight and the line to the center
# of the earth both lie.
#
my ( $SALT, $ALFA, $BETA ) = ( 1.25 , 15. , 90. );
#
# JLTS, PLM1, PLM2, PLM3, and PLM4 are the required arguments of the
# EZMAP routine MAPSET, which determines the boundaries of the map.
#
my $JLTS = 'MA';
my $PLM1 = float [ 0. , 0. ];
my $PLM2 = float [ 0. , 0. ];
my $PLM3 = float [ 0. , 0. ];
my $PLM4 = float [ 0. , 0. ];
#
# IGRD is the spacing, in degrees, of the EZMAP grid of latitudes and
# longitudes.
#
my $IGRD = 15;
#
# Define the constant used to convert from degrees to radians.
#
my $DTOR = .017453292519943;
#
# Define the color indices required.  0 and 1 are used for black and
# white (as is customary); the next NCLR values are distributed between
# pure blue (color 2) and pure red (color NCLR+1).
#
&NCAR::gscr (1,0,0.,0.,0.);
&NCAR::gscr (1,1,1.,1.,1.);
#
for my $ICLR ( 1 .. $NCLR ) {
  &NCAR::gscr (1,1+$ICLR,($ICLR-1)/($NCLR-1),0.,($NCLR-$ICLR)/($NCLR-1));
}
#
# Set the EZMAP projection parameters.
#
&NCAR::maproj ($PROJ,$PLAT,$PLON,$ROTA);
if( $PROJ =~ m/^SV/o ) {
  &NCAR::mapstr ('SA',$SALT);
  &NCAR::mapstr ('S1',$ALFA);
  &NCAR::mapstr ('S2',$BETA);
}
#
# Set the limits of the map.
#
&NCAR::mapset ($JLTS,$PLM1,$PLM2,$PLM3,$PLM4);
#
# Set the grid spacing.
#
&NCAR::mapsti ('GR - GRID SPACING',$IGRD);
#
# Initialize EZMAP, so that calls to MAPTRI will work properly.
#
&NCAR::mapint();
#
# Fill the cell array.  The data generator is rigged to create
# values between 0 and 1, so as to make it easy to interpolate to
# get a color index to be used.  Obviously, the statement setting
# DVAL can be replaced by one that yields a value of some real data
# field of interest (normalized to the range from 0 to 1).
#
for my $I ( 1 .. $NCLS ) {
  my $X=&NCAR::cfux(.05+.90*(($I-1)+.5)/($NCLS));
  for my $J ( 1 .. $NCLS ) {
    my $Y=&NCAR::cfuy(.05+.90*(($J-1)+.5)/($NCLS));
    &NCAR::maptri ($X,$Y,my ( $RLAT,$RLON ) );
    if( $RLAT != 1.E12 ) {
      my $DVAL=.25*(1.+cos($DTOR*10.*$RLAT))
              +.25*(1.+sin($DTOR*10.*$RLON))*cos($DTOR*$RLAT);
      set( 
       $ICRA, $J-1, $I-1, 
       &NCAR::Test::max( 2,&NCAR::Test::min($NCLR+1,2+int($DVAL*$NCLR)))
      );
    } else {
      set( $ICRA, $J-1, $I-1, 0 );
    }
  }
}
#
# Draw the cell array.
#
&NCAR::gca (&NCAR::cfux(.05),&NCAR::cfuy(.05),&NCAR::cfux(.95),&NCAR::cfuy(.95),
            1000,1000,1,1,$NCLS,$NCLS,$ICRA);
#
# Draw a map on top of the cell array.
#
&NCAR::mapdrw();
#
# Put a label at the top of the plot.
#
&NCAR::set   (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::wtstr (.5,.975,'EXAMPLE 10',2,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex10.ncgm';
