# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/28-put_get_delete_tests.t'

#########################

# This test script tests out the following:
#   1) Uploads a file to the FTPS server.
#   2) Get's the file's size on the FTPS server.
#   3) Verifies it's a regular file via is_file().
#   4) Verifies it's not a directory via is_dir().
#   5) Downloads the same file.
#   6) Then delets the uploaded & downloaded files.

# A second series of tests finds out what happens when you
# try to overwrite a file previously uploaded & downloaded.

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
   my $base_name = get_log_name ();
   $base_name =~ s/[.]log[.]txt$//;

   # So each Net::FTPSSL object uses it's own log file ...

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
      ok ( 1, "Skipping the put/get/delete test cases!  You specified read-only access to the FTPS server!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("STOR") ) {
      ok ( 1, "Skipping the put/get/delete test cases!  The FTPS server says the 'put' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("RETR") ) {
      ok ( 1, "Skipping the put/get/delete test cases!  The FTPS server says the 'get' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("DELE") ) {
      ok ( 1, "Skipping the put/get/delete test cases!  The FTPS server says the 'delete' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # -------------------------------------------

   ok (1, "All tests should pass unless you don't have enough permission on the FTPS server to run them!" );

   # ok (0, "Finish writing the PUT/GET/DELTETE Tests ...");

   $ftps->binary ();
   run_tests ( $ftps, $bin_file, "help_me.bin",     File::Spec->catfile ($work_dir, "b_help_me.bin") );
   run_tests ( $ftps, $bin_file, "h e l p m e.bin", File::Spec->catfile ($work_dir, "b_h e l p m e.bin") );
   run_tests ( $ftps, $bin_file, "help_me",         File::Spec->catfile ($work_dir, "b_help_me") );

   $ftps->ascii ();
   run_tests ( $ftps, $ascii_file, "help_me.txt",     File::Spec->catfile ($work_dir, "a_help_me.txt") );
   run_tests ( $ftps, $ascii_file, "h e l p m e.txt", File::Spec->catfile ($work_dir, "a_h e l p m e.txt") );
   run_tests ( $ftps, $ascii_file, "a_help_me",       File::Spec->catfile ($work_dir, "a_help_me") );

   my $f = "Overwite Test.tst";
   my $f2 = File::Spec->catfile ($work_dir, $f);
   run_overwrite_tests ( $ftps, $ascii_file, $bin_file, $f, $f2 );

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================
# This test uploads a file, downloads the file, and then deletes it
# from the FTPS server and the local downloaded copy!

sub run_tests
{
   my $ftps       = shift;
   my $src_file   = shift;
   my $upld_file  = shift;
   my $dwnld_file = shift;

   write_to_log ( $ftps, "TEST", "--------------------------------------------------------------" );
   ok ( 1, "-----------------------------------------------------" );

   my ( $src_size, $upld_size, $dwnld_size ) = ( 0, 0, 0 );

   $src_size = -s $src_file;    # Size of the source file ...

   my $res = $ftps->put ( $src_file, $upld_file );
   ok ( $res, "Upload worked!  ($src_file)");

   $upld_size = $ftps->size ( $upld_file );
   if ( defined $upld_size ) {
      ok ( $src_size == $upld_size, "The uploaded file is sized correctly ($src_size vs $upld_size)" );
   } else {
      ok ( 1, "The size function doesn't work on this server!" );
   }

   $res = $ftps->get ( $upld_file, $dwnld_file );
   ok ( $res, "Download worked!  ($upld_file)");

   $dwnld_size = -s $dwnld_file;    # Size of the downloaded file ...
   if ( defined $dwnld_size ) {
      ok ( $src_size == $dwnld_size, "The downloaded file is sized correctly ($src_size vs $dwnld_size)" );
   } else {
      ok ( 0, "The downloaded file is sized correctly ($src_size vs undef)" );
   }

   unlink ( $dwnld_file );
   $res = $ftps->delete ( $upld_file );
   ok ( $res, "Deleted the file on the FTPS server!" );
   $res = (-f $dwnld_file) ? 0 : 1;
   ok ( $res, "Deleted the downloaded file on the local server!" );

   return;
}

# ===========================================================================
# Same as run_test() except it tries to overwrite the files uploaded/dowloaded.

sub run_overwrite_tests
{
   my $ftps       = shift;
   my $src_file_a = shift;    # Ascii file ...
   my $src_file_b = shift;    # Binary file ...
   my $upld_file  = shift;
   my $dwnld_file = shift;

   # Verify the size of the source files are different ...
   my ( $size_a, $size_b ) = ( -s $src_file_a, -s $src_file_b );
   ok ( $size_a != $size_b, "The size of the ASCII & BINARY files are different as expected!" );

   write_to_log ( $ftps, "TEST", "--------------------------------------------------------------" );
   ok ( 1, "-----------------------------------------------------" );

   # -------------------------------------------------------------------
   # Does the initial upload/download of the file ...
   # -------------------------------------------------------------------
   $ftps->ascii ();

   my $res1  = $ftps->put ($src_file_a, $upld_file);
   my $size1 = $ftps->size ($upld_file);
   ok ( $res1, "Initial upload of the ascii test file is on the FTPS server." );

   $res1 = $ftps->is_file ( $upld_file );
   ok ( $res1, "The FTPS server says the uploaded file is a regular file!" );

   $res1 = $ftps->is_dir ( $upld_file );
   ok ( ! $res1, "The FTPS server says the uploaded file is not a directory!" );

   $res1 = $ftps->get ( $upld_file, $dwnld_file );
   ok ( $res1, "The initial download of the test file worked!" );

   my $sz1 = -s $dwnld_file;
   ok ( $size_a == $sz1, "The initial download generated a file of the correct size!" );

   # -------------------------------------------------------------------
   # Does the overwrite upload/download of the same file ...
   # -------------------------------------------------------------------
   my $res2  = $ftps->put ($src_file_a, $upld_file);
   my $size2 = $ftps->size ($upld_file);
   ok ( $res2, "Overwrote the upload of the ascii test file on the FTPS server." );

   if ( defined $size1 && defined $size2 ) {
      ok ( $size1 == $size2, "The size of the file on the FTPS server didn't change!" );
   } else {
      ok ( 1, "The size command wasn't supported by your server!" );
   }

   $res2 = $ftps->get ( $upld_file, $dwnld_file );
   ok ( $res2, "The overwrite download of the test file worked!" );

   my $sz2 = -s $dwnld_file;
   if ( defined $sz1 && defined $sz2 ) {
      ok ( $sz1 == $sz2, "The size of the downloaded file on the local server didn't change!" );
   } else {
      ok ( 0, "The size of the downloaded file on the local server didn't change!" );
   }

   # -------------------------------------------------------------------
   # Now lets overwrite things with the binary file (different size)
   # -------------------------------------------------------------------
   $ftps->binary ();

   my $res3  = $ftps->put ($src_file_b, $upld_file);
   my $size3 = $ftps->size ($upld_file);
   ok ( $res3, "Overwrote the upload of the ascii test file with a binary test file on the FTPS server." );

   if ( defined $size1 && defined $size3 ) {
      ok ( $size1 != $size3, "The size of the file on the FTPS server changed as expected!" );
   } else {
      ok ( 1, "The size command wasn't supported by your server!" );
   }

   $res3 = $ftps->get ( $upld_file, $dwnld_file );
   my $sz3 = -s $dwnld_file;

   if ( defined $size_b && defined $sz3 ) {
      ok ( $size_b == $sz3, "The size of the file on the local server changed to the binary size as expected!" );
   } else {
      ok ( 0, "The size of the file on the local server changed to the binary size as expected!" );
   }

   # -----------------------------------------------
   # Now delete the file in both places ...
   # -----------------------------------------------

   $res1 = $ftps->delete ( $upld_file );
   ok ( $res1, "The file on the FTPS server was deleted!" );
   unlink ($dwnld_file);
   $res1 = (-f $dwnld_file) ? 0 : 1;
   ok ( $res1, "Deleted the downloaded file on the local server!" );

   return;
}

