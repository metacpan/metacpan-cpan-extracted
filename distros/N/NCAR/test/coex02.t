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
#  Number of squares in the X and Y directions.
#
my $NX=4;
my $NY=4;
#
#  Size of each square; spacing between squares.
#
my $SZX = .235;
my $SZY = .135;
my $Y0 = .10;
my $Y1 = .88;
my $SPX=(1.-$NX*$SZX)/($NX+1);
my $SPY=($Y1-$Y0-$NY*$SZY)/($NY-1);
#
#  Arrays to store labels.
#
#
#  Color value array.
#
#
my @RGB = (
   [
      [ 0.86, 0.58, 0.44 ], [ 0.65, 0.16, 0.16 ],
      [ 1.00, 0.50, 0.00 ], [ 1.00, 0.00, 0.00 ],
   ],
   [
      [ 1.00, 1.00, 0.00 ], [ 0.00, 1.00, 0.00 ],
      [ 0.14, 0.56, 0.14 ], [ 0.00, 1.00, 1.00 ],
   ],
   [
      [ 0.20, 0.56, 0.80 ], [ 0.00, 0.00, 1.00 ],
      [ 0.50, 0.00, 1.00 ], [ 1.00, 0.00, 1.00 ],
   ],
   [
      [ 1.00, 1.00, 1.00 ], [ 0.66, 0.66, 0.66 ],
      [ 0.40, 0.40, 0.40 ], [ 0.00, 0.00, 0.00 ],
   ],
);
#
my @TLAB = (
   [ 'Tan',       'Brown',      'Orange',       'Red',     ],
   [  'Yellow',   'Green',      'Forest Green', 'Cyan',    ],
   [  'Sky Blue', 'Blue',       'Blue Magenta', 'Magenta', ],
   [ 'White',     'Light Gray', 'Dark Gray',    'Black',   ],
);

#
#  Use the Duplex character set of PLOTCHAR.
#
&NCAR::pcseti( 'CD', 1 );
#
#  Define color indices and RGB labels..
#
&NCAR::gscr(1,0,0.,0.,0.);
&NCAR::gscr(1,1,1.,1.,1.);

my @BLAB;

for my $j ( 1 .. $NX ) {
  for my $i ( 1 .. $NX ) {
    &NCAR::gscr(1, $NX*($j-1)+$i+1, @{ $RGB[$j-1][$i-1] } );
    $BLAB[ $i - 1 ][ $j - 1 ] = 
    sprintf( "R=%4.2f G=%4.2f B=%4.2f", @{ $RGB[$j-1][$i-1] } );
  }
}
#
#  Draw the color squares and titles.
#
for my $j ( 1 .. $NY ) {
  my $Y = $Y0+($j-1)*($SPY+$SZY);
  for my $i ( 1 .. $NX ) {
     my $X = $SPX+($i-1)*($SPX+$SZX);
     &drbox($X,$Y,$SZX,$Y0,$SZY,
            $TLAB[ $i - 1 ][ $j - 1 ],
            $BLAB[ $i - 1 ][ $j - 1 ],
            $NX*($j-1)+$i+1,1);
  }
}
#
#  Plot labels.
#
&NCAR::plchhq(.5,.04,
              'The titles below each box indicate Red, Green and Blue intensity values.',
              .012,0.,0.);
&NCAR::pcseti( 'CD', 1 );
&NCAR::plchhq(.5,.96,'Sixteen Sample Colors', .02,0.,0.);


sub drbox {
  my ( $X,$Y,$SZX,$Y0,$SZY,$TLAB,$BLAB,$INDX,$IWKID) = @_;
#
#  Draw a color square with lower left corner (X,Y)
#
#
  &NCAR::gsfaci($INDX);
  &NCAR::gsfais(1);

  my @A = ( $X, $X+$SZX, $X+$SZX, $X, $X );
  my @B = ( $Y, $Y, $Y+$SZY, $Y+$SZY, $Y );
  &NCAR::gfa(4, float( \@A ), float( \@B ) );
#
#  If the color is black, draw a boundary.
#
  &NCAR::gqcr($IWKID,$INDX,0, my $IER, my $CR, my $CG, my $CB);
  if( ( $CR == 0 ) && ( $CG == 0 ) && ( $CB == 0 ) ) {
    &NCAR::gsplci(1);
    &NCAR::gpl(5, float( \@A ), float( \@B ) );
  
  }
#
   my $ILEN = length($TLAB);
   my $ITLEN;
   for my $k ( reverse( 1 .. $ILEN ) ) {
     if( substr( $TLAB, $k, 1 ) != ' ' ) {
        $ITLEN = $k;
        last;
     }
   }
#
   $ILEN = length( $BLAB );
   my $IBLEN;
   for my $k ( reverse( 1 .. $ILEN ) ) {
     if( substr( $TLAB, $k, 1 ) != ' ' ) {
       $IBLEN = $k;
       last;
     }
   }
#
  &NCAR::gsplci(1);
  &NCAR::plchhq($X+.5*$SZX,$Y-.015, substr( $BLAB, 0, $IBLEN ),.0098,0.,0.);
  &NCAR::plchhq($X+.5*$SZX,$Y+$SZY+.017, substr( $TLAB, 0, $ITLEN),.012,0.,0.);
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/coex02.ncgm';
