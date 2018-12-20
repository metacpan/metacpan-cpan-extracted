# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/24-dir_tests.t'

#########################

# This test script tests out individual directory FTP commands.
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
   my $ftps = initialize_your_connection ();

   ok (1, "It is OK for some of the following FTP commands to fail if your FTPS server doesn't support a command!");

   # -------------------------------------------------------
   # The Change Directory Tests
   # -------------------------------------------------------

   my $home = $ftps->pwd ();   # Where are we now?
   my $res = $ftps->cdup ();
   my $pwd = $ftps->pwd ();
   ok ( $res, "Going up one level: ($pwd)" );
   if ( $home eq "/" ) {
      ok ( 1, "The current directory can't change!" );
   } else {
      ok ( ($home ne $pwd), "The current directory was changed!" );
   }

   $res = $ftps->cdup ();
   $pwd = $ftps->pwd ();
   ok ( $res, "Going up another level! ($pwd)");

   $res = $ftps->cwd ( $home );
   $pwd = $ftps->pwd ();
   ok ( ($home eq $pwd), "Returned to proper dir: ($pwd)" );
   ok ( ($home eq $pwd), "The current directory was correct!" );

   # -------------------------------------------------------

   $res = $ftps->is_file ( $home );
   ok ( ! $res, "IS-FILE test failed against dir ($home)!");

   $res = $ftps->is_dir ( $home );
   ok ( $res, "IS-DIR test passed against dir ($home)!");

   my $hmod;
   if ( $ftps->supported ( "mdtm" ) ) {
      $hmod = $ftps->mdtm ( $home ) || "";
      ok ( 1, "Directory last modified on: '$hmod'" );
   }

   # -------------------------------------------------------

   unless ( are_updates_allowed () ) {
      ok ( 1, "Skipping the Create/Rename/Delete directory test cases per request!" );

   } else {
      # The relative directory tests
      create_dir_test ($ftps, "NewDirTest", $home, $hmod);
      create_dir_test ($ftps, "N e w D i r T e s t", $home, $hmod);

      # The absolute path directory tests (hard coded to use unix paths)
      create_dir_test ($ftps, $home . "/TestDir", $home, $hmod);
      create_dir_test ($ftps, $home . "/T e s t D i r", $home, $hmod);
   }

   # -------------------------------------------------------

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# =====================================================================

sub create_dir_test
{
   my $ftps    = shift;
   my $new_dir = shift;    # The directory to create ...
   my $home    = shift;    # The home/current directory ...
   my $hmod    = shift;    # The timestamp on the home directory ...

   ok ( 1, "------------------------------------------------------" );

   my $res1 = $ftps->is_file ( $new_dir );
   my $res2 = $ftps->is_dir ( $new_dir );
   if ( $res1 || $res2 ) {
      ok ( 0, "Verifying the requested directory doesn't already exist on the FTPS server!" );
      return;
   }

   my $res = $ftps->mkdir ( $new_dir );
   ok ( $res, "Directory Created! ($new_dir)" );

   $res = $ftps->is_dir ( $new_dir );
   my $mod = $ftps->mdtm ( $new_dir ) || "";
   ok ( $res, "Verified the Directory now exists! - Created on: $mod" );

   $res = $ftps->cwd ( $new_dir );
   my $full = $ftps->pwd ();
   ok ( $res, "Entered directory ($new_dir)" );
   if ( $full ne $new_dir ) {
      ok ( 1, "The full path to the directory is: $full" );
   }

   $res = $ftps->cwd ( $home );
   ok ( $res, "Returned to home directory ($home)" );

   unless ( $ftps->supported ("MFMT") && $hmod ) {
      ok ( 1, "Updating the timestamp on a directory is not supported!" );
   } else {
      $res = $ftps->mfmt ( $hmod, $new_dir );
      $res2 = $ftps->mdtm ( $new_dir );
      ok ( $res, "Changed the directory's timestamp to ${res2}" );
   }

   my $delete_dir = $new_dir;
   unless ( $ftps->all_supported ("RNFR", "RNTO") ) {
      ok ( 1, "The renaming of directories are not supported!" );

   } else {
      sleep (1);     # Some servers require a brief pause before rename is honored!
      my $rename_dir = $new_dir . "2";
      $res = $ftps->rename ( $new_dir, $rename_dir );
      if ( ok ( $res, "Renamed the directory to: ${rename_dir}" ) ) {
         $delete_dir = $rename_dir;
      }
   }

   # Now delete the new directory ...
   $res = $ftps->rmdir ( $delete_dir );
   ok ( $res, "Deleted directory: ${delete_dir}" );

   return;
}

# =====================================================================

