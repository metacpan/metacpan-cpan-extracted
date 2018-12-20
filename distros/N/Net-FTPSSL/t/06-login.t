# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/06-login.t'

#########################

# This script verifies that the login information is good.
# If it fails, then any following test case will also fail!

# It also attempts to detect if the OverrideHELP & OverridePASV
# options are required for this purpose.  (Bug Id 61432)

# Finally each connection appends to the log file of the
# previous connection.

# Keeping these tests separate results in simpler test cases!

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
      should_we_run_test ("Validating the login credentials test case.");
   }

   my ( $host, $user, $pass, $dir, $ftps_opts, $psv_mode ) = ask_config_questions ();

   ok ( 1, "Input accepted!" );

   # Assume all commands supported!
   # So that login won't call help in case HELP itself is broken!
   $ftps_opts->{OverrideHELP} = 1;

   my $ftps = Net::FTPSSL->new ( $host, $ftps_opts );
   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created' ) or
        bail_testing ("Can't create a Net::FTPSSL object with the answers given!");

   $res = $ftps->trapWarn ();
   ok ( $res, "Warnings Trapped!" );

   # Should only get written to the log file ...
   warn ("Warning trap test!\n");

   $res = $ftps->login ($user, $pass);
   ok ( $res, "Login Successful!  Your credentials are good!" ) or
       bail_testing ("Can't login to the SFTP server.  Your credentials are probably bad!");

   if ($ftps->quot ("PRET", "LIST") == CMD_OK) {
      diag ("\n=========================================================");
      diag ('=== Adding option "Pret" to all future calls to new() ===');
      diag ("=========================================================\n");
      $ftps_opts->{Pret} = 1;     # Assumes all future calls will need!
      add_extra_arguments_to_config ('Pret', 1);
   }

   $ftps->quit ();
   write_to_log ($ftps, "LOG ENDING", "Closing the log for the 1st test.\n");

   # Put so future logs append to the exising one instead of
   # creating a new one and loosing the test results above!
   $ftps_opts->{Debug} = 2;

   # --------------------------------------------------------
   # Attempts to auto-detect if special options are required
   # for the FTPS connection to function normally ...
   # --------------------------------------------------------
   # Will dynamically check if OverrideHELP is really needed for
   # future calls to new() ...
   check_for_help_issue ( $host, $ftps_opts, $user, $pass );

   # if ( $psv_mode eq "P" && (! exists $ftps_opts->{Pret}) ) {
   if ( $psv_mode eq "P"  ) {
      check_for_pasv_issue ( $host, $ftps_opts, $user, $pass );
   }

   ok (1, "Work Arround Auto-Detect Tests Completed!");

   # --------------------------------------------------------
   # Verifiy we can still log in after potentially adding
   # more FTPSSL options ...
   # --------------------------------------------------------
   $ftps = Net::FTPSSL->new ( $host, $ftps_opts );
   $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created' ) or
        bail_testing ("Can't create a Net::FTPSSL object with the answers given!");

   $res = $ftps->login ($user, $pass);
   ok ( $res, "Login Successful!  Your credentials are good!" ) or
       bail_testing ("Can't login to the SFTP server.  Your credentials are probably bad!");

   # Tell what OS the FTPS server is running on ...
   if ( $ftps->supported ( "SYST" ) ) {
      $res = $ftps->quot ("SYST");
      ok ( $res == CMD_OK, "The SYST command worked!" );
   }

   if ( $ftps->supported ("HELP") ) {
      ok ( 1, "The help command is supported!" );
   } elsif ( exists $ftps_opts->{OverrideHELP} ) {
      ok ( 1, "The help command has been overriden!" );
   } else {
      ok ( 1, "The help command isn't supported!" );
   }

   $ftps->quit ();
   write_to_log ($ftps, "LOG ENDING", "Closing the log for the last test.\n");

   ok (1, "Final Login Test Works!");

   # We're done with the testing.
   stop_testing ();
}


# -----------------------------------------------------------------------------
# Test for Bug # 61432 (Help responds with mixed encrypted & clear text on CC.)
# Bug's not in my software, but on the server side!
# But still need tests for it in this script so all test cases will work.
# Never run a command that opens a data channel here ...
# -----------------------------------------------------------------------------
# Another issue discovered is when the HELP command returns same as SITE HELP.
# So treating it as an issue if "HELP" isn't listed as a valid FTP command.
# -----------------------------------------------------------------------------
sub check_for_help_issue
{
   my ( $host, $ftps_opts, $user, $pass ) = ( shift, shift, shift, shift );

   # Make a local copy of the option list ...
   my %loc_args = %{$ftps_opts};

   # Remove the OverrideHELP = 1 setting from ${ftps_opts} ...
   delete $loc_args{OverrideHELP};

   # So die will be called if the call to HELP fails!
   # Already know the login credentials are good!
   $loc_args{Croak} = 1;

   my $ftps = Net::FTPSSL->new ( $host, \%loc_args );
   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created for HELP test' );
   stop_testing  unless ( $res );

   $res = $ftps->trapWarn ();

   eval {
      $res = $ftps->login ($user, $pass);      # Calls help internally ...

      ok ( $res, "Login Successful!  Your credentials are still good for OverrideHELP Test!" );
      stop_testing  unless ( $res );

      if ( $ftps->supported ("HELP") ) {
         # HELP is supported!  No need to override it for our test suit ...
         # Should take this path if HELP is working as expected!
         add_extra_arguments_to_config ('OverrideHELP', 99);
         delete $ftps_opts->{OverrideHELP};
         ok ( 1, "The help command has been enabled!");

      } else {
         # Can't tell here if help is really working or not at this time.
         # But at least the login didn't throw an exception to be trapped!
         # So assuming HELP isn't working so that future tests won't bomb on me!
         diag ("Help is behaving strangely.  Option OverrideHELP is required after all for our testing.");
         add_extra_arguments_to_config ('OverrideHELP', 1);
         ok ( 1, "The help command has been disabled!");
      }
      $ftps->quit ();
   };
   if ( $@ ) {
      diag ("Help is broken.  Option OverrideHELP is required after all for this server.");
      add_extra_arguments_to_config ('OverrideHELP', 1);      # Assume all FTP commands supported.
      ok ( 1, "The help command remains disabled!");
   }

   write_to_log ($ftps, "LOG ENDING", "Closing the log for the HELP Override test.\n");

   return;
}


# -----------------------------------------------------------------------------
# Test for Bug # 61432 (Where PASV returns wrong IP Address)
# Bug's not in my software, but on the server side!
# But still need tests for it in this script so all test cases will work.
# On failure, the script will abort after writing ok(0,...);
# So that "make test" will see the failure.  Otherwise the tester thinks all is
# OK when all the other tests are skipped over!
# -----------------------------------------------------------------------------
sub check_for_pasv_issue {
   my ( $host, $ftps_opts, $user, $pass ) = ( shift, shift, shift, shift );

   my %loc_args = %{$ftps_opts};

   my $crypt = $loc_args{Encryption};

   my $ftps = Net::FTPSSL->new ( $host, \%loc_args );
   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created for OverridePASV test' );
   stop_testing  unless ( $res );

   $res = $ftps->trapWarn ();

   write_to_log ($ftps, "WARNING", "Trying to determine if PASV returns the wrong IP Address ...");

   $res = $ftps->login ($user, $pass);
   ok ( $res, "Login Successful!  Your credentials are still good for the OverridePASV test!" );

   # WARNING: Do not copy this code, it calls internal undocumented functions
   # that probably changes between releases.  I'm the developer, so I will keep
   # any changes here in sync with future releases.  But I need this low
   # level access to see if the FTPS server set up PASV correctly through the
   # firewall. (Bug 61432)  Should be fairly rare to see it fail ...

   if ( $crypt ne CLR_CRYPT ) {
      $ftps->_pbsz ();
      unless ($ftps->_prot ()) {
         ok( 0, "Setting up data channel in check_for_pasv_issue() failed!" );
         stop_testing ();
      }
   }

   my ($h, $p) = $ftps->_pasv ();

   write_to_log ($ftps, "WARNING", "Calling _open_data_channel ($h, $p)");

   # Can we open up the returned data channel ?
   if ( $ftps->_open_data_channel ($h, $p) ) {
      $ftps->_abort();
      $ftps->quit ();
      write_to_log ($ftps, "LOG ENDING", "Closing the log for the PASV test.\n");
      ok ( 1, "PASV works fine ..." );
      return;
   }

   # Very, very rare to get this far ...
   write_to_log ($ftps, "WARNING", "Attempting to reopen the same data channel using OveridePASV");

   if ( $ftps->_open_data_channel ($host, $p) ) {
      write_to_log ($ftps, "WARNING", "Success!");
      diag ("\nThis server has issues with returning the correct IP Address via PASV.");
      diag ("You Must use OverridePASV when calling new() for this server!");
      diag ("Adding this option for all further testing.");

      write_to_log ($ftps, "WARNING", "Must use OverridePASV ...");
      $ftps_opts->{OverridePASV} = $host;      # Things should now work!
      add_extra_arguments_to_config ('OverridePASV', $host);

      $ftps->_abort();
      $ftps->quit ();
      write_to_log ($ftps, "LOG ENDING", "Closing the log for the PASV test.\n");
      ok (1, "Using OverridePASV is required for this server.");
      return;
   }

   # It's even rarer to get here ...

   $ftps->quit ();
   write_to_log ($ftps, "LOG ENDING", "Closing the log for the PASV test.  Last ditch effort!\n");

   return;
}

