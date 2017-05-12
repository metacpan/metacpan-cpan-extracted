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
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
# 
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $MREG, $NREG ) = ( 50, 50 );      
my $ZREG = zeroes float, $MREG, $NREG;
      
#     EXTERNAL COLOR
#
# Get data array
#

open DAT, "<data/ccplbam.dat";
my @t;
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/, $t;
}
close DAT;
for my $J ( 1 .. $NREG ) {
  for my $I ( 1 .. $MREG ) {
    set( $ZREG, $I-1, $J-1, shift( @t ) );
  }
}

#
# Open GKS
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Call Conpack color fill routine
#
&CCPLBM($ZREG,$MREG,$NREG,\&COLOR,$IWKID);
#
# Close frame and close GKS
#
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
      
sub CCPLBM {
  my ($ZREG,$MREG,$NREG,$COLOR,$IWKID) = @_;

  my ( $LRWK, $LIWK, $LMAP, $NWRK, $NOGRPS ) = ( 5000, 5000, 50000, 5000, 5 );      
  my $RWRK = zeroes float, $LRWK;
  my $XWRK = zeroes float, $NWRK;
  my $YWRK = zeroes float, $NWRK;
  my $IWRK = zeroes long, $LIWK;
  my $MAP = zeroes long, $LMAP;
  my $IAREA = zeroes long, $NOGRPS;
  my $IGRP = zeroes long, $NOGRPS;
      
#     EXTERNAL FILL;
#     EXTERNAL COLOR;
#
# Initialize Areas
#
  &NCAR::arinam($MAP, $LMAP);
#
# Set contour interval and min and max contours 
#
  &NCAR::cpsetr('CIS',0.1);
  &NCAR::cpsetr('CMN',-0.4);
  &NCAR::cpsetr('CMX',1.8);
#
# Initialize Conpack and pick contour levels
#
  &NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
  &NCAR::cppkcl($ZREG,$RWRK,$IWRK);
#
# Set up color table
#
  &NCAR::cpgeti('NCL',my $NCL);
  $COLOR->($NCL+1,$IWKID);
#
# Add contours to area map
#
  &NCAR::cpclam($ZREG, $RWRK, $IWRK, $MAP);
#
# Add label boxes to area map
#
  &NCAR::cplbam($ZREG, $RWRK, $IWRK, $MAP);
#
# Set fill style to solid, and fill contours
#
  &NCAR::gsfais(1);
  &NCAR::arscam($MAP, $XWRK, $YWRK, $NWRK, $IAREA, $IGRP, $NOGRPS, \&FILL);
#
# Draw Perimeter
#
  &NCAR::cpback($ZREG, $RWRK, $IWRK);
#
# Draw Labels
#
  &NCAR::cplbdr($ZREG,$RWRK,$IWRK);
      
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
# Background color
# Black
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
   
rename 'gmeta', 'ncgm/ccplbam.ncgm';
