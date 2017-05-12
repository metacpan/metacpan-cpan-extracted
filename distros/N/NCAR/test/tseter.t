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
# This test program demonstrates minimal functioning of the error-
# handling package used by NCAR Graphics.  It first produces a single
# frame showing what output print lines to expect and then steps
# through a simple set of tests that should produce those print lines.
#
#
# Define error file, Fortran unit number, and workstation type,
# and workstation ID.
#
my ( $IERRF, $LUNIT, $IWTYPE, $IWKID ) = ( 6, 2, 1, 1 );
#
# Make required character-variable declarations.  ERMSG receives the
# error message returned by the character function SEMESS.
#
#
# The contents of the array LINE defines the lines of print that this
# program should produce.
#
#
my @LINE = (
  ' ' ,
  'PROGRAM TSETER EXECUTING' ,
  ' ' ,
  'TSETER - CALL ENTSR TO ENTER RECOVERY MODE' ,
  ' ' ,
  'TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 1' ,
  ' ' ,
  'TSETER - CALL ERROF TO TURN OFF INTERNAL ERROR FLAG' ,
  ' ' ,
  'TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 2', 
  ' ' ,
  'TSETER - EXECUTE STATEMENT \'IERRO=NERRO(JERRO)\'' ,
  'TSETER - RESULTING IERRO:             2' ,
  'TSETER - RESULTING JERRO:             2' ,
  ' ' ,
  'TSETER - EXECUTE STATEMENT \'ERMSG=SEMESS(0)\'' ,
  'TSETER - RESULTING ERMSG:  ROUTINE_NAME_2 - ERROR_MESSAGE_2' ,
  'TSETER - (PRINTING ABOVE LINE ALSO TESTED ICLOEM)' ,
  ' ' ,
  'TSETER - CALL EPRIN TO PRINT CURRENT ERROR MESSAGE',
  'ERROR    2 IN ROUTINE_NAME_2 - ERROR_MESSAGE_2' ,
  'TSETER - (AN ERROR MESSAGE SHOULD HAVE BEEN PRINTED)' ,
  ' ' ,
  'TSETER - CALL ERROF TO TURN OFF INTERNAL ERROR FLAG' ,
  ' ' ,
  'TSETER - CALL EPRIN TO PRINT CURRENT ERROR MESSAGE' ,
  'TSETER - (NOTHING SHOULD HAVE BEEN PRINTED)' ,
  ' ' ,
  'TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 3' ,
  ' ',
  'TSETER - TEST THE USE OF ICFELL' ,
  ' ' ,
  'TSETER - CALL RETSR TO LEAVE RECOVERY MODE - BECAUSE' ,
  'TSETER - THE LAST RECOVERABLE ERROR WAS NOT CLEARED,' ,
  'TSETER - THIS WILL CAUSE A FATAL-ERROR CALL TO SETER' ,
  'ERROR    3 IN SETER - AN UNCLEARED PRIOR ERROR EXISTS' ,
  '... MESSAGE FOR UNCLEARED PRIOR ERROR IS AS FOLLOWS:' ,
  '... ERROR    6 IN SETER/ROUTINE_NAME_3 - ERROR_MESSAGE_3' ,
  '... MESSAGE FOR CURRENT CALL TO SETER IS AS FOLLOWS:' ,
  '... ERROR    2 IN RETSR - PRIOR ERROR IS NOW UNRECOVERABLE' 
);
#
# Open GKS.
#
&NCAR::gopks ($IERRF, my $ISZDM);
&NCAR::gopwk ($IWKID, $LUNIT, $IWTYPE);
&NCAR::gacwk ($IWKID);
#
# Produce a single frame of output, detailing what the program ought to
# print.
#
&NCAR::set    (0.,1.,0.,1.,0.,1.,0.,1.,1);
#
&NCAR::pcsetc ('FC - FUNCTION CODE SIGNAL',chr(0));
#
&NCAR::pcseti ('FN - FONT NUMBER',26);
#
&NCAR::plchhq (.5,.975,'SETER TEST "tseter"',.025,0.,0.);
#
&NCAR::pcseti ('FN - FONT NUMBER',1);
#
&NCAR::plchhq (.5,.925,'See the print output; it should consist of the following lines:',.011,0.,0.);
#
for my $I ( 1 .. 40 ) {
  &NCAR::plchhq (.15,.9-($I-1)*.022,$LINE[$I-1],.011,0.,-1.);
}
#
# Advance the frame.
#
&NCAR::frame();
#
# Close GKS.
#
&NCAR::gdawk ($IWKID);
&NCAR::gclwk ($IWKID);
&NCAR::gclks();
#
# Enter recovery mode.
#
print STDERR "
PROGRAM TSETER EXECUTING
 
TSETER - CALL ENTSR TO ENTER RECOVERY MODE
";

#
&NCAR::entsr (my $IROLD,1);
#
# Log a recoverable error.  Nothing should be printed, but the internal
# error flag should be set and the message should be remembered.
#
print STDERR "
TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 1
";

#
&NCAR::seter ('ROUTINE_NAME_1 - ERROR_MESSAGE_1',1,1);
#
# Clear the internal error flag.
#
print STDERR "
TSETER - CALL ERROF TO TURN OFF INTERNAL ERROR FLAG
";

#
&NCAR::errof();
#
# Log another recoverable error.  Again, nothing should be printed, but
# the internal error flag should be set and the message should be
# remembered.
#
print STDERR "
TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 2
";

#
&NCAR::seter ('ROUTINE_NAME_2 - ERROR_MESSAGE_2',2,1);
#
# Pick up and print the error flag, as returned in each of two
# ways by the function NERRO.
#
print STDERR "
TSETER - EXECUTE STATEMENT 'IERRO=NERRO(JERRO)'
";

#
my $IERRO=&NCAR::nerro(my $JERRO);
#
printf( STDERR "
	TSETER - RESULTING IERRO:  %d
	TSETER - RESULTING JERRO:  %d
", $IERRO, $JERRO );
#
# Pick up and print the error message, as returned by the function
# SEMESS.  This also tests proper functioning of the function ICLOEM.
#
printf( STDERR "
TSETER - EXECUTE STATEMENT 'ERMSG=%s'
", &NCAR::semess( 0 ) );
#
my $ERMSG=&NCAR::semess(0);
#
printf( STDERR "
TSETER - RESULTING ERMSG:  %s
TSETER - (PRINTING ABOVE LINE ALSO TESTED ICLOEM)
", substr( $ERMSG, 0, &NCAR::icloem( $ERMSG ) ) );
#
# Print the current error message.
#
print STDERR "
TSETER - CALL EPRIN TO PRINT CURRENT ERROR MESSAGE
";
#
&NCAR::eprin();
#
print STDERR "
TSETER - (AN ERROR MESSAGE SHOULD HAVE BEEN PRINTED)
";
#
# Clear the internal error flag again.
#
print STDERR "
TSETER - CALL ERROF TO TURN OFF INTERNAL ERROR FLAG
";
#
&NCAR::errof();
#
# Try to print the error message again.  Nothing should be printed.
#
print STDERR "
TSETER - CALL EPRIN TO PRINT CURRENT ERROR MESSAGE
";
#
&NCAR::eprin();
#
print STDERR "
TSETER - (NOTHING SHOULD HAVE BEEN PRINTED)
";
#
# Log another recoverable error.
#
print STDERR "
TSETER - CALL SETER TO REPORT RECOVERABLE ERROR 3
";
#
&NCAR::seter ('ROUTINE_NAME_3 - ERROR_MESSAGE_3',5,1);
#
# Test the use of ICFELL.
#
print STDERR "
TSETER - TEST THE USE OF ICFELL
";
#
if( &NCAR::icfell( 'TSETER', 6 ) != 5 ) {
  print STDERR "
TSETER - ICFELL MALFUNCTIONED - SOMETHING'S WRONG
";
  exit();
}
#
# Turn recovery mode off without clearing the internal error flag,
# which should be treated as a fatal error.
#
print STDERR "
TSETER - CALL RETSR TO LEAVE RECOVERY MODE - BECAUSE
TSETER - THE LAST RECOVERABLE ERROR WAS NOT CLEARED,
TSETER - THIS WILL CAUSE A FATAL-ERROR CALL TO SETER
";
#
&NCAR::retsr ($IROLD);
#
# Control should never get to the next statement, but just in case ...
#
print STDERR "
TSETER - GOT CONTROL BACK - SOMETHING'S WRONG
";
#

rename 'gmeta', 'ncgm/tseter.ncgm';

