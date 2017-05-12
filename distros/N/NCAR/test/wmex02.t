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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

my $ICCLR = 3;
#
#  Data for two lines and a region illustrating spline fits.
#
my $NS=3;
my @XS = ( 0.10, 0.30, 0.50 );
my @YS = ( 0.45, 0.70, 0.75 );
my $NT=5;
my @XT = ( 0.15, 0.20, 0.50, 0.70, 0.85 );
my @YT = ( 0.05, 0.28, 0.53, 0.58, 0.75 );
my $NU=8;
my @XU = ( 0.35, 0.40, 0.60, 0.80, 0.85, 0.70, 0.50, 0.35 );
my @YU = ( 0.10, 0.30, 0.31, 0.43, 0.15, 0.10, 0.05, 0.10 );
#
#  Data for picture two illustrating slope control at end points.
#
my $NV=5;
my @XV = ( 0.10, 0.30, 0.50, 0.70, 0.90 );
my @YV = ( 1.00, 1.08, 1.00, 0.95, 0.94 );
      
#
#  Define a color table.
#
&NCAR::gscr(1, 0, 1.0, 1.0, 1.0);
&NCAR::gscr(1, 1, 0.0, 0.0, 0.0);
&NCAR::gscr(1, 2, 1.0, 0.0, 0.0);
&NCAR::gscr(1, 3, 0.0, 0.0, 1.0);
#
#  Plot title.
#
&NCAR::plchhq(0.50,0.94,':F26:Spline fits for fronts and regions',0.03,0.,0.);
&NCAR::plchhq(0.50,0.88,':F22: - marks the input coordinates',.025,0.,-.06);
&NCAR::pcgetr( 'XB', my $XB );
&cross($XB-.015,0.875,$ICCLR);
#
#  Define some parameters.
#
&NCAR::wmsetr( 'LIN - line widths of front lines', 3. );
&NCAR::wmseti( 'NMS - number of symbols on front line', 0 );
&NCAR::wmseti( 'WFC - color for warm fronts', 2 );
#
&NCAR::wmdrft($NS, float( \@XS ), float( \@YS ) );
for my $i ( 1 .. $NS ) {
  &cross($XS[$i-1],$YS[$i-1],$ICCLR);
}
&NCAR::wmdrft($NT,float( \@XT ), float( \@YT ) );
for my $i ( 1 .. $NT ) {
  &cross($XT[$i-1],$YT[$i-1],$ICCLR);
}
&NCAR::wmdrrg(
              $NU, float( \@XU ), float( \@YU ),
              'INDEX2',
              1,   float( \@XU ), float( \@YU ),
             );
for my $i ( 1 .. $NU ) {
  &cross($XU[$i-1],$YU[$i-1],$ICCLR);
}

sub cross {
  my ( $X, $Y, $ICLR ) = @_;
#
#  Draw a green filled cross at (X,Y).
#
  my $ID=16;
  my ( $IX, $IMX ) = ( 15, 100 );
  my $IMXH = $IMX/2;
  my ( $IMXM, $IMXP, $IMXHM, $IMXHP ) 
   = ( $IMX-$IX, $IMX+$IX, $IMXH-$IX, $IMXH+$IX );
  my ( @RCX, @RCY );    
#
  my @ICX = (
           0,    $IX,  $IMXH, $IMXM,
        $IMX,   $IMX, $IMXHP,  $IMX,
        $IMX,  $IMXM,  $IMXH,   $IX,
           0,      0, $IMXHM,     0,
  );
  my @ICY = (
           0,      0, $IMXHM,     0,
           0,    $IX,  $IMXH, $IMXM,
        $IMX,   $IMX, $IMXHP,  $IMX,
        $IMX,  $IMXM,  $IMXH,   $IX,
  );
#
  for my $i ( 1 .. $ID ) {
    push @RCX, $X-0.00027*($IMXH-$ICX[$i-1]);
    push @RCY, $Y-0.00027*($IMXH-$ICY[$i-1]);
  }
  &NCAR::gsfais(1);
  &NCAR::gqfaci( my $IOC, my $IERR);
  &NCAR::gsfaci($ICLR);
  &NCAR::gfa($ID,float( \@RCX ), float( \@RCY ) );
  &NCAR::gsfaci($IOC);
#
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/wmex02.ncgm';
