# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/22-supported.t'

#########################

# This test script tests out if the "supported" function works on this server!
# It is OK for some tests to fail here if a particular FTP command isn't
# supported by your FTPS server!

# Assumes that t/20-test_multiple_connections.t 100% passed it's tests!

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
   my $name0 = $base_name . "-000.base_test.log.txt";
   my $name1 = $base_name . "-001.OverrideHELP_1.log.txt";
   my $name2 = $base_name . "-002.OverrideHELP_0.log.txt";
   my $name3 = $base_name . "-003.OverrideHELP_minus_1.log.txt";
   my $name4 = $base_name . "-004.OverrideHELP_array_1.log.txt";
   my $name5 = $base_name . "-005.OverrideHELP_array_2.log.txt";

   # Turns on enhanced debug logging ...
   # Not for general use, only used here since debugging supported()!
   my $ftps = initialize_your_connection ( $name0, Debug => 99 );

   # The options used to establish the connection ...
   my $opts = get_opts_set_in_init ();

   # -------------------------------------------------------
   # Verifying supported() & _help() work as expected.
   # Must check logs for _help() success, since it returns a hash reference.
   # -------------------------------------------------------
   ok2 ( $ftps, 1, "*** Starting Log: ${name0} ***" );

   if ( exists $opts->{OverrideHELP} ) {
      # Should only happen if we auto-detected that your server doesn't
      # support the HELP command.  But also allowing for you hacking
      # your config file.
      which_override_was_used ( $ftps, $opts->{OverrideHELP} );

   } elsif ( ! $ftps->supported ("HELP" ) ) {
      ok2 ( $ftps, 1, "Must use OverrideHELP to run these tests.  HELP not supported!" );
      add_extra_arguments_to_config ('OverrideHELP', 1);

   } else {
      # Path that is executed for most FTPS servers ...
      # Chose common functions that should almost always be supported!

      ok2 ( $ftps, $ftps->supported("HELP"), "Checking if HELP is supported" );

      ok2 ( $ftps, $ftps->_help("HELP"), "Getting the HELP usage" );  # Never fails
      ok2 ( $ftps, 1, "--- " .  $ftps->last_message() . " ---");

      ok2 ( $ftps, $ftps->_help("HELP"), "Getting the HELP usage again (cached?)" );
      ok2 ( $ftps, 1, "--- " .  $ftps->last_message() . " -- (cached?) --");

      ok2 ( $ftps, $ftps->supported("PWD"), "Checking if PWD is supported" );
      ok2 ( $ftps, 1, "--- " .  $ftps->last_message() . " ---");

      my $site = $ftps->supported("SITE");
      if ( $site ) {
         ok2 ( $ftps, 1, "Checking if SITE is supported" );
      } else {
         ok2 ( $ftps, 1, "The SITE command wasn't supported!");
      }
      ok2 ( $ftps, 1, "--- " .  $ftps->last_message() . " ---");

      ok2 ( $ftps, $ftps->supported("HELP"), "Checking HELP supported again (cached?)" );
      ok2 ( $ftps, ! $ftps->supported("BADCMD"), "Verifying BADCMD isn't supported" );
      if ( $site ) {
         ok2 ( $ftps, ! $ftps->supported("SITE", "BADCMD"), "Verifying SITE BADCMD isn't supported" );
      }

      ok2 ( $ftps, $ftps->_help("BADCMD"), "Getting the BADCMD usage" );  # Never fails

      my $res = $ftps->all_supported ("USER", "PASS");
      ok2 ( $ftps, $res, "Both USER & PASS are supported!");
      $res = $ftps->all_supported ("USER", "PASS", "WALL");
      ok2 ( $ftps, ! $res, "Both USER & PASS are supported, but WALL isn't supported!");

      run_site_tests ( $ftps );
      run_feat_tests ( $ftps );
   }

   $ftps->quit ();

   # ---------------------------------------------------------------------------
   # Now lets test out the individual OverrideHELP use cases ...
   # ---------------------------------------------------------------------------

   ok2 ( $ftps, 1, "*** Starting Log: ${name1} ***" );
   $ftps = initialize_your_connection ( $name1, Debug => 99, OverrideHELP => 1 );
   override_help_1 ( $ftps );
   $ftps->quit ();

   ok2 ( $ftps, 1, "*** Starting Log: ${name2} ***" );
   $ftps = initialize_your_connection ( $name2, Debug => 99, OverrideHELP => 0 );
   override_help_0 ( $ftps );
   $ftps->quit ();

   ok2 ( $ftps, 1, "*** Starting Log: ${name3} ***" );
   $ftps = initialize_your_connection ( $name3, Debug => 99, OverrideHELP => -1 );
   override_help_minus_1 ( $ftps );
   $ftps->quit ();

   my @cmds_1 = qw / USER PASS HELP /;   # Help should still fail!
   my @cmds_2 = qw / USER PASS /;

   ok2 ( $ftps, 1, "*** Starting Log: ${name4} ***" );
   $ftps = initialize_your_connection ( $name4, Debug => 99, OverrideHELP => \@cmds_1 );
   override_help_array ( $ftps, \@cmds_1 );
   $ftps->quit ();

   ok2 ( $ftps, 1, "*** Starting Log: ${name5} ***" );
   $ftps = initialize_your_connection ( $name5, Debug => 99, OverrideHELP => \@cmds_2 );
   override_help_array ( $ftps, \@cmds_2 );
   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# ----------------------------------------------------
# Added in case individaul commands in the hash have
# been disabled.
sub find_first_active_cmd
{
   my $ftps     = shift;
   my $hash_ref = shift;    # A hash reference to a list of commands!
   my $always   = shift;    # If non-zero, there are no disabled cmds in hash.

   my @lbls = qw / SITE FEAT OPTS /;

   my $cmd;
   if ( scalar (keys %{$hash_ref}) > 0 ) {
      foreach (sort keys %{$hash_ref}) {
         next   if ( $_ eq "HELP" );  # Disabled in many cases!

         if ( $always || $hash_ref->{$_} ) {
            $cmd = $_;
            last;
         }
      }
      my $lbl = $lbls[$always];
      write_to_log ($ftps, "${lbl} Choices", join (", ", sort keys %{$hash_ref}));
   }

   return ( $cmd );
}

# ----------------------------------------------------
sub run_site_tests
{
   my $ftps = shift;

   unless ( $ftps->supported ("SITE") ) {
      ok2 ( $ftps, 1, "SITE is not supported!" );

   } else {
      ok2 ( $ftps, 1, "SITE is supported!" );

      my $cmd = find_first_active_cmd ( $ftps, $ftps->_help ("SITE"), 0 );

      if ( $cmd ) {
         ok2 ( $ftps, $ftps->supported("SITE", $cmd),
              "Verifying \"supported ('SITE', $cmd)\" is supported" );
         $cmd = "JUNK-FOOD";
         ok2 ( $ftps, ! $ftps->supported("SITE", $cmd),
              "Verifying \"supported ('SITE', $cmd)\" is NOT supported" );
      } else {
         ok2 ( $ftps, 1, "Verified \"supported ('SITE', <cmd>)\" is not supported!  List of SITE cmds not available" );
      }
   }

   return;
}

# ----------------------------------------------------

sub run_feat_tests
{
   my $ftps = shift;

   unless ( $ftps->supported ("FEAT") ) {
      ok2 ( $ftps, 1, "FEAT is not supported!" );
   } else {
      ok2 ( $ftps, 1, "FEAT is supported!" );

      my $opt;
      # my $cmd = find_first_active_cmd ( $ftps, $opt = $ftps->_help ("FEAT"), 1 );
      my $cmd = find_first_active_cmd ( $ftps, $opt = $ftps->_feat (), 1 );

      if ( $cmd ) {
         ok2 ( $ftps, $ftps->supported("FEAT", $cmd),
              "Verifying \"supported ('FEAT', $cmd)\" is supported" );

         $cmd = "JUNK-FOOD";
         ok2 ( $ftps, ! $ftps->supported("FEAT", $cmd),
              "Verifying \"supported ('FEAT', $cmd)\" is NOT supported" );

         if ( $ftps->supported("FEAT", "OPTS") ) {
            ok2 ( $ftps, 1, "There are FEAT commands you may modify using OPTS!" );
            $cmd = find_first_active_cmd ( $ftps, $opt->{OPTS}, 2 );
            ok2 ( $ftps, $ftps->supported("OPTS", $cmd),
                 "Verifying \"supported ('OPTS', $cmd)\" is supported" );
         } else {
            ok2 ( $ftps, 1, "There are no FEAT commands you may modify using OPTS!" );
         }
      } else {
         ok2 ( $ftps, 1, "Verified \"supported ('FEAT', <cmd>)\" is not supported!  List of FEAT cmds not available" );
      }
   }

   return;
}

# ----------------------------------------------------

sub which_override_was_used
{
   my $ftps = shift;
   my $opt  = shift;

   # Check for programming error ...
   unless ( defined $opt ) {
      ok2 ( $ftps, 0, "OverrideHELP was used!" );
      return;
   }

   # This one shouldn't be possible since can't put into config file.
   if ( ref ( $opt ) eq "ARRAY" ) {
      override_help_array ( $ftps, $opt );

   } elsif ( $opt == -1 ) {
      override_help_minus_1 ( $ftps );

   } elsif ( $opt == 0 ) {
      override_help_minus_0 ( $ftps );

   } else {
      override_help_1 ( $ftps );
   }

   return;
}

# ----------------------------------------------------
# How to test the individual overrides ...
# ----------------------------------------------------

# Only the specified commands are supported ...
sub override_help_array
{
   my $ftps = shift;
   my $cmds = shift;

   my ($res1, $res2);
   my $legal = join (", ", @{$cmds});

   ok2 ( $ftps, 1, 'Running OverrideHELP => \@legal_commands' );
   ok2 ( $ftps, 1, "The requested commands are: $legal" );

   ok2 ( $ftps, ! $ftps->supported("HELP"), "HELP is not supported!" );
   ok2 ( $ftps, ! $ftps->supported("BAD-GUY"), "BAD-GUY is not supported!" );
   ok2 ( $ftps, ! $ftps->supported("WALL"), "WALL is not supported!" );

   $res1 = $ftps->all_supported ("USER", "PASS");
   ok2 ( $ftps, $res1, "Both USER & PASS are supported!" );

   $res2 = $ftps->all_supported ("USER", "PASS", "WALL");
   ok2 ( $ftps, $res1 && ! $res2, "Both USER & PASS are supported, but WALL wasn't!" );

   $res2 = $ftps->all_supported ("USER", "PASS", "HELP");
   ok2 ( $ftps, $res1 && ! $res2, "Both USER & PASS are supported, but HELP wasn't!" );

   # Shouldn't do anything since neither command is in the list of commands!
   run_site_tests ( $ftps );
   run_feat_tests ( $ftps );

   return;
}

# ----------------------------------------------------
# Only FEAT commands are supported ...
sub override_help_minus_1
{
   my $ftps = shift;
   ok2 ( $ftps, 1, 'Running OverrideHELP => -1  (FEAT)' );
   ok2 ( $ftps, ! $ftps->supported("HELP"), "HELP is not supported!" );

   # Should't be in the list of FEAT commands ...
   run_site_tests ( $ftps );
   run_feat_tests ( $ftps );

   ok2 ( $ftps, 1, "No other tests performed!" );

   return;
}

# ----------------------------------------------------
# Nothing is supported ...
sub override_help_0
{
   my $ftps = shift;

   my ($res, $res2);
   ok2 ( $ftps, 1, 'Running OverrideHELP => 0' );
   ok2 ( $ftps, 1, "All calls to 'supported()' return FALSE!" );
   ok2 ( $ftps, ! $ftps->supported("HELP"), "HELP is not supported!" );
   ok2 ( $ftps, ! $ftps->supported("BAD-GUY"), "BAD-GUY is not supported!" );

   $res = $ftps->all_supported ("USER", "PASS", "WALL");
   if ( $res ) {
      # All 3 were marked as supported, something was seriously wrong!
      $res = ok2 ( $ftps, 0, "All 3 commands (USER, PASS, WALL) are not supported!" );
   } else {
      my $cnt = 0;
      foreach ("USER", "PASS", "WALL") {
         $res = $ftps->supported ($_);
         $cnt += 1  unless ($res);
      }
      $res = ok2 ( $ftps, $cnt == 3, "All 3 commands (USER, PASS, WALL) are not supported!  ($cnt of 3)" );
   }

   $res2 = $ftps->all_supported ("USER", "PASS", "HELP");
   my $cnt = 0;
   foreach ("USER", "PASS", "WALL") {
      $res = $ftps->supported ($_);
      $cnt += 1  unless ($res);
   }
   ok2 ( $ftps, ($cnt == 3 && ! $res2), "All 3 commands (USER, PASS, HELP) are not supported!" );

   # Should skip the tests since neither are supported ...
   run_site_tests ( $ftps );
   run_feat_tests ( $ftps );

   return;
}

# ----------------------------------------------------
# Everything is supported ... (except HELP)
sub override_help_1
{
   my $ftps = shift;

   my ($res, $res2);
   ok2 ( $ftps, 1, 'Running OverrideHELP => 1' );
   ok2 ( $ftps, 1, "All calls to 'supported()' return true except for the HELP command!" );
   ok2 ( $ftps, ! $ftps->supported("HELP"), "HELP is the only command not supported!" );
   ok2 ( $ftps, $ftps->supported("BAD-GUY"), "BAD-GUY is supported!" );

   $res = $ftps->all_supported ("USER", "PASS", "WALL");
   ok2 ( $ftps, $res, "All 3 commands (USER, PASS, WALL) are supported!" );

   $res2 = $ftps->all_supported ("USER", "PASS", "HELP");
   ok2 ( $ftps, $res && ! $res2, "Both USER & PASS are supported, but HELP wasn't!" );

   # These functions figure out if SITE & FEAT are really supported
   # so that the tests won't fail if they really aren't supported.
   run_site_tests ( $ftps );
   run_feat_tests ( $ftps );

   return;
}

