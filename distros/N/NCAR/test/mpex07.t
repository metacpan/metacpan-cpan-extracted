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
my $PLBL = 'MERIDIONAL LABELS ON A POLAR MAP';
#
#
# Turn off the clipping indicator.
#
&NCAR::gsclip (0);
#
# Move the map a little to provide more room for labels.
#
&NCAR::mappos (.075,.925,.05,.90);
#
# Use an elliptical (circular, in this case) perimeter.
#
&NCAR::mapsti ('EL',1);
#
# Show continents and international boundaries.
#
&NCAR::mapstc ('OU','PO');
#
# Use a stereographic projection, centered at the North Pole.
#
&NCAR::maproj ('ST',90.,0.,-100.);
#
# Specify the angular distances to the edges of the map.
#
&NCAR::mapset ('AN',
                float( [ 80., 0 ] ),
		float( [ 80., 0 ] ),
		float( [ 80., 0 ] ),
		float( [ 80., 0 ] ),
		);
#
# Draw the map.
#
&NCAR::mapdrw();
#
# Call a routine to label the meridians.  This routine is not
# a part of EZMAP; the code is given below.
#
&MAPLBM();
#
# Put the label at the top of the plot.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
&NCAR::pwrit (.5,.975,$PLBL,32,2,0,0);
#
# Draw a boundary around the edge of the plotter frame.
#
&NCAR::Test::bndary();


sub MAPLBM {
#
# This routine labels the meridians if and only if the current
# projection is azimuthal and centered at one of the poles, a
# circular boundary is being used, and the grid increment is an
# integral divisor of 180.  The routine was not thought general
# enough to include in EZMAP itself, but may nevertheless be of
# interest to users.
#
# Necessary local declarations.
#
#
# See if the conditions required for MAPLBM to work are met.
#
# The projection must be azimuthal, ...
#
  my $CHLB = '    ';
  &NCAR::mapgtc ('PR',my $PROJ);
  if( ( $PROJ !~ m/^ST/o ) 
   && ( $PROJ !~ m/^OR/o ) 
   && ( $PROJ !~ m/^LE/o ) 
   && ( $PROJ !~ m/^GN/o ) 
   && ( $PROJ !~ m/^AE/o ) ) { return };
#
# the pole latitude must be +90 degrees or -90 degrees, ...
#
  &NCAR::mapgtr ('PT',my $PLAT);
  if( abs( $PLAT ) < 89.9999) { return; };

#
# the perimeter must be elliptical, ...
#
  &NCAR::mapgti ('EL',my $IELP);
  if( $IELP == 0 ) { return; }
#
# the values used in the SET call must define a circle, ...
#
  &NCAR::getset (my ( $FLEW,$FREW,$FBEW,$FTEW,$ULEW,$UREW,$VBEW,$VTEW,$LNLG ) );
  my $ILEW=&NCAR::kfpx($FLEW);
  my $IREW=&NCAR::kfpx($FREW);
  my $IBEW=&NCAR::kfpy($FBEW);
  my $ITEW=&NCAR::kfpy($FTEW);
  if( ( $ULEW+$UREW > 0.0001 ) || ( $VBEW+$VTEW > 0.0001 ) ) { return; }
  if( ( $ULEW+$VTEW > 0.0001 ) || ( $VBEW+$UREW > 0.0001 ) ) { return; }
#
# and the grid spacing must be an integral divisor of 180.
#
  &NCAR::mapgtr ('GR',my $GRID);
  if( ( ( $GRID - int( $GRID ) ) != 0 ) || ( ( 180 % int( $GRID ) ) != 0 ) ) { return; }
  
#
# All conditions are satisfied.  Label the meridians.
#
# Collect the necessary information.
#
  my $IGRD= int( $GRID );
  &NCAR::mapgtr ('PN',my $PLON);
  &NCAR::mapgtr ('RO',my $ROTA);
  &NCAR::mapgti ('LS',my $ICSZ);
  if( $ICSZ == 0 ) {
     $ICSZ=8;
  } elsif( $ICSZ == 1 ) {
     $ICSZ=12;
  } elsif( $ICSZ == 2 ) {
     $ICSZ=16;
  } elsif( $ICSZ == 3 ) {
     $ICSZ=24;
  }
  
  my $WOCH=((  $ICSZ)/($IREW-$ILEW))*($UREW-$ULEW);
  my $HOCH=((2*$ICSZ)/($ITEW-$IBEW))*($VTEW-$VBEW);
  my $HOLB=$HOCH/1.5;
#
# Loop on the label values.
#
  for( my $I = -180; $I <= 179; $I += $IGRD ) {
#
# Express the value of the longitude in a nice form.
#
    my $CHRS = sprintf( '%3d', abs( $I ) );
    my $NCHS=0;
    if( abs( $I ) >= 100 ) {
      $NCHS=$NCHS+1;
      substr( $CHLB, $NCHS-1, 1, substr( $CHRS, 0, 1 ) );
    }
    if( abs( $I ) >= 10 ) {
      $NCHS=$NCHS+1;
      substr( $CHLB, $NCHS-1, 1, substr( $CHRS, 1, 1 ) );
    }
    $NCHS=$NCHS+1;
    substr( $CHLB, $NCHS-1, 1, substr( $CHRS, 2, 1 ) );
    if( ( $I > -180 ) && ( $I < 0 ) ) {
      $NCHS=$NCHS+1;
      substr( $CHLB, $NCHS-1, 1, 'W' );
    } elsif( ( $I > 0 ) && ( $I < 180 ) ) {
      $NCHS=$NCHS+1;
      substr( $CHLB, $NCHS-1, 1, 'E' );
    }
#
# Compute the width of the label.
#
    my $WOLB=($NCHS)*$WOCH;
#
# Find the angle at which the labelled meridian lies on the plot.
#
    my $ANGD;
    if( $PLAT > 0 ) {
      $ANGD=($I-90)-$PLON-$ROTA;
    } else {
      $ANGD=(90-$I)+$PLON-$ROTA;
    }
#
# Reduce the angle to the range from -180 to +180 and
# find its equivalent in radians.
#
    $ANGD=$ANGD-&NCAR::Test::sign(180.,$ANGD+180.)+&NCAR::Test::sign(180.,180.-$ANGD);
    my $ANGR=.017453292519943*$ANGD;
#
# Figure out where the end of the meridian is.
#
    my $XEND=$UREW*cos($ANGR);
    my $YEND=$VTEW*sin($ANGR);
#
# Extend the meridian a little to make a tick mark.
#
    &NCAR::line ($XEND,$YEND,1.015*$XEND,1.015*$YEND);
#
# Compute a center position for the label which puts its nearest
# edge at a fixed distance from the perimeter.  First, compute
# the components (DELX,DELY) of the vector from the center of the
# label box to the edge nearest the perimeter.
#
    my ( $DELX, $DELY );
    if($ANGD<-179.9999) {
      $DELX=+0.5*$WOLB;
      $DELY= 0.;
    } elsif ($ANGD< -90.0001) {
      $DELX=+0.5*$WOLB;
      $DELY=+0.5*$HOLB;
    } elsif ($ANGD< -89.9999) {
      $DELX= 0.0;
      $DELY=+0.5*$HOLB;
    } elsif ($ANGD<  -0.0001) {
      $DELX=-0.5*$WOLB;
      $DELY=+0.5*$HOLB;
    } elsif ($ANGD<  +0.0001) {
      $DELX=-0.5*$WOLB;
      $DELY= 0.0;
    } elsif ($ANGD< +89.9999) {
      $DELX=-0.5*$WOLB;
      $DELY=-0.5*$HOLB;
    } elsif ($ANGD< +90.0001) {
      $DELX= 0.0;
      $DELY=-0.5*$HOLB;
    } elsif ($ANGD<+179.9999) {
      $DELX=+0.5*$WOLB;
      $DELY=-0.5*$HOLB;
    } else {
      $DELX=+0.5*$WOLB;
      $DELY= 0.0;
    }
#
# Then, solve (for FMUL) the following equation:
#
#   SQRT((FMUL*XEND+DELX)**2+(FMUL*YEND+DELY)**2))=1.02*UREW
#
# which expresses the condition that the corner of the box
# nearest the circular perimeter should be at a distance of
# 1.02*(the radius of the perimeter) away from the center of
# the plot.
#
    my $A=$XEND*$XEND+$YEND*$YEND;
    my $B=2.*($XEND*$DELX+$YEND*$DELY);
    my $C=$DELX*$DELX+$DELY*$DELY-1.0404*$UREW*$UREW;
#
    my $FMUL=(-$B+sqrt($B*$B-4.*$A*$C))/(2.*$A);
#
# Draw the label.
#
    &NCAR::pwrit ($FMUL*$XEND,$FMUL*$YEND,$CHLB,$NCHS,$ICSZ,0,0);
#
# End of loop.
#
  }
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/mpex07.ncgm';
