# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/03-ask-questions-again.t'

#########################

# This test script repeats asking the "t/01-ask-questions.t" ...
# But this time it shouldn't ask for anything, it should use all defaults
# if the helper module works as advertised.
# Required if I don't want to have to ask the same questions over and
# over again for each test program.
# I only want to ask the questions a single time!

# The real purpose is to retire the monster test programs and replace
# them with dozens of smaller programs.  Making it easier to make
# changes to the program in the future!

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

   ok ( 1, "Answers verified!" );

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================

