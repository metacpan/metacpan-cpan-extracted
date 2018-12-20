# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/05-check-new-cmd.t'

#########################

# This tests if we can create a Net::FTPSSL object.  All other tests will fail
# if this test case can't succeed!
# It will attempt to dynamically add options to try to get past connect errors
# on failure.  And if any are added those options will be remembered between
# test cases.
# It only reports on overall results!  Not on individual attempts!

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
   # sleep (1);  # So the BEGIN tests complete before the message prints!

   # Only program "t/01-ask-questions.t" should ever set this value to "1"!
   # All other test programs should set to zero!
   my $force = 0;

   if ( should_we_ask_1st_question ($force) ) {
      should_we_run_test ("Repeating the Configuring test cases");
   }

   my ( $host, $user, $pass, $dir, $ftps_opts, $psv_mode ) = ask_config_questions ();

   ok ( 1, "Input accepted!" );

   my $ftps = Net::FTPSSL->new ( $host, $ftps_opts );

   # If it failed to connect, let's try again with some additional options added!
   if ( $ftps_opts->{Encryption} ne CLR_CRYPT && (! $ftps) &&
        $Net::FTPSSL::ERRSTR =~ m/:SSL3_CHECK_CERT_AND_ALGORITHM:/ ) {
       my $key = 'SSL_cipher_list';
       local $ftps_opts->{$key} = 'HIGH:!DH';

       diag ("\n########################################################");
       diag ("Making a 2nd attempt to connect using a new SSL option!");
       diag ("Adding: {$key} = '$ftps_opts->{$key}' for retry ...");
       diag ("########################################################");
       $ftps = Net::FTPSSL->new ( $host, $ftps_opts );
       if ( $ftps ) {
          add_extra_arguments_to_config ($key, $ftps_opts->{$key});
       }
   }

   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created' ) or
             bail_testing ("Can't create a Net::FTPSSL object with the answers given!");

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

