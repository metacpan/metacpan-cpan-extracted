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
#  Illustrate setting nominal linewidth.
#
#
#  Strategic horizontal and vertical positions.
#  
my @XP = ( 0.12, 0.35, 0.60, 0.85 );
my @YP = ( 0.80, 0.73, .63 );;
#
#  Length of displayed lines.
#
my $XLEN = .18;
#
#  Linewidth scale factors.
#
my @WSCALE = ( 0.5, 1.0, 2.0, 4.0, 8.0 );
#
#  Nominal linewidths.
#
my @WIDTHN = ( 0.5, 1.0, 4.0 );
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
&NCAR::gscr(1,2,1.,0.,0.);
#
#  All changes apply to workstation with id IWKID.
#
&NCAR::ngseti( 'Workstation', 1 );
#
#  Set line caps to "butt".
#
&NCAR::ngseti( 'Caps', 0 );
#
my ( @X, @Y );
for my $NWIDTH ( 1 .. 3 ) {
   $X[0] = $XP[$NWIDTH]-0.5*$XLEN;
   $X[1] = $XP[$NWIDTH]+0.5*$XLEN;
#
#  Set nominal linewidth.
#
&NCAR::ngsetr( 'Nominal linewidth', $WIDTHN[$NWIDTH-1] );
  for my $ISCL ( 1 .. 5 ) {
#
#  Set linewidth scale factor.
#
    &NCAR::gslwsc($WSCALE[$ISCL-1]);
    $Y[0] = $YP[2] - 0.1*($ISCL-1);
    $Y[1] = $Y[0];
    &NCAR::gpl(2,float( \@X ),float( \@Y ));
  }
}
#
#  Label the plot.
#
&NCAR::pcseti( 'FN', 25 );
&NCAR::pcseti( 'CC', 1 );
&NCAR::plchhq($XP[2],$YP[0]-0.010,'Nominal linewidths',.030,0.,0.);
&NCAR::plchhq($XP[1],$YP[1]+0.002,'0.5',.023,0.,0.);
&NCAR::plchhq($XP[2],$YP[1]+0.002,'1.0 (default)',.023,0.,0.);
&NCAR::plchhq($XP[3],$YP[1]+0.002,'4.0',.023,0.,0.);
&NCAR::plchhq($XP[0],$YP[0],'Linewidth',.019,0.,0.);
&NCAR::plchhq($XP[0],0.5*($YP[0]+$YP[1]),'scale',.019,0.,0.);
&NCAR::plchhq($XP[0],$YP[1],'factors',.019,0.,0.);
my $SF = .25;
for my $I ( 1 .. 5 ) {
  $SF = 2.*$SF;
  my $LLAB = sprintf( '%3.1f', $SF );
  &NCAR::plchhq($XP[0],$YP[2]-0.1*($I-1),$LLAB,.023,0.,0.);
}
#
&NCAR::ngsetr( 'Nominal linewidth', 1. );
&NCAR::gsplci(2);
&NCAR::gslwsc(8.);
@X = (  .03, .97 );
@Y = ( $YP[1]-0.04, $YP[1]-0.04 );
&NCAR::gpl(2,float( \@X ),float( \@Y ));
@X = ( $XP[1]-0.70*$XLEN, $XP[1]-0.70*$XLEN );
@Y = ( $YP[0]+0.035, $YP[2]-0.435 );
&NCAR::gpl(2,float( \@X ),float( \@Y ));
# 

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/pgkex22.ncgm';
