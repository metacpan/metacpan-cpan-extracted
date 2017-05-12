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
#  Get the character body limits.
#
my $XCENT = .5;
my $CAP =  .7;
my $BASE = .3;
my $HALF = .5*($CAP+$BASE);
my $TOP = $HALF+.7*($CAP-$BASE);
my $BOT = $HALF-.8*($CAP-$BASE);
#
#  Convert the character height to width for Plotchar.
#
my $CWIDTH = (6./7.)*($CAP-$BASE);
#
#  Turn computation of text extent information on.
#
&NCAR::pcseti( 'TE', 1 );
#
#  Specify the text font and color.
#
&NCAR::pcseti( 'FN', 21 );
&NCAR::pcseti( 'CC', 1 );
#
#  Compute the text extent information.
#
&NCAR::plchhq($XCENT,$HALF,'B',$CWIDTH,360.,0.);
#
#  Turn text extent computation off.
#
my ( $TLEFT, $TRIGHT );
&NCAR::pcseti( 'TE', 0 );
&NCAR::pcgetr( 'XB', $TLEFT );
&NCAR::pcgetr( 'XE', $TRIGHT );
my $EXTL = .15;
my $EXTR = .05;
#
#  Draw a hatch pattern in the character body limits.
#

my @XB = ( 
 $TLEFT,
 $TRIGHT,
 $TRIGHT,
 $TLEFT,
);
my @YB = (
 $BOT,
 $BOT,
 $TOP,
 $TOP,
);
&NCAR::gsfais(3);
&NCAR::gsfasi(6);
&NCAR::gfa(4, float( \@XB ), float( \@YB ) );
&NCAR::gsfais(1);
#
#  Draw the character.
#
&NCAR::plchhq($XCENT,$HALF,'B',$CWIDTH,0.,0.);
#
#  Label the plot.
#
&NCAR::line($TLEFT-$EXTR,$TOP,$TRIGHT+$EXTR,$TOP);
&NCAR::line($TLEFT-$EXTL,$CAP,$TRIGHT+$EXTR,$CAP);
&NCAR::line($TLEFT,$HALF,$TRIGHT+$EXTR,$HALF);
&NCAR::line($TLEFT-$EXTL,$BASE,$TRIGHT+$EXTR,$BASE);
&NCAR::line($TLEFT-$EXTR,$BOT,$TRIGHT+$EXTR,$BOT);
#
&NCAR::line($TLEFT,$TOP+$EXTR,$TLEFT,$BOT-$EXTR);
&NCAR::line($TRIGHT,$TOP+$EXTR,$TRIGHT,$BOT-$EXTR);
&NCAR::line($XCENT,$TOP+$EXTR,$XCENT,$BOT-$EXTR);
#
my $SZ = .015;
&NCAR::plchhq($TRIGHT+$EXTR+.01,$TOP,'top',$SZ,0.,-1.);
&NCAR::plchhq($TRIGHT+$EXTR+.01,$CAP,'cap',$SZ,0.,-1.);
&NCAR::plchhq($TRIGHT+$EXTR+.01,$HALF,'half',$SZ,0.,-1.);
&NCAR::plchhq($TRIGHT+$EXTR+.01,$BASE,'base',$SZ,0.,-1.);
&NCAR::plchhq($TRIGHT+$EXTR+.01,$BOT,'bottom',$SZ,0.,-1.);
&NCAR::plchhq($TLEFT,$BOT-$EXTR-.025,'left',$SZ,0.,0.);
&NCAR::plchhq($XCENT,$BOT-$EXTR-.025,'center',$SZ,0.,0.);
&NCAR::plchhq($TRIGHT,$BOT-$EXTR-.025,'right',$SZ,0.,0.);
#
$SZ = .013;
my $CNTL = $TLEFT-.08;
&NCAR::plchhq($CNTL,$HALF+.050,'CHARACTER',$SZ,0.,0.);
&NCAR::plchhq($CNTL,$HALF+.020,'HEIGHT',$SZ,0.,0.);
#
&arw($CNTL,$CAP,0);
&arw($CNTL,$BASE,1);
&NCAR::line($CNTL,$HALF+.050+.02,$CNTL,$CAP);
&NCAR::line($CNTL,$HALF,$CNTL,$BASE);
#
&NCAR::plchhq($XCENT,.89,'The hatched area denotes the character body',.016,0.,0.);
&NCAR::pcseti( 'FN', 25 );
&NCAR::plchhq($XCENT,.94,'Font Coordinate System',.024,0.,0.);
&NCAR::frame;

sub arw {
  my ( $XP,$YP,$IP ) = @_;
#
#  Draws an arrow tip at (X,Y) which is up if IP=0 and down if IP=1
#

  my ( $DX, $DY ) = (.01,.035);
  my $IYS = 1;
  if( $IP == 0 ) {
    $IYS = -1;
  }
  my @X = (
    $XP-$DX,
    $XP,
    $XP+$DX,
  );
  my @Y = (
    $YP+$IYS*$DY,
    $YP,
    $YP+$IYS*$DY,
  );
  &NCAR::gfa(3, float( \@X ), float( \@Y ));
};
&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex08.ncgm';
