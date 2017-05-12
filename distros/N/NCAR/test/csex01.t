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
#       $Id: csex01.f,v 1.2 1999/01/28 23:55:28 fred Exp $
#
#
#  This example illustrates the effects of using differing numbers
#  of knots in calls to CSA1S with the same input data.
#
#
#  The dimensionality of the problem.
#
my $NDIM = 1;
#
#  The number of input data points.
#
my $NDATA = 10;
#
#  The number of output data points.
#
my $NPTS = 101;
#  
#  The maximum number of knots used in any call.
#
my $NCF = 9;
#
#  The size of the workspace.
#
my $NWRK = $NCF * ( $NCF + 3 );
#
#  Dimension arrays.
#
my $XDATA = zeroes float, $NDIM, $NDATA;
my $YDATA = zeroes float, $NDATA;
my $XDATAT = zeroes float, $NDATA;
my $WORK = zeroes float, $NWRK;
my $XO = zeroes float, $NPTS;
my $YO4 = zeroes float, $NPTS;
my $YO7 = zeroes float, $NPTS;
my $YO9 = zeroes float, $NPTS;
#
#  Define the original data.
#
my @xdata = ( 0.00, 0.1, 0.2, 0.30, 0.5, 0.6, 0.65, 0.8, 0.9, 1.00 );
my @ydata = ( 0.0, 0.8, -0.9, -0.9, 0.9, 1.0, 0.90, -0.8, -0.8, 0. );
for my $I ( 1 .. 10 ) {
  set( $XDATA, 0, $I-1, $xdata[$I-1] );
  set( $YDATA, $I-1, $ydata[$I-1] );
}
#
#  Create the output X coordinate array.
# 
my $XINC = 1./($NPTS-1);
for my $I ( 1 .. $NPTS ) {
  set( $XO, $I-1, ($I-1)*$XINC );
}
#
#  Calculate the approximated function values using differing 
#  number of knots.
#
my $KNOTS = 4;
&NCAR::csa1s ($NDATA,$XDATA,$YDATA,$KNOTS,$NPTS,$XO,$YO4,$NWRK,$WORK,my $IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from CSA1S\n", $IER );;
  exit( 0 );;
}
#
$KNOTS = 7;
&NCAR::csa1s ($NDATA,$XDATA,$YDATA,$KNOTS,$NPTS,$XO,$YO7,$NWRK,$WORK,$IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from CSA1S\n", $IER );;
  exit( 0 );;
}
#
$KNOTS = 9;
&NCAR::csa1s ($NDATA,$XDATA,$YDATA,$KNOTS,$NPTS,$XO,$YO9,$NWRK,$WORK,$IER);
if( $IER != 0 ) {
  printf( STDERR "\nError %3d returned from CSA1S\n", $IER );;
  exit( 0 );;
}
#
#  Draw a plot of the approximation functions and mark the original points.
#
for my $I ( 1 .. $NDATA ) {
  set( $XDATAT, $I-1, at( $XDATA, 0, $I-1 ) );
}
#
&DRWFT1($NDATA,$XDATAT,$YDATA,$NPTS,$XO,$YO4,$YO7,$YO9);
#


sub DRWFT1 {
  my ($NUMO,$X,$Y,$IO,$XO,$CURVE1,$CURVE2,$CURVE3) = @_;
#
#  This subroutine uses NCAR Graphics to plot three curves on
#  the same picture showing the results from calling CSA1X with
#  differing number of knots.  The values for the curves are
#  contained in arrays CURVE1, CURVE2, and CURVE3.
#
#
#  Define error file, Fortran unit number, workstation type
#  and workstation ID.
#
  my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
#  Vertical position for initial curve.
#
  my $YPOS_TOP = 0.88;
#
#  Open GKS, open and activate a workstation.
#
  &NCAR::gopks ($IERRF, my $ISZDM);
  &NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
  &NCAR::gacwk ($IWKID);
#
#  Define a color table.
#
  &NCAR::gscr($IWKID, 0, 1.0, 1.0, 1.0);
  &NCAR::gscr($IWKID, 1, 0.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 2, 1.0, 0.0, 0.0);
  &NCAR::gscr($IWKID, 3, 0.0, 0.0, 1.0);
  &NCAR::gsclip(0);
#
#  Plot the main title.
#
  &NCAR::plchhq(0.50,0.95,':F21:Demo for csa1s',0.035,0.,0.);
#
#  Draw a background grid for the first curve.
#
  my $YB = -1.2;
  my $YT =  1.2;
  &BKGFT1($YPOS_TOP,'knots = 4',$YB,$YT);
  &NCAR::gridal(5,5,4,1,1,1,10,0.0,$YB);
#
#  Mark the original data points.
#
  &NCAR::gsmksc(2.2);
  &NCAR::gspmci(3);
  &NCAR::gslwsc(1.);
  &NCAR::gpm($NUMO,$X,$Y);
#
#  Graph the approximated function values for KNOTS=4.
#
  &NCAR::gsplci(1);
  &NCAR::gpl($IO,$XO,$CURVE1);
#
#  Graph the approximated function values for KNOTS=7.
#
  &BKGFT1($YPOS_TOP-0.3,'knots = 7',$YB,$YT);
  &NCAR::gridal(5,5,4,1,1,1,10,0.0,$YB);
  &NCAR::gpm($NUMO,$X,$Y);
  &NCAR::gpl($IO,$XO,$CURVE2);
  &NCAR::gsplci(1);
#
#  Graph the approximated function values for KNOTS=9.
#
  &BKGFT1($YPOS_TOP-0.6,'knots = 9',$YB,$YT);
  &NCAR::gridal(5,5,4,1,1,1,10,0.0,$YB);
  &NCAR::gpm($NUMO,$X,$Y);
  &NCAR::gpl($IO,$XO,$CURVE3);
  &NCAR::gsplci(1);
  &NCAR::frame();
#
  &NCAR::gdawk($IWKID);
  &NCAR::gclwk($IWKID);
  &NCAR::gclks();
#
}


sub BKGFT1 {
  my ($YPOS,$LABEL,$YB,$YT) = @_;
#
#  This subroutine draws a background grid.
#
  my $XX = zeroes float, 2;
  my $YY = zeroes float, 2;
#
  &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1);
#
#  Plot the curve label using font 21 (Helvetica).
#
  &NCAR::pcseti('FN',21);
  &NCAR::plchhq(0.25,$YPOS - 0.03,$LABEL,0.025,0.,-1.);
  &NCAR::set(0.13,0.93,$YPOS-0.2,$YPOS,0.0,1., $YB, $YT, 1);
#
#  Draw a horizontal line at Y=0. using color index 2.
#
  my $XX = float [ 0, 1 ];
  my $YY = float [ 0, 0 ];
  &NCAR::gsplci(2);
  &NCAR::gpl(2,$XX,$YY);
  &NCAR::gsplci(1);
#
#  Set Gridal parameters. 
#
#
#   Set LTY to indicate that the Plotchar routine PLCHHQ should be used.
#
  &NCAR::gaseti('LTY',1);
#
#   Size and format for X axis labels.
#
  &NCAR::gasetr('XLS',0.02);
  &NCAR::gasetc('XLF','(F3.1)');
#
#   Size and format for Y axis labels.
#
  &NCAR::gasetr('YLS',0.02);
  &NCAR::gasetc('YLF','(F5.1)');
#
#   Length of major tick marks for the X and Y axes.
#
  &NCAR::gasetr('XMJ',0.02);
  &NCAR::gasetr('YMJ',0.02);
#
}


rename 'gmeta', 'ncgm/csex01.ncgm';
