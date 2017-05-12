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
#  Define the number of values, the number of hues, the number
#  of saturations, and the number of points bounding a color box.
#
my ( $NW, $NCOL, $NSAT, $NPTS ) = ( 3, 16, 4, 4 );
my ( @X, @Y );
#

my $PI = 3.14159265;
#
#  Define the values to be used.
#
my @VAL = ( 0.60, 0.80, 1.00 );
#
#  Y-coordinates for the saturation labels.
#
my @ST = ( -.1, -.375, -.625, -.850 );
#
my $IASF = zeroes long, 13;

&NCAR::gsclip(0);
&NCAR::gsasf($IASF);
&NCAR::gsfais(1);
#
#  Background and foreground colors.
#
&NCAR::gscr(1,0,0.0,0.0,0.0);
&NCAR::gscr(1,1,1.0,1.0,1.0);
#
#  Loop on the values.
#

print STDERR "\n";

for my $IL ( 1 .. $NW ) {
  my $INDEX = 2;
  &NCAR::set(.1,.9,.1,.9,-1.2,1.2,-1.2,1.2,1);
  my $RINC = 2 * $PI / $NCOL;
  my $HINC = 360.0  / $NCOL;
  my $SINC =  1.00  / ($NSAT - 1);
#
#  Loop on the hues.
#

  
  my ( $R, $G, $B );
  for my $IHUE ( 0 .. $NCOL - 1 ) {
    my $HUE = $IHUE * $HINC;
    my $THETA1 = ($IHUE -.5) * $RINC;
    my $THETA2 = ($IHUE +.5) * $RINC;
    $X[0] = 0;
    $X[3] = 0;
    $Y[0] = 0;
    $Y[3] = 0;
    
    for my $ISAT ( 1 .. $NSAT ) {
      my $SAT = ($ISAT - 1) * $SINC;
      &NCAR::hsvrgb($HUE,$SAT,$VAL[ $IL - 1 ], $R, $G, $B);
      &NCAR::gscr(1,$INDEX,$R,$G,$B);
      &NCAR::gsfaci($INDEX);
      
      my $RLEN = $ISAT / $NSAT;
      $X[1] = cos($THETA1) * $RLEN;
      $Y[1] = sin($THETA1) * $RLEN;
      $X[2] = cos($THETA2) * $RLEN;
      $Y[2] = sin($THETA2) * $RLEN;
      
      &NCAR::gfa(4, float( \@X ), float( \@Y ) );
      $X[0] = $X[1];
      $X[3] = $X[2];
      $Y[0] = $Y[1];
      $Y[3] = $Y[2];
       
      $INDEX++;
    }

  }    
#
#  Label the plots.
#
  
&NCAR::pcseti( 'QU  - QUALITY FLAG', 0 );
&NCAR::pcseti( 'CD  - SELECT DUPLEX DATA SET', 1 );

  my $TITLE = sprintf( "VALUE = %4.2f", $VAL[ $IL - 1 ] );
  &NCAR::gsplci(1);
  &NCAR::plchhq(0.0,1.25, substr( $TITLE, 0, 12 ),21.0,0.0,0.0);
  for my $L ( 2 .. $NSAT ) {
    my $SAT = ( $L - 1 ) * $SINC;
    $TITLE = sprintf( "S = %4.2f", $SAT );
    &NCAR::plchhq(0.0,$ST[ $L - 1 ], substr( $TITLE, 0, 6 ),15.0,0.0,0.0);
    
  }

  &NCAR::plotif(0.,0.,2);
  &NCAR::gsplci(1);
  &NCAR::line(.98,0.,1.03,0.);
  &NCAR::plchhq(1.08,0.,'Hue=0.',15.0,0.0,-1.0);
  &NCAR::line( .700,.700, .750,.740);
  &NCAR::plchhq( .80,.740,'Hue=45.',15.0,0.0,-1.0);
  &NCAR::line(-.700,.700,-.750,.740);
  &NCAR::plchhq(-.80,.740,'Hue=135.',15.0,0.0,1.0);
  &NCAR::line(-.700,-.700,-.750,-.740);
  &NCAR::plchhq(-.80,-.740,'Hue=225.',15.0,0.0,1.0);
  &NCAR::line( .700,-.700, .750,-.740);
  &NCAR::plchhq( .80,-.740,'Hue=315.',15.0,0.0,-1.0);
  &NCAR::frame;

}




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/coex03.ncgm';
