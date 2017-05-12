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
#  Define colors.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 0.0, 0.0, 1.0);
&NCAR::gscr(1, 3, 0.4, 0.0, 0.4);
&NCAR::gscr(1, 4, 1.0, 0.0, 0.0);
#
#  Draw a star with interior style hollow (the style index is
#  a dummy in this call since it is ignored for interior style
#  hollow).
#
my $ISTYLE = 0;
my $ISTNDX = 1;
my $ICOLOR = 1;
&star(.35,.79,.09,$ISTYLE,$ISTNDX,$ICOLOR);
#
#  Label the hollow area using Plotchar.
#
&NCAR::pcseti( 'FN', 21 );
&NCAR::pcseti( 'CC', 3 );
&NCAR::gsfais(1);
&NCAR::plchhq(.17,.77,'Hollow',.022,0.,-1.);
#
#  Draw a star with interior style solid (the style index is
#  a dummy in this call since it is ignored for interior style
#  solid).
#
$ISTYLE = 1;
$ISTNDX = 1;
$ICOLOR = 1;
&star(.75,.79,.09,$ISTYLE,$ISTNDX,$ICOLOR);
#
#  Label the solid area.
#
&NCAR::gsfais(1);
&NCAR::plchhq(.60,.77,'Solid',.022,0.,-1.);
#
#  Draw stars with interior style hatch and with the six standardized
#  hatch styles:
#
#    Style index   Fill pattern
#    -----------   ------------
#       1          Horizontal lines
#       2          Vertical lines
#       3          Positive slope lines
#       4          Negative slope lines
#       5          Combined vertical and horizontal lines
#       6          Combined positive slope and negative slope lines
#
$ICOLOR = 2;
for my $I ( 1 .. 6 ) {
  my $X = .2+.3*(($I-1) % 3)+.02;
  my $Y = .3*(int((9-$I)/3))-.10;
  my $SCL = .15;
  $ISTYLE = 3;
  $ISTNDX = $I;
  &star($X,$Y,$SCL,$ISTYLE,$ISTNDX,$ICOLOR);
#
#  Label the hatched areas.
#
  &NCAR::gsfais(1);
  &NCAR::plchhq($X-.17,$Y-.004,'Hatch,',.018,0.,-1.);
  my $LABEL = sprintf( 'index %1.1d', $I );
  &NCAR::gsfais(1);
  &NCAR::plchhq($X-.17,$Y-.034,$LABEL,.018,0.,-1.);
}
#
#  Main plot label.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 3 );
&NCAR::gsfais(1);
&NCAR::plchhq(.5,.95,'Fill area interior styles',.035,0.,0.);

sub star {
  my ( $X,$Y,$SCL,$ISTYLE,$ISTNDX,$ICOLOR) = @_;
#
#  Draw a five-pointed star with interior style ISTYLE, style index
#  ISTNDX (if applicable), and colored using the color defined by
#  color index ICOLOR.
#
  my $ID=10;
#
#  Coordinate data for a five-pointed star.
#
  my $XS = float [
      0.00000, -0.22451, -0.95105, -0.36327, -0.58780,
      0.00000,  0.58776,  0.36327,  0.95107,  0.22453 
  ];
  my $YS = float [
      1.00000,  0.30902,  0.30903, -0.11803, -0.80900,
     -0.38197, -0.80903, -0.11805,  0.30898,  0.30901 
  ];

#
  my $XD = zeroes float, $ID;
  my $YD = zeroes float, $ID;
  for my $I ( 1 .. $ID ) {
     set( $XD, $I - 1, $X+$SCL*at( $XS, $I - 1 ) );
     set( $YD, $I - 1, $Y+$SCL*at( $YS, $I - 1 ) );
  }
#
  &NCAR::gsfais($ISTYLE);
  &NCAR::gsfaci($ICOLOR);
  &NCAR::gsfasi($ISTNDX);
  &NCAR::gfa($ID,$XD,$YD);
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex17.ncgm';
