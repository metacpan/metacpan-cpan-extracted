# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

unlink( 'gmeta' );

use PDL;
use NCAR::Test;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my $ZZX  = float [  -9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0, -1.0 ];
my $ZZYL = float [   6.5,  8.5,  6.5,  8.5,  6.5,  8.5,  6.5,  8.5,  6.5 ];
my $ZZYM = float [  -1.0,  1.0, -1.0,  1.0, -1.0,  1.0, -1.0,  1.0, -1.0 ];
my $CIRX = float [  6.15, 5.26, 4.25, 3.59, 3.59, 4.25, 5.26, 6.15, 6.50 ];
my $CIRY = float [  8.46, 8.98, 8.80, 8.01, 6.99, 6.20, 6.02, 6.54, 7.50 ];
# 
# 
#  Define normalization transformation 1 and select it.
#
&NCAR::gswn   (1, -10.0, 10.0, -10.0, 10.0);
&NCAR::gsvp   (1, 0.1, 0.9, 0.1, 0.9) ;
&NCAR::gselnt (1) ;
# 
#  Draw a zig-zag POLYLINE. 
#
&NCAR::gpl (9, $ZZX, $ZZYL);
#
#  Set the marker type to 2 (plus sign) and draw markers.
#
&NCAR::gsmk (2);
&NCAR::gpm (9, $ZZX, $ZZYM);
#  
#  Set the fill area interior style to 1 (solid fill) and draw a 
#  solid filled nonagon.
#
&NCAR::gsfais (1);
&NCAR::gfa (9, $CIRX, $CIRY);
# 
#  Define 24x12 foreground/background checkerboard pattern. 
#

my @icells;
for my $ix ( 1 .. 24 ) {
  my $jx = $ix % 2;
  for my $iy ( 1 .. 12 ) {
    my $jy = $iy % 2;
    if( ( ( $jx == 1 ) && ( $jy == 1 ) ) || ( ( $jx == 0 ) && ( $jy == 0 ) ) ) {
      $icells[ $ix - 1 ][ $iy - 1 ] = 1;
    } else {
      $icells[ $ix - 1 ][ $iy - 1 ] = 0;
    }
  }
}
#
#  Draw the checkerboard with CELL ARRAY. 
#
&NCAR::gca (1.5,-1.25,8.5,1.25, 24, 12, 1, 1, 24, 12, long( \@icells ) );
# 
#  Set the character height to 3% of the screen (.03*20.)
#
&NCAR::gschh (0.6) ;
#
#  Set the text alignment to "center" in the horizontal and "half" in
#  the vertical.
#
&NCAR::gstxal (2, 3);

my $xpos =  0.0;
my $ypos = -5.0;
#
#  Draw the text string. 
#
&NCAR::gtx (0.0, -7., 'Example text string');
#
#  Label the primitives.
#
&NCAR::gtx(-5.0,5.0,'Polyline');
&NCAR::gtx( 5.0,5.0,'Fill area');
&NCAR::gtx(-5.0,-2.5,'Polymarker');
&NCAR::gtx( 5.0,-2.5,'Cell array');
&NCAR::gtx( 0.0,-9.5,'Text');
#


&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex02.ncgm';
