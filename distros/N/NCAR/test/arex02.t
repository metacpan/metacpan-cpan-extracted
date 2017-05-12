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
print STDERR "\n";
#
# This program illustrates the use of the routine ARMVAM, particularly
# as it is used in the process of recovering from area map overflow
# problems.  Because this example is intended to be strictly FORTRAN
# 77, no attempt is made to do real dynamic storage allocation;
# instead, an area map array of a fixed size is used, and the AREAS
# routines are only told about a part of that array.  Still, the idea
# is much the same as one would use in C or, presumably, in FORTRAN
# 90 (if and when compilers become generally available for FORTRAN 90).
#
#
# Define the size of the area map array to be used.  The part of this
# used by the AREAS routines will fluctuate as needed.
#
my $LAMA=6000;
#
# Define the sizes of the work arrays to be used by ARSCAM.
#
my ( $NCRA, $NGPS ) = ( 1000, 10 );
#
# Declare the area map array.
#
my $IAMA = zeroes long, $LAMA;
#
# Declare the work arrays to be used by ARSCAM.
#
my $XCRA = zeroes float, $NCRA;
my $YCRA = zeroes float, $NCRA;
my $IAAI = zeroes long,  $NGPS;
my $IAGI = zeroes long,  $NGPS;
#
# Declare the routine that will color the areas defined by the area map.
#
#       EXTERNAL COLRAM
#
# Define the perimeter for all three groups of edges.
#
my $PERIX = float [ .90,.90,.10,.10,.90 ];
my $PERIY = float [ .10,.90,.90,.10,.10 ];
#
# Define the group 1 edges.
#
my $G1E1X = float [ .75,.68,.50,.32,.25,.32,.50,.68,.75 ];
my $G1E1Y = float [ .50,.68,.75,.68,.50,.32,.25,.32,.50 ];
#
my $G1E2X = float [ .60,.60,.40,.40,.60 ];
my $G1E2Y = float [ .40,.60,.60,.40,.40 ];
#
# Define the group 3 edges.
#
  my $G3E1X = float [ .10,.20 ];
  my $G3E1Y = float [ .80,.90 ];
#
  my $G3E2X = float [ .10,.40 ];
  my $G3E2Y = float [ .60,.90 ];
#
  my $G3E3X = float [ .10,.60 ];
  my $G3E3Y = float [ .40,.90 ];
#
  my $G3E4X = float [ .10,.80 ];
  my $G3E4Y = float [ .20,.90 ];
#
  my $G3E5X = float [ .20,.90 ];
  my $G3E5Y = float [ .10,.80 ];
#
  my $G3E6X = float [ .40,.90 ];
  my $G3E6Y = float [ .10,.60 ];
#
  my $G3E7X = float [ .60,.90 ];
  my $G3E7Y = float [ .10,.40 ];
#
  my $G3E8X = float [ .80,.90 ];
  my $G3E8Y = float [ .10,.20 ];
#
  my $G3E9X = float [ .40,.20 ];
  my $G3E9Y = float [ .70,.50 ];
#
# Define the group 5 edges.
#
  my $G5E1X = float [ .50,.80,.80,.50,.50,.20,.35 ];
  my $G5E1Y = float [ .50,.50,.80,.80,.50,.20,.35 ];
#
# Change the GKS "fill area interior style" to be "solid".
#
&NCAR::gsfais (1);
#
# Define the colors to be used.
#
&NCAR::gscr (1,0,0.,0.,0.);
&NCAR::gscr (1,1,1.,1.,1.);
#
for my $I ( 1 .. 9 ) {
  my $S=$I/9.;
  &NCAR::gscr (1,10+$I,$S,1.-$S,0.);
  &NCAR::gscr (1,20+$I,$S,1.-$S,1.);
}
#
# Define the mapping from the user system to the plotter frame.
#
&NCAR::set (.05,.95,.05,.95,0.,1.,0.,1.,1);
#
# Tell AREAS to make identifiers larger and further from the arrows
# and make the arrowheads bigger.
#
&NCAR::arsetr ('ID - IDENTIFIER DISTANCE',.02);
&NCAR::arsetr ('IS - IDENTIFIER SIZE',.01);
&NCAR::arsetr ('AL - ARROWHEAD LENGTH',.04);
&NCAR::arsetr ('AW - ARROWHEAD WIDTH',.008);
#
# Initialize the variable that keeps track of how much space is
# currently used in the area map.
#
my $NAMA=500;
#
# Initialize the area map.
#
&NCAR::arinam ($IAMA,$NAMA);
#
# Put group 1 edges into the area map.  Instead of calling the AREAS
# routine AREDAM directly, we call an example routine that puts the
# package SETER into recovery mode, checks for overflow of the area
# map array, and uses ARMVAM to recover.
#
&EXEDAM ($IAMA,$LAMA,$NAMA,$PERIX,$PERIY,5,1, 0,-1);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G1E1X,$G1E1Y,9,1, 2, 1);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G1E2X,$G1E2Y,5,1, 1, 2);
#
# Put group 3 edges into the area map.  Again, instead of calling the
# AREAS routine AREDAM directly, we call EXEDAM to allow for error
# recovery.
#
&EXEDAM ($IAMA,$LAMA,$NAMA,$PERIX,$PERIY,5,3, 0,-1);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E1X,$G3E1Y,2,3, 1, 2);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E2X,$G3E2Y,2,3, 2, 3);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E3X,$G3E3Y,2,3, 3, 4);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E4X,$G3E4Y,2,3, 4, 5);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E5X,$G3E5Y,2,3, 5, 6);

&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E6X,$G3E6Y,2,3, 6, 7);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E7X,$G3E7Y,2,3, 7, 8);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E8X,$G3E8Y,2,3, 8, 9);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G3E9X,$G3E9Y,2,3, 9,10);

#
# Put group 5 edges into the area map.  Again, instead of calling the
# AREAS routine AREDAM directly, we call EXEDAM to allow for error
# recovery.
#
&EXEDAM ($IAMA,$LAMA,$NAMA,$PERIX,$PERIY,5,5, 0,-1);
&EXEDAM ($IAMA,$LAMA,$NAMA,$G5E1X,$G5E1Y,7,5,-1, 0);
#
# Preprocess the area map.  Again, instead of calling the AREAS
# routine ARPRAM directly, we call EXPRAM to allow for error
# recovery.  Do debug plots to make sure things are working okay.
#
&NCAR::ardbpa ($IAMA,1,'BEFORE CALLING ARPRAM - GROUP 1');
&NCAR::ardbpa ($IAMA,3,'BEFORE CALLING ARPRAM - GROUP 3');
&NCAR::ardbpa ($IAMA,5,'BEFORE CALLING ARPRAM - GROUP 5');
&EXPRAM ($IAMA,$LAMA,$NAMA,0,0,0);
&NCAR::ardbpa ($IAMA,1,'AFTER CALLING ARPRAM - GROUP 1');
&NCAR::ardbpa ($IAMA,3,'AFTER CALLING ARPRAM - GROUP 3');
&NCAR::ardbpa ($IAMA,5,'AFTER CALLING ARPRAM - GROUP 5');
#
# Pack the contents of the area map into the smallest possible space.
#
&NCAR::armvam ($IAMA,$IAMA,at($IAMA,0)-(at($IAMA,5)-at($IAMA,4)-1));
#
# Scan the area map.  Again, instead of calling the AREAS routine
# ARSCAM directly, we call EXSCAM to allow for error recovery.
#
&EXSCAM ($IAMA,$LAMA,$NAMA,$XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS,\&COLRAM);

sub COLRAM {
  my ($XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS) = @_;
#
# Pick off the individual group identifiers.
#
  my $IAI1=0;
  my $IAI3=0;
  my $IAI5=0;
#
  for my $I ( 1 .. $NGPS ) {
    if( at( $IAGI, $I-1 ) == 1 ) { $IAI1 = at( $IAAI, $I-1 ); }
    if( at( $IAGI, $I-1 ) == 3 ) { $IAI3 = at( $IAAI, $I-1 ); }
    if( at( $IAGI, $I-1 ) == 5 ) { $IAI5 = at( $IAAI, $I-1 ); }
  }
#
# Skip coloring if either of the first two area identifiers is zero or
# negative or if the final one is negative.
#
  unless( ( $IAI1 <= 0 ) || ( $IAI3 <= 0 ) || ( $IAI5 < 0 ) ) {
#
# Otherwise, color the area, using a color index which is obtained by
# combining the area identifiers for groups 1 and 3.
#
  &NCAR::gsfaci (10*$IAI1+$IAI3);
  &NCAR::gfa    ($NCRA-1,$XCRA,$YCRA);
#
# Done.
#
  }
}

sub EXEDAM {
  my ($IAMA,$LAMA,$NAMA,$XCRA,$YCRA,$NCRA,$IGID,$IAIL,$IAIR) = @_;
#
# Put SETER into recovery mode, saving the previous setting of the
# recovery-mode flag in IROLD.
#
  &NCAR::entsr (my $IROLD,1);
#
# Attempt to put the edges in the error map.
#
  L101:
  &NCAR::aredam ($IAMA,$XCRA,$YCRA,$NCRA,$IGID,$IAIL,$IAIR);
#
# See if a recoverable error occurred during the call to AREDAM.
#
  if( &NCAR::nerro(my $NERR) != 0 ) {
#
# A recoverable error occurred.  See if it was due to overflowing the
# area map array and if we can do something about it.
#
    if( ( &NCAR::semess( 2 ) =~ m/AREA-MAP ARRAY OVERFLOW/o ) 
     && ( $NAMA < $LAMA) ) {
#
# Recover from an area map array overflow.  First, log what's happening.
#
      print STDERR "EXEDAM - OVERFLOW RECOVERY - NAMA = $NAMA\n";
#
# Clear the internal error flag in SETER.
#
      &NCAR::errof();
#
# Move the area map to a slightly larger part of the area map array.
#
      $NAMA=&NCAR::Test::min($NAMA+100,$LAMA);
      &NCAR::armvam ($IAMA,$IAMA,$NAMA);
#
# Go back to try the call to AREDAM again.
#
      goto L101;
#
    } else {
#
# Either the error is not an overflow error or we can't do anything
# about it.  Exit with a fatal error message.
#
      &NCAR::seter ('EXEDAM - CAN\'T GET AROUND AREDAM ERROR',1,2);
#
    }
#
  } else {
#
# No recoverable error occurred.  Restore the original value of SETER's
# recovery-mode flag.
#
    &NCAR::retsr ($IROLD);
#
  }
#
# Done.
#
  $_[2] = $NAMA;
}

sub EXPRAM {
  my ($IAMA,$LAMA,$NAMA,$IFL1,$IFL2,$IFL3) = @_;
#
# Put SETER into recovery mode, saving the previous setting of the
# recovery-mode flag in IROLD.
#
  &NCAR::entsr (my $IROLD,1);
#
# Attempt to pre-process the area map.
#
  L101:
  &NCAR::arpram ($IAMA,$IFL1,$IFL2,$IFL3);
#
# See if a recoverable error occurred during the call to ARPRAM.
#
  if( &NCAR::nerro( my $NERR ) != 0 ) {
#
# A recoverable error occurred.  See if it was due to overflowing the
# area map array and if we can do something about it.
#
    if( ( &NCAR::semess( 2 ) =~ m/AREA-MAP ARRAY OVERFLOW/o )
     && ( $NAMA < $LAMA) ) {
#
# Recover from an area map array overflow.  First, log what's happening.
#
       print STDERR "EXPRAM - OVERFLOW RECOVERY - NAMA = $NAMA\n";
#
# Clear the internal error flag in SETER.
#
       &NCAR::errof();
#
# Move the area map to a slightly larger part of the area map array.
#
       $NAMA=&NCAR::Test::min($NAMA+100,$LAMA);
       &NCAR::armvam ($IAMA,$IAMA,$NAMA);
#
# Go back to try the call to ARPRAM again.
#
       goto L101;
#
    } else {
#
# Either the error is not an overflow error or we can't do anything
# about it.  Exit with a fatal error message.
#
      &NCAR::seter ('EXPRAM - CAN\'T GET AROUND ARPRAM ERROR',1,2);
#
    }
#
   } else {
#
# No recoverable error occurred.  Restore the original value of SETER's
# recovery-mode flag.
#
    &NCAR::retsr ($IROLD);
#
  }
#
# Done.
#
  $_[2] = $NAMA;
}

sub EXSCAM {
  my ($IAMA,$LAMA,$NAMA,$XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS,$URPA) = @_;
#
# Put SETER into recovery mode, saving the previous setting of the
# recovery-mode flag in IROLD.
#
  &NCAR::entsr (my $IROLD,1);
#
# Attempt to scan the area map.
#
  L101:
  &NCAR::arscam ($IAMA,$XCRA,$YCRA,$NCRA,$IAAI,$IAGI,$NGPS,$URPA);
#
# See if a recoverable error occurred during the call to ARSCAM.
#
  if( &NCAR::nerro(my $NERR) != 0 ) {
#
# A recoverable error occurred.  See if it was due to overflowing the
# area map array and if we can do something about it.
#
    if( ( &NCAR::semess(2) =~ m/AREA-MAP ARRAY OVERFLOW/o )
     && ( $NAMA < $LAMA ) ) {
#
# Recover from an area map array overflow.  First, log what's happening.
#
      print STDERR "EXSCAM - OVERFLOW RECOVERY - NAMA = $NAMA\n";
#
# Clear the internal error flag in SETER.
#
      &NCAR::errof();
#
# Move the area map to a slightly larger part of the area map array.
#
      $NAMA=&NCAR::Test::min($NAMA+100,$LAMA);
      &NCAR::armvam ($IAMA,$IAMA,$NAMA);
#
# Go back to try the call to ARPRAM again.
#
      goto L101;
#
    } else {
#
# Either the error is not an overflow error or we can't do anything
# about it.  Exit with a fatal error message.
#
       &NCAR::seter ('EXSCAM - CAN\'T GET AROUND ARSCAM ERROR',1,2);
#
    }
#
  } else {
#
# No recoverable error occurred.  Restore the original value of SETER's
# recovery-mode flag.
#
     &NCAR::retsr ($IROLD);
#
   }
#
# Done.
#
  $_[2] = $NAMA;
}


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/arex02.ncgm';
