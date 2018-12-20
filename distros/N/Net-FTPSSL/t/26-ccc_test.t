# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/26-ccc_test.t'

#########################

# This test script tests out if the "CCC" command works on this server!
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

   # The options used to establish the connection ...
   my $opts = get_opts_set_in_init ();

   ok (1, "It is OK for some of the following FTP commands to fail if your FTPS server doesn't support a command!");

   # -------------------------------------------------------
   # Verifying the ccc() command works as expected.
   # -------------------------------------------------------

   if ( $opts->{Encryption} eq CLR_CRYPT ) {
      ok ( 1, "Skipping the 'CCC' test since the CCC command doesn't work for regular FTP ..." );

   } elsif ( ! $ftps->supported ( "CCC" ) ) {
      ok ( 1, "Skipping the 'CCC' test since the CCC command is not supported on this server!" );

   } else {
      my $res = $ftps->noop ();
      ok ( $res, "NOOP command worked against encrypted channel." );

      my $dir = $ftps->pwd ();
      ok ( $dir, "Current directory is: $dir");

      write_to_log ($ftps, "Start CCC CMD", "--------------------------------------------------");
      $res = $ftps->ccc ();
      ok ( $res, "Clear Command Channel command worked!");
      write_to_log ($ftps, "Stop CCC CMD ($res)", "--------------------------------------------------");

      $res = $ftps->noop ();
      ok ( $res, "NOOP command worked against the cleared channel." );

      my $dir2 = $ftps->pwd ();
      ok ( $dir eq $dir2, "Current directory is: $dir2");
   }

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

