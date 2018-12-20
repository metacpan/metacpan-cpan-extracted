# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/20-multiple_connections.t'

#########################

# This test script validates that each Net::FTPSSL object writes to it's own log file.

# This is also the 1st test program to use:  initialize_your_connection()!

#########################

use strict;
use warnings;

use Test::More;    # I'm not pre-counting the tests ...
use File::Copy;
use File::Basename;
use File::Spec;

BEGIN {
   # How to find the test helper module ...
   push (@INC, File::Spec->catdir (".", "t", "test-helper"));
   push (@INC, File::Spec->catdir (".", "test-helper"));

   # Must include after updating @INC ...
   # doing: "use helper1234;" doesn't work!
   my $res = use_ok ("helper1234");     # Test # 1 ...
   unless ( $res ) {
      BAIL_OUT ("Can't load the test helper module ... Probably due to syntax errors!" );
   }

   use_ok ('Net::FTPSSL');              # Test # 2 ...
}

# ===========================================================================

{
   my $base_name = get_log_name ();

   $base_name =~ s/[.]log[.]txt$//;

   # So each Net::FTPSSL object uses it's own log file ...
   my $name1 = $base_name . ".001.log.txt";
   my $name2 = $base_name . ".002.log.txt";
   my $name3 = $base_name . ".003.log.txt";

   my $ftps_1 = initialize_your_connection ($name1);
   my $ftps_2 = initialize_your_connection ($name2);
   my $ftps_3 = initialize_your_connection ($name3);

   ok ( 1, "Starting our tests ...");

   # Verifies that each log file exists ...
   my $res1 = ( -f $name1 ) ? 1 : 0;
   my $res2 = ( -f $name2 ) ? 1 : 0;
   my $res3 = ( -f $name3 ) ? 1 : 0;
   ok ( $res1, "The 1st log file exists!");
   ok ( $res2, "The 2nd log file exists!");
   ok ( $res3, "The 3rd log file exists!");

   # Writes the same message to each log file ...
   warn ("Writting this warning to all 3 log files ...\n");

   # Write a different message to each log file ...
   write_to_log ( $ftps_1, "WRITE-TEST", "Writting to the 1st log file ..." );
   write_to_log ( $ftps_2, "WRITE-TEST", "Writting to the 2nd log file ..." );
   write_to_log ( $ftps_3, "WRITE-TEST", "Writting to the 3rd log file ..." );

   # So each log file records a different command ...
   # All servers should support all 3 FTP commands!
   $res3 = $ftps_3->noop ();
   $res2 = $ftps_2->binary ();
   $res1 = $ftps_1->ascii ();

   ok ( $res3, "The no-op command worked OK.");
   ok ( $res2, "The binary command worked OK.");
   ok ( $res1, "The ascii command worked OK.");

   $ftps_1->quit ();
   $ftps_2->quit ();
   $ftps_3->quit ();

   # We're done with the testing.
   stop_testing ();
}

