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
my @RGB;

#
#  Set fill area interior style to solid.
#
&NCAR::gsfais(1);
#
#  Define all permutations of RGB's needed.
#
&colset(\@RGB);
#
#  Put out 5 color charts, varying the red value with each frame.
#
for my $NPAGE ( 1 .. 5 ) {
&setcol(\@RGB,$NPAGE,1);
&ttlbar();
&cube();
&title($NPAGE,1);
&NCAR::frame;
}

sub colset {;
  my $RGB = shift;
#
#  Define the RGB color triples needed.  This is done by filling the
#  RGB array with all 405 permutations for a 9 x 9 color cube in 5
#  plots.  All values are normalized to fall in the range 0 to 1.
#
  my @CLRS = (
         0.,  32.,  64.,
        96., 128., 160.,
       192., 224., 255.,
  );
#
  my $INDEX = 1;
  for my $i ( 1 .. 5 ) {
    for my $j ( 1 .. 9 ) {
      for my $k ( 1 .. 9 ) {
         $RGB->[ 0 ][ $INDEX - 1 ] = $CLRS[ 2 * $i - 2 ] / 255.;
         $RGB->[ 1 ][ $INDEX - 1 ] = $CLRS[ $j ] / 255.;
         $RGB->[ 2 ][ $INDEX - 1 ] = $CLRS[ $k ] / 255.;
         $INDEX++;
      }
    }
  }
}

sub setcol {
  my ( $RGB, $INDEX, $IWKID ) = @_;
  &NCAR::gscr($IWKID,0,0.,0.,0.);
  &NCAR::gscr($IWKID,1,1.,1.,1.);
  my $NDX = 81*($INDEX-1)+1;
  for my $n ( 1 .. 81 ) { 
     &NCAR::gscr($IWKID,$n+2, 
                 $RGB->[ 0 ][ $NDX - 1 ],
                 $RGB->[ 1 ][ $NDX - 1 ],
                 $RGB->[ 2 ][ $NDX - 1 ],
                 );
     $NDX++;   
  }
}

sub cube {
#
#  Draw 81 color squares of size DELX x DELY.  Start at position
#  (X1,Y1).  Use blank space of GAPX and GAPY between the squares.
#
  my $DELX=0.095;
  my $DELY=0.095;
  my $GAPX=$DELX-0.003;
  my $GAPY=$DELY-0.003;
  my $X1 = 0.13;
  my $Y1 = 0.075;
  my ( @CELLX, @CELLY );
#
#  Set the parameters for the starting point.
#
  my $X = $X1;
  my $Y = $Y1;
#
#  Start with color index 3 so that the foreground and background
#  color indices are not touched.
#
  my $INDCOL = 3;
#
#  Put out 9 x 9 squares.
#
  for my $i ( 1 .. 9 ) {
    for my $l ( 1 .. 9 ) {
#
#  Define square.
#
      $CELLX[0] = $X;
      $CELLY[0] = $Y;
      $CELLX[1] = $X + $GAPX;
      $CELLY[1] = $Y;
      $CELLX[2] = $X + $GAPX;
      $CELLY[2] = $Y + $GAPY;
      $CELLX[3] = $X;
      $CELLY[3] = $Y + $GAPY;
#
#  Set color to index INDCOL and draw square.
#
      &NCAR::gsfaci($INDCOL);
      &NCAR::gfa(4, float( \@CELLX ), float( \@CELLY ) );
      $X = $X + $DELX;
      $INDCOL = $INDCOL + 1;
    }
    $Y = $Y + $DELY;
    $X = $X1;
}
}

sub ttlbar {
#
#  Label the chart with the red intensity.
#
  my ( $X1, $Y1, $XSIDE, $YSIDE ) = ( 0.70, 0.93, 0.28, 0.04 );
#
#  Define the fill area.
#

  my ( @CELLX, @CELLY );
  $CELLX[0] = $X1;
  $CELLY[0] = $Y1;
  $CELLX[1] = $X1 + $XSIDE;
  $CELLY[1] = $Y1;
  $CELLX[2] = $X1 + $XSIDE;
  $CELLY[2] = $Y1 + $YSIDE;
  $CELLX[3] = $X1;
  $CELLY[3] = $Y1 + $YSIDE;
#
#  Set the color and draw the fill area.
#
  &NCAR::gsfaci(3);
  &NCAR::gfa(4, float( \@CELLX ), float( \@CELLY ) );
#
}
sub title {
  my ( $NPAGE, $IWKID ) = @_;
#
#  Label the chart using white characters..
#
  my @AX1 = ( .073, .048, .073 );
  my @AY1 = ( .900, .800, .800 );
  my @AX2 = ( .960, .860, .860 );
  my @AY2 = ( .028, .010, .028 );
  my ( $DELX, $DELY ) = ( .095, .095 );
  my @IL = (   3,    2,    2,    2,    1,    1,    1,    1,    1 );
#
  &NCAR::gsplci(1);
#
#  Print the title of each axis.
#
  &NCAR::plchhq(0.5,0.01,'Blue Axis' ,0.015,0.,0.);
  &NCAR::plchhq(0.05,0.5,'Green Axis',0.015,90.,0.);
#
#  Draw the arrow-line on each axis.
#
  &NCAR::line(0.073,0.90,0.073,0.078);
  &NCAR::gsfaci(1);
  &NCAR::gfa(3, float( \@AX1 ), float( \@AY1 ) );
#
  &NCAR::line(0.15,0.028,0.96,0.028);
  &NCAR::gsfaci(1);
  &NCAR::gfa(3, float( \@AX2 ), float( \@AY2 ) );
#
#  Print the red value for the frame at hand.
#
  my $ITMP = 64*($NPAGE-1);
  if( $NPAGE == 5 ) { $ITMP = 255 };
  my $RLV = $ITMP/255.;
  my $RVAL = sprintf( "RED = %3.3d = %4.2f", $ITMP, $RLV );
  &NCAR::plchhq(.84,.95,$RVAL,.014,0.,0.);
#
#  Print the Green values up the side.
#
  my $X = 0.10;
  my $Y1 = 0.125;
  my $Y2 = 0.108;
  
  for my $i ( 1 .. 9 ) {
    my $ITMP = 32 * ( $i - 1 );
    if( $i == 9 ) { $ITMP = 255; }
    my $CVAL = sprintf( "%3.3d", $ITMP );
    my $RVL = $ITMP / 255;
    my $DVAL = sprintf( "%4.2f", $RVL );
    #&NCAR::plchhq($X,$Y1,CVAL(IL(I):3),.008,0.,0.);
    &NCAR::plchhq($X,$Y2,$DVAL,.008,0.,0.);
    $Y1 = $Y1+$DELY;
    $Y2 = $Y2+$DELY;
  }
#
#  Print the Blue values across the bottom.
#
  my $Y1 = 0.060;
  my $Y2 = 0.043;
  my $X = 0.18;
  for my $i ( 1 .. 9 ) {
    my $ITMP = 32 * ( $i - 1 );
    if( $i == 9 ) { $ITMP = 255; }
    my $CVAL = sprintf( "%3.3d", $ITMP );
    my $RVL = $ITMP / 255;
    my $DVAL = sprintf( "%4.2f", $RVL );
    #&NCAR::plchhq($X,$Y1,CVAL(IL(I):3),.008,0.,0.);
    &NCAR::plchhq($X,$Y2,$DVAL,.008,0.,0.);
    $X = $X+$DELX;
  }
#
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/coex01.ncgm';
