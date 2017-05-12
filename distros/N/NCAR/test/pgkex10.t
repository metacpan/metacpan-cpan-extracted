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
&NCAR::gscr(1,0, 1.0, 1.0, 1.0);
&NCAR::gscr(1,1, 0.0, 0.0, 0.0);
&NCAR::gscr(1,2, 1.0, 0.0, 0.0);
&NCAR::gscr(1,3, 0.0, 0.0, 1.0);
&NCAR::gscr(1,4, 0.0, 1.0, 0.0);
&NCAR::gscr(1,5, 0.4, 0.0, 0.4);
&NCAR::gscr(1,6, 1.0, 0.0, 0.0);
#
#  Select Triplex Roman font.
#
&NCAR::gstxfp(-13,2);
#
#  Text path = right, color = black
#
my $X = .2;
my $Y = .7;
&NCAR::gschh(.04);
&NCAR::gstxp(0);
&NCAR::gstxci(1);
&NCAR::gstxal(1,3);
&NCAR::gtx($X,$Y,'Text path=right');
&cross($X,$Y);
#
#  Text path = left, color = blue
#
$X = .80;
$Y = .115;
&NCAR::gschh(.04);
&NCAR::gstxp(1);
&NCAR::gstxci(3);
&NCAR::gstxal(3,3);
&NCAR::gtx($X,$Y,'Text path=left');
&cross($X,$Y);
#
#  Text path = down, color = red
#
$X = .22;
$Y = .62;
&NCAR::gschh(.025);
&NCAR::gstxp(3);
&NCAR::gstxci(2);
&NCAR::gstxal(2,1);
&NCAR::gtx($X,$Y,'Text path=down');
&cross($X,$Y);
#
#  Text path = up, color = green
#
$X = .79;
$Y = .18;
&NCAR::gschh(.03);
&NCAR::gstxp(2);
&NCAR::gstxci(4);
&NCAR::gstxal(2,5);
&NCAR::gtx($X,$Y,'Text path=up');
&cross($X,$Y);
#
#  Label the plot using Plotchar.
#
&NCAR::gsplci(4);
&NCAR::gslwsc(2.);
&NCAR::pcseti( 'CD', 1 );
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 5 );
&NCAR::plchhq(.5,.93,'Text colors and paths',.028,0.,0.);
&NCAR::plchhq(.5,.88,'Font = triplex Roman',.028,0.,0.);
&cross(.193,.826);
&NCAR::plchhq(.5,.83,'- marks the GTX coordinate',.028,0.,0.);

sub cross { 
  my ( $X, $Y ) = @_;
#
#  Draw a green filled cross at (X,Y).
#
my $ID=16;
my ( $IX, $IMX ) = ( 15, 100 );
my $IMXH=$IMX/2;
my $IMXM=$IMX-$IX;
my $IMXP=$IMX+$IX;
my $IMXHM=$IMXH-$IX;
my $IMXHP=$IMXH+$IX;
my $RCX = zeroes float, $ID;
my $RCY = zeroes float, $ID;
#
my $ICX = long [
                  0,   $IX, $IMXH,$IMXM,
               $IMX,  $IMX,$IMXHP, $IMX,
               $IMX, $IMXM, $IMXH,  $IX,
                  0,     0,$IMXHM,    0,
          ];
my $ICY = long [
                  0,     0,$IMXHM,    0,
                  0,   $IX, $IMXH,$IMXM,
               $IMX,  $IMX,$IMXHP, $IMX,
               $IMX, $IMXM, $IMXH,  $IX,
          ];
#
for my $I ( 1 .. $ID ) {;
  set( $RCX, $I - 1, $X-0.00025*($IMXH- at( $ICX, $I - 1 ) ) );
  set( $RCY, $I - 1, $Y-0.00025*($IMXH- at( $ICY, $I - 1 ) ) );

}
&NCAR::gsfais(1);
&NCAR::gsfaci(5);
&NCAR::gfa($ID,$RCX,$RCY);

}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex10.ncgm';
