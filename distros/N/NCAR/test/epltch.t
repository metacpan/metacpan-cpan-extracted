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
# Define an array in which to put the numbers of the filled fonts.
#
my $IFFN = zeroes long, 23;
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
# Define a flag which says, if 0, that the first eight plots are to
# occupy eight separate frames and, if 1, that those plots are to be
# compressed onto two frames.
#
my $ICMP = 1;
#
# Define the special characters needed in example 1-10.
#
my @SPCH = (
    '!', '"', '#', '$', '%', '&', "''",'(', ')', '*',
    '+', ',', '-', '.', '/', ':', ';', '<', '=', '>',
    '?', '@', '[', '\\',']', '^', '_', '`', '{', '|',
    '}', '~'                                        
);
#
# Define the font numbers for the filled fonts.
#
my @IFFN = ( 1, 21, 22, 25, 26, 29, 30, 33, 34, 35, 36, 37 ,
             121,122,125,126,129,130,133,134,135,136,137 );
#
# --- E X E C U T A B L E   C O D E -----------------------------------
#
# Set the "fill area interior style" to "solid".
#
&NCAR::gsfais (1);
#
# Do a call to SET which allows us to use fractional coordinates.
#
&NCAR::set (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
# --- E X A M P L E S   1 - 1   T H R O U G H   1 - 8 -----------------
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
        &NCAR::set( .5*(($J-1)%2),.5*(($J-1)%2)+.5,
                    .5-.5*int(($J-1)/2),   1.-.5*int(($J-1)/2),
                    0.,1.,0.,1.,1);
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
      my $XPOS=.125+.07*$K;
      &NCAR::plchhq ($XPOS,.90,substr( $CLBL[$K-1], 0, 3),$CSMU*.006,0.,0.);
      &NCAR::plchhq ($XPOS,.88,substr( $CLBL[$K-1], 3, 5),$CSMU*.004,0.,0.);
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
     &NCAR::plchhq (.085,$YPOS,substr( $RLBL[12*($J-1)+$K-1], 0, 1),$CSMU*.006,0.,-1.);
     &NCAR::plchhq (.105,$YPOS,substr( $RLBL[12*($J-1)+$K-1], 1, 4),$CSMU*.004,0.,-1.);
#
# Each pass through the following loop produces a single character.
#
     for my $L ( 1 .. 12 ) {
        my $XPOS=.125+.07*$L;
        my $CTMP= ':' . substr( $CLBL[$L-1], 0, 3 ) 
                . ':' . substr( $RLBL[12*($J-1)+$K-1], 0, 1 );
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
if( $ICMP != 0 ) { &NCAR::set(0.,1.,0.,1.,0.,1.,0.,1.,1); }
#
# --- E X A M P L E   1 - 9 -------------------------------------------
#
# Do a single frame showing various capabilities of PLCHHQ.
#
# Put labels at the top of the plot.
#
&NCAR::plchhq (.5,.98,'PLCHHQ - VARIOUS CAPABILITIES',.02,0.,0.);
#
# First, write characters at various sizes.
#
&NCAR::plchhq (.225,.900,'SIZE is -1.0',-1.0,0.,0.);
&NCAR::plchhq (.225,.873,'SIZE is -.75',-.75,0.,0.);
&NCAR::plchhq (.225,.846,'SIZE is .015',.015,0.,0.);
&NCAR::plchhq (.225,.811,'SIZE is .020',.020,0.,0.);
&NCAR::plchhq (.225,.776,'SIZE is 15.0',15.0,0.,0.);
&NCAR::plchhq (.225,.742,'SIZE is 20.0',20.0,0.,0.);
#
# Next, write characters at various angles.
#
&NCAR::plchhq (.225,.453,'   ANGD is   0.',.012,  0.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is  45.',.012, 45.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is  90.',.012, 90.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is 135.',.012,135.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is 180.',.012,180.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is 225.',.012,225.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is 270.',.012,270.,-1.);
&NCAR::plchhq (.225,.453,'   ANGD is 315.',.012,315.,-1.);
#
# Next, use various values of the centering option.
#
&NCAR::plchhq (.225,.164,'CNTR is -1.5',.012,0.,-1.5);
&NCAR::plchhq (.225,.140,'CNTR is -1.0',.012,0.,-1.0);
&NCAR::plchhq (.225,.116,'CNTR is -0.5',.012,0.,-0.5);
&NCAR::plchhq (.225,.092,'CNTR is  0.0',.012,0., 0.0);
&NCAR::plchhq (.225,.068,'CNTR is +0.5',.012,0.,+0.5);
&NCAR::plchhq (.225,.044,'CNTR is +1.0',.012,0.,+1.0);
&NCAR::plchhq (.225,.020,'CNTR is +1.5',.012,0.,+1.5);
#
# Turn on the computation of text-extent-vector magnitudes and use
# them to draw a box around a label.  (DRAWBX is not part of PLOTCHAR;
# the code for it appears at the end of this example.)
#
&NCAR::pcseti ('TE - TEXT EXTENT FLAG',1);
#
&NCAR::plchhq (.130,.140,'TEXT EXTENT BOX',.012,35.,0.);
&DRAWBX (.130,.140,35.,.01);
#
&NCAR::pcseti ('TE - TEXT EXTENT FLAG',0);
#
# On the right side of the frame, create examples of the various kinds
# of function codes.  First, do them using high-quality characters.
#
&NCAR::plchhq (.715,.900,'HIGH-QUALITY CHARACTERS USED BELOW',.012,0.,0.);
#
&NCAR::pcsetc ('FC','$');
&NCAR::plchhq (.625,.870,'INPUT STRING',.012,0.,0.);
&NCAR::plchhq (.625,.840,'------------',.012,0.,0.);
&NCAR::plchhq (.625,.810,':L:A',.012,0.,0.);
&NCAR::plchhq (.625,.780,':IGL:A',.012,0.,0.);
&NCAR::plchhq (.625,.750,'A:S:2:N:+B:S:2:N:',.012,0.,0.);
&NCAR::plchhq (.625,.720,'A:S:B',.012,0.,0.);
&NCAR::plchhq (.625,.690,'A:SPU:B',.012,0.,0.);
&NCAR::plchhq (.625,.660,':GIU:+',.012,0.,0.);
&NCAR::plchhq (.625,.630,':1045:',.012,0.,0.);
&NCAR::plchhq (.625,.600,'10:S:10:S:100',.012,0.,0.);
&NCAR::plchhq (.625,.570,'X:B1:2:S1:3',.012,0.,0.);
&NCAR::plchhq (.625,.540,'X:B1:2:S:3:N:Y:S:2',.012,0.,0.);
&NCAR::plchhq (.625,.510,'X:S:A:B:1:NN:ABC',.012,0.,0.);
&NCAR::plchhq (.625,.480,'1.3648:L1:410:S:-13',.012,0.,0.);
#
&NCAR::pcsetc ('FC',':');
&NCAR::plchhq (.875,.870,'RESULT',.012,0.,0.);
&NCAR::plchhq (.875,.840,'------',.012,0.,0.);
&NCAR::plchhq (.875,.810,':L:A',.012,0.,0.);
&NCAR::plchhq (.875,.780,':IGL:A',.012,0.,0.);
&NCAR::plchhq (.875,.750,'A:S:2:N:+B:S:2:N:',.012,0.,0.);
&NCAR::plchhq (.875,.720,'A:S:B',.012,0.,0.);
&NCAR::plchhq (.875,.690,'A:SPU:B',.012,0.,0.);
&NCAR::plchhq (.875,.660,':GIU:+',.012,0.,0.);
&NCAR::plchhq (.875,.630,':1045:',.012,0.,0.);
&NCAR::plchhq (.875,.600,'10:S:10:S:100',.012,0.,0.);
&NCAR::plchhq (.875,.570,'X:B1:2:S1:3',.012,0.,0.);
&NCAR::plchhq (.875,.540,'X:B1:2:S:3:N:Y:S:2',.012,0.,0.);
&NCAR::plchhq (.875,.510,'X:S:A:B:1:NN:ABC',.012,0.,0.);
&NCAR::plchhq (.875,.480,'1.3648:L1:410:S:-13',.012,0.,0.);
#
# Now, do the same examples using medium-quality characters.
#
&NCAR::plchhq (.715,.440,'MEDIUM-QUALITY CHARACTERS USED BELOW',.012,0.,0.);
#
&NCAR::pcseti ('QU',1);
#
&NCAR::pcsetc ('FC','$');
&NCAR::plchhq (.625,.410,'INPUT STRING',.012,0.,0.);
&NCAR::plchhq (.625,.380,'------------',.012,0.,0.);
&NCAR::plchhq (.625,.350,':L:A',.012,0.,0.);
&NCAR::plchhq (.625,.320,':IGL:A',.012,0.,0.);
&NCAR::plchhq (.625,.290,'A:S:2:N:+B:S:2:N:',.012,0.,0.);
&NCAR::plchhq (.625,.260,'A:S:B',.012,0.,0.);
&NCAR::plchhq (.625,.230,'A:SPU:B',.012,0.,0.);
&NCAR::plchhq (.625,.200,':GIU:+',.012,0.,0.);
&NCAR::plchhq (.625,.170,':1045:',.012,0.,0.);
&NCAR::plchhq (.625,.140,'10:S:10:S:100',.012,0.,0.);
&NCAR::plchhq (.625,.110,'X:B1:2:S1:3',.012,0.,0.);
&NCAR::plchhq (.625,.080,'X:B1:2:S:3:N:Y:S:2',.012,0.,0.);
&NCAR::plchhq (.625,.050,'X:S:A:B:1:NN:ABC',.012,0.,0.);
&NCAR::plchhq (.625,.020,'1.3648:L1:410:S:-13',.012,0.,0.);
#
&NCAR::pcsetc ('FC',':');
&NCAR::plchhq (.875,.410,'RESULT',.012,0.,0.);
&NCAR::plchhq (.875,.380,'------',.012,0.,0.);
&NCAR::plchhq (.875,.350,':L:A',.012,0.,0.);
&NCAR::plchhq (.875,.320,':IGL:A',.012,0.,0.);
&NCAR::plchhq (.875,.290,'A:S:2:N:+B:S:2:N:',.012,0.,0.);
&NCAR::plchhq (.875,.260,'A:S:B',.012,0.,0.);
&NCAR::plchhq (.875,.230,'A:SPU:B',.012,0.,0.);
&NCAR::plchhq (.875,.200,':GIU:+',.012,0.,0.);
&NCAR::plchhq (.875,.170,':1045:',.012,0.,0.);
&NCAR::plchhq (.875,.140,'10:S:10:S:100',.012,0.,0.);
&NCAR::plchhq (.875,.110,'X:B1:2:S1:3',.012,0.,0.);
&NCAR::plchhq (.875,.080,'X:B1:2:S:3:N:Y:S:2',.012,0.,0.);
&NCAR::plchhq (.875,.050,'X:S:A:B:1:NN:ABC',.012,0.,0.);
&NCAR::plchhq (.875,.020,'1.3648:L1:410:S:-13',.012,0.,0.);
#
&NCAR::pcseti ('QU',0);
#
# Advance the frame.
#
&NCAR::frame;
#
# --- E X A M P L E   1 - 1 0 -----------------------------------------
#
# Do a single frame showing the medium-quality characters with various
# aspect ratios.
#
# Put labels at the top of the plot.
#
&NCAR::plchmq (.5,.98,'PLCHMQ - ALL CHARACTERS - VARIOUS ASPECT RATIOS',.02,0.,0.);
#
&NCAR::plchmq (.5,.95,'(Ratio of height to width varies from 2 in the top group down to .5 in the bottom group.)',.01,0.,0.);
#
# Produce five groups of characters.
#
my $SOSC;
for my $I ( 1 .. 32 ) {
   substr( $SOSC, $I-1, 1, $SPCH[$I-1] );
}
#
for my $I ( 1 .. 5 ) {
  my $YPOS=1.-.18*$I;
&NCAR::pcsetr ('HW',2.-1.5*($I-1)/4.);
&NCAR::plchmq (.5,$YPOS+.04,'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',.02,0.,0.);
&NCAR::plchmq (.5,$YPOS    ,'abcdefghijklmnopqrstuvwxyz0123456789',.02,0.,0.);
&NCAR::plchmq (.5,$YPOS-.04,substr( $SOSC, 0, 32 ),.02,0.,0.);
}
#
# Advance the frame.
#
&NCAR::frame;

#
# --- E X A M P L E   1 - 1 1 -----------------------------------------
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
&NCAR::plchhq (.5,.98,'PLCHHQ - FONTCAP DATABASES ADDED 6/90',.02,0.,0.);
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
  my $YCEN=.945-.045*$IFNT;
#
  my $CHRS = sprintf( '%8i', $IFNT );
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
    if( $ICHR == 80 ) { $YCEN = $YCEN-.0225; }
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
# --- E X A M P L E   1 - 1 2 -----------------------------------------
#
# Do a single frame showing the use of fontcap databases and some of
# the new features added in June of 1990.
#
# Double the line width.
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
#
# Put a label at the top of the plot.
#
&NCAR::plchhq (.5,.98,'PLCHHQ - FEATURES ADDED 6/90',.02,0.,0.);
#
# Temporarily use the slash as a function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER','/');
#
# Combine characters from several different fonts to produce a single
# line.
#
&NCAR::plchhq (.5,.910,'/F13/A line containing characters from several fonts:  /F8/P/BF13/0/N/=/F5/g/SF13/2/N/+/F5/j/SF13/2/N/',.012,0.,0.);
#
# Reset the internal parameter 'FN' to 4 and write a line illustrating
# the effect of function codes "Fn", "F", and "F0".  Then reset 'FN'
# to 0.
#
&NCAR::pcseti ('FN - FONT NUMBER',4);
&NCAR::plchhq (.5,.844,'Set \'FN\' (Font Number) to 4 and write a line using "F" function codes:',.012,0.,0.);
&NCAR::plchhq (.5,.820,'Before an F10 - /F10/after an F10 - /F/after an F - /F0/after an F0.',.012,0.,0.);
&NCAR::pcseti ('FN - FONT NUMBER',0);
#
# Write lines illustrating various kinds of zooming.
#
&NCAR::plchhq (.500,.754,'/F13/Unzoomed characters from font 13.',.012,0.,0.);
&NCAR::plchhq (.500,.730,'/F13X150Q/Characters zoomed in width, using X150Q.',.012,0.,0.);
&NCAR::plchhq (.500,.700,'/F13Y150Q/Characters zoomed in height, using Y150Q.',.012,0.,0.);
&NCAR::plchhq (.500,.664,'/F13Z150Q/Characters zoomed both ways, using Z150Q.',.012,0.,0.);
#
# Write a line illustrating non-aligned zooming in height.
#
&NCAR::plchhq (.5,.630,'/F13/Unaligned zoom of selected characters: /F16Y200/S/Y/cientific /Y200/V/Y/isualization /Y200/G/Y/roup', .012,0.,0.);
#
# Write lines illustrating the use of 'AS' and 'SS'.
#
&NCAR::pcsetr ('AS - ADD SPACE BETWEEN CHARACTERS     ',.125);
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',  0.);
&NCAR::plchhq (.5,.564,'/F14/Line written with \'AS\' = .125 and \'SS\' = 0.',.012,0.,0.);
&NCAR::pcsetr ('AS - ADD SPACE BETWEEN CHARACTERS     ',  0.);
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',  0.);
&NCAR::plchhq (.5,.540, '/F14/Line written with \'AS\' = 0. and \'SS\' = 0.',.012,0.,0.);
&NCAR::pcsetr ('AS - ADD SPACE BETWEEN CHARACTERS     ',  0.);
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',.125);
&NCAR::plchhq (.5,.516, '/F14/Line written with \'AS\' = 0. and \'SS\' = .125',.012,0.,0.);
&NCAR::pcsetr ('AS - ADD SPACE BETWEEN CHARACTERS     ',  0.);
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',  0.);
#
# Illustrate the difference between inexact centering and exact
# centering of a single character.
#
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',.128);
#
&NCAR::plchhq (.1,.455,'/F7/This "g" is centered on the cross using CNTR = 0. and \'CE\' = 0:',.012,0.,-1.);
&NCAR::line (.880,.455,.920,.455);
&NCAR::line (.900,.435,.900,.475);
&NCAR::pcseti ('CE - CENTERING OPTION',0);
&NCAR::plchhq (.9,.455,'/F7/g',.025,0.,0.);
&NCAR::pcseti ('CE - CENTERING OPTION',0);
#
&NCAR::plchhq (.1,.405,'/F7/This "g" is centered on the cross using CNTR = 0. and \'CE\' = 1:',.012,0.,-1.);
&NCAR::line (.880,.405,.920,.405);
&NCAR::line (.900,.385,.900,.425);
&NCAR::pcseti ('CE - CENTERING OPTION',1);
&NCAR::plchhq (.9,.405,'/F7/g',.025,0.,0.);
&NCAR::pcseti ('CE - CENTERING OPTION',0);
#
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',0.);
#
# Put some large characters on a grid to show the digitization.
#
&NCAR::plchhq (.5,.312,'Large characters on digitization grid.  X\'s mark edge points of the characters.',.01,0.,0.);
#
&NCAR::pcgetr ('SA - SIZE ADJUSTMENT',my $SIZA);
my $WDTH=.15;
my $XLFT=.500-48.*($WDTH/16.);
my $XRGT=.500+48.*($WDTH/16.);
my $YBOT=.150-11.*($WDTH/16.);
my $YTOP=.150+14.*($WDTH/16.);
#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (1.);
#
for( my $I = -48; $I <= 48; $I++ ) {
  my $XCRD=.500+$I*($WDTH/16.);
  &NCAR::line ($XCRD,$YBOT,$XCRD,$YTOP);
}
#
for( my $J = -11; $J <= 14; $J++ ) {
  my $YCRD=.150+$J*($WDTH/16.);
  &NCAR::line ($XLFT,$YCRD,$XRGT,$YCRD);
}#
&NCAR::plotif (0.,0.,2);
&NCAR::gslwsc (2.);
#
my $XCRD=.500-45.*($WDTH/16.);
my $YCRD=.150+1.5*($WDTH/16.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD-$WDTH/32.,$XCRD+$WDTH/32.,$YCRD+$WDTH/32.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD+$WDTH/32.,$XCRD+$WDTH/32.,$YCRD-$WDTH/32.);
&NCAR::plchhq ($XCRD,$YCRD,'/F9/A',$WDTH/$SIZA,0.,-1.);
&NCAR::pcgetr ('XE - X COORDINATE AT END OF STRING',$XCRD);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD-$WDTH/32.,$XCRD+$WDTH/32.,$YCRD+$WDTH/32.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD+$WDTH/32.,$XCRD+$WDTH/32.,$YCRD-$WDTH/32.);
&NCAR::plchhq ($XCRD,$YCRD,'/F9/B',$WDTH/$SIZA,0.,-1.);
&NCAR::pcgetr ('XE - X COORDINATE AT END OF STRING',$XCRD);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD-$WDTH/32.,$XCRD+$WDTH/32.,$YCRD+$WDTH/32.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD+$WDTH/32.,$XCRD+$WDTH/32.,$YCRD-$WDTH/32.);
&NCAR::plchhq ($XCRD,$YCRD,'/F9/C',$WDTH/$SIZA,0.,-1.);
&NCAR::pcgetr ('XE - X COORDINATE AT END OF STRING',$XCRD);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD-$WDTH/32.,$XCRD+$WDTH/32.,$YCRD+$WDTH/32.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD+$WDTH/32.,$XCRD+$WDTH/32.,$YCRD-$WDTH/32.);
&NCAR::plchhq ($XCRD,$YCRD,'/F9/D',$WDTH/$SIZA,0.,-1.);
&NCAR::pcgetr ('XE - X COORDINATE AT END OF STRING',$XCRD);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD-$WDTH/32.,$XCRD+$WDTH/32.,$YCRD+$WDTH/32.);
&NCAR::line ($XCRD-$WDTH/32.,$YCRD+$WDTH/32.,$XCRD+$WDTH/32.,$YCRD-$WDTH/32.);
#
# Return to a colon as the function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER',':');
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
# --- E X A M P L E   1 - 1 3 -----------------------------------------
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
&NCAR::plchhq (.5,.945,':F1:c selects the ASCII character "c", as shown in the first two lines.',.01,0.,0.);
#
&NCAR::plchhq (.5,.925,':Fn:c selects the corresponding character from font n.',.01,0.,0.);
#
# Return to a colon as the function code character.
#
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER',':');
#
# Loop through all the new filled fonts.
#
for my $IFNS ( 1 .. 23 ) {
#
  my $YCEN=.945-.0391304*$IFNS;
#
  my $CHRS = sprintf( '%8i', $IFFN[$IFNS-1] );
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
#
# Advance the frame.
#
&NCAR::frame;
#
# --- E X A M P L E   1 - 1 4 -----------------------------------------
#
# Do a single frame showing some of the new features added in December
# of 1992.
#
# Put a label at the top of the plot and, below that, an explanatory
# note.
#
&NCAR::plchhq (.5,.975,':F25:PLCHHQ - FEATURES ADDED 12/92',.025,0.,0.);
#
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',.275);
&NCAR::plchhq (.5,.938,':F13:(Use idt\'s \'zoom\' to view some of this in detail, especially stacking.)',.017,0.,0.);
&NCAR::pcsetr ('SS - SUBTRACT SPACE BETWEEN CHARACTERS',0.);
#
# Illustrate the use of filled fonts with shadows and outlines.  First,
# define some colors to use.
#
&NCAR::gscr (1,2,0.,.5,.5);
&NCAR::gscr (1,3,.9,.9,0.);
&NCAR::gscr (1,4,1.,.3,.3);
&NCAR::gscr (1,5,0.,0.,1.);
&NCAR::gscr (1,6,.2,.2,.2);
#
# Write a line.
#
&NCAR::plchhq (.5,.900,':F26:By default, the current foreground color is used.',.024,0.,0.);
#
# Define the principal color to be used for characters.
#
&NCAR::pcseti ('CC - CHARACTER COLOR',4);
#
# Write another line.
#
&NCAR::plchhq (.5,.850,':F26:A non-negative \'CC\' requests a different color.',.026,0.,0.);
#
# Turn on character shadows and define various characteristics of the
# shadow.
#
&NCAR::pcseti ('SF - SHADOW FLAG',1);
&NCAR::pcsetr ('SX - SHADOW OFFSET IN X',-.1);
&NCAR::pcsetr ('SY - SHADOW OFFSET IN Y',-.1);
&NCAR::pcseti ('SC - SHADOW COLOR',2);
#
# Write another line.
#
&NCAR::plchhq (.5,.796,':F26:\'SF\', \'SC\', \'SX\', and \'SY\' create shadows.',.028,0.,0.);
#
# Turn on character outlines and define the color of the outline.
#
&NCAR::pcseti ('OF - OUTLINE FLAG',1);
&NCAR::pcseti ('OC - OUTLINE COLOR',3);
&NCAR::pcseti ('OL - OUTLINE LINE WIDTH',1);
#
# Write another line.
#
&NCAR::plchhq (.5,.738,':F26:\'OF\', \'OC\', and \'OL\' add outlines.',.030,0.,0.);
#
# Turn on the drawing of boxes and define characteristics of them.
#
&NCAR::pcseti ('BF - BOX FLAG',7);
&NCAR::pcseti ('BL - BOX LINE WIDTH',2);
&NCAR::pcsetr ('BM - BOX MARGIN',.15);
&NCAR::pcsetr ('BX - BOX SHADOW X OFFSET',-.1);
&NCAR::pcsetr ('BY - BOX SHADOW Y OFFSET',-.1);
&NCAR::pcseti ('BC(1) - BOX COLOR - BOX OUTLINE    ',5);
&NCAR::pcseti ('BC(2) - BOX COLOR - BOX FILL       ',6);
&NCAR::pcseti ('BC(3) - BOX COLOR - BOX SHADOW FILL',2);
#
# Write another line.
#
&NCAR::plchhq (.5,.672,':F26:\'BF\', \'BC\', \'BL\', \'BM\', \'BX\', and \'BY\' add a box.',.026,0.,0.);
#
# Get rid of the box shadow, which doesn't add much.
#
&NCAR::pcseti ('BF - BOX FLAG',3);
#
# Write another line.
#
&NCAR::pcsetc ('FC - FUNCTION-CODE CHARACTER','/');
&NCAR::plchhq (.5,.592,'/F26/\'MA\' and \'OR\' are used for mapping:',.030,0.,0.);
&NCAR::pcsetc ('FC - FUNCTION CODE CHARACTER',':');
#
# Write a couple of headers for the plots that follow.
#
&NCAR::plchhq (.28,.528,':F25:(EZMAP)',.024,0.,0.);
&NCAR::plchhq (.72,.528,':F33:(r:F25: and :F33:q)',.024,0.,0.);
#
# Initialize EZMAP and draw a background.
#
&NCAR::mapstc ('OU','CO');
&NCAR::mapsti ('GR',5);
&NCAR::mappos (.065,.495,.065,.495);
&NCAR::mapstr ('SA',8.5);
&NCAR::maproj ('SV',0.,-25.,0.);
&NCAR::mapint;
&NCAR::maplot;
&NCAR::mapgrd;
#
# Tell PLOTCHAR to map characters through EZMAP.
#
&NCAR::pcseti ('MA - MAPPING FLAG',1);
&NCAR::pcsetr ('OR - OUT-OF-RANGE FLAG',1.E12);
#
# Write a line across the surface of the globe.
#
&NCAR::plchhq (-25.,0.,':F25Y200:NCAR GRAPHICS',8.,30.,0.);
#
# Do an appropriate SET call for a rho-theta mapping.
#
&NCAR::set    (.505,.935,.065,.495,-27.5,27.5,-27.5,27.5,1);
#
# Tell PLOTCHAR to use a rho-theta mapping.
#
&NCAR::pcseti ('MA - MAPPING FLAG',2);
&NCAR::pcsetr ('OR - OUT-OF-RANGE FLAG',0.);
#
# Write three lines in rho/theta space, orienting them so they come out
# in a circle after mapping.
#
&NCAR::plchhq (20., 90.,':F25Y125:NCAR GRAPHICS',8.,-90.,0.);
&NCAR::plchhq (20.,210.,':F25Y125:NCAR GRAPHICS',8.,-90.,0.);
&NCAR::plchhq (20.,-30.,':F25Y125:NCAR GRAPHICS',8.,-90.,0.);
#
# Turn off mapping and recall SET to allow fractional coordinates again.
#
&NCAR::pcseti ('MA - MAPPING FLAG',0);
#
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
# Change the drawing order to allow for "stacking" characters from
# right to left.
#
&NCAR::pcseti ('DO - DRAWING ORDER',-2);
#
# Reduce the space between characters so the "stacking" is visible.
#
&NCAR::pcsetr ('SS - SUBTRACT-SPACE FLAG',.3);
#
# Turn off the box.  Make the shadows black and position them so they
# help make the stacked characters readable.
#
&NCAR::pcseti ('BF - BOX FLAG',0);
&NCAR::pcseti ('SC - SHADOW COLOR',0);
&NCAR::pcsetr ('SX - SHADOW OFFSET IN X',.1);
&NCAR::pcsetr ('SY - SHADOW OFFSET IN Y',0.);
#
# Write a final line demonstrating "stacking".
#
&NCAR::plchhq (.5,.030,':F26:Use    \'DO\'    and    \'SS\'    to   +"stack"    characters    in    either    direction.',.026,0.,0.);
#
# Advance the frame.
#
&NCAR::frame;

sub DRAWBX {
  my ($XCEN,$YCEN,$ANGD,$XTRA) = @_;
  &NCAR::pcgetr ('DL - DISTANCE LEFT  ',my $DSTL);
  &NCAR::pcgetr ('DR - DISTANCE RIGHT ',my $DSTR);
  &NCAR::pcgetr ('DB - DISTANCE BOTTOM',my $DSTB);
  &NCAR::pcgetr ('DT - DISTANCE TOP   ',my $DSTT);
  my $ANGR=.017453292519943*$ANGD;
  my $SINA=sin($ANGR);
  my $COSA=cos($ANGR);
  my $XFRA=&NCAR::cfux($XCEN);
  my $YFRA=&NCAR::cfuy($YCEN);
  my $XALB=$XFRA-($DSTL+$XTRA)*$COSA+($DSTB+$XTRA)*$SINA;
  my $YALB=$YFRA-($DSTL+$XTRA)*$SINA-($DSTB+$XTRA)*$COSA;
  my $XARB=$XFRA+($DSTR+$XTRA)*$COSA+($DSTB+$XTRA)*$SINA;
  my $YARB=$YFRA+($DSTR+$XTRA)*$SINA-($DSTB+$XTRA)*$COSA;
  my $XART=$XFRA+($DSTR+$XTRA)*$COSA-($DSTT+$XTRA)*$SINA;
  my $YART=$YFRA+($DSTR+$XTRA)*$SINA+($DSTT+$XTRA)*$COSA;
  my $XALT=$XFRA-($DSTL+$XTRA)*$COSA-($DSTT+$XTRA)*$SINA;
  my $YALT=$YFRA-($DSTL+$XTRA)*$SINA+($DSTT+$XTRA)*$COSA;
  &NCAR::plotif ($XALB,$YALB,0);
  &NCAR::plotif ($XARB,$YARB,1);
  &NCAR::plotif ($XART,$YART,1);
  &NCAR::plotif ($XALT,$YALT,1);
  &NCAR::plotif ($XALB,$YALB,1);
  &NCAR::plotif (0.,0.,2);
}

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/epltch.ncgm';
