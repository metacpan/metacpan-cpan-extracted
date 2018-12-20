# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/30-more_put_delete_tests.t'

#########################

# This test script tests out the various put() variants & listing variants.
# Doing the following type's of tests!
#    1) put
#    2) append
#    3) uput
#    4) uput2
#    5) transfer
#    6) nlst
#    7) list
#    8) deletes everything uploaded.

# It is OK for some tests to fail here if a particular FTP command isn't
# supported by your FTPS server or your account doesn't have permission
# to perform that test!

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
   my $name1 = $base_name . ".001-default.log.txt";
   my $name2 = $base_name . ".002-transfer.log.txt";

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
   my $ftps = initialize_your_connection ($name1);

   # -----------------------------------------------------
   # Verifying you are allowed to run these tests ...
   # I can only verify if the server supports a cmd, not
   # if your account has enough privileges to run them.
   # We find that out if commands start to fail!
   # -----------------------------------------------------
   unless ( are_updates_allowed () ) {
      ok ( 1, "Skipping the more put/delete test cases!  Specified read-only access to the FTPS server!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("DELE") ) {
      ok ( 1, "Skipping the more put/delete test cases!  The FTPS server says the delete command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # Must do individually since all_supported() won't for this particular test.
   if ( (! $ftps->supported ("STOR")) &&
        (! $ftps->supported ("APPE")) &&
        (! $ftps->supported ("STOU")) ) {
      ok ( 1, "Skipping the more put/delete test cases!  The FTPS server says none of the put/append/uput command variants are supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # Didn't use supported() here on purpose ...
   my @lst = $ftps->nlst ();
   if ( $ftps->last_status_code () != CMD_OK ) {
      ok ( 1, "Skipping the more put/delete test cases!  The FTPS server says the NLST command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # -------------------------------------------

   ok (1, "All tests should pass unless you don't have enough permission on the FTPS server to run them!" );

   my @upload_list;

   # --------------------------------------------------------------
   # The put tests ... (STOR)
   # Provides the test files used for transfer() which also uses STOR.
   # Which was why we repeated some tests from t/18-*.t.
   # --------------------------------------------------------------
   my @put_list = ( "help_me.bin", "h e l p m e.bin", "helpme" );

   unless ( $ftps->supported ("STOR") ) {
      ok ( 1, "Skipping the 'put' test cases!  The FTPS server says the 'put' command is not supported!" );
   } else {
      write_to_log ( $ftps, "SEPARATOR", "--------------------P--------------------" );
      $ftps->binary ();
      my $b = basename ($bin_file);
      foreach my $f ( @put_list ) {
         my $res = $ftps->put ( $bin_file, $f );
         next  unless ( ok ( $res, "Uploading $b as '$f' via put()" ) );
         push (@upload_list, $f);
      }

      # Upload via an open file handle ...
      my ($fh, $f, $sts);
      open ( $fh, "<", $bin_file );
      binmode ( $fh );
      $sts = $ftps->put ( $fh, $f = "bin file handle.bin" );
      ok ($sts, "put ( <filehandle>, $f ) worked!");
      push (@upload_list, $f)  if ( $sts );
      close ( $fh );
      push (@put_list, $f);
   }


   # --------------------------------------------------------------
   # The append tests ... (APPE)
   # --------------------------------------------------------------
   unless ( $ftps->supported ("APPE") ) {
      ok ( 1, "Skipping the 'append' test cases!  The FTPS server says the 'append' command is not supported!" );
   } else {
      write_to_log ( $ftps, "SEPARATOR", "--------------------A--------------------" );
      my $b = basename ($ascii_file);
      my $f = "append to me.txt";

      ok ( 1, "Append -----------------------------------------------------------" );

      # Doing this way in case put() wasn't supported earlier.
      # Fairly unlikely, but always possible ...
      $ftps->ascii ();
      my $res = $ftps->append ($ascii_file, $f);
      ok ( $res, "Initial upload using 'append'.  Called $f" );
      my $size = $ftps->size ( $f );
      ok ( defined $size, "Got the file's size on the FTPS server! ($size)" );

      push (@upload_list, $f)  if ( $res );

      if ( $res && defined $size ) {
         # Get the number of lines inside the uploaded file ...
         $ftps->binary ();
         my $bs = $ftps->size ($f);
         my $lines = $size - $bs;
         ok ( defined $bs, "The uploaded file had ${lines} lines in it!" );

         # Now the real tests can be done since our tools work ...
         $ftps->ascii ();
         $res = $ftps->append ($ascii_file, $f);
         ok ( $res, "Appending '$f' to the file already uploaded!" );
         my $size2 = $ftps->size ( $f );
         ok ( defined $size2, "Got the file's new size on the FTPS server! ($size2)" );
         my $s2 = 2 * $size;
         ok ( ($size2 == $s2), "The resulting file was the correct size.");

         $ftps->binary ();
         $bs = $ftps->size ($f);
         $lines = $size2 - $bs;
         ok ( defined $bs, "The appended file now has ${lines} lines in it!" );

         # Append to the file a 2nd time ...
         $ftps->ascii ();
         $res = $ftps->append ($ascii_file, $f);
         ok ( $res, "Appending to '$f' again!" );
         my $size3 = $ftps->size ( $f );
         ok ( defined $size2, "Got the file's new size on the FTPS server! ($size3)" );
         my $s3 = 3 * $size;
         ok ( ($size3 == $s3), "The resulting file was the correct size.");

         $ftps->binary ();
         $bs = $ftps->size ($f);
         $lines = $size3 - $bs;
         ok ( defined $bs, "The appended file now has ${lines} lines in it!" );
      }
      ok ( 1, "End Append -------------------------------------------------------" );
   }


   # --------------------------------------------------------------
   # The uput tests ... (STOU)
   # --------------------------------------------------------------
   unless ( $ftps->supported ("STOU") ) {
      ok ( 1, "Skipping the 'uput' test cases!  The FTPS server says the 'uput' command is not supported!" );

   } else {
      my $f;
      $ftps->ascii ();
      $f = uput_test ( $ftps, $ascii_file, "hello.txt" );
      push (@upload_list, $f)  if ( $f );
      $f = uput_test ( $ftps, $ascii_file, "hello.txt" );        # Again ...
      push (@upload_list, $f)  if ( $f );
      $f = uput_test ( $ftps, $ascii_file, "h e l l o.txt" );
      push (@upload_list, $f)  if ( $f );
      $f = uput_test ( $ftps, $ascii_file, "h e l l o.txt" );    # Again ...
      push (@upload_list, $f)  if ( $f );

      # Originally uploaded via the "put" test as a binary file.
      # Reloading it here with an ascii file ...
      # It shouldn't overwite anything.
      if ( $ftps->supported ("STOR") ) {
         $f = uput_test ( $ftps, $ascii_file, $put_list[0] );
         push (@upload_list, $f)  if ( $f );
      }
   }

   # --------------------------------------------------------------
   # The uput2 tests ... (STOU)
   # Already know the needed nlst() command is supported.
   # --------------------------------------------------------------
   unless ( $ftps->supported ("STOU") ) {
      ok ( 1, "Skipping the 'uput2' test cases!  The FTPS server says the 'uput' command is not supported!" );

   } else {
      my ($f, $d, $fh);
      $ftps->ascii ();

      ok ( 1, "uput2 -----------------------------------------------------------" );
      $f = $ftps->uput2 ( $ascii_file );
      ok ($f, "uput2 ( $ascii_file ) worked!  Uploaded as '$f'");
      push (@upload_list, $f)  if ( $f && $f ne "?" );

      $f = $ftps->uput2 ( $ascii_file, $d = "hello.txt" );
      ok ($f, "uput2 ( $ascii_file, $d ) worked!  Uploaded as '$f'");
      push (@upload_list, $f)  if ( $f && $f ne "?" );

      $f = $ftps->uput2 ( $ascii_file, $d = "b e l l o w.txt" );
      ok ($f, "uput2 ( $ascii_file, $d ) worked!  Uploaded as '$f'");
      push (@upload_list, $f)  if ( $f && $f ne "?" );

      open ( $fh, "<", $ascii_file );
      $f = $ftps->uput2 ( $fh, $d = "by file handle.txt" );
      ok ($f, "uput2 ( <filehandle>, $d ) worked!  Uploaded as '$f'");
      push (@upload_list, $f)  if ( $f && $f ne "?" );
      close ( $fh );
      ok ( 1, "End uput2 -------------------------------------------------------" );
   }

   # --------------------------------------------------------------
   # The transfer tests between 2 remote FTPS servers ...
   # No local copy of the file is made!
   # Both connections point to the same directory on the
   # same FTPS server.
   # --------------------------------------------------------------
   if ( ! $ftps->supported ("STOR") ) {
      ok ( 1, "Skipping the 'transfer' test cases!  The FTPS server says the 'put' command is not supported!" );
   } elsif ( ! $ftps->supported ("RETR") ) {
      ok ( 1, "Skipping the 'transfer' test cases!  The FTPS server says the 'get' command is not supported!" );
   } else {
      write_to_log ( $ftps, "SEPARATOR", "--------------------T--------------------" );
      my $other_ftps = initialize_your_connection ($name2);

      $ftps->binary ();
      $other_ftps->binary ();

      foreach my $f ( @put_list ) {
         my $f2 = "transfer_" . $f;
         write_to_log ( $ftps, "PART", "------------------- ${f} -------------------" );
         write_to_log ( $other_ftps, "PART", "------------------- ${f2} -------------------" );
         my $res = $ftps->transfer ( $other_ftps, $f, $f2 );
         ok ( $res, "Transfer of '$f' Succeeded as '$f2'" );
         push (@upload_list, $f2)  if ( $res );
      }

      $other_ftps->quit ();
   }


   # --------------------------------------------------------------
   # Now that we have files on the server, lets try the NLST & LIST commands!
   # Some of these tests have issues with spaces in the file's name!
   # --------------------------------------------------------------
   nlst_tests ($ftps, \@lst, \@upload_list);    # No issue.
   list_tests ($ftps, \@lst, \@upload_list);    # Has issues.

   # --------------------------------------------------------------
   # The delete tests ... (DELE)  [ Already know it's supported ]
   # --------------------------------------------------------------

   write_to_log ( $ftps, "SEPARATOR", "--------------------D--------------------" );
   foreach my $f ( @upload_list ) {
      my $res = $ftps->delete ( $f );
      ok ( $res, "Deleted file '$f' on the SFTP server!" );
   }

   # --------------------------------------------------------------

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================
# WARNING: When using "LIST" with pattern matching, LIST has issues with
#          files with spaces in the name.  Since you'd like the pattern
#          only to apply to the file's name, not the leading junk!
#
# Example:
#   1) -rwxrwx--- 1 owner group          512 Oct 27  2009 owner_m e.txt
#   2) -rwxrwx--- 1 owner group         1512 Oct 27  2009 owner_you.txt
# ==>  Searching for "*.txt" would find both files.
# ==>  But "owner*" would only find the 2nd file.
#
# That's because I haven't yet figured out a way to reliably ignore the
# leading junk yet.  The leading junk varies widely by server and
# sometimes between lines on the same server!  (Old vs New files)
# 

sub list_tests
{
   my $ftps   = shift;
   my $orig   = shift;    # From the original nlst call ...
   my $upload = shift;    # The new files I expect to find ...

   # List which files we know about on the FTPS server ...
   # There may be some overlap ..
   my %data;
   foreach (@{$orig})   { $data{$_} = 1; }   # Stale files
   foreach (@{$upload}) { $data{$_} = 2; }   # New files

   # Collect some stats on what we expect to find ...
   my ($cnt, $bcnt, $tcnt, $xcnt, $xcnt_space) = (0, 0, 0, 0, 0);

   my ($space, $no_space) = ("", "");
   foreach my $f (sort keys %data) {
      ++$cnt;

      # LIST has issues searching for files with spaces in thier name!
      my $space_in_name_flag = ( $f =~ m/\s/ ) ? 1 : 0;

      # Get the 1st file that matches each criteria ...
      $no_space = $f  if ( $no_space eq "" && ! $space_in_name_flag );
      $space = $f     if ( $space eq ""    && $space_in_name_flag );

      # These patterns don't have any issues matching files with spaces ...
      ++$bcnt  if ( $f =~ m/[.]bin$/ );
      ++$tcnt  if ( $f =~ m/[.]txt$/ );

      # This pattern has issues with spaces in the file name ...
      if ( $f =~ m/^transfer_/ ) {
         ++$xcnt;
         ++$xcnt_space  if ( $space_in_name_flag );
      }
   }

   write_to_log ( $ftps, "SEPARATOR", "--------------------L--------------------" );

   # This is the 1st time I tried the list command out ...
   my @lst = sort $ftps->list ();
   if ( $ftps->last_status_code () != CMD_OK ) {
      ok (1, "The list() command wasn't supported!  So skipping these tests!");
      return;
   }

   my $tlt = @lst;
   ok ( $cnt == $tlt, "LIST call returned the correct number of files ($cnt vs $tlt)" );
   write_to_log ( $ftps, "LFOUND-1", join ("\nLFOUND-1: ", @lst) );

   if ( $no_space ne "" ) {
      @lst = sort $ftps->list (undef, $no_space);
      $tlt = @lst;
      ok ( 1 == $tlt, "LIST call with pattern '$no_space' found one match!" );
      write_to_log ( $ftps, "LFOUND-2", join (", ", @lst) );
   }

   if ( $space ne "" ) {
      @lst = sort $ftps->list (undef, $space);
      $tlt = @lst;
      ok ( 1 == $tlt, "LIST call with pattern '$space' found one match!" );
      write_to_log ( $ftps, "LFOUND-3", join (", ", @lst) );
   }

   if ( $bcnt > 0 ) {
      @lst = sort $ftps->list (undef, "*.bin");
      $tlt = @lst;
      ok ( $bcnt == $tlt, "LIST call with pattern '*.bin' found ${bcnt} matches!" );
      write_to_log ( $ftps, "LFOUND-4", join (", ", @lst) );
   }

   if ( $tcnt > 0 ) {
      @lst = sort $ftps->list (undef, "*.txt");
      $tlt = @lst;
      ok ( $tcnt == $tlt, "LIST call with pattern '*.txt' found ${tcnt} matches!" );
      write_to_log ( $ftps, "LFOUND-5", join (", ", @lst) );
   }

   if ( $xcnt > 0 ) {
      @lst = sort $ftps->list (undef, "transfer_*");
      $tlt = @lst;
      my $range_ok = ( (($xcnt - $xcnt_space) <= $tlt) && ($tlt <= $xcnt) );
      ok ( $range_ok, "LIST call with pattern 'transfer_*' found ${tlt} of ${xcnt} possible matches!" );
      write_to_log ( $ftps, "LFOUND-6", join (", ", @lst) );
   }

   return;
}

# ===========================================================================
# NOTE: This version doesn't have any issues with spaces in the file's name!

sub nlst_tests
{
   my $ftps   = shift;
   my $orig   = shift;    # From the original nlst call ...
   my $upload = shift;    # The new files I expect to find ...

   # List which files we know about on the FTPS server ...
   # There may be some overlap ..
   my %data;
   foreach (@{$orig})   { $data{$_} = 1; }   # Stale files
   foreach (@{$upload}) { $data{$_} = 2; }   # New files

   # Collect some stats on what we expect to find ...
   my ($cnt, $bcnt, $tcnt, $xcnt) = (0, 0, 0, 0);
   my ($space, $no_space) = ("", "");
   foreach my $f (sort keys %data) {
      ++$cnt;

      # NLST doesn't have issues searching for files with spaces in thier name!
      my $space_in_name_flag = ( $f =~ m/\s/ ) ? 1 : 0;

      # Get the 1st file that matches each criteria ...
      $no_space = $f  if ( $no_space eq "" && ! $space_in_name_flag );
      $space = $f     if ( $space eq ""    && $space_in_name_flag );

      ++$bcnt  if ( $f =~ m/[.]bin$/ );
      ++$tcnt  if ( $f =~ m/[.]txt$/ );
      ++$xcnt  if ( $f =~ m/^transfer_/ );
   }

   write_to_log ( $ftps, "SEPARATOR", "--------------------N--------------------" );
   my @lst = sort $ftps->nlst ();
   my $tlt = @lst;
   ok ( $cnt == $tlt, "NLST call returned the correct number of files ($cnt vs $tlt)" );
   write_to_log ( $ftps, "FOUND-1", join (", ", @lst) );

   if ( $no_space ne "" ) {
      @lst = sort $ftps->nlst (undef, $no_space);
      $tlt = @lst;
      ok ( 1 == $tlt, "NLST call with pattern '$no_space' found one match!" );
      write_to_log ( $ftps, "FOUND-2", join (", ", @lst) );
   }

   if ( $space ne "" ) {
      @lst = sort $ftps->nlst (undef, $space);
      $tlt = @lst;
      ok ( 1 == $tlt, "NLST call with pattern '$space' found one match!" );
      write_to_log ( $ftps, "FOUND-3", join (", ", @lst) );
   }

   if ( $bcnt > 0 ) {
      @lst = sort $ftps->nlst (undef, "*.bin");
      $tlt = @lst;
      ok ( $bcnt == $tlt, "NLST call with pattern '*.bin' found ${bcnt} matches!" );
      write_to_log ( $ftps, "FOUND-4", join (", ", @lst) );
   }

   if ( $tcnt > 0 ) {
      @lst = sort $ftps->nlst (undef, "*.txt");
      $tlt = @lst;
      ok ( $tcnt == $tlt, "NLST call with pattern '*.txt' found ${tcnt} matches!" );
      write_to_log ( $ftps, "FOUND-5", join (", ", @lst) );
   }

   if ( $xcnt > 0 ) {
      @lst = sort $ftps->nlst (undef, "transfer_*");
      $tlt = @lst;
      ok ( $xcnt == $tlt, "NLST call with pattern 'transfer_*' found ${xcnt} matches!" );
      write_to_log ( $ftps, "FOUND-6", join (", ", @lst) );
   }

   return;
}

# ===========================================================================
# Done as a stand alone test function since on some servers it doesn't tell
# you what it calls the file on the FTPS server.  So doing this the hard way!

# This is what uput2() actually does for you.  But in this case it's validating
# things every step of the way.

# Doing it this way also allows me to verify that the returned value is
# actually correct when it does return the uploaded file name.

# Returns: The name of the file on the FTPS server, else undef on failure!

sub uput_test
{
   my $ftps   = shift;
   my $file   = shift;
   my $asFile = shift;

   write_to_log ( $ftps, "SEPARATOR", "-------------------- uput ($file, $asFile) --------------------" );

   my @lst = $ftps->nlst ();
   unless ( ok ( $ftps->last_status_code () == CMD_OK,
                 'nlst() command before uput worked' ) ) {
      return ( undef );    # On failure go no further ...
   }

   # Put into a hash for easier lookup later on.
   my %hsh;
   foreach ( @lst ) { $hsh{$_} = 1; }

   my $upload = $ftps->uput ( $file, $asFile );
   if ( $upload ) {
      ok ( 1, "File uploaded via 'uput' as: $asFile ==> $upload" );
   } else {
      ok ( 0, "File uploaded via 'uput' as: $asFile ==> ???" );
      return ( undef );    # On failure go no further ...
   }

   # ----------------------------------------------------------
   # Now that we know it uploaded OK, lets see if we guessed
   # the filename used correctly!
   # ----------------------------------------------------------

   @lst = $ftps->nlst ();
   ok ( $ftps->last_status_code () == CMD_OK,
        'nlst() command after uput worked' );

   # Build a list of candidates for the final uploaded name.
   my @new;
   my %guess;
   my $cnt = 0;
   foreach ( @lst ) {
      next  if ( $hsh{$_} );   # Already know about this file ...
      push ( @new, $_ );
      $guess{$_} = 1;
      ++$cnt;
   }

   # Determine what the uploaded file was actually called
   # And tell us if our original guess was correct!
   my ( $resDel, $resG ) = ( undef, 0 );    # Assume failure ...
   if ( $cnt == 0 ) {
      # Should never happen ... We handled the failure case earlier ...
      ok ( 0, "The uput command uploaded the file as: ???" );
   } elsif ( $cnt == 1 ) {
      $resDel = $new[0];
      $resG = ( $resDel eq $upload ) ? 1 : 0;
      ok ( 1, "The uput command uploaded the file as: $resDel" );
   } else {
      # Shouldn't ever happen ...
      # Only happens if someone else is also uploading to this directory
      # at the same time this test program does!
      ok ( 0, "The uput command uploaded 1 of $cnt file(s): " . join (",", @new) );

      # Can we guess which one from the list it was?
      if ( $upload ne "?" ) {
         $resG = $guess{$upload};
         $resDel = $upload  if ( $resG );
      }
   }

   # ----------------------------------------------------------
   # Now provide a general statement about the upload.
   # ----------------------------------------------------------
   if ( $upload eq "?" ) {
      my $msg = "'uput' doesn't know the uploaded filename.  The FTPS server won't tell us!";
      if ( $resDel ) {
         $msg .= "  But our guess is that it's: $resDel";
      }
      ok ( 1, $msg );
   } else {
      ok ( $resG, "'uput' returned the correct name on the FTPS server!" );
   }

   return ( $resDel );       # The uploaded file to delete later on!
}

