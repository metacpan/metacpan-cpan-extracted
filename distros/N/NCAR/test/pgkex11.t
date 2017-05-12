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
&NCAR::gscr(1,4, 0.4, 0.0, 0.4);
#
#  Specify the character height for all strings, select simplex
#  Roman font.
#
&NCAR::gschh(.025);
&NCAR::gstxfp(-4,2);
&NCAR::gstxci(3);
my $X = .50;
my $Y = .90;
#
#  Alignment = (1,3) [  left, center]
#
$Y = $Y-.1;
&NCAR::gstxal(1,3);
&NCAR::gtx($X,$Y,'Alignment = (1,3)');
&cross($X,$Y);
#
#  Alignment = (2,3) [center, center]
#
$Y = $Y-.1;
&NCAR::gstxal(2,3);
&NCAR::gtx($X,$Y,'Alignment = (2,3)');
&cross($X,$Y);
#
#  Alignment = (3,3) [ right, center]
#
$Y = $Y-.1;
&NCAR::gstxal(3,3);
&NCAR::gtx($X,$Y,'Alignment = (3,3)');
cross($X,$Y);
#
#  Alignment = (1,1) [  left,    top]
#
$X = .25;
$Y = $Y-.1;
&NCAR::gstxal(1,1);
&NCAR::gtx($X,$Y,'Alignment = (1,1)');
&cross($X,$Y);
#
#  Alignment = (1,2) [  left,    cap]
#
$Y = $Y-.1;
&NCAR::gstxal(1,2);
&NCAR::gtx($X,$Y,'Alignment = (1,2)');
&cross($X,$Y);
#
#  Alignment = (1,3) [  left, center]
#
$Y = $Y-.1;
&NCAR::gstxal(1,3);
&NCAR::gtx($X,$Y,'Alignment = (1,3)');
&cross($X,$Y);
#
#  Alignment = (1,4) [  left,   base]
#
$Y = $Y-.1;
&NCAR::gstxal(1,4);
&NCAR::gtx($X,$Y,'Alignment = (1,4)');
&cross($X,$Y);
#
#  Alignment = (1,5) [  left, bottom]
#
$Y = $Y-.1;
&NCAR::gstxal(1,5);
&NCAR::gtx($X,$Y,'Alignment = (1,5)');
&cross($X,$Y);
#
#  Label the plot.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 4 );
&NCAR::plchhq(.5,.93,'Text Alignment Attributes',.025,0.,0.);
&cross(.22,.876);
&NCAR::plchhq(.5,.88,'- marks the GTX coordinate',.025,0.,0.);


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
for my $I ( 1 .. $ID ) {
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



rename 'gmeta', 'ncgm/pgkex11.ncgm';
