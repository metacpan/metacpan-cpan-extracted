# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; };
END {print "not ok 1\n" unless $loaded;};
use NCAR;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

unlink( 'gmeta' );

use PDL;
use NCAR::Test;
use strict;

&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );

#
#  Define a small color table.
#
&NCAR::gscr(1,0,1.,1.,1.);
&NCAR::gscr(1,1,0.,0.,1.);
&NCAR::gscr(1,2,1.,0.,0.);
#
#  Generate a straight line with 100 points.
#
my ( @x, @y );
for my $i ( 1 .. 100 ) {
  push @x, $i;
  push @y, 10 * $i;
}
#
#  Use SET to define normalization transformation 1 with linear 
#  scaling in the X direction and log scaling in the Y direction.
#
&NCAR::set(.15,.85,.15,.85,1.,100.,10.,1000.,2);
#
#  Set line color to red.
#
&NCAR::gsplci(2);
#
#  Initialize the AUTOGRAPH entry EZXY so that the frame is not 
#  advanced and the Y axis is logarithmic.  Turn off axis labels.
#
&NCAR::displa(2,0,2);
&NCAR::anotat(' ',' ',0,0,0,[]);
#
#  Output the polyline (X,Y) using EZXY.
#
&NCAR::ezxy( float( \@x ), float( \@y ), 100, ' ' );
#
#  Put out a couple of labels (DRWTXT uses NDC space).
#
&drwtxt(.50,.07,'The X axis is linear',-7,.025,0.);
&drwtxt(.07,.50,'The Y axis is log',-7,.025,90.);

sub drwtxt {
  my ( $x , $y, $txt, $ifnt, $chgt, $ang) = @_;
#
#  This subroutine draws the text string in TXT at position (X,Y) using
#  font IFNT with character height CHGT (specified in NDC) and text 
#  angle ANG degrees.  The position (X,Y) is in NDC. This subroutine 
#  is isolated from any GKS attribute settings in the calling program 
#  by using inquiry functions to save all settings on entry and restore 
#  all settings on exit.  The text is aligned as (center, half) and is 
#  drawn in the foreground color.  
#
  my $errind;
  my $pi = 3.1415927;
  my $clrect = zeroes float, 4;
#
#  Inquire and save the state of all attributes that will be used in
#  this subroutine.  These will be restored on exit.
#
#   Clipping
  &NCAR::gqclip( $errind, my $iclipo, $clrect );
#
#   Character up vector.
  &NCAR::gqchup( $errind, my $chupxo, my $chupyo );
#
#   Text alignment.
  &NCAR::gqtxal( $errind, my $ilnho, my $ilnvo );
#
#   Text font.
  &NCAR::gqtxfp( $errind, my $itxfo, my $itxpo );
#
#   Character height.
  &NCAR::gqchh( $errind, my $chho );
#
#  Get and save the existing normalization transformation information,
#  including the log scaling parameter..
#
  my ( $xv1, $xv2, $yv1, $yv2, $xw1, $xw2, $yw1, $yw2, $ls );
  &NCAR::getset( $xv1, $xv2, $yv1, $yv2, $xw1, $xw2, $yw1, $yw2, $ls );
#
#  Use NDC space for drawing TXT.
#
  &NCAR::gselnt(0);
#
#  Define the text font.
#
  &NCAR::gstxfp($ifnt,2);
#
#  Set the character height.
#
  &NCAR::gschh( $chgt );
#
#  Set the text alignment to (center, half).
#
  &NCAR::gstxal(2,3);
#
#  Select the foreground color.
#
  &NCAR::gstxci(1);
#
#  Define the character up vector in accordance with ANG (recall that
#  the up vector is perpendicular to the text path).
#
  my $rang = ( $ang + 90 ) * ( 2 * $pi / 360 );
  &NCAR::gschup( cos($rang), sin($rang) );
#
#  Draw the text string in TXT.
#
  &NCAR::gtx( $x, $y, $txt );
#
#  Restore the original normalization transformation.
#
  &NCAR::set( $xv1, $xv2, $yv1, $yv2, $xw1, $xw2, $yw1, $yw2, $ls );
#
#  Restore all other attributes.
#
  &NCAR::gsclip( $iclipo );
  &NCAR::gschup( $chupxo, $chupyo );
  &NCAR::gstxal( $ilnho, $ilnvo );
  &NCAR::gstxfp( $itxfo, $itxpo );
  &NCAR::gschh ( $chho );
#
}
&bndary();

&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();



rename 'gmeta', 'ncgm/pgkex03.ncgm';
