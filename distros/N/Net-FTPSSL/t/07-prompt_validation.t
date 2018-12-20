# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/07-prompt_validation.t'

#########################

# This script validates the remainder of the prompted information.

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
      should_we_run_test ("Validating the remaining prompts test case.");
   }

   my ( $host, $user, $pass, $dir, $ftps_opts, $psv_mode ) = ask_config_questions ();

   ok ( 1, "Input accepted!" );

   my $ftps = Net::FTPSSL->new ( $host, $ftps_opts );
   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created' );
   stop_testing ()  unless ( $res );

   $res = $ftps->trapWarn ();
   ok ( $res, "Warnings Trapped!" );

   $res = $ftps->login ($user, $pass);
   ok ( $res, "Login Successful!  Your credentials are good!" );
   stop_testing ()  unless ( $res );    # If login failure ...

   if ( $psv_mode ne "P" ) {
      my $t = $ftps->force_epsv (1);
      $psv_mode = ( $t ) ? "1" : "2";
       $t = $ftps->force_epsv (2)  unless ( $t );
       ok ( $t, "Force Extended Passive Mode (EPSV $psv_mode)" );
       unless ( $t ) {
          bail_testing ("EPSV is not supported, please rerun tests using PASV instead!");
       } else {
          add_extra_arguments_to_config ('EPASV_OPT_VALUE', $psv_mode);
       }
   }

   $res = $ftps->cwd ($dir);
   ok ( $res, "Change Dir Successful!" ) or
       bail_testing ("Can't change into the test directory!  Please change your answer for it!");

   my $current = $ftps->pwd ();
   $res = ($current eq $dir);
   ok ( $res, "Change Dir Verified!" ) or
       bail_testing ("Invalid directory specified on the SFTP server!  ($dir)");

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

