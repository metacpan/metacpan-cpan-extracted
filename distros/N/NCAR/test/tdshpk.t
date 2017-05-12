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
   
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Open GKS, open workstation of type 1, activate workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);

#
# Declare arrays in which to put coordinates for calls to DPCURV.
#
my $XCRA = zeroes float, 1001;
my $YCRA = zeroes float, 1001;
#
# Declare an array in which to define the bits of an integer dash
# pattern (which saves one from having to do the binary to decimal
# conversion).
#
my $IBTS = float [ 1,0,1,1,0,1,1,1,0,1,1,1,1,0 ];
#
# Define multiplicative constants to get from degrees to radians and
# vice-versa.
#
my $DTOR = .017453292519943;
my $RTOD = 57.2957795130823;
#
# Turn off clipping by GKS.
#
&NCAR::gsclip (0);
#
# Define some colors to use.
#
&NCAR::gscr   ($IWKID,0,0.,0.,0.);
&NCAR::gscr   ($IWKID,1,1.,1.,1.);
&NCAR::gscr   ($IWKID,2,1.,0.,1.);
&NCAR::gscr   ($IWKID,3,1.,1.,0.);
#
# Define the mapping from the user system to the fractional system for
# the first frame.
#
&NCAR::set (.03,.97,.01,.95,-10.,10.,-10.,10.,1);
#
# Put a label at the top of the first frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),'DEMONSTRATING THE USE OF DASHPACK - FRAME 1',.015,0.,0.);
#
# Use the default character dash pattern to draw a box whose edges
# are straight lines and put a label in the middle of the box.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 1111111111111111 (binary)
# or '$$$$$$$$$$$$$$$$' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
my $YCEN=8.5;
#
&NCAR::dpline (-9.,$YCEN+.75, 9.,$YCEN+.75);
&NCAR::dpline ( 9.,$YCEN+.75, 9.,$YCEN-.75);
&NCAR::dpline ( 9.,$YCEN-.75,-9.,$YCEN-.75);
&NCAR::dpline (-9.,$YCEN-.75,-9.,$YCEN+.75);
#
&NCAR::plchhq (0.,$YCEN,'A box drawn using DPLINE and the default character dash pattern.',.01,0.,0.);
#
# Redefine the character dash pattern, draw a second box whose edges
# are straight lines, and put a label in the middle of the box.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 1111111111111111 (binary)
# or '$$$$$$$$$$$$$$$$' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$_$$$A');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 1111111111111111 (binary)
# or '$$$_$$$A' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
$YCEN=6.0;
#
&NCAR::dpline (-9.,$YCEN+.75, 9.,$YCEN+.75);
&NCAR::dpline ( 9.,$YCEN+.75, 9.,$YCEN-.75);
&NCAR::dpline ( 9.,$YCEN-.75,-9.,$YCEN-.75);
&NCAR::dpline (-9.,$YCEN-.75,-9.,$YCEN+.75);
#
&NCAR::plchhq (0.,$YCEN,'A box drawn using DPLINE and a simple character dash pattern.',.01,0.,0.);
#
# Use a 14-bit binary dash pattern to draw a third box whose edges are
# straight lines and put a label in the middle of the box.  Note that
# the routine IPKBTS, which packs the bits of the integer dash pattern
# into an integer variable, is not a part of DASHPACK, but of this
# example.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 1111111111111111 (binary)
# or '$$$_$$$A' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpseti ('DPS - DASH PATTERN SELECTOR',-14);
#
&NCAR::dpseti ('DPT - DASH PATTERN (BINARY)',&IPKBTS($IBTS,14));
#
# Note: At this point, 'DPS' = -14, 'DPT' = 01011011101111 (binary)
# or '$$$_$$$A' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
$YCEN=3.5;
#
&NCAR::dpline (-9.,$YCEN+.75, 9.,$YCEN+.75);
&NCAR::dpline ( 9.,$YCEN+.75, 9.,$YCEN-.75);
&NCAR::dpline ( 9.,$YCEN-.75,-9.,$YCEN-.75);
&NCAR::dpline (-9.,$YCEN-.75,-9.,$YCEN+.75);
#
&NCAR::plchhq (0.,$YCEN,'A box drawn using DPLINE and a 14-bit binary dash pattern.',.01,0.,0.);
#
# Draw an oval using DPCURV and a character dash pattern in which there
# are no breakpoints.  Smoothing is off by default.
#
# Note: At this point, 'DPS' = -14, 'DPT' = 01011011101111 (binary)
# or '$$$_$$$A' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1., 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpseti ('DPS - DASH PATTERN SELECTOR',0);
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$$$$$$W/O BREAKPOINTS');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$$$W/O BREAKPOINTS' (character), 'LTL' = 0, 'MFS' = 1,
# 'PCF' = 0, 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1.,
# 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
$YCEN=0.5;
#

sub Pow {
  my ( $x, $a ) = @_;
  return $x ? exp( $a * log( abs( $x ) ) ) : 0;
}

for my $I ( 1 .. 19 ) {
  my $ANGD=20.*($I-1);
  my $xcra = 9.*cos($DTOR*$ANGD);
  set( $XCRA, $I-1, $xcra );
  set( $YCRA, $I-1, .11 * &Pow( ( &Pow( 9, 6 ) - &Pow( $xcra, 6 ) ), 1/6 ) );
  if( $ANGD > 180 ) { set( $YCRA, $I-1, -at( $YCRA, $I-1 ) ); }
  set( $YCRA, $I-1, $YCEN + at( $YCRA, $I-1 ) );
}
#
&NCAR::dpcurv ($XCRA,$YCRA,19);
#
&NCAR::plchhq (0.,$YCEN,'An oval drawn using DPCURV, with smoothing off and a:C:dash pattern in which the labels have no breakpoints.',.01,0.,0.);
#
# Draw a second oval using DPCURV and a character dash pattern in which
# there are breakpoints.  Reduce the added space to be left in each
# label gap.  Smoothing is still off.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$$$W/O BREAKPOINTS' (character), 'LTL' = 0, 'MFS' = 1,
# 'PCF' = 0, 'SAF' = 360, 'SCF' = 0, 'SSL' = .01, 'TCS' = -1.,
# 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$$$W|I|T|H| |B|R|E|A|K|P|O|I|N|T|S');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$W|I|T|H| |B|R|E|A|K|P|O|I|N|T|S' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 0, 'SSL' = .01,
# 'TCS' = -1., 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
$YCEN=-3.5;
#
for my $I ( 1 .. 19 ) {
  my $ANGD=20.*($I-1);
  my $xcra = 9.*cos($DTOR*$ANGD);
  set( $XCRA, $I-1, $xcra );
  set( $YCRA, $I-1, .11 * &Pow( ( &Pow( 9, 6 ) - &Pow( $xcra, 6 ) ), 1/6 ) );
  if( $ANGD > 180 ) { set( $YCRA, $I-1, -at( $YCRA, $I-1 ) ); }
  set( $YCRA, $I-1, $YCEN + at( $YCRA, $I-1 ) );
}
#
&NCAR::dpcurv ($XCRA,$YCRA,19);
#
&NCAR::plchhq (0.,$YCEN,'An oval drawn using DPCURV, with smoothing off and:C:a dash pattern in which the labels have breakpoints.',.01,0.,0.);
#
# Draw a third oval in the same way as the second one, but instead of
# embedding break characters in the label, turn on the single-character
# flag.  Turn on the smoother and use even less added space around each
# piece of the broken label.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$W|I|T|H| |B|R|E|A|K|P|O|I|N|T|S' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 0, 'SSL' = .01,
# 'TCS' = -1., 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$$$$WITH sinGLE-CHARACTER FLAG SET');
#
&NCAR::dpseti ('SCF - sinGLE-CHARACTER FLAG',1);
#
&NCAR::dpsetr ('TCS - TENSION ON CUBIC SPLINES',2.5);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$WITH sinGLE-CHARACTER FLAG SET' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
$YCEN=-7.5;
#
for my $I ( 1 .. 19 ) {
  my $ANGD=20.*($I-1);
  my $xcra = 9.*cos($DTOR*$ANGD);
  set( $XCRA, $I-1, $xcra );
  set( $YCRA, $I-1, .11 * &Pow( ( &Pow( 9, 6 ) - &Pow( $xcra, 6 ) ), 1/6 ) );
  if( $ANGD > 180 ) { set( $YCRA, $I-1, -at( $YCRA, $I-1 ) ); }
  set( $YCRA, $I-1, $YCEN + at( $YCRA, $I-1 ) );
}
#
&NCAR::dpcurv ($XCRA,$YCRA,19);
#
&NCAR::plchhq (0.,$YCEN,'An oval drawn using DPCURV, with smoothing on and the:C:single-character flag set to create many breakpoints.',.01,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
# Put a label at the top of the second frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),'DEMONSTRATING THE USE OF DASHPACK - FRAME 2',.015,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the upper left quadrant of the frame.
#
&NCAR::set (.030,.485,.495,.950,-10.,10.,-10.,10.,1);
#
# Use DPFRST, DPVECT, and DPCURV to draw a spiral.  The label will
# follow the curve, because the single-character flag is still on, and
# the curve will be smoothed, because the smoother is still turned on.
# The additional space around the label pieces is reduced even more.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$WITH sinGLE-CHARACTER FLAG SET' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$A SPIRAL DRAWN UsinG DPFRST/VECT/LAST');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$A SPIRAL DRAWN UsinG DPFRST/VECT/LAST' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpfrst (0.,0.);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpvect($RRHO*cos($THTA),$RRHO*sin($THTA));
}
#
&NCAR::dplast;
#
# Put a small label below the spiral.
#
&NCAR::plchhq (0.,-9.,'Using DPFRST, DPVECT, and DPLAST.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the upper right quadrant of the frame.
#
&NCAR::set (.515,.970,.495,.950,-10.,10.,-10.,10.,1);
#
# Use DPDRAW to draw another spiral.  Note that the single-character
# flag is still on, so the label follows the curve.  Note also that,
# even though the smoother is still on, it has no effect on DPDRAW.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$A SPIRAL DRAWN UsinG DPFRST/VECT/LAST' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPDRAW');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPDRAW' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpdraw (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
   my $RRHO=8.*($I-1)/100.;
   my $THTA=6.28318530717958*($I-1)/20.;
   &NCAR::dpdraw (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpdraw (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::plchhq (0.,-9.,'Using DPDRAW.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the lower left quadrant of the frame.
#
&NCAR::set (.030,.485,.010,.455,-10.,10.,-10.,10.,1);
#
# Use DPSMTH to draw the same spiral.  The single-character flag is
# still on and smoothing is still on.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPDRAW' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPSMTH');
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPSMTH' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsmth (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=6.28318530717958*($I-1)/20.;
  &NCAR::dpsmth (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpsmth (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::plchhq (0.,-9.,'Using DPSMTH.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the lower right quadrant of the frame.
#
&NCAR::set (.515,.970,.010,.455,-10.,10.,-10.,10.,1);
#
# Use DPSMTH to draw another spiral.  This time, use PLCHHQ function
# codes in the label string and use color to distinguish the label
# from the line.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$_$_$_$_$_$_$_$A SPIRAL DRAWN UsinG DPSMTH' (character),
# 'LTL' = 0, 'MFS' = 1, 'PCF' = 0, 'SAF' = 360, 'SCF' = 1, 'SSL' = .01,
# 'TCS' = 2.5, 'WOC' = .01, 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$$$$$$$$$$$$$$$$C|o|n|t|o|u|r| |l|e|v|e|l| |=| |1|3|.|6|2|:L1:4|1|0:S:14:N:');
#
&NCAR::dpseti ('LTL - LINE-THROUGH-LABEL FLAG',1);
#
&NCAR::dpseti ('SCF - sinGLE-CHARACTER FLAG',0);
#
&NCAR::dpsetr ('SSL - SMOOTHED SEGMENT LENGTH',.001);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$$$$$$$$$$$$$C|o|n|t|o|u|r| |l|e|v|e|l| |=| |1|3|.|6|2|:L
# 1:4|1|0:S:14:N:' (character), 'LTL' = 1, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::gsplci (2);
&NCAR::pcseti ('CC - CHARACTER COLOR',3);
#
&NCAR::dpsmth (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=6.28318530717958*($I-1)/15.;
  &NCAR::dpsmth (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpsmth (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::gsplci (1);
&NCAR::pcseti ('CC - CHARACTER COLOR',1);
#
&NCAR::plchhq (0.,-9.,'Using PLCHHQ function codes and colors.',.01,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Put a label at the top of the third frame.
#
&NCAR::plchhq (&NCAR::cfux(.5),&NCAR::cfuy(.975),'DEMONSTRATING THE USE OF DASHPACK - FRAME 3',.015,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the upper left quadrant of the frame.
#
&NCAR::set (.030,.485,.495,.950,-10.,10.,-10.,10.,1);
#
# Use DPSMTH to draw a spiral.  Use color to distinguish the labels
# from the line, and orient all the labels horizontally.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$$$$$$$$$$$$$$$C|o|n|t|o|u|r| |l|e|v|e|l| |=| |1|3|.|6|2|:L
# 1:4|1|0:S:14:N:' (character), 'LTL' = 1, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 0, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$$SPIRAL');
#
&NCAR::dpseti ('SAF - STRING-ANGLE FLAG',-360);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$SPIRAL' (character), 'LTL' = 1, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = -360, 'SCF' = 0, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::gsplci (2);
&NCAR::pcseti ('CC - CHARACTER COLOR',3);
#
&NCAR::dpsmth (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpsmth (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpsmth (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::gsplci (1);
&NCAR::pcseti ('CC - CHARACTER COLOR',1);
#
&NCAR::plchhq (0.,-9.,'Using horizontal labels.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the upper right quadrant of the frame.
#
&NCAR::set (.515,.970,.495,.950,-10.,10.,-10.,10.,1);
#
# Use DPDRAW to draw a spiral.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$$SPIRAL' (character), 'LTL' = 1, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = -360, 'SCF' = 0, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$$$SPIRAL');
#
&NCAR::dpseti ('LTL - LINE-THROUGH-LABEL FLAG',0);
#
&NCAR::dpseti ('PCF - PLOTCHAR FLAG',1);
#
&NCAR::dpseti ('SAF - STRING-ANGLE FLAG',360);
#
&NCAR::dpseti ('SCF - sinGLE-CHARACTER FLAG',1);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$SPIRAL' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 1,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpdraw (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpdraw (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpdraw (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::plchhq (0.,-9.,'Using PLCHMQ instead of PLCHHQ.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the lower left quadrant of the frame.
#
&NCAR::set (.030,.485,.010,.455,-10.,10.,-10.,10.,1);
#
# Use DPDRAW to draw a spiral.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$$$SPIRAL' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 1,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .01,
# 'WOG' = .005, and 'WOS' = .005.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$_$_$_$SPIRAL');
#
&NCAR::dpseti ('PCF - PLOTCHAR FLAG',0);
#
&NCAR::dpsetr ('WOC - WIDTH OF CHARACTERS',.02);
#
&NCAR::dpsetr ('WOG - WIDTH OF GAP',.01);
#
&NCAR::dpsetr ('WOS - WIDTH OF SOLID',.01);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$SPIRAL' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .02,
# 'WOG' = .01, and 'WOS' = .01.
#
&NCAR::dpdraw (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpdraw (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpdraw (0.,0.,2);
#
# Put a small label below the spiral.
#
&NCAR::plchhq (0.,-9.,'Changing character and solid/gap sizes.',.01,0.,0.);
#
# Define the mapping from the user system to the fractional system in
# such a way as to use only the lower right quadrant of the frame.
#
&NCAR::set (.515,.970,.010,.455,-10.,10.,-10.,10.,1);
#
# Use DPDRAW to draw two spirals and then use 'MFS' to offset one.
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$SPIRAL' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .02,
# 'WOG' = .01, and 'WOS' = .01.
#
&NCAR::dpsetr ('WOC - WIDTH OF CHARACTERS',.008);
#
&NCAR::dpsetr ('WOG - WIDTH OF GAP',.008);
#
&NCAR::dpsetr ('WOS - WIDTH OF SOLID',.008);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$_$_$_$SPIRAL' (character), 'LTL' = 0, 'MFS' = 1, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .008,
# 'WOG' = .008, and 'WOS' = .008.
#
# Draw the first spiral.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$SPIRAL 1');
#
&NCAR::dpsetr ('MFS - MULTIPLIER FOR FIRST SOLID',1.5);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$SPIRAL 1' (character), 'LTL' = 0, 'MFS' = 1.5, 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .008,
# 'WOG' = .008, and 'WOS' = .008.
#
&NCAR::dpdraw (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=6.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpdraw (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpdraw (0.,0.,2);
#
# Draw the second spiral.
#
&NCAR::dpsetc ('DPT - DASH PATTERN (CHARACTER)','$$$$$SPIRAL 2');
#
&NCAR::dpsetr ('MFS - MULTIPLIER FOR FIRST SOLID',3.);
#
# Note: At this point, 'DPS' = 0, 'DPT' = 01011011101111 (binary)
# or '$$$$$SPIRAL 2' (character), 'LTL' = 0, 'MFS' = 3., 'PCF' = 0,
# 'SAF' = 360, 'SCF' = 1, 'SSL' = .001, 'TCS' = 2.5, 'WOC' = .008,
# 'WOG' = .008, and 'WOS' = .008.
#
&NCAR::dpdraw (&NCAR::cufx(0.),&NCAR::cufy(0.),0);
#
for my $I ( 2 .. 101 ) {
  my $RRHO=8.*($I-1)/100.;
  my $THTA=8.*($I-1)/50.;
  &NCAR::dpdraw (&NCAR::cufx($RRHO*cos($THTA)),&NCAR::cufy($RRHO*sin($THTA)),1);
}
#
&NCAR::dpdraw (0.,0.,2);
#
# Put a small label below the spirals.
#
&NCAR::plchhq (0.,-9.,'Using the first-solid multiplier.',.01,0.,0.);
#
# Advance the frame.
#
&NCAR::frame();
#
# Done.
#
print STDERR "
DASHPACK TEST EXECUTED OKAY - SEE PLOTS TO CERTIFY
";
#

#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Done.
#

sub IPKBTS { 
  my ($IBTS,$NBTS) = @_;
#
# This value of this function, when given an array of NBTS 0s and 1s,
# is the integer resulting from packing those bits together, to be
# used as an integer dash pattern.
#
#
# Initialize the value of the function to zero.
#
  my $IPKBTS=0;
#
# One at a time, shift the bits by the proper amount and "or" them into
# the value of the function, making sure to use only the lowest-order
# bit of each incoming array element.
#
  for my $I ( 1 .. $NBTS ) {
     $IPKBTS=$IPKBTS & ( ( at( $IBTS, $I-1 ) & 1 ) << ( $NBTS-$I ) );
  }
#
# Done.
#
  return $IPKBTS;
} 
 
   
rename 'gmeta', 'ncgm/tdshpk.ncgm';
