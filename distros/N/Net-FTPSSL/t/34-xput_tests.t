# Before 'make install' is performed this script should be runnable with
# `make test'. After 'make install' it should work as 'perl ./t/34-xput_tests.t'

#########################

# This test script tests out the x*() functions ...
# Does the following type's of tests!
#    1) xput
#    2) xget
#    3) xtransfer
#    4) deletes everything uploaded.

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
   my $name2 = $base_name . ".002-xtransfer.log.txt";

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
   my $ftps = initialize_your_connection ($name1, "xWait" => 1);

   # -----------------------------------------------------
   # Verifying you are allowed to run these tests ...
   # I can only verify if the server supports a cmd, not
   # if your account has enough privileges to run them.
   # We find that out if commands start to fail!
   # -----------------------------------------------------
   unless ( are_updates_allowed () ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  Specified read-only access to the FTPS server!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("DELE") ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  The FTPS server says the 'delete' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("STOR") ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  The FTPS server says the 'xput' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->supported ("RETR") ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  The FTPS server says the 'xget' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   unless ( $ftps->all_supported ("RNFR", "RNTO") ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  The FTPS server says the 'rename' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # Didn't use supported() here on purpose ...
   my @lst = $ftps->nlst ();
   if ( $ftps->last_status_code () != CMD_OK ) {
      ok ( 1, "Skipping the xput/xget/xtransfer test cases!  The FTPS server says the 'nlst' command is not supported!" );
      $ftps->quit ();
      stop_testing ();
   }

   # -------------------------------------------

   ok (1, "All tests should pass unless you don't have enough permission on the FTPS server to run them!" );

   my @upload_list;      # The files on the FTPS server ...
   my @local_list;       # The files downloaded to the client ...
   my $res;

   # The files to upload to the server ...
   my @put_list = ( "help_me.bin", "h e l p m e.bin", "helpme", "h e l p m e", "fake_text.bin.txt", "f a k e t e x t.txt" );

   # All files are binary files for these tests ...
   # Not sending any ASCII files despite what the file extensions suggest!
   $ftps->binary ();

   # --------------------------------------------------------------
   # The xput tests ... (STOR, RNFR, RNTO)
   # Uploads the test files to use for xget() & xtransfer to use.
   # --------------------------------------------------------------

   write_to_log ( $ftps, "SEPARATOR", "--------------------xput--------------------" );
   my $b = basename ($bin_file);

   $res = $ftps->xput ( $bin_file );
   if ( ok ( $res, "Uploading $b as itself via xput()" ) ) {
      push (@upload_list, $b);
   }

   foreach my $f ( @put_list ) {
      $res = $ftps->xput ( $bin_file, $f );
      next  unless ( ok ( $res, "Uploading $b as '$f' via xput()" ) );
      push (@upload_list, $f);
   }

   # --------------------------------------------------------------
   # The xget tests (RETR)
   # --------------------------------------------------------------
   write_to_log ( $ftps, "SEPARATOR", "--------------------xget--------------------" );
   foreach my $f ( @upload_list ) {
      my $download_file = File::Spec->catfile ($work_dir, $f);
      $res = $ftps->xget ( $f, $download_file );
      next  unless ( ok ( $res, "Downloading '$f' as '$f' via xput()" ) );
      push (@local_list, $download_file);
   }

   # --------------------------------------------------------------
   # The xtransfer tests ... (RETR, STOR, RNFR, RNTO)
   # This tests transfering files between 2 remote FTPS servers ...
   # No local copy of the file is made!
   # Both connections point to the same directory on the
   # same FTPS server for these tests.
   # --------------------------------------------------------------
   write_to_log ( $ftps, "SEPARATOR", "--------------------xtransfer--------------------" );
   my $other_ftps = initialize_your_connection ($name2, "xWait" => 1);
   $other_ftps->binary ();
   foreach my $f ( @put_list ) {
      my $f2 = "xtransfer_" . $f;
      write_to_log ( $ftps, "PART", "------------------- ${f} -------------------" );
      write_to_log ( $other_ftps, "PART", "------------------- ${f2} -------------------" );
      $res = $ftps->xtransfer ( $other_ftps, $f, $f2 );
      ok ( $res, "xtransfer of '$f' Succeeded as '$f2'" );
      push (@upload_list, $f2)  if ( $res );
   }
   $other_ftps->quit ();

   # --------------------------------------------------------------
   # Now that we have files on the server, lets try the NLST
   # commands to verify things with the correct names!
   # --------------------------------------------------------------
   nlst_tests ($ftps, \@lst, \@upload_list);

   # --------------------------------------------------------------
   # The delete tests ... (DELE)  [ Already know it's supported ]
   # --------------------------------------------------------------

   write_to_log ( $ftps, "SEPARATOR", "--------------------Delete--------------------" );
   foreach my $f ( @upload_list ) {
      $res = $ftps->delete ( $f );
      ok ( $res, "Deleted file '$f' on the SFTP server!" );
   }

   # Delete everything downloaded ...
   $res = unlink ( @local_list );
   ok ( $res, "Deleted ${res} downloaded file(s) from the local file system!" );

   # --------------------------------------------------------------

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# ===========================================================================

sub nlst_tests
{
   my $ftps   = shift;
   my $orig   = shift;    # From the original nlst call ... (usually an empty list)
   my $upload = shift;    # The new files I expect to find ...

   # List which files we know about on the FTPS server ...
   # It's possible there may be some overlap if a previous test case
   # run failed to clean up after itself!
   my %data;
   foreach (@{$orig})   { $data{$_} = 1; }   # Stale files
   foreach (@{$upload}) { $data{$_} = 2; }   # New files

   # Collect some stats on what we expect to find ...
   my ($cnt, $bcnt, $tcnt, $xcnt) = (0, 0, 0, 0);
   my ($space, $no_space) = ("", "");
   foreach my $f (sort keys %data) {
      ++$cnt;
      $no_space = $f  if ( $no_space eq "" && $f !~ m/\t/ );
      $space = $f     if ( $space eq ""    && $f =~ m/\t/ );
      ++$bcnt  if ( $f =~ m/[.]bin$/ );
      ++$tcnt  if ( $f =~ m/[.]txt$/ );
      ++$xcnt  if ( $f =~ m/^xtransfer_/ );
   }

   write_to_log ( $ftps, "SEPARATOR", "--------------------NLST--------------------" );
   my @lst = sort $ftps->nlst ();
   my $tlt = @lst;
   ok ( $cnt == $tlt, "NLST call returned the expected number of files ($cnt vs $tlt)" );
   write_to_log ( $ftps, "FOUND-1", join (", ", @lst) );

   # Did we find anything we didn't expect?
   foreach ( @lst ) { ok ( 0, "Expected file: '$_'!" )   unless ( exists $data{$_} ); }

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
      ok ( $bcnt == $tlt, "NLST call with pattern '*.bin' found ${bcnt} matches! " );
      write_to_log ( $ftps, "FOUND-4", join (", ", @lst) );
   }

   if ( $tcnt > 0 ) {
      @lst = sort $ftps->nlst (undef, "*.txt");
      $tlt = @lst;
      ok ( $tcnt == $tlt, "NLST call with pattern '*.txt' found ${tcnt} matches! " );
      write_to_log ( $ftps, "FOUND-5", join (", ", @lst) );
   }

   if ( $xcnt > 0 ) {
      @lst = sort $ftps->nlst (undef, "xtransfer_*");
      $tlt = @lst;
      ok ( $xcnt == $tlt, "NLST call with pattern 'xtransfer_*' found ${xcnt} matches! " );
      write_to_log ( $ftps, "FOUND-6", join (", ", @lst) );
   }

   return;
}

# ===========================================================================

