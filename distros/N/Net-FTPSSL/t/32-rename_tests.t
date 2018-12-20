# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl ./t/32-rename_tests.t'

#########################

# This test script tests out the following:
# This test script does the following to test out the rename function
#   1) Uploads a test file to the FTPS server.
#   2) Renames the test file on the FTPS server several times.
#   3) Deletes the uploaded file on the FTPS server!

# It is OK for some tests to fail here if a particular FTP command isn't
# supported by your FTPS server!

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
   # -------------------------------------------
   # Validating the test environment ...
   # -------------------------------------------
   my $data_dir   = File::Spec->catdir ( dirname ($0), "data" );
   my $bin_file   = File::Spec->catfile ( $data_dir, "test_file.tar.gz" );
   my $ascii_file = File::Spec->catfile ( $data_dir, "00-basic.txt" );
   my $work_dir   = File::Spec->catdir ( dirname ($0), "work" );

   unless ( -d $data_dir && -r _ && -w _ && -x _ ) {
      ok (0, "The data dir exists and we have full access to it!  ($data_dir)");
      stop_testing ();
   }

   unless ( -f $bin_file && -r _ ) {
      ok (0, "Found the binary test data file!  ($bin_file)");
      stop_testing ();
   }

   unless ( -f $ascii_file && -r _ ) {
      ok (0, "Found the ascii test data file!  ($ascii_file)");
      stop_testing ();
   }

   unless ( -d $work_dir && -r _ && -w _ && -x _ ) {
      ok (0, "The work dir exists and we have full access to it!  ($work_dir)");
      stop_testing ();
   }

   # -------------------------------------------
   # Initializing your FTPS connection ...
   # -------------------------------------------
   my $ftps = initialize_your_connection ();

   # -----------------------------------------------------
   # Verifying you are allowed to run these tests ...
   # I can only verify if the server supports a cmd, not
   # if your account has enough privileges to run them.
   # We find that out if commands start to fail!
   # -----------------------------------------------------
   unless ( are_updates_allowed () ) {
      ok ( 1, "Skipping the rename test cases!  You specified read-only access to the FTPS server!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->all_supported ("RNFR", "RNTO") ) {
      ok ( 1, "Skipping the rename test cases!  The FTPS server says the 'rename' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("DELE") ) {
      ok ( 1, "Skipping the rename test cases!  The FTPS server says the 'delete' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("STOR") ) {
      ok ( 1, "Skipping the rename test cases!  The FTPS server says the 'put' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # -------------------------------------------

   ok (1, "All tests should pass unless you don't have enough permission on the FTPS server to run them!" );

   $ftps ->binary ();
   my $res = $ftps->put ( $bin_file );
   ok ( $res, "Uploaded the test file to work with." );

   my $current_name = basename ( $bin_file );
   foreach my $f ( "help_me.bin", "h e l p m e.bin", "helpme", "h e l p m e", "fake_text.bin.txt", "f a k e t e x t.txt" ) {
      # Some FTPS servers require a brief pause before it will honor a rename request.
      sleep (1);

      $res = $ftps->rename ( $current_name, $f );
      ok ( $res, "Renamed '${current_name}' to '${f}' on the FTPS server." );

      my $res2 = $ftps->is_file ( $f );
      ok ( $res2, "   Verified the file now uses its new name on the FTPS server!" );

      $res2 = $ftps->is_file ( $current_name );
      ok ( ! $res2, "   Verified the file doesn't still uses its old name on the FTPS server!" );

      $current_name = $f  if ( $res );
   }

   sleep (1);
   $res = $ftps->rename ( $current_name, $current_name );
   if ( $res ) {
      ok ( 1,  "The FTPS server allowed you to rename a file to itself!" );
   } else {
      ok ( 1, "You can't rename a file to itself on the FTPS server!" );
   }

   $res = $ftps->delete ( $current_name );
   ok ( $res, "Deleted file '${current_name}' on the FTPS server!" );

   # -------------------------------------------

   $res = $ftps->rename ( "no-such-file.txt", "still-no-such-file.txt" );
   ok ( ! $res, "You can't rename a file that doesn't exist on the FTPS server!" );

   $res = $ftps->delete ( "no-such-file.txt" );
   ok ( ! $res, "You can't delete a file that doesn't exist on the FTPS server!" );

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================

