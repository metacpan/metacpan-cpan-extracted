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

my $NS=2;
my @XS = ( 0.10, 0.90 );
my @YS;
#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 0.0, 1.0);
&NCAR::gscr(1, 4, 0.4, 0.0, 0.4);
#
#  Plot title.
#
&NCAR::plchhq(0.50,0.94,':F26:Parameter control of front attributes', 0.03,0.,0.);
#
#  Various fronts with different attributes.
#
&NCAR::pcseti( 'CC', 4 );
my $FSIZE = .021;
$YS[0] = .76;
$YS[1] = .76;
&NCAR::pcsetc( 'FC', '%' );
&NCAR::plchhq($XS[0],$YS[0]+.06,"%F22%Starting with FRO='STA', WFC=2 (red), CFC=3 (blue):",$FSIZE,0.,-1.);
&NCAR::wmsetc( 'FRO', 'STA' );
&NCAR::wmseti( 'WFC', 2 );
&NCAR::wmseti( 'CFC', 3 );
&NCAR::wmdrft( $NS,float( \@XS ), float( \@YS ) );
#
$YS[0] = .60;
$YS[1] = .60;
&NCAR::plchhq($XS[0],$YS[0]+.06,"%F22%then setting BEG=0., END=.05, BET=.03 gives:",$FSIZE,0.,-1.);
&NCAR::wmsetr( 'BEG', 0.00 );
&NCAR::wmsetr( 'END', 0.05 );
&NCAR::wmsetr( 'BET', 0.03 );
&NCAR::wmdrft( $NS,float( \@XS ), float( \@YS ) );
#
$YS[0] = .44;
$YS[1] = .44;
&NCAR::plchhq($XS[0],$YS[0]+.06,'%F22%then setting NMS=5 and STY=-1,2,1,-2,2 gives:',$FSIZE,0.,-1.);
&NCAR::wmseti( 'NMS', 5 );
&NCAR::wmseti( 'PAI', 1 );
&NCAR::wmseti( 'STY', -1 );
&NCAR::wmseti( 'PAI', 2 );
&NCAR::wmseti( 'STY', 2 );
&NCAR::wmseti( 'PAI', 3 );
&NCAR::wmseti( 'STY', 1 );
&NCAR::wmseti( 'PAI', 4 );
&NCAR::wmseti( 'STY', -2 );
&NCAR::wmseti( 'PAI', 5 );
&NCAR::wmseti( 'STY', 2 );
&NCAR::wmdrft( $NS,float( \@XS ), float( \@YS ) );
#
$YS[0] = .27;
$YS[1] = .27;
&NCAR::plchhq($XS[0],$YS[0]+.07,'%F22%then setting SWI=.05 and LIN=12. gives:',$FSIZE,0.,-1.);
&NCAR::wmsetr( 'SWI', 0.05 );
&NCAR::wmsetr( 'LIN', 12. );
&NCAR::wmdrft( $NS,float( \@XS ), float( \@YS ) );
#
$YS[0] = .10;
$YS[1] = .10;
&NCAR::plchhq($XS[0],$YS[0]+.07,'%F22%then setting REV=1 gives:',.022,0.,-1.);
&NCAR::wmseti( 'REV', 1 );
&NCAR::wmdrft( $NS,float( \@XS ), float( \@YS ) );

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex04.ncgm';
