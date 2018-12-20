# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/01-test-if-environment-ok.t'

#########################

# Checks the local file system to verify that required directories and
# test files are actually present!

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
# Main Program ...
# ===========================================================================

{
   # -------------------------------------------
   # Validating the test environment ...
   # -------------------------------------------
   my $data_dir   = File::Spec->catdir ( dirname ($0), "data" );
   my $bin_file   = File::Spec->catfile ( $data_dir, "test_file.tar.gz" );
   my $ascii_file = File::Spec->catfile ( $data_dir, "00-basic.txt" );
   my $work_dir   = File::Spec->catdir ( dirname ($0), "work" );
   my $log_dir    = File::Spec->catdir ( dirname ($0), "logs" );

   my $bad_cnt = 0;

   my $msg = "The data dir exists and we have full access to it!  ($data_dir)";
   if ( -d $data_dir && -r _ && -w _ && -x _ ) {
      ok (1, $msg);
   } else {
      ok (0, $msg);
      ++$bad_cnt;
   }

   $msg = "Found the binary test data file!  ($bin_file)";
   if ( -f $bin_file && -r _ ) {
      ok (1, $msg);
   } else {
      ok (0, $msg);
      ++$bad_cnt;
   }

   $msg = "Found the ascii test data file!  ($ascii_file)";
   if ( -f $ascii_file && -r _ ) {
      ok (1, $msg);
   } else {
      ok (0, $msg);
      ++$bad_cnt;
   }

   $msg = "The work dir exists and we have full access to it!  ($work_dir)";
   if ( -d $work_dir && -r _ && -w _ && -x _ ) {
      ok (1, $msg);
   } else {
      ok (0, $msg);
      ++$bad_cnt;
   }

   $msg = "The log dir exists and we have full access to it!  ($log_dir)";
   if ( -d $log_dir && -r _ && -w _ && -x _ ) {
      ok (1, $msg);
   } else {
      ok (0, $msg);
      ++$bad_cnt;
   }

   # Did we encounter any errors in our setup?
   if ( $bad_cnt ) {
      bail_testing ("Corrupted build environment.  You're missing one or more test files and/or directories in your build.");
   }

   # No everything was A-OK!
   stop_testing ();
}

