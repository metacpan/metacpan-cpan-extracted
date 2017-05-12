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
# --- D E C L A R A T I O N S -----------------------------------------
#
# Define the column and row labels.  The character string ':c:r', where
# "c" is the first three characters of a column label and "r" is the
# first character of a row label, is used to select the character to
# be written in that column of that row.
#
my @CLBL = (
    'PRU(0000)','PRL(0100)','IRU(0200)','IRL(0300)',
    'KRU(0400)','KRL(0500)','PGU(0600)','PGL(0700)',
    'IGU(1000)','IGL(1100)','KGU(1200)','KGL(1300)'
);
#
my @RLBL = (
    'A(01)','B(02)','C(03)','D(04)','E(05)','F(06)',
    'G(07)','H(10)','I(11)','J(12)','K(13)','L(14)',
    'M(15)','N(16)','O(17)','P(20)','Q(21)','R(22)',
    'S(23)','T(24)','U(25)','V(26)','W(27)','X(30)',
    'Y(31)','Z(32)','0(33)','1(34)','2(35)','3(36)',
    '4(37)','5(40)','6(41)','7(42)','8(43)','9(44)',
    '+(45)','-(46)','*(47)','/(50)','((51)',')(52)',
    '$(53)','=(54)',' (55)',',(56)','.(57)','     '
);
#
#
# Define a flag which says, if 0, that the first eight plots are to
# occupy eight separate frames and, if 1, that those plots are to be
# compressed onto two frames.
#
my $ICMP = 1;
#
# Define the font numbers for the filled fonts.
#
my @IFFN = ( 
  21, 22, 25, 26, 29, 30, 33, 34, 35, 36, 37 ,
   121,122,125,126,129,130,133,134,135,136,137
);
#
# Set up the background and foreground colors
#
&NCAR::gscr (1,0,1.,1.,1.);
&NCAR::gscr (1,1,0.,0.,0.);
#
# Set the "fill area interior style" to "solid".
#
&NCAR::gsfais (1);
#
# Do a call to SET which allows us to use fractional coordinates.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
# Produce examples of the complex and duplex character sets.
#
# Compute a character-size multiplier, depending on whether the first
# eight plots are being put on eight frames or two.
#
my $CSMU=(2-$ICMP);
#
# Each pass through the loop on I produces four plots - the first four
# for the complex set, and the second four for the duplex set.
#
for my $I ( 1 .. 2 ) {
#
# Change to the appropriate character set.
#
  &NCAR::pcseti ('CD',$I-1);
#
# Each pass through the following loop produces a single plot.
#
  for my $J ( 1 .. 4 ) {
#
# If the first eight plots are to be compressed, re-do the SET call to
# put the plot in a particular quadrant of the frame.
#
    if( $ICMP != 0 ) {
      &NCAR::set( 
          .5*(($J-1)%2),
          .5*(($J-1)%2)+.5,
          .5-.5*int(($J-1)/2),
           1.-.5*int(($J-1)/2),
           0.,1.,0.,1.,1
      );
    }
#
# Put labels at the top of the frame and along the left edge.
#
    if( $I == 1 ) {
      &NCAR::plchhq (.5,.98,'PLCHHQ - COMPLEX CHARACTER SET',$CSMU*.01,0.,0.);
    } else {
      &NCAR::plchhq (.5,.98,'PLCHHQ - DUPLEX CHARACTER SET',$CSMU*.01,0.,0.);
    }
#
    &NCAR::plchhq (.58,.9267,'FUNCTION CODES SPECIFYING SIZE, FONT, AND CASE',$CSMU*.00735,0.,0.);
#
    &NCAR::plchhq (.035,.445,':D:STANDARD FORTRAN CHARACTERS',$CSMU*.00735,0.,0.);
#
# Force constant spacing of the characters used for the column and row
# labels, so that they will line up better with each other.
#
    &NCAR::pcsetr ('CS',1.25);
#
# Label the columns.
#
    for my $K ( 1 .. 12 ) {
      my $XPOS=.125+.07*($K);
      &NCAR::plchhq ($XPOS,.90,substr( $CLBL[$K-1], 0, 3),$CSMU*.006,0.,0.);
      &NCAR::plchhq ($XPOS,.88,substr( $CLBL[$K-1], 3, 6),$CSMU*.004,0.,0.);
    }
#
# Each pass through the following loop produces a single row.
#
    for my $K ( 1 .. 12 ) {
#
# Compute the Y coordinate of the row.
#
      my $YPOS=.9-.07*$K;
#
# Label the row.
#
      &NCAR::plchhq (.085,$YPOS,substr( $RLBL[12*($J-1)+$K-1], 0, 1 ),$CSMU*.006,0.,-1.);
      &NCAR::plchhq (.105,$YPOS,substr( $RLBL[12*($J-1)+$K-1], 1, 4 ),$CSMU*.004,0.,-1.);
#
# Each pass through the following loop produces a single character.
#
      for my $L ( 1 .. 12 ) {
         my $XPOS=.125+.07*($L);
         my $CTMP=':'.substr($CLBL[$L-1],0, 3).':'.substr($RLBL[12*($J-1)+$K-1],0,1);
         &NCAR::plchhq ($XPOS,$YPOS,$CTMP,$CSMU*.01,0.,0.);
      }
#
    }
#
# Return to variable spacing.
#
    &NCAR::pcsetr ('CS',0.);
#
# If eight frames are being produced, advance the frame here.
#
    if( $ICMP == 0 ) { &NCAR::frame(); }
#
  }
#
# If two frames are being produced, advance the frame here.
#
  if( $ICMP != 0 ) { &NCAR::frame(); }
#
}
#
# Return to the complex character set.
#
&NCAR::pcseti ('CD',0);
#
# If two frames were produced, re-do the call to SET which allows us to
# use fractional coordinates.
#
if( $ICMP != 0 ) { &NCAR::set( 0.,1.,0.,1.,0.,1.,0.,1.,1); }
#
# Do a single frame showing all the characters in the fontcap databases,
# access to which was added in June of 1990.
#
# Double the line width.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
#
# Put a label at the top of the plot.
#
&NCAR::plchhq (.5,.98,'PLCHHQ - FONTCAP DATABASES ADDED 6/90', .02,0.,0.);
#
# Temporarily use the slash as a function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER','/');
#
# Put an explanatory note on the plot.
#
&NCAR::plchhq (.5,.945,':F1:c selects the ASCII character "c", as shown in the first two lines.',.01,0.,0.);
#
&NCAR::plchhq (.5,.925,':Fn:c (2/F18/K/F0/n/F18/K/F0/20) selects the corresponding character from font n.',.01,0.,0.);
#
# Return to a colon as the function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER',':');
#
# Loop through all the available fonts.
#
for my $IFNT ( 1 .. 20 ) {
#
  my $YCEN=.945-.045*($IFNT);
#
  my $CHRS = sprintf( '%8d', $IFNT );
  substr( $CHRS, 0, 4, 'FONT' );
  &NCAR::pcseti ('FN - FONTCAP NUMBER',7);
  &NCAR::plchhq (.005,$YCEN,$CHRS,.012,0.,-1.);
#
  &NCAR::pcseti ('FN - FONTCAP NUMBER',$IFNT);
#
# Draw all the meaningful characters from the font.
#
  for my $ICHR ( 33 .. 126 ) {
    my $XCEN;
    if( $ICHR <= 79 ) {
      $XCEN=.125+.0183*($ICHR-32);
    } else {
      $XCEN=.125+.0183*($ICHR-79);
    }
    if( $ICHR == 80 ) { $YCEN = $YCEN - .0225; }
    if( chr( $ICHR ) eq ':' ) { &NCAR::pcsetc('FC','!'); }
    &NCAR::plchhq ($XCEN,$YCEN,chr( $ICHR ),.01,0.,0.);
    if( chr( $ICHR ) eq ':' ) { &NCAR::pcsetc('FC',':'); }
  }
#
# End of loop through fonts.
#
}
#
# Restore the fontcap number to 0 to select the PWRITX database.
#
&NCAR::pcseti ('FN - FONTCAP NUMBER',0);
#
# Go back to normal line width.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (1.);
#
# Advance the frame.
#
&NCAR::frame;
#
# Do a single frame showing all the characters in the fontcap databases,
# access to which was added in October of 1992.
#
# Put a label at the top of the plot.
#
&NCAR::plchhq (.5,.98,'PLCHHQ - FONTCAP DATABASES ADDED 10/92',.02,0.,0.);
#
# Temporarily use the slash as a function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER','/');
#
# Put an explanatory note on the plot.
#
&NCAR::plchhq (.5,.945,':F21:c selects the ASCII character "c", as shown in the first two lines.',.01,0.,0.);
#
&NCAR::plchhq (.5,.925,':Fn:c selects the corresponding character from font n.',.01,0.,0.);
#
# Return to a colon as the function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER',':');
#
# Loop through all the new filled fonts.
#
for my $IFNS ( 1 .. 22 ) {
#
  my $YCEN=.945-.0391304*($IFNS);
#
  my $CHRS = sprintf( '%8d', $IFFN[$IFNS-1] );
  substr( $CHRS, 0, 4, 'FONT' );
  &NCAR::pcseti ('FN - FONTCAP NUMBER',7);
  &NCAR::plchhq (.005,$YCEN,$CHRS,.012,0.,-1.);
#
  &NCAR::pcseti ('FN - FONTCAP NUMBER',$IFFN[$IFNS-1]);
#
# Draw all the meaningful characters from the font.
#
  for my $ICHR ( 33 .. 126 ) {
    my $XCEN;
    if( $ICHR <= 79 ) {
      $XCEN=.125+.0183*($ICHR-32);
    } else {
      $XCEN=.125+.0183*($ICHR-79);
    }
    if( $ICHR == 80 ) { $YCEN=$YCEN-.0195652; }
    if( chr( $ICHR ) eq ':' ) { &NCAR::pcsetc('FC','!'); }
    &NCAR::plchhq ($XCEN,$YCEN,chr($ICHR),.01,0.,0.);
    if( chr( $ICHR ) eq ':' ) { &NCAR::pcsetc('FC',':'); }
  }
#
# End of loop through fonts.
#
}
#
# Restore the fontcap number to 0 to select the PWRITX database.
#
&NCAR::pcseti ('FN - FONTCAP NUMBER',0);


&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fpcfonts.ncgm';
