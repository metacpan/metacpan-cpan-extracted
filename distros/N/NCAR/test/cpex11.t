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
# Declare the data array and the real and integer workspace arrays.
#
my $ZDAT = zeroes float, 37, 19;
my $RWRK = zeroes float, 10000;
my $IWRK = zeroes long, 10000;
#
# Define the constant pi/180, used to convert angles from degrees to
# radians.
#
my $DTOR = .017453292519943;
#
# Define a global array of data using a simple function of longitude
# (which is a linear function of the first subscript of the data array)
# and latitude (which is a linear function of the second subscript).
#
for my $I ( 1 .. 37 ) {
  my $RLON=-180.+10.*($I-1);
  for my $J ( 1 .. 19 ) {
    my $RLAT=-90.+10.*($J-1);
    set( $ZDAT, $I - 1, $J - 1, sin($DTOR*$RLON)*cos($DTOR*$RLAT) );
  }
}
#
# Salt in a few special values.
#

 set( $ZDAT, 1 - 1, 8 - 1, 1.E36 );
 set( $ZDAT, 2 - 1, 8 - 1, 1.E36 );
 set( $ZDAT, 3 - 1, 8 - 1, 1.E36 );
 set( $ZDAT,35 - 1, 8 - 1, 1.E36 );
 set( $ZDAT,36 - 1, 8 - 1, 1.E36 );
 set( $ZDAT,37 - 1, 8 - 1, 1.E36 );
 set( $ZDAT,19 - 1, 9 - 1, 1.E36 );
 set( $ZDAT,16 - 1,10 - 1, 1.E36 );
 set( $ZDAT,17 - 1,10 - 1, 1.E36 );
 set( $ZDAT,18 - 1,10 - 1, 1.E36 );
 set( $ZDAT,19 - 1,10 - 1, 1.E36 );
 set( $ZDAT,20 - 1,10 - 1, 1.E36 );
 set( $ZDAT,21 - 1,10 - 1, 1.E36 );
 set( $ZDAT,22 - 1,10 - 1, 1.E36 );
 set( $ZDAT,19 - 1,11 - 1, 1.E36 );
 set( $ZDAT, 1 - 1,12 - 1, 1.E36 );
 set( $ZDAT, 2 - 1,12 - 1, 1.E36 );
 set( $ZDAT, 3 - 1,12 - 1, 1.E36 );
 set( $ZDAT,35 - 1,12 - 1, 1.E36 );
 set( $ZDAT,36 - 1,12 - 1, 1.E36 );
 set( $ZDAT,37 - 1,12 - 1, 1.E36 );
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Tell EZMAP what part of the plotter frame to use.
#
&NCAR::mappos (.05,.95,.01,.91);
#
# Tell EZMAP what projection to use.  This projection maps the entire
# globe to the interior of a circle of radius 2.  Distortion near the
# outer edge of the circle is very great; mapped points from the data
# grid become so widely separated that contour lines wind up crossing
# each other.
#
&NCAR::maproj ('LE',75.,99.,0.);
#
# Initialize EZMAP.
#
&NCAR::mapint;
#
# Tell CONPACK to map its output through CPMPXY, using that value which
# causes the EZMAP routine MAPTRA to be called.
#
&NCAR::cpseti( 'MAP - MAPPING FLAG', 1 );
#
# Tell CONPACK what value EZMAP returns for the out-of-range value.
#
&NCAR::cpsetr( 'ORV - OUT-OF-RANGE VALUE', 1.E12 );
#
# Tell CONPACK not to do a SET call (because EZMAP has already done it).
#
&NCAR::cpseti( 'SET - DO-SET-CALL FLAG', 0 );
#
# Tell CONPACK what the special value is.
#
&NCAR::cpsetr( 'SPV - SPECIAL VALUE', 1.E36 );
#
# Tell CONPACK what values are to be associated with the extreme values
# of each of the subscripts of the data array.
#
&NCAR::cpsetr( 'XC1 - X COORDINATE AT I=1', -180. );
&NCAR::cpsetr( 'XCM - X COORDINATE AT I=M', +180. );
&NCAR::cpsetr( 'YC1 - Y COORDINATE AT J=1', -90. );
&NCAR::cpsetr( 'YCN - Y COORDINATE AT J=N', +90. );
#
# Tell CONPACK to draw the mapped boundary of the data grid.
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -1 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
#
# Tell CONPACK to draw the mapped boundary of the area filled with
# special values.
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -2 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
#
# Tell CONPACK to draw a limb line (separating areas that are visible
# under the projection from area that are not visible).
#
&NCAR::cpseti( 'PAI - PARAMETER ARRAY INDEX', -3 );
&NCAR::cpseti( 'CLU - CONTOUR LEVEL USE FLAG', 1 );
#
# Tell PLOTCHAR not to interpret colons as function-code signal
# characters.
#
&NCAR::pcsetc( 'FC', "\0" );
#
# Tell PLOTCHAR to use one of the filled fonts.
#
&NCAR::pcseti( 'FN', 25 );
#
# Tell CONPACK what the dimensions of the data array and the workspace
# arrays are and make it initialize itself.
#
&NCAR::cprect ($ZDAT,37,37,19,$RWRK,10000,$IWRK,10000);
#
# Draw the mapped contour lines, the mapped edges of the grid, the
# mapped edges of the special value area, and the visible/invisible
# boundary of the mapping.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Put a label at the top of the first frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),
     'Using certain mappings can cause a problem like this:  Grid',
     .018,0.,0.);
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.939),
     'points are spread so far apart that contour lines cross.',
     .018,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Set the value of the parameters 'PIC' and 'PIE' to interpolate points
# on all contour lines and all edge lines.
#
&NCAR::cpseti( 'PIC - POINT INTERPOLATION ON CONTOURS   ', 7 );
&NCAR::cpseti( 'PIE - POINT INTERPOLATION ON OTHER EDGES', 7 );
#
# Again draw the mapped contour lines, the mapped edges of the grid,
# the mapped edges of the special value area, and the visible/invisible
# boundary of the mapping.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Label the second frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),
     'Using \'PIC\' = \'PIE\' = 7 solves the problem expensively by',
     .018,0.,0.);
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.939),
     'interpolating seven points on every segment before mapping.',
     .018,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Turn off the interpolation requested by 'PIC' and 'PIE'.
#
&NCAR::cpseti( 'PIC - POINT INTERPOLATION ON CONTOURS   ', 0 );
&NCAR::cpseti( 'PIE - POINT INTERPOLATION ON OTHER EDGES', 0 );
#
# Set the value of the parameter 'PIT' to .05 to turn on interpolation
# of points only in problem areas (where the X/Y distance between points
# in user space exceeds 5/100ths of the horizontal/vertical dimension
# of the window.
#
&NCAR::cpsetr( 'PIT - POINT INTERPOLATION THRESHOLD', .05 );
#
# Again draw the mapped contour lines, the mapped edges of the grid,
# the mapped edges of the special value area, and the visible/invisible
# boundary of the mapping.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Label the third frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),
     'Using \'PIT\' = .05 solves the problem less expensively (and',
                                                          .018,0.,0.);
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.939),
     'more reliably) by interpolating points only as needed.',
                                                          .018,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Now turn smoothing on, using a value that says to smooth before
# mapping.
#
&NCAR::cpsetr( 'T2D - TENSION ON 2D SMOOTHER', -2.5 );
#
# Again draw the mapped contour lines, the mapped edges of the grid,
# the mapped edges of the special value area, and the visible/invisible
# boundary of the mapping.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Label the fourth frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),
     'With \'PIT\' on, you can still smooth: Here, \'T2D\' = -2.5,',
                                                          .018,0.,0.);
&NCAR::plchhq (&NCAR::cfuy(.5),&NCAR::cfuy(.939),
     'which causes the smoothing to be done before the mapping.',
                                                          .018,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Now turn smoothing on, using a value that says to smooth after
# mapping.
#
&NCAR::cpsetr( 'T2D - TENSION ON 2D SMOOTHER', 2.5 );
#
# Again draw the mapped contour lines, the mapped edges of the grid,
# the mapped edges of the special value area, and the visible/invisible
# boundary of the mapping.
#
&NCAR::cpcldr ($ZDAT,$RWRK,$IWRK);
#
# Label the fifth frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),
     'With \'PIT\' on, you can still smooth: Here, \'T2D\' = +2.5,',
                                                          .018,0.,0.);
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.939),
     'which causes the smoothing to be done after the mapping.',
                                                          .018,0.,0.);




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/cpex11.ncgm';
