# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/36-misc_tests.t'

#########################

# This test script tests out the "quot()" function.
# Also tests out the callback functionality using nlst & list.

#########################

use strict;
use warnings;

use Test::More;    # I'm not pre-counting the tests ...
use File::Copy;
use File::Basename;
use File::Spec;

my $ftps_os = "unix";

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
   my $ftps = initialize_your_connection ();

   # Upload everything in ascii mode ...
   $ftps->ascii ();

   # Check if allowed to upload/delete files for the nlst/list callback tests!
   my $updates_ok = 0;
   if ( are_updates_allowed () ) {
      if ( $ftps->all_supported ("DELE", "STOR") ) {
         $updates_ok = 1;       # OK to upload/delete files ...
      }
   }

   # Tell what OS the FTPS server is running on ...
   if ( $ftps->supported ( "SYST" ) ) {
      my $res = $ftps->quot ("SYST");
      ok ( $res == CMD_OK, "The SYST command worked!" );

      $ftps_os = "windows"  if ( $ftps->last_message() =~ m/windows/i );
   }


   # Assuming this default directory has nothing in it unless this test
   # case actually uploads some files to it for us!
   my $home = $ftps->pwd ();

   # For read-only access, assume the root directory more likely
   # to have something in it than our home directory if it's empty!
   # There's no guarentee that it isn't also empty!  Or isn't the
   # same directory.  But it works out better for debugging this test
   # script on my FTPS servers!
   my $mlst_test_file;
   unless ( $updates_ok ) {
      my @lst = $ftps->nlst();
      if ( $#lst == -1 ) {
         $ftps->cwd ("/");
         $home = $ftps->pwd ();
         @lst = $ftps->nlst();
      }
      # Grab one of the returned files in the list ...
      $mlst_test_file = $lst[0]  if ( $#lst != -1 );
   }

   my $res = 1;
   if ( $ftps->supported ("NOOP") ) {
      $res = $ftps->noop ();
   }
   ok ( $res, "Noop test worked or was skipped!" );

   do_quot_test ( $ftps, "NOOP" );
   do_quot_test ( $ftps, "PWD" );

   my %callback_hash;
   $ftps->set_callback (\&callback_func, \&end_callback_func, \%callback_hash);

   # What to call the test files on the FTPS server ...
   my @updt_lst = ("test_file.txt", "test_file.pm", "test file.pz",
                   "Help_File.tif", "help file.txt");

   # Upload the files to better test the callback functions ...
   if ( $updates_ok ) {
      foreach my $f ( @updt_lst ) {
         my $res = $ftps->put ( $ascii_file, $f );
         my $b = basename ( $ascii_file );
         ok ( $res, "Uploaded '$b' as '$f' to the FTPS server." );

         $mlst_test_file = $f  if ( $res && ! defined $mlst_test_file );
      }
   }

   # Tests specifying a directory to query ...
   do_list_test ( $ftps, 1, $home, 'h*', 0 );       # NLST ...
   do_list_test ( $ftps, 0, $home, 'h*', 0 );       # LIST ...
   do_list_test ( $ftps, 2, $home, 'h*', 0 );       # MLSD ...

   do_list_test ( $ftps, 1, $home, '*.p?', 0 );     # NLST ...
   do_list_test ( $ftps, 0, $home, '*.p?', 0 );     # LIST ...
   do_list_test ( $ftps, 2, $home, '*.p?', 0 );     # MLSD ...

   # Tests specifying use the default directory to query ...
   # May behave differently on some servers ...
   do_list_test ( $ftps, 1, undef, '*.p?', 0 );     # NLST ...
   do_list_test ( $ftps, 0, undef, '*.p?', 0 );     # LIST ...
   do_list_test ( $ftps, 2, undef, '*.p?', 0 );     # MLSD ...

   # Tests specifying using the current directory to query ...
   do_list_test ( $ftps, 1, '.', '*.p?', 0 );       # NLST ...
   do_list_test ( $ftps, 0, '.', '*.p?', 0 );       # LIST ...
   do_list_test ( $ftps, 2, '.', '*.p?', 0 );       # MLSD ...

   # Do a test without any filtering in place ...
   do_list_test ( $ftps, 1, undef, '', 1 );         # NLST ...
   do_list_test ( $ftps, 0, undef, '', 1 );         # LIST ...
   do_list_test ( $ftps, 2, undef, '', 1 );         # MLSD ...

   $ftps->set_callback ();    # Disable callbacks again!

   unless ( $ftps->supported ("MLST") ) {
      ok ( 1, "Skipping MLST test, the command isn't supported!" );
   } elsif ( ! $mlst_test_file ) {
      ok ( 1, "Skipping MLST test, there is no reference file on the FTPS server." );
   } else {
      my $res = $ftps->mlst ( $mlst_test_file );
      ok ( $res, "MLST worked.  ($res)" );
      if ( $res ) {
         my $data_ref = $ftps->parse_mlsx ( $res );
         my $name = $data_ref->{";file;"} || "";
         ok ( $name ne "", "parse_mlsx() worked for file: '$name'." );
      }
   }

   # Some hard coded test cases ...
   parse_tests ( $ftps );

   # Delete all the test files uploaded earlier ...
   if ( $updates_ok ) {
      foreach my $f ( @updt_lst ) {
         my $res = $ftps->delete ( $f );
         ok ( $res, "Deleted '$f' from the FTPS server." );
      }
   }

   $ftps->quit ();

   # We're done with the testing.
   stop_testing ();
}

# =====================================================================
sub do_quot_test
{
   my $ftps = shift;
   my $cmd  = shift;

   if ( $ftps->supported ($cmd) ) {
      my $res = $ftps->quot ($cmd);
      ok ($res == CMD_OK, "quot(${cmd}) test worked!");
   } else {
      ok (1, "quot(${cmd}) skipped since not supported!");
   }

   return;
}

# =====================================================================
sub do_list_test
{
   my $ftps     = shift;
   my $nlst_flg = shift;   # 1 - NLST, 0 - LIST, 2 - MLSD
   my $dir      = shift;
   my $pattern  = shift;
   my $same     = shift;   # 0 or 1

   my $lbl1 = "???";
   my $lbl2 = $dir || "undef";
   my @lst;

   if ( $nlst_flg == 0 ) {
      $lbl1 = "list";
   } elsif ( $nlst_flg == 1 ) {
      $lbl1 = "nlst";
   } elsif ( $nlst_flg == 2 ) {
      $lbl1 = "mlsd";
   }

   unless ( $ftps->supported ( $lbl1 ) ) {
      ok (1, "Command ${lbl1} is not supported!");
      write_to_log ($ftps, "END", "-----------------------------------------");
      return;
   }

   if ( $nlst_flg == 0 ) {
      @lst = $ftps->list ($dir);
   } elsif ( $nlst_flg == 1 ) {
      @lst = $ftps->nlst ($dir);
   } elsif ( $nlst_flg == 2 ) {
      @lst = $ftps->mlsd ($dir);
   }
   my $cnt1 = @lst;

   ok ( $ftps->last_status_code() == CMD_OK,
        "${lbl1}(${lbl2}) command with callback returned ${cnt1} row(s)" );
   write_list ( $ftps, uc($lbl1), \@lst );

   if ( $nlst_flg == 0 ) {
      @lst = $ftps->list ($dir, $pattern);
   } elsif ( $nlst_flg == 1 ) {
      @lst = $ftps->nlst ($dir, $pattern);
   } elsif ( $nlst_flg == 2 ) {
      @lst = $ftps->mlsd ($dir, $pattern);
   }
   my $cnt2 = @lst;

   ok ( $ftps->last_status_code() == CMD_OK,
        "${lbl1}(${lbl2}) command with wildcards (${pattern}) returned ${cnt2} row(s)");
   write_list ( $ftps, uc($lbl1), \@lst );

   if ( $same ) {
      ok ( $cnt1 == $cnt2, "Both lists returned same number of rows in the result sets!" );
   } else {
      ok ( $cnt1 != $cnt2, "Both lists returned different result sets!" );
   }

   # Verify we can succesfully parse the 2nd call for its MLSD results ...
   if ( $nlst_flg == 2 ) {
      foreach ( @lst ) {
         my $data_ref = $ftps->parse_mlsx ($_);
         my $name = $data_ref->{";file;"} || "";
         my $cb = $data_ref->{cb} || "no";   # yes if added by callback methods.
         ok ( $name ne "", "parse_mlsx() worked for file: $name" );
      }
   }

   write_to_log ($ftps, "END", "-----------------------------------------");

   return;
}

# =====================================================================
# Writes the array contents to the log file ...

sub write_list
{
   my $ftps = shift;
   my $lbl  = shift;
   my $list = shift;

   foreach my $l ( @{$list} ) {
      write_to_log ($ftps, $lbl, $l);
   }

   return;
}

# =====================================================================
# Called whenever a data channel is being processed ...
# Callbacks added to Net::FTPSSL as of v0.07

sub callback_func
{
   my $ftps_function_name = shift;   # Tells who called me!
   my $data_ref           = shift;   # The data to/from the data channel.
   my $data_len_ref       = shift;   # The size of the data buffer.
   my $total_len          = shift;   # The number of bytes to date.
   my $callback_data_ref  = shift;   # The callback work space.

   if ( $ftps_function_name =~ m/:list$/ ) {
      ${$data_ref} =~ s/[a-z]/\U$&/g;    # Convert to upper case!
      # Reformat #'s Ex: 1234567 into 1,234,567.
      while ( ${$data_ref} =~ s/(\d)(\d{3}\D)/$1,$2/ ) { }
      ${$data_len_ref} = length (${$data_ref});  # May have changed data length!

   } elsif ( $ftps_function_name =~ m/:nlst$/ ) {
      ${$data_ref} =~ s/[a-z]/\U$&/g;    # Convert to upper case!
      # ${$data_ref} =~ s/^/[0]: /gm;      # Add a prefix per line.

      # Make the prefix unique per line ...
      my $cnt = ++$callback_data_ref->{counter};
      while ( ${$data_ref} =~ s/\[0\]/[$cnt]/) {
        $cnt = ++$callback_data_ref->{counter};
      }

      # Fix so counter is correct for next time called!
      --$callback_data_ref->{counter};
      ${$data_len_ref} = length (${$data_ref});  # Changed length of data!

   # Machine listing ...
   } elsif ( $ftps_function_name =~ m/:mlsd$/ ) {
      # Make no changes to the data ..

   # A repeat call for the same unknown FTPS function.
   } elsif ( exists $callback_data_ref->{$ftps_function_name} ) {
      ++$callback_data_ref->{$ftps_function_name};

   # Only happens if the 1st time this callback has been called for a method!
   } else {
      warn " *** Unexpected callback for $ftps_function_name! ***\n";
      $callback_data_ref->{$ftps_function_name} = 1;
   }

   return;
}

# =====================================================================
# Called whenever a data channel is terminated ...
# Callbacks added to Net::FTPSSL as of v0.07
# Returns: Any additional data to add to the end of the data channel ...
#          Only LIST & NLST actually returns anything.

sub end_callback_func
{
   my $ftps_function_name = shift;   # Tells who called me!
   my $total_len          = shift;   # The total number of bytes sent out!
   my $callback_data_ref  = shift;   # The callback work space.

   my $data_channel;

   my @list = ("cars.pl", "Junker", "T-Bird", "Coup", "Model-T",
               "Horse & Buggy", "help.pm", "help me.pl");
   my $sep = "";

   if ( $ftps_function_name =~ m/:nlst$/ ) {
      my $cnt;
      $data_channel = "";

      foreach ( @list ) {
         $cnt = ++$callback_data_ref->{counter};
         $data_channel .= $sep . "$_";
         # $data_channel .= $sep . "[$cnt]: $_";
         $sep = "\n";
      }

      # So the next nlst call will start counting all over again!
      delete ($callback_data_ref->{counter});

   } elsif ( $ftps_function_name =~ m/:list$/ ) {
      $data_channel = "";

      my $prefix;
      if ( $ftps_os eq "unix" ) {
         $prefix = '-rwxrwxrwx 2   cBack           local   100     sep 14 17:40 ';
      } else {
         $prefix = "09-14-18  05:40PM       <virtual>      ";
      }

      foreach ( @list ) {
         $data_channel .= $sep . $prefix . $_;
         $sep = "\n";
      }

   } elsif ( $ftps_function_name =~ m/:mlsd$/ ) {
      $data_channel = "";

      my $dir  = "modify=20181016153306;perm=fle;size=4096;type=dir;cb=yes;unique=8000000A00000007U2;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; ";
      my $file = "modify=20130124220103;perm=dfr;size=1074;type=file;cb=yes;unique=8000000A00000004U6D3;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; ";
      my $prefix = $dir;

      foreach ( @list ) {
         # Alternate between the 2 prefixes ...
         $prefix = ( $dir eq $prefix ) ? $file : $dir;
         $data_channel .= $sep . $prefix . $_;
         $sep = "\n";
      }

   # The other callback already logged this function, so no need
   # to repeat it here.  It's deleted so that any new call to
   # this function will show up in the logs next time.
   } elsif ( exists $callback_data_ref->{$ftps_function_name} ) {
      my $cnt = $callback_data_ref->{$ftps_function_name};
      delete $callback_data_ref->{$ftps_function_name};

   # Only happens if the other callback is never called for a method!
   # This happens more often than you'd think.
   } else {
      warn " *** Unexpected end callback for $ftps_function_name! ***\n";
   }

   return ($data_channel);
}

# =====================================================================
# Does static hard coded validation of the parse_mlsx() function ...

sub parse_tests
{
   my $ftps = shift;

   my @good_cmds = (
     "modify=20180902080303;perm=fle;size=4096;type=cdir;unique=8000000A00000004U2;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; .",
     "modify=20180902080303;perm=fle;size=4096;type=pdir;unique=8000000A00000004U2;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; ..",
     "modify=19700105074701;perm=fle;size=256;type=dir;unique=8000000A00000004UD;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; .SPOTLIGHT",
     "modify=20140219200821;perm=adfr;size=758;type=file;unique=8000000A00000004U13;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; .profile",
     "modify=20170816202854;perm=adfr;size=14;type=OS.unix=symlink;unique=8000000A0000000EU8;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; honey.txt",
     "modify=20130124220103;perm=dfr;size=1074;type=file;unique=8000000A00000004U6D3;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; my own file.log",
     "modify=20170816202854;perm=adfr;size=8;type=OS.unix=symlink;unique=8000000A00000007U10060;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; lib",
     "modify=20170816202854;perm=adfr;size=14;type=OS.unix=symlink;unique=8000000A0000000EU8;UNIX.group=208;UNIX.groupname=ftpapp;UNIX.mode=0444;UNIX.owner=17590;UNIX.ownername=xixUvYCt; one; big; game.txt",
     "type=; unknown type.txt",
     "; no features.txt"
     );

   my @bad_cmds = (
     "type=file",
     "type=dir;",
     "type=pdir; ",
     "abc",
     "abc;",
     "abc; ",
     "abc; file.txt",
     "; ",
     ""
     );

   foreach ( @good_cmds ) {
      my $data = $ftps->parse_mlsx ( $_ );
      if ( $data ) {
         my $file = $data->{";file;"};
         my $type = (exists $data->{type}) ? $data->{type} : "<undef>";
         ok ( 1, "Parse succeeded for file: '${file}'  Type: ${type}" );
      } else {
         ok ( 0, "Parse succeeded for file: '<unknown>'  Type: <unknown>" );
      }
   }

   foreach ( @bad_cmds ) {
      my $data = $ftps->parse_mlsx ( $_ );
      unless ( $data ) {
         ok ( 1, "Parse failed as expected: '$_'" );
      } else {
         ok ( 0, "Parse failed as expected: '$_'" );
      }
   }

   return;
}

# =====================================================================

