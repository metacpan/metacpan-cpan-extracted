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
   
&NCAR::gopks( 6, 1 );
&NCAR::gopwk( 1, 2, 1 );
&NCAR::gacwk( 1 );


#
# Define the data arrays.
#
my $XDRA = zeroes float, 1201;
my $YDRA = zeroes float, 1201;
#
# Fill the data arrays.  The independent variable represents
# time during the year (a hypothetical year with equal-length
# months) and is set up so that minor ticks can be lengthened
# to delimit the months; the major ticks, though shortened to
# invisibility, still determine where the labels go.
#
sub Cosh {
  my $x = shift;
  return ( exp( $x ) + exp( -$x ) ) / 2;
}

for my $I ( 1 .. 1201 ) {
  set( $XDRA, $I-1, $I-51 );
  set( $YDRA, $I-1, Cosh( ( $I-601 ) / 202 ) );
}
#
# Change the labels on the bottom and left axes.
#
&NCAR::anotat ('MONTHS OF THE YEAR$','ROMAN NUMERALS$',0,0,0,[]);
#
# Fix the minimum and maximum values on both axes and prevent
# AUTOGRAPH from using rounded values at the ends of the axes.
#
&NCAR::agsetf ('X/MIN.',-50.);
&NCAR::agsetf ('X/MAX.',1150.);
&NCAR::agseti ('X/NICE.',0);
#
&NCAR::agsetf ('Y/MIN.',1.);
&NCAR::agsetf ('Y/MAX.',10.);
&NCAR::agseti ('Y/NICE.',0);
#
# Specify the spacing between major tick marks on all axes.
# Note that the AUTOGRAPH dummy routine AGCHNL is supplanted
# (below) by one which supplies dates for the bottom axis and
# Roman numerals for the left axis in place of the numeric
# labels one would otherwise get.
#
&NCAR::agseti ('  LEFT/MAJOR/TYPE.',1);
&NCAR::agseti (' RIGHT/MAJOR/TYPE.',1);
&NCAR::agseti ('BOTTOM/MAJOR/TYPE.',1);
&NCAR::agseti ('   TOP/MAJOR/TYPE.',1);
#
&NCAR::agsetf ('  LEFT/MAJOR/BASE.',  1.);
&NCAR::agsetf (' RIGHT/MAJOR/BASE.',  1.);
&NCAR::agsetf ('BOTTOM/MAJOR/BASE.',100.);
&NCAR::agsetf ('   TOP/MAJOR/BASE.',100.);
#
# Suppress minor ticks on the left and right axes.
#
&NCAR::agseti ('  LEFT/MINOR/SPACING.',0);
&NCAR::agseti (' RIGHT/MINOR/SPACING.',0);
#
# On the bottom and top axes, put one minor tick between each
# pair of major ticks, shorten major ticks to invisibility,
# and lengthen minor ticks.  The net effect is to make the
# minor ticks delimit the beginning and end of each month,
# while the major ticks, though invisible, cause the names of
# the months to be where we want them.
#
&NCAR::agseti ('BOTTOM/MINOR/SPACING.',1);
&NCAR::agseti ('   TOP/MINOR/SPACING.',1);
#
&NCAR::agsetf ('BOTTOM/MAJOR/INWARD. ',0.);
&NCAR::agsetf ('BOTTOM/MINOR/INWARD. ',.015);
&NCAR::agsetf ('   TOP/MAJOR/INWARD. ',0.);
&NCAR::agsetf ('   TOP/MINOR/INWARD. ',.015);
#
# Draw a boundary around the edge of the plotter frame.
#
&BNDARY();
#
# Draw the graph, using EZXY.
#
&NCAR::ezxy ($XDRA,$YDRA,1201,'EXAMPLE 10 (MODIFIED NUMERIC LABELS)$');

sub NCAR::agchnl {
  my ( $IAXS,$VILS,$CHRM,$MCIM,$NCIM,$IPXM,$CHRE,$MCIE,$NCIE) = @_;
#
# Define the names of the months for use on the bottom axis.
#
  my @MONS = ( 'JAN','FEB','MAR','APR','MAY','JUN',
               'JUL','AUG','SEP','OCT','NOV','DEC' );
#
# Modify the numeric labels on the left axis.
#
  if( $IAXS == 1 ) {
    &AGCORN (int($VILS),$CHRM,$NCIM);
    $IPXM=0;
    $NCIE=0;
#
# Modify the numeric labels on the bottom axis.
#
  } elsif($IAXS == 3 ) {
    $IMON = int( int( $VILS+.5 ) / 100 + 1 );
    substr( $CHRM, 0, 3, $MONS[$IMON-1] );
    $NCIM=3;
    $IPXM=0;
    $NCIE=0;
  }
  $_[0] = $IAXS;
  $_[1] = $VILS;
  $_[2] = $CHRM;
  $_[3] = $MCIM;
  $_[4] = $NCIM;
  $_[5] = $IPXM;
  $_[6] = $CHRE;
  $_[7] = $MCIE;
  $_[8] = $NCIE;
#
# Done.
#
}
sub AGCORN {
  my ($NTGR,$BCRN,$NCRN) = @_;
#
# This routine receives an integer in NTGR and returns its
# Roman-numeral equivalent in the first NCRN characters of
# the character variable BCRN.  It only works for integers
# within a limited range and it does some rather unorthodox
# things (like using zero and minus).
#
# ICH1, ICH5, and IC10 are character variables used for the
# single-unit, five-unit, and ten-unit symbols at a given
# level.
#
#
# Treat numbers outside the range (-4000,+4000) as infinites.
#
  if( abs( $NTGR ) > 4000 ) { 
    if( $NTGR > 0 ) {
      $_[2]=5;
      substr( $_[1], 0, 5, '(INF)' );
    } else {
      $_[2]=6;
      substr( $_[1], 0, 6, '(-INF)' );
    }
    return;
  }
#
# Use a '0' for the zero.  The Romans never had it so good.
#
  if( $NTGR == 0 ) {
    $_[2]=1;
    substr( $_[1], 0, 1, '0' );
    return;
  }
#
# Zero the character counter.
#
  $NCRN = 0;
#
# Handle negative integers by prefixing a minus sign.
#
  if( $NTGR < 0 ) {
    $NCRN=$NCRN+1;
    substr( $BCRN, $NCRN-1, 1, '-' );
  }
#
# Initialize constants.  We'll check for thousands first.
#
  my $IMOD=10000;
  my $IDIV=1000;
  my $ICH1='M';
#
# Find out how many thousands (hundreds, tens, units) there
# are and jump to the proper code block for each case.
#
L101:
  my $INTG=int((abs($NTGR) % $IMOD)/$IDIV);
#
  for( $INTG+1 ) {
    ( $_ == 1 ) && ( goto L107 );
    ( $_ == 2 ) && ( goto L104 );
    ( $_ == 3 ) && ( goto L104 );
    ( $_ == 4 ) && ( goto L104 );
    ( $_ == 5 ) && ( goto L102 );
    ( $_ == 6 ) && ( goto L103 );
    ( $_ == 7 ) && ( goto L103 );
    ( $_ == 8 ) && ( goto L103 );
    ( $_ == 9 ) && ( goto L103 );
    ( $_ ==10 ) && ( goto L106 );
  }
#
# Four - add ICH1 followed by ICH5.
#
L102:
  $NCRN=$NCRN+1;
  substr( $BCRN, $NCRN-1, 1, $ICH1 );
#
# Five through eight - add ICH5, followed by INTG-5 ICH1's.
#
L103:
  $NCRN=$NCRN+1;
  substr( $BCRN, $NCRN-1, 1, $ICH5 );
#
  $INTG=$INTG-5;
  if( $INTG < 0 ) { goto L107; }
#
# One through three - add that many ICH1's.
#
L104:
  for my $I ( 1 .. $INTG ) {
    $NCRN=$NCRN+1;
    substr( $BCRN, $NCRN-1, 1, $ICH1 );
  }
#
   goto L107;
#
# Nine - add ICH1, followed by IC10.
#
L106:
  $NCRN=$NCRN+1;
  substr( $BCRN, $NCRN-1, 1, $ICH1 );
  $NCRN=$NCRN+1;
  substr( $BCRN, $NCRN-1, 1, $IC10 );
#
# If we're done, exit.
#
L107:
  $_[0] = $NTGR;
  $_[1] = $BCRN;
  $_[2] = $NCRN;
  if( $IDIV == 1 ) { return; }
#
# Otherwise, tool up for the next digit and loop back.
#
  $IMOD=$IMOD/10;
  $IDIV=$IDIV/10;
  $IC10=$ICH1;
#
  if( $IDIV == 100 ) {
    $ICH5='D';
    $ICH1='C';
  } elsif( $IDIV == 10 ) {
    $ICH5='L';
    $ICH1='X';
  } else {
    $ICH5='V';
    $ICH1='I';
  }
#
  goto L101;
}


&NCAR::frame();

&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();


sub BNDARY {
&NCAR::plotit(     0,    0,0 );
&NCAR::plotit( 32767,    0,1 );
&NCAR::plotit( 32767,32767,1 );
&NCAR::plotit(     0,32767,1 );
&NCAR::plotit(     0,    0,1 );
}


rename 'gmeta', 'ncgm/agex10.ncgm';
