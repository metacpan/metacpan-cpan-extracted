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

use NCAR::COMMON qw( %SRFIP1 );

#
#
# Define the required arrays.
#
my $XDAT = zeroes float, 100;
my $YDAT = zeroes float, 100;
my $ODAT = zeroes float, 40, 40;
my $ZDAT = zeroes float, 100, 100;
my $QDAT = zeroes float, 100, 100;
my $WORK = zeroes long, 20000;
#
# Define the data for the label on top of the graph.
#
my $PLBL = 'Longs Peak relief using SRFACE';
# 
# Define the line of sight (viewpoint and point looked at).
#
my $STLN = float [ 5247.5 , 5247.5 , 2530. , 247.5 , 247.5 , 1280. ];
#
# Generate x-coordinate values.
#
for my $I ( 1 .. 100 ) {
  set( $XDAT, $I-1, 5*($I-1) );
}
#
# Generate y-coordinate values.
#
for my $J ( 1 .. 100 ) {
  set( $YDAT, $J-1, 5*($J-1) );
}
#
# Put the original Long's Peak data in the array ODAT.
#
open DAT, "<data/srex01.dat";
for my $J ( 1 .. 40 ) {
  my $X = <DAT>;
  chomp $X;
  $X =~ s/^\s*//o;
  $X =~ s/\s*$//o;
  my @X = split m/\s+/o, $X;
  for my $I ( 1 .. 40 ) {
    set( $ODAT, $J-1, $I-1, $X[$I-1] );
  }
}
close DAT;
#
# Interpolate to get more closely-spaced data in the array QDAT.
#
for my $J ( 1 .. 100 ) {
  my $FL=1.+38.99999999*($J-1)/99.;
  my $L=int($FL);
  $FL=$FL-$L;
  for my $I ( 1 .. 100 ) {
    my $FK=1.+38.99999999*($I-1)/99.;
    my $K=int($FK);
    $FK=$FK-$K;
    set( $QDAT, $J-1, $I-1, 
     (1.-$FL)*((1.-$FK)*at($ODAT,$L-1,$K-1)+$FK*at($ODAT,$L-1,$K))+
         $FL *((1.-$FK)*at($ODAT,$L  ,$K-1)+$FK*at($ODAT,$L  ,$K))
    );
  }
}
#
# Apply a nine-point smoother to get smoother data in the array ZDAT.
#
for my $J ( 1 .. 100 ) {
  my $JM1=&NCAR::Test::max($J-1,1);
  my $JP1=&NCAR::Test::min($J+1,100);
  for my $I ( 1 .. 100 ) {
    my $IM1=&NCAR::Test::max($I-1,1);
    my $IP1=&NCAR::Test::min($I+1,100);
    set( $ZDAT, $J-1, $I-1,
     .2500*at( $QDAT, $J-1, $I-1 )+
     .1250*(at( $QDAT,$J-1,$IM1-1)+at( $QDAT,$J-1,$IP1-1)+
            at( $QDAT,$JM1-1,$I-1)+at( $QDAT,$JP1-1,$I-1))+
     .0625*(at( $QDAT,$JM1-1,$IM1-1)+at( $QDAT,$JM1-1,$IP1-1)+
            at( $QDAT,$JP1-1,$IM1-1)+at( $QDAT,$JP1-1,$IP1-1))
    );
  }
}
#
# Plot the data four times.
#
for my $NPLT ( 1 .. 4 ) {
#
# Before the 2nd, 3rd, and 4th plots, rotate the data by 90 degrees.
#
  if( $NPLT != 1 ) {
    for my $J ( 1 .. 100 ) {
      for my $I ( 1 .. 100 ) {
        set( $QDAT, $J-1, $I-1, at( $ZDAT, $J-1, $I-1 ) );
      }
    }
    for my $J ( 1 .. 100 ) {
      my $K=101-$J;
      for my $I ( 1 .. 100 ) {
        my $L=$I;
        set( $ZDAT, $J-1, $I-1, at( $QDAT, $L-1, $K-1 ) );
      }
    }
  }
#
# Call LOGO to add NCAR and SCD logos.
#
&LOGO();
#
# Set common variables for skirt and frame calls.
#
$SRFIP1{ISKIRT} = 1;
$SRFIP1{HSKIRT} = 1100;
$SRFIP1{IFR}    = 0;
#
# Use SRFACE to draw a representation of the surface.
#
&NCAR::srface ($XDAT,$YDAT,$ZDAT,$WORK,100,100,100,$STLN,0.);
#
# Put in label on the top of the map.
#
&NCAR::pwrit (.5,.850,$PLBL,30,3,0,0);
#
# Advance to the next frame.
#
&NCAR::frame();
#
# End of loop.
#
}
#
sub LOGO {
  &NCAR(.55,.92);
  &SCD(.04,.04);
  &IRONS(0.09,0.090);
}
sub NCAR {
  my ($XPOS,$YPOS) = @_;
#
  &NCAR::pcseti ('CD', 1);
  &NCAR::plchhq ( $XPOS,$YPOS, 'NCAR  GRAPHICS',.038, 0.0, 0.0 );
#
  &NCAR::pcseti ('CD', 0);
#
}
#
sub SCD {
  my ($XBOT, $YBOT) = @_;
#
  &NCAR::pcseti ('CD', 1);
  &NCAR::plchhq ( $XBOT, $YBOT, 'SCD', .04, 0.0, -1.0 );
#
  &NCAR::plchhq ( $XBOT + .145, $YBOT + .008,'SCIENTIFIC COMPUTING DIVISION', .012, 0.0, -1.0);
#
  &NCAR::plchhq ( $XBOT + .145, $YBOT - .016,'NATIONAL CENTER FOR ATMOSPHERIC RESEARCH', .012, 0.0, -1.0);
#
  &NCAR::pcseti ('CD', 0);
#
  &NCAR::line (0.93,0.07,.18,0.07);
#
}
#
sub IRONS {
  my ($X1,$Y1) = @_;
#
  &NCAR::line ($X1+.039,$Y1+.050,$X1+0.015,$Y1+0.054);
  &NCAR::line ($X1+.015,$Y1+.054,$X1-.032,$Y1+0.013);
#
# Devil's Thumb.
#
  &NCAR::line ($X1+.010,$Y1+.048,$X1+.007,$Y1+0.054);
  &NCAR::line ($X1+.007,$Y1+.054,$X1+.007,$Y1+0.059);
  &NCAR::line ($X1+.007,$Y1+.059,$X1+.005,$Y1+0.053);
  &NCAR::line ($X1+.005,$Y1+.053,$X1+.006,$Y1+0.044);
#
# Bear Mountain.
#
  &NCAR::line ($X1+0.026,$Y1+0.03,$X1+.038,$Y1+.05);
  &NCAR::line ($X1+.038,$Y1+.05,$X1+.053,$Y1+.07);
  &NCAR::line ($X1+.053,$Y1+.07,$X1+.078,$Y1+.03);
  &NCAR::line ($X1+.078,$Y1+.03,$X1+.098,$Y1+.05);
  &NCAR::line ($X1+.098,$Y1+.05,$X1+.1,$Y1+.04);
  &NCAR::line ($X1+.1,$Y1+.04,$X1+.13,$Y1+.065);
  &NCAR::line ($X1+.13,$Y1+.065,$X1+.18,$Y1+.029);
  &NCAR::line ($X1+.18,$Y1+.029,$X1+.25,$Y1+.039);
  &NCAR::line ($X1+.25,$Y1+.039,$X1+.27,$Y1+.026);
#
  &NCAR::line ($X1+.27,$Y1+.026,$X1+.81,$Y1+.026);
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/srex01.ncgm';
