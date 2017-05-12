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
#  Plots tables of all the weather symbols.
#
my @CFNT = ( 'a ','N ','W ','CH','CM','CL','C ' );
my @YLAB = (
 [ 'a','Pressure Tendency ' ],
 [ 'N','Sky Cover         ' ],
 [ 'W','Past Weather      ' ],
 [ 'CH','High Clouds      ' ],
 [ 'CM','Medium Clouds    ' ],
 [ 'CL','Low Clouds       ' ],
 [ 'C','Cloud Types       ' ],
);
my @YLEN = (
  [ 1,17 ],
  [ 1, 9 ],
  [ 1,12 ],
  [ 2,11 ],
  [ 2,13 ],
  [ 2,10 ],
  [ 1,11 ],
);
&NCAR::gslwsc(1.);
#
#  Font WW -- Present Weather table.
#
#  Table width.
#
my $X1 = .025;
my $X2 = .975;
#
#  Table heights.
#  
my $Y1 = 0.;
my $Y2 = .95;
my $Y3 = 1.;
#
#  Number of columns and rows.
#
my $NC = 10;
my $NR = 10;
#
&NCAR::gsplci(1);
&NCAR::gstxci(1);
&DTABLE('WW',$NR,$NC,$X1,$Y1,$X2,$Y2,$Y3,1,1,1);
my $SIZE = .4*($Y3-$Y2);
my $YY = .5*($Y2+$Y3);
&NPUTS($YY,'WW','Present Weather',$SIZE);
&NCAR::frame;
#
$NR = 1;
$NC = 10;
my $R = 4.5/12.;
my $DY = .095;
my $SPC = 1./7.-(1.+$R)*$DY;
for my $NF ( 1 .. 7 ) {
  my $YB = ($NF-1)*((1.+$R)*$DY+$SPC);
  $Y1 = $YB;
  $Y2 = $YB+$DY;
  $Y3 = $YB+(1+$R)*$DY;
  &DTABLE($CFNT[$NF-1],$NR,$NC,$X1,$Y1,$X2,$Y2,$Y3,1,1,1);
  $YY = .5*($Y2+$Y3);
  &NPUTS(
    $YY,
    substr( $YLAB[$NF-1][0], 0, $NF ),
    substr( $YLAB[$NF-1][1], 0, $NF ),
    .5*($Y3-$Y2)
  );
}


sub DTABLE {
  my ($FONT,$NR,$NC,$X1,$Y1,$X2,$Y2,$Y3,$ITX1,$ITX2,$ILNC) = @_;
#
#  Draw table of characters from font FONT with NR rows and NC columns.
#  The boundary of the table in world coordinates is (X1,Y1) to (X2,Y2).
#  The line color index is ILNC and the text color index for the label
#  characters is ITX1 and for the displayed characters is ITX2.
#
#
#  Change the flag for Plotchar function codes to a non-printing
#  ASCII character since function codes will not be  
#  used and all printing ASCII characters will be used.
#
  &NCAR::pcsetc('FC',chr(30));
#
#  Draw table grid and compute the centers of the grid boxes.
#
  &NCAR::gslwsc(2.);
  &NCAR::gsplci($ILNC);
  my $XX = zeroes float, 2;
  my $YY = zeroes float, 2;
  my $XC = zeroes float, 10;
  my $YC = zeroes float, 10;
  my $XLC = zeroes float, 10;
  my $YLC = zeroes float, 10;
  my $YINC = ($Y2-$Y1)/$NR;
  for my $J ( 1 .. $NR+1 ) {
    set( $YY, 0, $Y1+($J-1)*$YINC );
    set( $YY, 1, $Y1+($J-1)*$YINC );
    set( $XX, 0, $X1 );
    set( $XX, 1, $X2 );
    &NCAR::gpl(2,$XX,$YY);
    if( $J <= $NR ) {
      set( $YC, $J-1, at( $YY, 0 ) + .4*$YINC );
      set( $YLC, $J-1, at( $YY, 0 ) + .8*$YINC );
    }
  }
#     
  my $XINC = ($X2-$X1)/$NC;
  for my $I ( 1 .. $NC+1 ) {
    set( $YY, 0, $Y1 );
    set( $YY, 1, $Y2 );
    set( $XX, 0, $X1+($I-1)*$XINC );
    set( $XX, 1, at( $XX, 0 ) );
    &NCAR::gpl(2,$XX,$YY);
    if( $I <= $NC ) {
      set( $XC, $I-1, at( $XX, 0 ) + .6*$XINC );
      set( $XLC, $I-1, at( $XX, 0 ) + .2*$XINC );
    }
  }
  &NCAR::gslwsc(1.);
#
#  Draw the characters in the boxes.
#
  &NCAR::gstxal(2,3);
  &NCAR::gstxfp(-36,2);
#    
  &NCAR::gstxci($ITX2);
  for my $J ( 1 .. $NR ) {
    for my $I ( 1 .. $NC ) {
      my $NUM = ($NR-$J)*$NC+$I-1;
      &NCAR::ngwsym($FONT,$NUM,at( $XC, $I-1 ),at( $YC, $J-1 ),.43*$YINC,1,0);
    }
  }
#    
#  Draw the character number in the upper left of the box.
#
  my $CHGT = .14*$YINC;
  for my $J ( 1 .. $NR ) {
    for my $I ( 1 .. $NC ) {
      my $NUM = ($NR-$J)*$NC+$I-1;
      my $NLAB = sprintf( '%2d', $NUM );
      &NCAR::pcseti('FN',26);
      &NCAR::pcseti('CC',$ITX1);
      &NCAR::plchhq(at( $XLC, $I-1 ),at( $YLC, $J-1 ),$NLAB,6.*$CHGT/7.,0.,0.);
    }
  }
#
}
sub NPUTS {
  my ($YY,$STR1,$STR2,$SIZE) = @_;
#
#  Put out STR1, then a dash, then STR2 at size SIZE.
#
  my $TX = zeroes float, 4;
  my $TY = zeroes float, 4;
#
  &NCAR::gstxfp(-22,2);
  &NCAR::gstxal(1,3);
  &NCAR::gschh($SIZE);
  &NCAR::gqtxx(1,0.,$YY,$STR1, my ( $IER,$CPX,$CPY ),$TX,$TY);
  my $DX1 = $CPX;
  &NCAR::gqtxx(1,0.,$YY,$STR2,$IER,$CPX,$CPY,$TX,$TY);
  my $DX3 = $CPX;
  &NCAR::gstxfp(-34,2);
  &NCAR::gqtxx(1,0.,$YY,' > ',$IER,$CPX,$CPY,$TX,$TY);
  my $DX2 = $CPX;
  my $DX = $DX1+$DX2+$DX3;
  my $STRTX = .5-.5*$DX;
  &NCAR::pcseti('FN',22);
  &NCAR::plchhq($STRTX,$YY,$STR1,6.*$SIZE/7.,0.,-1.);
  &NCAR::plchhq($STRTX+$DX1+$DX2,$YY,$STR2,6.*$SIZE/7.,0.,-1.);
  &NCAR::gstxfp(-34,2);
  &NCAR::pcseti('FN',34);
  &NCAR::plchhq($STRTX+$DX1,$YY,' > ',6.*$SIZE/7.,0.,-1.);
}
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fngwsym.ncgm';
