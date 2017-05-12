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

my ( $T1, $T2 ) = ( 0.90, 0.84 );
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,0.);
&NCAR::gscr(1,2,.4,0.,.4);
#
#  Example 01 - chart of wind barbs for various speeds.
#
&NCAR::perim(1,1,1,1);
&NCAR::line(0.000, $T1+0.005, 1.000, $T1+0.005);
&NCAR::line(0.000, $T1-0.005, 1.000, $T1-0.005);
&NCAR::line(0.000, $T2, 1.000, $T2);
&NCAR::line(0.495, 0.000, 0.495, $T1-0.005);
&NCAR::line(0.505, 0.000, 0.505, $T1-0.005);
#
&NCAR::plchhq(0.5,0.955,':F25:Wind Speeds',.03,0.,0.);
&NCAR::pcseti( 'FN', 21 );
my $XCL = 0.12;
my $XCC = 0.26;
my $XCR = 0.40;

for my $I ( 1, 2 ) {
my $XL = $XCL+($I-1)*0.5;
my $XC = $XCC+($I-1)*0.5;
my $XR = $XCR+($I-1)*0.5;
&NCAR::plchhq($XL,0.87,'Symbol',0.022,0.,0.) ;
&NCAR::plchhq($XC,0.87,'Knots',0.022,0.,0.) ;
&NCAR::plchhq($XR,0.87,'Miles/hr.',0.022,0.,0.) ;
}
my $FINC = $T2/10.;
my $SIZE = 0.022;
my $XCL = 0.16;

&NCAR::gslwsc(3.);
&NCAR::ngseti( 'WO', 1 );
&NCAR::ngseti( 'CA', 0 );
#
my $P1 = $T2-0.75*$FINC;
&NCAR::wmsetr( 'WBS', 0.1 );
&NCAR::wmseti( 'COL', 1 );
&NCAR::wmgetr( 'WBS', my $WSLEN );
&NCAR::wmbarb($XCL-0.5*$WSLEN,$P1-0.5*$SIZE,0.,0.);
&NCAR::plchhq($XCC,$P1,'Calm',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'Calm',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-1.,0.);
&NCAR::plchhq($XCC,$P1,'1-2',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'1-2',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-5.,0.);
&NCAR::plchhq($XCC,$P1,'3-7',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'3-8',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-10.,0.);
&NCAR::plchhq($XCC,$P1,'8-12',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'9-14',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-15.,0.);
&NCAR::plchhq($XCC,$P1,'13-17',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'15-20',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-20.,0.);
&NCAR::plchhq($XCC,$P1,'18-22',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'21-25',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-25.,0.);
&NCAR::plchhq($XCC,$P1,'23-27',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'26-31',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-30.,0.);
&NCAR::plchhq($XCC,$P1,'28-32',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'32-37',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-35.,0.);
&NCAR::plchhq($XCC,$P1,'33-37',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'38-43',$SIZE,0.,0.);
#
      $XCL = $XCL+0.5;
      $XCC = $XCC+0.5;
      $XCR = $XCR+0.5;
      $P1 = $T2-0.75*$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-40.,0.);
&NCAR::plchhq($XCC,$P1,'38-42',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'44-49',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-45.,0.);
&NCAR::plchhq($XCC,$P1,'43-47',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'50-54',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-50.,0.);
&NCAR::plchhq($XCC,$P1,'48-52',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'55-60',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-55.,0.);
&NCAR::plchhq($XCC,$P1,'53-57',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'61-66',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-60.,0.);
&NCAR::plchhq($XCC,$P1,'58-62',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'67-71',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-65.,0.);
&NCAR::plchhq($XCC,$P1,'63-67',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'72-77',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-70.,0.);
&NCAR::plchhq($XCC,$P1,'68-72',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'78-83',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-75.,0.);
&NCAR::plchhq($XCC,$P1,'73-77',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'84-89',$SIZE,0.,0.);
#
       $P1 = $P1-$FINC;
&NCAR::wmbarb($XCL,$P1-0.5*$SIZE,-105.,0.);
&NCAR::plchhq($XCC,$P1,'103-107',$SIZE,0.,0.);
&NCAR::plchhq($XCR,$P1,'119-123',$SIZE,0.,0.);



&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex09.ncgm';
