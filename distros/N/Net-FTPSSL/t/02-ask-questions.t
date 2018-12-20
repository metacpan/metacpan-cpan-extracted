# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/02-ask-questions.t'

#########################

# This test script prompts the user for his FTPS server information
# so that the other test programs don't have to ask for it again!
# Once it's been successfully run, it provides the default answers for
# all the other test programs.

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
   my $force = 1;

   if ( should_we_ask_1st_question ($force) ) {
      should_we_run_test ("Configuring the test cases");
   }

   my ( $host, $user, $pass, $dir, $ftps_opts, $psv_mode ) = ask_config_questions ();

   ok ( 1, "Data Entered!" );

   my $make_test;
   if ( called_by_make_test () ) {
      ok ( 1, "Test run via 'make test'" );
      $make_test = 1;
   } else {
      ok ( 1, "Test run via 'perl $0'" );
      $make_test = 0;
   }

   print_env_vars ( $make_test );

   ok ( 1, "Environment (%ENV) saved to Log file." );

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================

sub print_env_vars
{
   my $mode = shift;

   my $log = get_log_name ();

   open (LOG, ">", $log) or bail_testing ("Can't create the log file!");

   if ( $mode ) {
      print LOG "Test was run via \"make test\"\n\n";
   } else {
      print LOG "Test was run via \"perl $0\"\n\n";
   }

   my $pv = sprintf ("%s  [%vd]", $], $^V);   # The version of perl!
   print LOG "Perl: $pv,  OS: $^O\n\n";

   foreach ( "Net-FTPSSL",
             "IO-Socket-SSL",  "Net-SSLeay",
             "IO-Socket-INET", "IO-Socket-INET6",
             "IO-Socket-IP",   "IO",
             "Socket" ) {
      my $mod = $_;
      $mod =~ s/-/::/g;
      my $ver = $mod->VERSION;
      if ( defined $ver ) {
         print LOG "$_ Version: $ver\n";
      } else {
         print LOG "$_ might not be installed.\n";
      }
   }

   print LOG "\n\n%ENV ...\n---------------------------------------------------------\n";

   foreach (sort keys %ENV) {
      print LOG "$_ = $ENV{$_}\n";
   }
   print LOG "\n";

   close (LOG);
}

# ===========================================================================

