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
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
# 
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
my ( $LRWK, $LIWK, $LMAP ) = ( 3500, 4000, 75000 );
my ( $MREG, $NREG ) = ( 50, 50 );
my $X = zeroes float, $MREG;
my $Y = zeroes float, $NREG;
my $ZREG = zeroes float, $MREG, $NREG;
my $RWRK = zeroes float, $LRWK;
my $IWRK = zeroes long, $LIWK;
my $MAP = zeroes long, $LMAP;
      
#     EXTERNAL CPDRPL

my @t;
open DAT, "<data/ccppc3.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t = split /\s+/o, $t;
}
close DAT;

for my $I ( 1 .. $MREG ) {
  set( $X, $I-1, shift( @t ) );
}

for my $J ( 1 .. $NREG ) {
  set( $Y, $J-1, shift( @t ) );
}

for my $I ( 1 .. $MREG ) {
  for my $J ( 1 .. $NREG ) {
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
# Initialize Areas
# 
&NCAR::arinam($MAP,$LMAP);
# 
# Choose which labelling scheme will be used.
# 
&NCAR::cpseti('LLP - LINE LABEL POSTIONING FLAG',3);
# 
# Label contours only when they are reasonably straight
# 
&NCAR::cpsetr('PC3 - PENALTY SCHEME CONSTANT 3',10.0);
&NCAR::cpsetr('PW3 - PENALTY SCHEME WEIGHT 3',2.0);
# 
# Initialize Conpack
# 
&NCAR::cprect($ZREG, $MREG, $MREG, $NREG, $RWRK, $LRWK, $IWRK, $LIWK);
# 
# Force Conpack to chose contour levels
# 
&NCAR::cppkcl($ZREG, $RWRK, $IWRK);
# 
# Modify Conpack chosen parameters
# 
&NCAR::cpgeti('NCL - NUMBER OF CONTOURS',my $NCONS);
for my $I ( 1 .. $NCONS ) {
  &NCAR::cpseti('PAI - PARAMETER ARRAY INDEX',$I);
# 
# Force every line to be labeled.
# 
  &NCAR::cpseti('CLU - CONTOUR LEVEL USE   FLAG',3);
}
# 
# Draw Perimeter
# 
&NCAR::cpback($ZREG, $RWRK, $IWRK);
# 
# Add contours to area map
# 
&NCAR::cpclam($ZREG,$RWRK,$IWRK,$MAP);
# 
# Add labels to area map
# 
&NCAR::cplbam($ZREG,$RWRK,$IWRK,$MAP);
# 
# Draw Contours
# 
&NCAR::cpcldm($ZREG,$RWRK,$IWRK,$MAP,\&NCAR::cpdrpl);
# 
# Draw Labels
# 
&NCAR::cplbdr($ZREG,$RWRK,$IWRK);
# 
# Close frame and close GKS
# 
&NCAR::frame();
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
      
      

rename 'gmeta', 'ncgm/ccppc3.ncgm';
