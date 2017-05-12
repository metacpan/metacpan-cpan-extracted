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
   
#
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my $NPTS = 200;
my $XDRA = zeroes float, $NPTS;
my $YDRA = zeroes float, $NPTS;

for my $I ( 1 .. $NPTS ) {
  my $xdra = $I*0.1;
  set( $XDRA, $I-1, $xdra );
  set( $YDRA, $I-1, exp( $xdra * sin( $xdra ) ) );
}

#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);

&DEFCLR($IWKID);

&NCAR::agseti ('Y/LOGARITHMIC.',1);
&NCAR::agsetf('DASH/SELECTOR.',-1.0);

&NCAR::agsetc('LABEL/NAME.','B');
&NCAR::agseti('LINE/NUMBER.',-100);
&NCAR::agsetc('LINE/TEXT.','TIME (SECONDS)$');

&NCAR::agsetc('LABEL/NAME.','L');
&NCAR::agseti('LINE/NUMBER.',100);
&NCAR::agsetc('LINE/TEXT.','POSITION (METERS)$');

&NCAR::ezxy ($XDRA,$YDRA,$NPTS,'Log scaling and publication quality text$');

#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();


sub DEFCLR {
  my ($IWKID) = @_;
  &NCAR::gscr($IWKID, 0, 0.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 1, 1.0, 1.0, 1.0);
  &NCAR::gscr($IWKID, 2, 1.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 3, 0.0, 1.0, 0.0);
  &NCAR::gscr($IWKID, 4, 0.4, 0.7, 0.9);
  &NCAR::gscr($IWKID, 5, 0.7, 0.4, 0.7);
  &NCAR::gscr($IWKID, 6, 0.9, 0.7, 0.4);
  &NCAR::gscr($IWKID, 7, 0.4, 0.9, 0.7);
}

        
sub NCAR::agchax {
  my ($IFLG,$IAXS,$IPRT,$VILS) = @_;
  &NCAR::plotif (0.,0.,2);
  if( $IFLG == 0 ) {
    &NCAR::gsplci( 2 );
    &NCAR::gstxci( 3 );
  } else {
    &NCAR::gsplci(1);
    &NCAR::gstxci(1);
  }
}

sub NCAR::agchcu {
  my ($IFLG,$KDSH) = @_;
  &NCAR::plotif (0.,0.,2);
  if( $IFLG == 0 ) {
    &NCAR::gsplci( abs($KDSH)+3 );
    &NCAR::gstxci( abs($KDSH)+3 );
  } else {
    &NCAR::gsplci(1);
    &NCAR::gstxci(1);
  }
}

sub NCAR::agchil {
  my ($IFLG,$LBNM,$LNNO) = @_;
  &NCAR::plotif (0.,0.,2);
  if( $IFLG == 0 ) {
    &NCAR::gstxci( 4 );
  } else {
    &NCAR::gstxci( 1 );
  }
}

sub NCAR::agpwrt {
  my ($XPOS, $YPOS, $CHRS, $NCHS, $ISIZ, $IORI, $ICEN) = @_;
  &NCAR::pcgetr ('CS - CONSTANT SPACING FLAG', my $CSFL);
# If the label centering option is on, give wider spacing.
  if( $ICEN != 0 ) {
    &NCAR::pcsetr ('CS - CONSTANT SPACING FLAG', 1.25);
  } else {
    &NCAR::pcsetr ('CS - CONSTANT SPACING FLAG', 0.0 );
  }
# Set the size of the labels to be the same as Autograph
# would normally use.
  &NCAR::plchhq ($XPOS, $YPOS, substr( $CHRS, 0, $NCHS),.8*$ISIZ,$IORI, $ICEN);
# Return spacing to whatever it was before we wrote this label
  &NCAR::pcsetr ('CS - CONSTANT SPACING FLAG', $CSFL);
#                                                                       
}

rename 'gmeta', 'ncgm/class3.ncgm';
