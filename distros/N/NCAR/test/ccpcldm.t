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
#  Define error file, Fortran unit number, and workstation type,
#  and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );

my ( $MREG, $NREG ) = ( 50, 50 );
my $XREG = zeroes float, $MREG;
my $YREG = zeroes float, $NREG;
my $ZREG = zeroes float, $MREG, $NREG;

#     EXTERNAL COLOR
#
# Get data array
#
my @t;
open DAT, "data/ccpcldm.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $I ( 1 .. $MREG ) {
  set( $XREG, $I-1, shift( @t ) );
}
for my $J ( 1 .. $NREG ) {
  set( $YREG, $J-1, shift( @t ) );
}
for my $J ( 1 .. $NREG ) {
  for my $I ( 1 .. $MREG ) {
    set( $ZREG, $I-1, $J-1, shift( @t ) );
  }
}
#
#  Open GKS, open and activate a workstation.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Call Conpack color fill routine
#
&CCPLDM($ZREG,$MREG,$NREG,\&COLOR,$IWKID);
#
# Close frame
#
&NCAR::frame();
#
# Deactivate and close workstation, close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks;

sub CCPLDM {
  my ($ZREG,$MREG,$NREG,$COLOR,$IWKID) = @_;

  my ( $LRWK, $LIWK, $LMAP, $NWRK, $NOGRPS ) = ( 5000, 5000, 50000, 5000, 5 );
  my $IWRK = zeroes long, $LIWK;
  my $RWRK = zeroes float, $LRWK;
  my $XWRK = zeroes float, $NWRK;
  my $YWRK = zeroes float, $NWRK;
  my $MAP = zeroes long, $LMAP;
  my $IAREA = zeroes long, $NOGRPS;
  my $IGRP = zeroes long, $NOGRPS;

#      EXTERNAL FILL
#      EXTERNAL CPDRPL
#      EXTERNAL COLOR
#
# Set fill style to solid
#
  &NCAR::gsfais(1);
#
# Use regular or penalty labeling scheme so that contour labels can be
# boxed.
#
  &NCAR::cpseti('LLP - LINE LABEL POSITIONING FLAG',2);
#
# Initialize Conpack
#
  &NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
#
# Set up color table
#
  &NCAR::cppkcl ($ZREG, $RWRK, $IWRK);
  &NCAR::cpgeti('NCL - NUMBER OF CONTOUR LEVELS', my $NCL);
  $COLOR->($NCL+1,$IWKID);
#
# Draw Perimeter
#
  &NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Initialize Areas
#
  &NCAR::arinam($MAP, $LMAP);
#
# Add label boxes to area map
#
  &NCAR::cplbam($ZREG, $RWRK, $IWRK, $MAP);
#
# Draw Labels
#
  &NCAR::cplbdr($ZREG, $RWRK, $IWRK);
#
# Add contours to area map
#
  &NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#
# Fill contours
#
  &NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&FILL);
#
# Draw contours, masking label boxes
#
  &NCAR::cpcldm($ZREG, $RWRK, $IWRK, $MAP, \&NCAR::cpdrpl);

}      

sub FILL {
  my ($XWRK,$YWRK,$NWRK,$IAREA,$IGRP,$NGRPS) = @_;
  
  my $IAREA3;    
  for my $I ( 1 .. $NGRPS ) { 
    if( at( $IGRP, $I-1 ) == 3 ) { $IAREA3 = at( $IAREA, $I-1 ); }   
  }
  if( $IAREA3 > 0 ) {     
#
# If the area is defined by 3 or more points, fill it
#
    &NCAR::gsfaci($IAREA3+2);
    &NCAR::gfa($NWRK,$XWRK,$YWRK);
  }
    
#
# Otherwise, do nothing
#
}


sub COLOR {
  my ($N,$IWKID) = @_;
#
# BACKGROUND COLOR
# BLACK
#
  &NCAR::gscr($IWKID,0,0.,0.,0.);
#
# First foreground color is white
#
  &NCAR::gscr($IWKID,1,1.,1.,1.);
#
# Second foreground color is gray
#
  &NCAR::gscr($IWKID,2,.75,.75,.75);
#
# Choose other foreground colors spaced equally around the spectrum
#
  my $ICNT=0;
  my $HUES=360./$N;
#
# REDLN is intended to be the line between red and violet values
#
  my $REDLN=36.0;
  my $LAP=int($REDLN/$HUES);
  for my $I ( 1 .. $N ) {
    my $XHUE=$I*$HUES;
    &NCAR::hlsrgb($XHUE,60.,75.,my ( $RED,$GREEN,$BLUE ) );
#
# Sort colors so that the redest is first, and violetest is last
#
    if( $XHUE <= $REDLN ) {
      &NCAR::gscr($IWKID,($N+2)-($LAP-$I),$RED,$GREEN,$BLUE);
      $ICNT=$ICNT+1;
    } else {
      &NCAR::gscr($IWKID,$I-$ICNT+2,$RED,$GREEN,$BLUE);
    }
  }
      
}

   
rename 'gmeta', 'ncgm/ccpcldm.ncgm';
