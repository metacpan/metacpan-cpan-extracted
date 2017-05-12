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
# PURPOSE                To provide a simple demonstration of the
#                        routine FSLFNT.
#
# USAGE                  CALL FSLFNT (IERROR)
#
# ARGUMENTS
#
# ON OUTPUT              IERROR
#                          An integer variable
#                            = 0  If there is a normal exit from FSLFNT
#                            = 1  Otherwise
#
# I/O                    If there is a normal exit from FSLFNT,
#                        the message
#
#                          FSLFNT TEST SUCCESSFUL . . . SEE PLOTS TO
#                          VERIFY PERFORMANCE
#
#                        is written on unit 6
#
# PRECISION              SINGLE
#
# REQUIRED LIBRARY       FSLFNT
# FILES
#
# LANGUAGE               FORTRAN
#
# HISTORY                Written  by members of the
#                        Scientific Computing Division of NCAR,
#                        Boulder Colorado
#
# PORTABILITY            FORTRAN 77
#
#
#
# Store character strings in array CARDS.  These strings contain text,
# plus information regarding character size and location of the text
# on the scroll.
#
my $NCARDS = 4;
my @CARDS = (
   '  512  760    1  1.5Demonstration',
   '  512  600    1  1.5Plot',
   '  512  440    1  1.0for',
   '  512  280    1  1.5STITLE',
);
#
# Employ the new high quality filled fonts in PLOTCHAR
#
&NCAR::pcsetc('FN','times-roman');
#
# Define the remaining inputs to routine STITLE.  Note that the
# output produced (a single frame with no scrolling to appear for
# 6.0 seconds) could equally well have been produced by FTITLE.
# We call STITLE in this demo to avoid reading the input lines.
#
my $NYST  = 512;
my $NYFIN = 512;
my $TST   = 0.0;
my $TMV   = 0.0;
my $TFIN  = 6.0;
my $MOVIE =   1;
#
# Call STITLE.
#
&NCAR::stitle (\@CARDS,$NCARDS,$NYST,$NYFIN,$TST,$TMV,$TFIN,$MOVIE);
print STDERR "     FSLFNT TEST SUCCESSFUL SEE PLOTS TO VERIFY PERFORMANCE\n";

&NCAR::frame();
&NCAR::gdawk( 1 );
&NCAR::gclwk( 1 );
&NCAR::gclks();

rename 'gmeta', 'ncgm/fslfont.ncgm';
