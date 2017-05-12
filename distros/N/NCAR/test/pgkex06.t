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
my $ILD=121;
my $PLX = zeroes float, $ILD;
my $PLY = zeroes float, $ILD;
my $DLX = zeroes float, $ILD;
my $DLY = zeroes float, $ILD;
my $RADC = .0174532;
#
#  Define color indices, color index 0 defines the background color.
#
&NCAR::gscr(1,0, 1.0, 1.0, 1.0);
&NCAR::gscr(1,1, 0.0, 0.0, 0.0);
&NCAR::gscr(1,2, 1.0, 0.0, 0.0);
&NCAR::gscr(1,3, 0.0, 0.0, 1.0);
&NCAR::gscr(1,4, 0.0, 1.0, 0.0);
&NCAR::gscr(1,5, 0.4, 0.0, 0.4);
#
#  Generate data for a spiral.
#
my $J = 0;
for( my $I = 0; $I <= 720; $I += 6 ) {
 my $SCALE = $I/4500.;
 $J = $J+1;
 set( $PLX, $J - 1, $SCALE * cos( ( $I - 1 ) * $RADC ) );
 set( $PLY, $J - 1, $SCALE * sin( ( $I - 1 ) * $RADC ) );
}
#
#  Draw spirals with different linetypes, colors, and widths.
#
for my $I ( 1 .. 4 ) {
  my $X = .28+.42*($I % 2);
  my $Y = .25+.41*(int(($I-1)/2));
  &NCAR::gsplci($I);
  my $WDTH = 2.*($I-1)+1.;
  &NCAR::gslwsc($WDTH);
  &NCAR::gsln($I);
  for my $J ( 1 .. $ILD ) {
    set( $DLX, $J - 1, $X + at( $PLX, $J - 1 ) );
    set( $DLY, $J - 1, $Y + at( $PLY, $J - 1 ) );
  }
  &NCAR::gpl($ILD,$DLX,$DLY);
#
#  Label the lines.
#

  my $LABEL1 = sprintf( 'Type = %1.1d', $I );
  my $LABEL2 = sprintf( 'Width = %3.1d', $WDTH );
  &NCAR::gstxal(2,3);
  &NCAR::gschh(.022);
  &NCAR::gstxfp(-12,2);
  &NCAR::gstxci(5);
  &NCAR::gtx($X,$Y+.18,$LABEL1);
  &NCAR::gtx($X,$Y+.14,$LABEL2);
}
#
#  Label the plot using Plotchar.
#
&NCAR::gsln(1);
#     
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 5 );
&NCAR::plchhq(.5,.93,'Polylines',.035,0.,0.);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex06.ncgm';
