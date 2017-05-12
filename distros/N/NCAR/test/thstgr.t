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
   
 
#
#	$Id: thstgr.f,v 1.7 1995/06/14 14:04:55 haley Exp $
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# OPEN GKS, OPEN WORKSTATION OF TYPE 1, ACTIVATE WORKSTATION
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# PURPOSE                To provide a demonstration of the HISTGR
#                        utility and to test each of the four IFLAG
#                        options.
#
# USAGE                  CALL THSTGR (IERROR,IWKID)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An error flag
#                          = 0, If the test is successful,
#                          = 1, otherwise.
#
# I/O                    If the test is successful, the message
#
#                          HISTGR TEST SUCCESSFUL  . . .  SEE PLOT
#                          TO VERIFY PERFORMANCE
#
#                        is written on unit 6.
#
#                        In addition, three (3) labeled frames are
#                        produced.  To determine if the test was
#                        successful examine these plots.
#
# PRECISION              Single
#
# REQUIRED LIBRARY       HISTGR
# FILES
#
# REQUIRED GKS LEVEL     0A
#
# LANGUAGE               FORTRAN 77
#
# HISTORY                Originally written May, 1985; revised
#                        August, 1987
#
# ALGORITHM              THSTGR computes data and calls HISTGR
#                        5 times, exercising different options.
#
#
#  Array DAT1 is filled with values to be used as input for HISTGR
#
my ( $NDIM, $NCLS, $NWRK ) = ( 320, 17, 374 );
#
#  NWRK = NDIM + 3*(NCLS+1)
#
my $DAT1 = zeroes float, $NDIM, 2;
my $ARR7 = zeroes float, 7;
my $WORK = zeroes float, $NWRK;
my $CLASS = zeroes float, $NCLS+1;
my $SPAC = zeroes float, 2;
my $COLORS = zeroes long, 15;
#
#  Define the RGB triples needed below.
#
my @RGB = (
  [ 0.70, 0.70, 0.70, ],
  [ 0.75, 0.00, 1.00, ],
  [ 0.30, 0.10, 1.00, ],
  [ 0.10, 0.50, 1.00, ],
  [ 0.00, 0.70, 1.00, ],
  [ 0.00, 1.00, 1.00, ],
  [ 0.00, 1.00, 0.70, ],
  [ 0.00, 1.00, 0.00, ],
  [ 0.70, 0.00, 0.70, ],
  [ 1.00, 1.00, 0.00, ],
  [ 1.00, 0.75, 0.00, ],
  [ 1.00, 0.48, 0.00, ],
  [ 1.00, 0.00, 0.48, ],
  [ 1.00, 0.00, 0.00, ],
  [ 1.00, 1.00, 1.00  ],
);
#
my ( $TX, $TY ) = ( .5, .9765 );
#
#  Define 15 color indices, 14 spaced throughout the color
#  spectrum, and the last one being white.
#
&NCAR::gscr($IWKID,0,0.,0.,0.);
for my $I ( 1 .. 15 ) {
  &NCAR::gscr($IWKID,$I,@{ $RGB[$I-1] });
}
#
#  Call ENTSR (from PORT library) to recover from warnings
#
&NCAR::entsr(my $IDUM, 1);
#
# Change the Plotchar special character code from a : to a @
#
my $IFC;
substr( $IFC, 0, 1, '@' );
&NCAR::pcsetc('FC',$IFC);
#
#
#  Frame 1:  Demonstrate the default version of HISTGR, IFLAG = 0.
#
my $IFLAG = 0;
my $NCLASS = 11;
my $NPTS = 320;
#
for my $I ( 1 .. $NPTS ) {
  for my $J( 1 .. 2 ) {
    set( $DAT1, $I-1, $J-1, 0 );
  }
}

sub Log10 {
  my $x = shift;
  return log( $x ) / log( 10 );
}

for my $I ( 1 .. $NPTS ) {
  my $X = $I;
  set( $DAT1, $I-1, 0, 10. * &Log10(0.1*$X+1.) );
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Flush PLOTIT's buffers.
#
&NCAR::plotit(0,0,0);
#
#  Set text and polyline color indices to 15 (white).
#
&NCAR::gstxci(15);
&NCAR::gsplci(15);
#
&NCAR::plchlq ($TX,$TY,'DEMONSTRATION PLOT FOR DEFAULT VERSION OF HISTGR',16.,0.,0.);
&NCAR::histgr($DAT1, $NDIM, $NPTS, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#  Frame 2:  Demonstrate the comparison of two previously determined
#            histograms, IFLAG = 3.
#
$IFLAG = 3;
$NCLASS = 6;
my $NPTS2 = 6;
for my $I ( 1 .. $NPTS2 ) {
  set( $DAT1, $I-1, 0, 2*sin( $I ) );
  set( $DAT1, $I-1, 1, 2.5*cos( $I/.5 ) );
  set( $CLASS, $I-1, $I );
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Turn on color, title, perimeter, frequency, format, character,
#  label, and spacing options.
#
set( $COLORS , 1-1, 8  );
set( $COLORS , 2-1, 3  );
set( $COLORS , 3-1, 14 );
set( $COLORS , 4-1, 11 );
set( $COLORS , 5-1, 6  );
set( $COLORS , 6-1, 13 );
set( $COLORS , 7-1, 14 );
set( $COLORS , 8-1, 5  );
&NCAR::hstopi('COL=ON',3,0,$COLORS,8);
#
#  Choose large, horizontal alphanumeric labels for class labels.
#
&NCAR::hstopc('TI=ON','OPTIONS CHANGED: PRM,TIT,CHA,LAB,FOR,COL,FQN and SPA',7,3);
&NCAR::hstopl('PR=ON');
&NCAR::hstopc('FQ=ON','MONTHLY PRECIPITATION',7,3);
&NCAR::hstopc('FO=ON','(F3.0)',9,3);
my $MON='JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC';
&NCAR::hstopc('CH=ON',$MON,12,3);
&NCAR::hstopc('LA=ON','COMPARE TWO DATASETS',7,3);
set( $SPAC, 0, 2.0  );
set( $SPAC, 1, -1.5 );
&NCAR::hstopr('SP=ON',$SPAC,2);
#
#  The second argument must be the actual dimension size of DAT1.
#
&NCAR::histgr($DAT1, $NDIM, $NPTS2, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#  Frame 3:  Put four plots on 1 frame by setting FRAME = OFF for the
#            first 3 plots and FRAME = ON for the last plot.
#
#     Plot 1:   IFLAG = 0, automatic sorting of the input data into
#               NCLASS = 17 bins.
#
$IFLAG = 0;
$NCLASS = 17;
$NPTS = 320;
for my $I ( 1 .. $NPTS ) {
  my $X = $I;
  set( $DAT1, $I-1, 0, 10. * &Log10(0.1*$X+1.) );
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Turn on horizontal bars, title, median, window, color,
#  and spacing options.
#
#  Choose large horizontal class labels.
#
&NCAR::hstopc('TI=ON','OPTIONS: HOR, WIN, FRA, MED, COL, SPA, & TIT',9,3);
&NCAR::hstopl('HO=ON');
&NCAR::hstopl('ME=ON');
#
#  Plot 1 goes into the top left quadrant of the frame.
#
#       ARR7 coordinates are XMIN, XMAX, YMIN, YMAX.
#
set( $ARR7, 1-1, 0. );
set( $ARR7, 2-1, .5 );
set( $ARR7, 3-1, .5 );
set( $ARR7, 4-1, 1. );
&NCAR::hstopr('WI=ON',$ARR7,4);
#
set( $COLORS, 1-1,  8  );
set( $COLORS, 2-1,  2  );
set( $COLORS, 3-1,  10 );
set( $COLORS, 4-1,  4  );
set( $COLORS, 5-1,  5  );
set( $COLORS, 6-1,  6  );
set( $COLORS, 7-1,  7  );
set( $COLORS, 8-1,  8  );
&NCAR::hstopi('COL=ON',2,0,$COLORS,8);
set( $SPAC, 0, 3.0 );
set( $SPAC, 1, 0.0 );
&NCAR::hstopr('SP=ON',$SPAC,2);
#
#  Turn off the frame advance.
#
&NCAR::hstopl('FR=OF');
&NCAR::histgr($DAT1, $NDIM, $NPTS, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#     Plot 2:   IFLAG = 2, one set of 11 histogram classes and their
#               associated values are plotted.
#
$IFLAG = 2;
$NCLASS = 11;
$NPTS2 = 11;
for my $I ( 1 .. $NPTS2 ) {
  set( $CLASS, $I-1, 2*$I );
  set( $DAT1, $I-1, 0, sqrt( 2*$I ) );
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Turn on title, label, frequency, format, and window options.
#
#  Choose medium sized, horizontal labels for class labels
#
&NCAR::hstopc('TI=ON','OPTIONS CHANGED: LAB,FQN,TIT,FOR,FRA AND WIN',11,3);
&NCAR::hstopc('LA=ON','Y VALUES ASSIGNED TO X VALUES',11,3);
&NCAR::hstopc('FQ=ON','SQUARE ROOT OF CLASS MID-VALUES',12,3);
&NCAR::hstopc('FO=ON','(I3)',11,3);
#
#  Plot 2 goes into the top right quadrant of the frame.
#
set( $ARR7, 0, .5 );
set( $ARR7, 1, 1. );
set( $ARR7, 2, .5 );
set( $ARR7, 3, 1. );
&NCAR::hstopr('WIN=ON',$ARR7,4);
#
#  Turn off color and frame advance options.
#
&NCAR::hstopi('COL=OF',2,0,$COLORS,8);
&NCAR::hstopl('FR=OFF');
&NCAR::histgr($DAT1, $NDIM, $NPTS2, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#     Plot 3:   IFLAG = 1, input values are sorted into a defined set of
#               8 classes.
#
$IFLAG = 1;
$NCLASS = 8;
$NPTS = 320;
my $X = 0.;
for my $I ( 1 .. $NPTS ) {
  set( $DAT1, $I-1, 0, sin( $X ) );
  $X = $X + .02;
}
#
set( $CLASS, 0, -0.6 );
for my $I ( 1 .. $NCLASS ) {
  set( $CLASS, $I, at( $CLASS, $I-1 ) + 0.20 );
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Turn on class, draw line, format, title, and label options.
#
&NCAR::hstopi('CL=ON',2,30,$COLORS,8);
&NCAR::hstopl('DR=ON');
&NCAR::hstopc('FOR=ON','(F6.2)',9,3);
&NCAR::hstopc('TI=ON','OPTIONS CHANGED: CLA,DRL,FOR,TIT,LAB,MID,WIN,SHA and FRA',9,3);
&NCAR::hstopc('LA=ON','CLASS VALUES CHOSEN FROM -0.6 to 1.0',9,3);
#
#  Plot 3 goes into the lower left quadrant of the frame.
#
set( $ARR7, 1-1,  0. );
set( $ARR7, 2-1,  .5 );
set( $ARR7, 3-1,  0. );
set( $ARR7, 4-1,  .5 );
&NCAR::hstopr('WI=ON',$ARR7,4);
#
#  Turn off color, midvalues, frame advance and shading options.
#
#  Write the class labels at a 30 deg angle.
#
&NCAR::hstopi('CO=OF',2,30,$COLORS,8);
&NCAR::hstopl('MI=OFF');
&NCAR::hstopl('FR=OFF');
&NCAR::hstopl('SH=OFF');
&NCAR::histgr($DAT1, $NDIM, $NPTS, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#     Plot 4:   IFLAG = 0, input values are sorted into 11 equally sized
#               bins over the range of the input values.
#
$IFLAG = 0;
$NCLASS = 11;
$NPTS = 320;
my $X = 0.;
for my $I ( 1 .. $NPTS ) {
  set( $DAT1, $I-1, 0, sin( $X ) );
  $X = $X + .02;
}
#
#  (First call HSTOPL('DEF=ON') to activate all default options.)
#
&NCAR::hstopl('DE=ON');
#
#  Turn on class, frequency, format, title, window, and label options.
#
#  Choose medium sized vertical class value labels.
#
&NCAR::hstopi('CL=ON',2,90,$COLORS,8);
&NCAR::hstopc('FQN=ON','NUMBER OF OCCURENCES IN EACH CLASS',9,3);
&NCAR::hstopc('FOR=ON','(F6.2)',9,3);
&NCAR::hstopc('TI=ON','OPTIONS CHANGED: CLA,LAB,FQN,TIT,SPA,PER,FOR AND WIN',9,3);
#
#  Plot 4 goes into the lower right quadrant of the frame.
#
set( $ARR7, 1-1, .5 );
set( $ARR7, 2-1, 1. );
set( $ARR7, 3-1, 0. );
set( $ARR7, 4-1, .5 );
&NCAR::hstopr('WIN=ON',$ARR7,4);
&NCAR::hstopc('LAB=ON','CLASS VALUES COMPUTED WITHIN HISTGR',9,3);
#
#  Turn off color, spacing and percent axis options.
#
&NCAR::hstopi('CO=OF',2,90,$COLORS,8);
&NCAR::hstopr('SP=OF',$SPAC,2);
&NCAR::hstopl('PER=OFF');
#
&NCAR::histgr($DAT1, $NDIM, $NPTS, $IFLAG, $CLASS, $NCLASS, $WORK, $NWRK);
#
#
print STDERR "\n
HISTGR TEST SUCCESSFUL
SEE PLOT TO VERIFY PERFORMANCE
";
   
#
# DEACTIVATE AND CLOSE WORKSTATION, CLOSE GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
 
   
rename 'gmeta', 'ncgm/thstgr.ncgm';
