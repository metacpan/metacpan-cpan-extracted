# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use NCAR;
use NCAR::Test qw();
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
my $XDAT = zeroes float, 400;
my $YDAT = zeroes float, 400;
#
# Fill the data arrays.
#
for my $I ( 1 .. 400 ) {
  set( $XDAT, $I-1, ( $I-1 ) / 399 );
}
#
my @t;
open DAT, "<data/agex09.dat";
{
  local $/ = undef;
  my $t = <DAT>;
  $t =~ s/^\s*//o;
  $t =~ s/\s*$//o;
  @t =split m/\s+/o, $t;
}
close DAT;
for my $J ( 1 .. 400 ) {
  set( $YDAT, $J-1, shift( @t ) );
}
#
# The y data ranges over both positive and negative values.
# It is desired that both ranges be represented on the same
# graph and that each be shown logarithmically, ignoring
# values in the range -.01 to +.01, in which we have no
# interest.  First we map each y datum into its absolute
# value (.01 if the absolute value is too small).  Then we
# take the base-10 logarithm, add 2.0001 (so as to be sure
# of getting a positive number), and re-attach the original
# sign.  We can plot the resulting y data on a linear y axis.
#
sub Log10 {
  my $x = shift;
  return log( $x ) / log( 10 );
}

for my $I ( 1 .. 400 ) {
  my $y = at( $YDAT, $I-1 );
  set( $YDAT, $I-1, 
  &NCAR::Test::sign( Log10( &NCAR::Test::max( abs( $y ), .01 ) )+2.0001, $y )
  );
}
#
# In order that the labels on the y axis should show the
# original values of the y data, we change the user-system-
# to-label-system mapping on both y axes and force major
# ticks to be spaced logarithmically in the
# label system (which will be defined by the subroutine
# AGUTOL in such a way as to re-create numbers in the
# original range).
#
&NCAR::agseti ('LEFT/FUNCTION.',1);
&NCAR::agseti ('LEFT/MAJOR/TYPE.',2);
#
&NCAR::agseti ('RIGHT/FUNCTION.',1);
&NCAR::agseti ('RIGHT/MAJOR/TYPE.',2);
#
# Change the left-axis label to reflect what's going on.
#
&NCAR::agsetc ('LABEL/NAME.','L');
&NCAR::agseti ('LINE/NUMBER.',100);
&NCAR::agsetc ('LINE/TEXT.','LOG SCALING, POSITIVE AND NEGATIVE$');
#
# Draw a boundary around the edge of the plotter frame.
#
&BNDARY();
#
# Draw the curve.
#
&NCAR::ezxy ($XDAT,$YDAT,400,'EXAMPLE 9$');


sub NCAR::agutol { 
  my ($IAXS,$FUNS,$IDMA,$VINP,$VOTP) = @_;
#
# Left or right axis.
#
  if( $FUNS == 1 ) {
    if( $IDMA < 0 ) { 
      $VOTP = &NCAR::Test::sign( 
          Log10( &NCAR::Test::max( abs( $VINP ), .01 ) )+2.0001, 
          $VINP
      );
    } else {
      $VOTP = &NCAR::Test::sign( 
         exp( log( 10 ) * ( abs( $VINP ) - 2.0001 ) ),
         $VINP
      );
    }
#
# All others.
#
  } else {
    $VOTP=$VINP;
  }
  $_[4] = $VOTP;
#
# Done.
#
}

sub NCAR::agchnl {
  my ($IAXS,$VILS,$CHRM,$MCIM,$NCIM,$IPXM,$CHRE,$MCIE,$NCIE) = @_;
  return;
#
# Modify the left-axis numeric label marking the value "0.".
#
  if( ( $IAXS == 1 ) && ( $VILS == 0 ) ) {
    substr( $CHRM, 0, 1, ' ' );
    $NCIM=1;
    $IPXM=0;
    $NCIE=0;
  }
  $_[2] = $CHRM;
  $_[4] = $NCIM;
  $_[5] = $IPXM;
  $_[6] = $CHRE;
  $_[8] = $NCIE;
#
# Done.
#
}
#


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

rename 'gmeta', 'ncgm/agex09.ncgm';
