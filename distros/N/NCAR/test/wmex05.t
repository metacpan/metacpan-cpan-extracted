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

my ( $NU, $NO, $NC ) = ( 8, 8, 5 );
my $NOP1 = $NO + 1;
#
#  Data for a region.
#

my ( @XP, @YP );

my @XU = ( 0.05, 0.20, 0.40, 0.70, 0.80, 0.65, 0.40, 0.05);
my @YU = ( 0.70, 0.45, 0.60, 0.70, 0.80, 0.95, 0.84, 0.70);
my @XOFF = ( 0.10, 0.52, 0.10, 0.52, 0.10, 0.52,  0.10,  0.52);
my @YOFF = ( 0.47, 0.47, 0.27, 0.27, 0.07, 0.07, -0.13, -0.13);
my @XCLIP = ( 0.10, 0.75, 0.75, 0.10, 0.10 );
my @YCLIP = ( 0.50, 0.50, 0.85, 0.85, 0.50 );
my @LABELS = ( 'Ice','Snow','Flurries','Rain','Showers',
               'Thunderstorms','Temperature',
               'Temperature','(clipped)' );
#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 0.0, 1.0);
&NCAR::gscr(1, 4, 0.0, 1.0, 0.0);
#
&NCAR::plchhq(0.50,0.93,':F26:Weather and temperature regions',0.033,0.,0.)       ;
#
&NCAR::wmseti( 'COL', 3 );
my $SCALE = .4;
&NCAR::wmsetr( 'RHT - size scale', 0.015 );
&NCAR::pcseti( 'FN', 26 );

for my $i ( 1 .. $NO ) {
  for my $j ( 1 .. $NU ) {
    $XP[ $j - 1 ] = $SCALE * $XU[ $j - 1 ] + $XOFF[ $i - 1 ];
    $YP[ $j - 1 ] = $SCALE * $YU[ $j - 1 ] + $YOFF[ $i - 1 ];
  }
  if( $i <= ( $NO - 2 ) ) {
   &NCAR::wmdrrg( $NU, float( \@XP ), float( \@YP ), 
                  $LABELS[ $i - 1 ],
                  1, float( \@XP ), float( \@YP ) );
   &NCAR::plchhq( $XP[2]+.01,$YP[2]-.025,$LABELS[ $i - 1 ],0.02,0.,-1.)       ;
  } elsif( $i == ( $NO - 1 ) ) {
   &NCAR::wmdrrg( $NU, float( \@XP ), float( \@YP ),
                  'INDEX2',
                  1, float( \@XP ), float( \@YP ) );
   &NCAR::plchhq( $XP[2]+.01,$YP[2]-.025,$LABELS[ $i - 1 ],0.02,0.,-1.)       ;
  } elsif( $i == $NO ) {
   for my $j ( 1 .. $NC ) {
     $XCLIP[ $j - 1 ] = $SCALE * $XCLIP[ $j - 1 ] + $XOFF[ $i - 1 ];
     $YCLIP[ $j - 1 ] = $SCALE * $YCLIP[ $j - 1 ] + $YOFF[ $i - 1 ];
   }
   &NCAR::wmdrrg( $NU, float( \@XP ), float( \@YP ), 
                  'INDEX4',
                  $NC, float( \@XCLIP ), float( \@YCLIP ) );
   &NCAR::plchhq( $XP[2]+.01,$YP[2]-.025,$LABELS[ $i - 1 ],0.02,0.,-1.)       ;
   &NCAR::plchhq( $XP[2]+.01,$YP[2]-.060,$LABELS[ $i ],0.02,0.,-1.)       ;
  }
}




&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex05.ncgm';
