# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/10-complex.t'

#########################

# Goal here is to give as many success messagse as possible.
# Especially when not all FTP servers support all functions.
# So the logic here can be a bit convoluted.

use strict;
use warnings;

# Uncomment if you need to trace issues with IO::Socket:SSL methods as well.
# Proper values are: debug0, debug1, debug2 & debug3.  3 is the most verbose!
# use IO::Socket::SSL qw(debug3);

use Test::More tests => 86;   # Also update skipper (one less)
use File::Copy;
use File::Basename;
use File::Spec;
use Time::Local;

my $skipper = 85;

# plan tests => 68;  # Can't use due to BEGIN block

BEGIN { use_ok('Net::FTPSSL') }    # Test # 1

sleep (1);  # So test 1 completes before the message prints!

# So can more easily detect warnings instead of trolling my logs.
my ($trap_warnings, $trap_warnings2) = ("", "");

$SIG{__WARN__} = sub { my $x = 1; my $c;
                       while ($c=(caller($x++))[3]) {
                         next  if ($c eq "Net::FTPSSL::_printWarn" || $c eq "Net::FTPSSL::__ANON__");
                         $trap_warnings .= $c . "()  ";
                       }
                       $trap_warnings .= "\n" . $_[0];
                       $trap_warnings2 .= $_[0];
                     };

# These log files need to be global ...
my $debug_log1 = File::Spec->catfile ("t", "BABY_1_new.txt");
my $debug_log2 = File::Spec->catfile ("t", "BABY_2_new.txt");
my $debug_log3 = File::Spec->catfile ("t", "BABY_3_new.txt");
my $debug_log_other = File::Spec->catfile ("t", "10-other_transfer_log.txt");

diag( "" );
diag( "\nYou can also perform a deeper test." );
diag( "Some information will be required for this test:" );
diag( "A secure ftp server address, a user, a password and a directory" );
diag( "where the user has permissions to read and write." );

my $p_flag = proxy_supported ();

my $more_test = ask_yesno("Do you want to make a deeper test");

SKIP: {
    skip ( "Deeper test skipped for some reason...", $skipper ) unless $more_test;

    my( $address, $server, $port, $user, $pass, $dir, $mode, $data, $encrypt_mode, $psv_mode ); 

    $address = ask2("Server address ( host[:port] )", undef, undef, $ENV{FTPSSL_SERVER});
    ( $server, $port ) = split( /:/, $address );
    $port = ""  unless (defined $port);   # Gets rid of warning while FTPSSL provides default port!

    $user = ask2("\tUser", "anonymous", undef, $ENV{FTPSSL_USER});

    $pass = ask2("\tPassword [a space for no password]", "user\@localhost", undef, $ENV{FTPSSL_PWD});

    $dir = ask2("\tDirectory", "<HOME>", undef, $ENV{FTPSSL_DIR});
    $dir = "" if ($dir eq "<HOME>");   # Will ask server for it later on.

    $mode = uc ($ENV{FTPSSL_MODE} || EXP_CRYPT);
    $mode = ask("\tConnection mode (I)mplicit, (E)xplicit, or (C)lear.",
                $mode, "(I|E|C)");

    if ( $mode eq CLR_CRYPT ) {
       $data = $encrypt_mode = "";   # Make sure not undef ...
    } else {
       $data = ask("\tData Connection mode (C)lear or (P)rotected.",
                   DATA_PROT_PRIVATE, "(C|S|E|P)");

       $encrypt_mode = ask("\tUse (T)LS or (S)SL encryption", "T", "(T|S)");
    }
    $encrypt_mode = ($encrypt_mode eq "S") ? 1 : 0;

    $psv_mode = ask("\tUse (P)ASV or (E)PSV for data connections", "P", "(P|E)");

    my $proxy;
    $proxy = ask_proxy_questions ()  if ($p_flag);


    # INET didn't support despite comments elsewhere.
    # my @svrs = split (/,\s*/, $server);
    # if (scalar (@svrs) > 1) { $server = \@svrs; }   # Requested list of servers

    # The main copy of the log file ...
    my $log_file = File::Spec->catfile ("t", "10-complex.txt");

    # The custom copy mentioned in the README file.
    my $copy_file = File::Spec->catfile ("t", "10-complex_log_new.${server}-${mode}-${data}-${encrypt_mode}.txt");

    # -----------------------------------------------------------
    # End of user interaction ...
    # -----------------------------------------------------------

    # This section initializes an unsupported feature to Net::FTPSSL.
    # Code is left here so that I can easily revisit it in the future if needed.
    # That's why option SSL_Client_Certificate is commented out for %ftps_opts
    # below but left uncommented here.  This feature tested in other test file.
    # So do not use this feature here unless you absolutely have no choice!
    my %advanced_hash = ( SSL_version => ($encrypt_mode ? "SSLv23" : "TLSv1"),
                          Timeout => 22 );
    # -----------------------------------------------------------

    my %callback_hash;
    # Delete test files from previous run
    unlink ("./t/test_file_new.tar.gz",
            "./t/FTPSSL.pm_new.tst",
            $log_file, $copy_file,
            $debug_log1, $debug_log2, $debug_log3, $debug_log_other);

    # So we can save the Debug trace in a file from this test.
    # We don't use DebugLogFile for this on purpose so that everything
    # written to STDERR is in the log file, including msgs from this test!
    # But doing it this way is very undesireable in a real program!
    # See test_log_redirection () for correct way to save to a log file.
    open (OLDERR, ">&STDERR");
    open (STDERR, "> $log_file");

    # Leave SSL_Client_Certificate commented out ... Unsupported feature for test ...
    # This hash provides the basic info for all the FTPSSL connections
    # based on the user's answers above.
    my %ftps_opts = ( Port => $port, Encryption => $mode,
                      DataProtLevel => $data, useSSL => $encrypt_mode,
                      # SSL_Client_Certificate => \%advanced_hash,
                      Timeout => 30, Debug => 1, Trace => 1 );

    # Added to allow debugging of the response() code!
    if (exists $ENV{FTPSSL_DEBUG_LEVEL} ) {
       $ftps_opts{Debug} = 99;
    }

    # Set if we are going through a proxy server ...
    if (defined $proxy) {
       $ftps_opts{ProxyArgs} = $proxy;
    }

    unless ( valid_credentials ( $server, \%ftps_opts, $user, $pass, $dir ) ) {
       skip("Can't log into the FTPS Server.  Skipping the remaining tests ...",
            $skipper );
    }
    my $save = $ftps_opts{PreserveTimestamp};   # GMT vs Local Timestamps...

    # Only call if the command channel is encrypted during the test ...
    if ( $mode ne CLR_CRYPT ) {
       # Will dynamically add OverrideHELP for future calls to new() if required ...
       check_for_help_issue ( $server, \%ftps_opts, $user, $pass );
    }

    if ( $psv_mode eq "P" && (! exists $ftps_opts{Pret}) ) {
       # Will dynamically add OverridePASV for future calls to new() if required ...
       unless (check_for_pasv_issue ( $server, \%ftps_opts, $user, $pass, $mode )) {
          skip ( "PASV not working, there are issues with your FTPS server.",
                 $skipper );
       }
    }

    # Put back into hash going forward ...
    $ftps_opts{PreserveTimestamp} = $save;
    $ftps_opts{Croak} = 1;

    # Just needed for some problem servers for xput & xtransfer to work!
    # But probably not needed 99.999% of the time.
    $ftps_opts{xWait} = 1;

    # For testing the transfer option ...
    my %other_opts = %ftps_opts;
    $other_opts{DebugLogFile} = $debug_log_other;

    print STDERR "\n**** Starting the real server test ****\n";
    ($trap_warnings, $trap_warnings2) = ("", "");

    # Writes logs to STDERR which this script redirects to a file ...
    my $ftp = Net::FTPSSL->new( $server, \%ftps_opts );

    isa_ok( $ftp, 'Net::FTPSSL', 'Net::FTPSSL object creation' );

    # Trap where the log file is so we can write warnings to it.
    # my $FTP_LOG_FILE = $ftp->get_log_filehandle ();
    $ftp->trapWarn (1); # Normally has no argument!  Special case for this prog!

    # Uncomment if you want to see the warning logic in action!
    # my $helpless; print "Help: ${helpless}\n";

    # This one writes to it's own log file ... (handles TRANSFERS)
    my $ftp_other = Net::FTPSSL->new( $server, \%other_opts );
    isa_ok( $ftp_other, 'Net::FTPSSL', 'Net::FTPSSL "other" object creation' );

    ok2 ( $ftp->login ($user, $pass), "Login to $server" );
    ok2 ( $ftp_other->login ($user, $pass), "Login to $server" );
    # is ( $trap_warnings, "", "New & Login produce no warnings (OK to fail this test)" );

    # Turning off croak now that our environment is correct!
    $ftp->set_croak (0);
    $ftp_other->set_croak (0);

    if ( $psv_mode ne "P" ) {
       my $t = $ftp->force_epsv (1);
       $psv_mode = ( $t ) ? "1" : "2";
       $t = $ftp->force_epsv (2)  unless ( $t );
       ok2 ( $t, "Force Extended Passive Mode (EPSV $psv_mode)" );
       unless ( $t ) {
         --$skipper;
         skip ( "EPSV not supported, please rerun test using PASV instead!",
                $skipper );
       }
       # Repeat for the other connection.  But no need to test results.
       $t = $ftp_other->force_epsv (1);
       $t = $ftp_other->force_epsv (2)  unless ( $t );
    } else {
       ok2 ( 1, "Using PASV mode for data connections" );
    }

    # Ask for the user's HOME dir if it's not provided!
    $dir = $ftp->pwd ()  unless ($dir);

    # -------------------------------------------------------------------------
    # Verifying extra connections work as expected and don't interfere
    # with the logs for this main test going to STDERR ...
    # Can ignore any warnings from this section ...
    # -------------------------------------------------------------------------
    my ($save_warnings, $save_warnings2) = ($trap_warnings, $trap_warnings2);
    test_log_redirection ( $server, \%ftps_opts, $user, $pass, $psv_mode );
    ($trap_warnings, $trap_warnings2) = ($save_warnings, $save_warnings2);

    # -------------------------------------------------------------------------
    # Back to processing the real test cases ...
    # -------------------------------------------------------------------------
    ok2( $ftp->cwd( $dir ), "Changed the dir to $dir" );
    my $pwd = $ftp->pwd();
    ok2( defined $pwd, "Getting the directory: ($pwd)" );
    $dir = $pwd  if (defined $pwd);     # Convert relative to absolute path.

    ok2( $ftp_other->cwd ($dir), "'Other' Changed the dir to $dir");

    my $res = $ftp->cdup ();
    $pwd = $ftp->pwd();
    ok2 ( $res, "Going up one level: ($pwd)" );

    $res = $ftp->cwd ( $dir );
    $pwd = $ftp->pwd();
    ok2 ( $res, "Returning to proper dir: ($pwd)" );

    # Verifying supported() & _help() work as expected.
    # Must check logs for _help() success, since it returns a hash reference.

    ok2( $ftp->supported("HELP"), "Checking if HELP is supported" );
    ok2( $ftp->_help("HELP"), "Getting the HELP usage" );  # Never fails
    print STDERR "--- " . $ftp->last_message() . " ---\n";

    ok2( $ftp->_help("HELP"), "Getting the HELP usage again (cached?)" );
    print STDERR "--- " . $ftp->last_message() . " -- (cached?) --\n";

    ok2( $ftp->supported("HELP"), "Checking HELP supported again (cached?)" );
    ok2( ! $ftp->supported("BADCMD"), "Verifying BADCMD isn't supported" );
    ok2( ! $ftp->supported("SITE", "BADCMD"), "Verifying SITE BADCMD isn't supported" );
    ok2( $ftp->_help("BADCMD"), "Getting the BADCMD usage" );  # Never fails

    # Verifying we can check out valid SITE sub-commands ...
    # Returns hash ref of valid SITE commands
    my $site = $ftp->_help ("SITE");
    if (scalar (keys %{$site}) > 0) {
       my @sites = sort (keys %{$site});
       ok2( $ftp->supported("SITE", $sites[0]), "Verifying SITE $sites[0] is supported" );
    } else {
       ok2( 1, "verifyed \"supported ('SITE', <cmd>)\" is not supported!  List of SITE cmds not available" );
    }

    ok2( $ftp->noop(), "Noop test" );

    # -----------------------------------------------
    # Start put/uput/get/rename/delete section ...
    # -----------------------------------------------

    # Check if timestamps are preserved via get/put commands ... (Both ends)
    my $supported = $ftp->all_supported ("MFMT", "MDTM");
    
    # Verify's the command works as expected. (Just an FYI test)
    ok2 ( test_mdtm_in_gmt ($ftp) );

    my $spaceFile = "F T P S S L.pm";
    ok2( $ftp->put( './FTPSSL.pm' ), "puting a test ascii file on $dir" );
    ok2( $ftp->put( './FTPSSL.pm', $spaceFile ), "puting a test ascii file with spaces on $dir" );

    # Hiding in its own function since the test has gotten so complex!
    my ( $uput_name, $do_delete ) = uput_test ( $ftp, "./FTPSSL.pm" );

    ok2( $ftp->binary (), 'putting FTP in binry mode' );
    ok2( $ftp->put( './t/test_file.tar.gz' ), "puting a test binary file on $dir" );

    # Query after put() call so there is something to find!
    # (Otherwise it looks like it may have failed.)
    my @lst = $ftp->list ();
    ok2( $ftp->last_status_code() == CMD_OK, 'list() command' );
    print_result (\@lst);

    $ftp->set_callback (\&callback_func, \&end_callback_func, \%callback_hash);
    @lst = $ftp->list ();
    ok2( $ftp->last_status_code() == CMD_OK, 'list() command with callback' );
    print_result (\@lst);
    $ftp->set_callback ();   # Disable callbacks again

    @lst = $ftp->list (undef, "*.p?");
    ok2( $ftp->last_status_code() == CMD_OK, 'list() command with wildcards (*.p?)' );
    print_result (\@lst);

    run_stat_test ( $ftp, $dir, "FTPSSL.pm", $spaceFile );

    if ( $do_delete ) {
       ok2( $ftp->delete($uput_name), "deleting $uput_name on $server" );
    }

    # -----------------------------------
    # Check if the rename fails, since that will affect the remaining tests ...
    # Possible reasons: Command not supported or your account doesn't have
    # permission to do the rename!
    # -----------------------------------
    my $rename_works = 0;
    $res = $ftp->rename ('test_file.tar.gz', 'test_file_new.tar.gz');
    my $msg = $ftp->last_message();      # If it failed, find out why ...
    if ($ftp->all_supported ("RNFR", "RNTO")) {
       if ($res) {
          ok2( $res, 'renaming bin file works' );
          $rename_works = 1;
       } else {
          ok2( (($msg =~ m/Permission denied/) || ($msg =~ m/^550 /)) ? 1 : 0,
              "renaming bin file check: ($msg)" );
       }
    } else {
       ok2( ! $res, "Rename is not supported on this server" );
    }

    # So we know what to call the renamed file on the FTP server.
    my $file = $res ? "test_file_new.tar.gz" : "test_file.tar.gz";

    $do_delete = 0;
    ok2( $ftp->ascii (), 'putting FTP back in ascii mode' );
    $res = $ftp->xput ('./FTPSSL.pm', './ZapMe.pm');
    $msg = $ftp->last_message();      # If it failed, find out why ...
    if ($rename_works) {
       ok2 ($res, "File Recognizer xput Test to a directory Completed");
       ok2 ($ftp->xput ('./FTPSSL.pm', 'ZapMe2.pm'), "xput in current directory");
    } else {
       ok2 (1, "File Recognizer xput Test Skipped ($msg)");
       ok2( $ftp->noop(), "Noop test - Skip 2nd xput test as well" );
    }

    if ($rename_works) {
       my $new = $spaceFile;
       $new =~ s/P S/P-S/g;
       $res = $ftp->rename ($spaceFile, $new);
       $spaceFile = $new  if ($res);
       ok2 ( $res, "Rename a file with spaces in it worked!" );
    } else {
       ok2 (1, "Rename of a file with spaces was skipped!");
    }

    # With call back
    $ftp->set_callback (\&callback_func, \&end_callback_func, \%callback_hash);
    @lst = $ftp->nlst ();
    ok2 ( $ftp->last_status_code() == CMD_OK, 'nlst() command with callback' );
    print_result (\@lst);
    $ftp->set_callback ();   # Disable callbacks again

    # Without call back
    @lst = $ftp->nlst ();
    ok2 ( $ftp->last_status_code() == CMD_OK, 'nlst() command' );
    print_result (\@lst);

    @lst = $ftp->nlst (undef, "*.p?");
    ok2 ( $ftp->last_status_code() == CMD_OK, 'nlst() command with wildcarrds (*.p?)' );
    print_result (\@lst);

    # Silently delete it, don't make it part of the test ...
    # Since if the xput test failed, this test will fail.
    $ftp->delete ("ZapMe.pm");
    $ftp->delete ("ZapMe2.pm");

    ok2( $ftp->binary (), 'putting FTP back in binary mode' );
    ok2( $ftp->get($file, './t/test_file_new.tar.gz'), 'retrieving the binary file' );
    my $size = $ftp->size ($file);
    my $original_size = -s './t/test_file.tar.gz';
    ok2 ( defined $size, "The binary file's size via FTPS on $server was $size vs $original_size");

    # Now check out the before & after BINARY images
    ok2( $original_size == -s './t/test_file_new.tar.gz',
        "Verifying BINARY file matches original size" );
    ok2( $original_size == $size,
        "Verifying FTPS Server agreed with the sizes." );
    my $same_dates = (stat ('./t/test_file.tar.gz'))[9] == (stat ('./t/test_file_new.tar.gz'))[9];
    ok2( (! $supported) || $same_dates,
        $supported ? "The binary file's Timestamp was preserved!"
                   : "Preserving Binary file timestamps are not supported!" );
    ok2( $ftp->delete($file), "deleting the test bin file on $server" );

    ok2( $ftp->ascii (), 'putting FTP back in ascii mode' );
    ok2( $ftp->xget("FTPSSL.pm", './t/FTPSSL.pm_new.tst'), 'retrieving the ascii file again via xget()' );

    # Now check out the before & after ASCII images
    ok2( -s './FTPSSL.pm' == -s './t/FTPSSL.pm_new.tst',
        "Verifying ASCII file matches original size" );
    $same_dates = (stat ('./FTPSSL.pm'))[9] == (stat ('./t/FTPSSL.pm_new.tst'))[9];
    ok2( (! $supported) || $same_dates,
        $supported ? "The ASCII Timestamps were preserved!"
                   : "Preserving ASCII timestamps are not supported!" );

    $file = "delete_me_I_do_not_exist.txt";
    ok2 ( ! $ftp->get ($file), "Get a non-existant file!" );
    if (-f $file) {
       $size = -s $file;
       unlink ($file);
       print STDERR " *** Deleted local file: $file  [$size byte(s)].\n";
    } else {
       print STDERR " *** No local copy was created!\n";
    }

    # -----------------------------------------
    # End put/get/rename/delete section ...
    # -----------------------------------------

    # -------------------------------------------------------------------
    # Testing out the transfer & xtransfer functions between servers ...
    # -------------------------------------------------------------------
    my ($t1, $xt);
    $t1 = ok2($ftp->transfer ($ftp_other, "FTPSSL.pm", "FTPSSL.pm.transfer"),
              "Transfered the file between servers");
    $xt = ok2($ftp->xtransfer ($ftp_other, "FTPSSL.pm", "FTPSSL.pm.xtransfer"),
              "xTransfered the file between servers");

    $size = $ftp_other->size ("FTPSSL.pm.transfer") || -1;
    $original_size = $ftp->size ("FTPSSL.pm");
    my $xsize = $ftp_other->size ("FTPSSL.pm.xtransfer") || -1;

    ok2( $size == $original_size, "Transfer Size Check! ($size, $original_size)" );
    ok2( $xsize == $original_size, "xTransfer Size Check! ($xsize, $original_size)" );

    # Now clean up after ourselves ...
    ok2( $ftp->delete("FTPSSL.pm"), "deleting the test file on $server" );
    ok2( $ftp_other->delete ("FTPSSL.pm.transfer"), "Deleted the transfter file.");
    if ( $xt ) {
       ok2( $ftp_other->delete ("FTPSSL.pm.xtransfer"), "Deleted the xtransfter file.");
    } else {
       ok2( 1, "The xtransfter failed, so no file to delete!");
    }
    ok2( $ftp->delete($spaceFile), "Deleted the test file with spaces in it's name." );

    # -----------------------------------------
    # Clear the command channel, do limited work after this ...
    # Add any new tests before this block ...
    # -----------------------------------------
    if ( $mode eq CLR_CRYPT ) {
       ok2 ( $ftp->noop (), "Noop since CCC not supported using regular FTP." );
    } elsif ( $ftp->supported ("ccc") ) {
       ok2 ( $ftp->ccc (), "Clear Command Channel Test" );
    } else {
       ok2 ( $ftp->noop (), "Noop since CCC not supported on this server." );
    }
    ok2 ( $ftp->pwd (), "Get Current Directory Again" );

    # -----------------------------------------
    # Closing the connection ...
    # -----------------------------------------

    $ftp->quit();

    # Free so any context messages will still appear in the log file.
    $ftp = undef;

    # -----------------------------------------
    # Did the code generate any warnings ???
    # -----------------------------------------
    if ( $trap_warnings ne "" ) {
       diag ("\n\nIf you see any warnings below from Net-FTPSSL, they are not errors!\nThey are just warnings!\nIf you have time, please forward the log file generated by this program to the developer.\nThe log file '$log_file' has a copy of all warnings written to screen!\nThis will help me maintain clean code with all the various OS, configurations & servers.\n--------------------------------------\n$trap_warnings2\n\n");
       print STDERR "\n\n\nHere's a copy of all the warnings with stack trace generated via Net-FTPSSL!\n$trap_warnings\n";
    }

    # Restore STDERR now that the tests are done!
    open (STDERR, ">&OLDERR");
    if (1 == 2) {
       print OLDERR "\n";   # Perl gives warning if not present!  (Not executed)
    }

    # Create the custom copy mentioned in the README file.
    File::Copy::copy ($log_file, $copy_file);
}

# =====================================================================
# Start of subroutines ...
# =====================================================================

sub ok2 {
   my $res = shift;
   my $msg = shift;

   ok ( $res, $msg );

   my $tag = $res ? "ok" : "not ok";

   $res = ""  unless (defined $res);
   $msg = ""  unless (defined $msg);
   print STDERR ".......... $tag (${res}, ${msg})\n";

   return ( $res );    # So I can easily get the status ...
}


# ---------------------------------------------------------
# The complex "uput" test, have to do a before & after
# query in case "uput" doesn't return the file name!
# The uploaded file should be a new name!
# ---------------------------------------------------------
sub uput_test {
   my $ftp = shift;
   my $test_file = shift;   # May have path info

   my $ignore_name = basename ( $test_file );

   # Get a listing of what's currently in the directory ...
   my %list;
   my @lst = $ftp->nlst ();
   foreach ( @lst ) {
      $list{$_} = 1;
   }

   print_result (\@lst);

   # So the supported test will appear in the log file 1st!
   my $res = $ftp->supported ("STOU");
   my $uput_name = $ftp->uput ( $test_file );

   # Now check for new files after the uput command was run ...
   my @new_files;
   my $found = 0;
   @lst = $ftp->nlst ();
   print_result (\@lst);
   foreach ( @lst ) {
      unless ( exists $list{$_} ) {
         ++$found;
         push (@new_files, $_);
         print STDERR "New: $_\n";       # Printed in case of multiple hits ...
      }
   }

   my $guess = ( $found == 0 ) ? "" : $new_files[0];

   my $do_delete = 0;
   if ($res) {
      ok2 ( $found == 1, "nlst found one extra file on the server after the uput command [$guess]" );
      my $new_name = (defined $uput_name) ? $uput_name : "<undef>";

      if ( $new_name eq "?" ) {
         ok2 (1, "The FTPS server refused to tell us the name uput used [?], but nlst said [$guess]");
         $do_delete = 1   if ($found == 1);
         $uput_name = $guess;
      } elsif ( $new_name eq $guess ) {
         ok2 (1, "The FTPS server returned the same name for uput as nlst did!  [$new_name]");
         $do_delete = 1;
      } elsif ( defined $uput_name ) {
         ok2 (0, "The FTPS server returned the same name for uput as nlst did!  [$new_name] vs [$guess]");
      } else {
         ok2 (0, "The uput command worked!");  # Failure despite the message!
      }

      unless ( $do_delete ) {
         ok2 ( 1, "uput delete skiped since 'uput' not didn't return a good name!" );
      }

   } else {
      ok2( ! $uput_name, "uput should fail since STOU not supported on this server" );
      ok2 ( $found == 0, "uput didn't upload any new files! [$guess]" );
      ok2 ( 1, "uput delete skiped since 'uput' not supported!" );
   }

   return ($uput_name, $do_delete);
}


# Done so can use these results to improve on the logic for
# is_file() & is_dir()!
sub run_stat_test {
   my $ftp = shift;
   my $dir = shift;
   my $file = shift;
   my $spaces = shift;

   # Check if supported is returning a false positive!
   # Found a server where HELP says it's supported, but it really isn't!
   if ( $ftp->supported ( "STAT" ) ) {
      my $stat = $ftp->quot ("STAT", $file);
      if ( $stat == CMD_ERROR ) {
         $ftp->fix_supported (0, "STAT");
         diag ("STAT wasn't really supported after all!");
         print STDERR "STAT wasn't really supported after all ...\n";
      }
   }

   my $save = 0;
   if ( $ftp->supported ( "STAT" ) ) {
      print STDERR "Disabling the SIZE command ... So can use STAT!\n";
      if ( $ftp->supported ( "SIZE" ) ) {
         $save = $ftp->fix_supported (0, "SIZE");
      }
   }

   my $no_such_file = "This-Is-Not-A-File";

   # Not using File::Spec on purpose!  FTPS protocol expects Unix format paths.
   my $file2 = "./" . $file;

   ok2 ($ftp->is_file ($file), "Passed is_file test!");
   ok2 ($ftp->is_file ($spaces), "Passed is_file with spaces test!");
   ok2 (! $ftp->is_file ($dir), "Failed is_file test, a directory is not a file!");
   ok2 (! $ftp->is_file ($no_such_file), "Failed is_file test checking no such file!");
   ok2 ($ftp->is_file ($file2), "Passed is_file test with path info in it!");

   ok2 (! $ftp->is_dir ($file), "Failed is_dir test, its a regular file!");
   ok2 ($ftp->is_dir ($dir), "Passed is_dir test the directory exists!");
   ok2 (! $ftp->is_dir ($no_such_file), "Failed is_dir test checking no such file/dir!");

   if ( $save ) {
      print STDERR "Restoring the SIZE command ...\n";
      $ftp->fix_supported (1, "SIZE");
   }

   # Should be back to testing via "SIZE" instead of STAT again!
   ok2 ($ftp->is_file ($file), "Passed is_file test!");
   ok2 ($ftp->is_dir ($dir), "Passed is_dir test the directory exists!");

   return;
}


# Validates we can log in & then does GMT/Local Time test.
sub valid_credentials {
   my $server = shift;
   my $opts = shift;
   my $user = shift;
   my $pass = shift;
   my $dir  = shift;

   print STDERR "\nValidating the user input credentials & PRET test against the server ...\n";

   my $ftps = Net::FTPSSL->new( $server, $opts );

   # Lets try again on failure by adding some additional options to new().
   if ( (! $ftps) &&
        $Net::FTPSSL::ERRSTR =~ m/:SSL3_CHECK_CERT_AND_ALGORITHM:/ ) {
      print STDERR "\n\n";
      print STDERR "########################################################\n";
      print STDERR "Making a 2nd attempt to connect using a new SSL option!\n";
      print STDERR "########################################################\n";
      diag ("Adding: {SSL_cipher_list} = 'HIGH:!DH' for retry ...");
      $opts->{SSL_cipher_list} = 'HIGH:!DH';
      $ftps = Net::FTPSSL->new( $server, $opts );
   }

   isa_ok( $ftps, 'Net::FTPSSL', 'Net::FTPSSL ' . $Net::FTPSSL::ERRSTR );
   --$skipper;

   my $sts = 0;    # Assume failure ...

   if ( defined $ftps ) {
      $sts = $ftps->login ($user, $pass);
      ok2( $sts, "Login to $server" );
      --$skipper;

      if ( $sts ) {
         if ($ftps->quot ("PRET", "LIST") == CMD_OK) {
            diag ("\n=========================================================");
            diag ('=== Adding option "Pret" to all future calls to new() ===');
            diag ("=========================================================\n");
            $opts->{Pret} = 1;   # Assumes all future calls will need!
         }
      } else {
         diag ("\n=========================================================");
         diag ("=== Your FTPS login credentials are probably invalid! ===");
         diag ("=========================================================");
         diag ("\n");
      }
   }

   # Some additional tests if the FTPS connection is acive ...
   if ( $sts ) {
      my $msg;
      ok2( $ftps->cwd( $dir ), "Changed the dir to $dir" );
      --$skipper;
      ($opts->{PreserveTimestamp}, $msg) = test_mdtm_in_gmt ( $ftps );
      $msg .= "  [" . $opts->{PreserveTimestamp} . "]";
      ok2 ( $opts->{PreserveTimestamp}, $msg );
      --$skipper;
      $ftps->quit ();
   }

   return ( $sts );
}

# -----------------------------------------------------------------------------
# Test for Bug # 61432 (Help responds with mixed encrypted & clear text on CC.)
# Bug's not in my software, but on the server side!
# But still need tests for it in this script so all test cases will work.
# Does no calls to ok() on purpose ...
# Never open a data channel here ...
# -----------------------------------------------------------------------------
sub check_for_help_issue {
   my $server = shift;
   my $opts = shift;
   my $user = shift;
   my $pass = shift;

   print STDERR "\nTrying to determine if HELP works on encrypted channels ...\n";
   my $ftps = Net::FTPSSL->new( $server, $opts );
   $ftps->login ($user, $pass);
   $ftps->noop ();
   my $sts = $ftps->quot ("HELP");
   if ( $sts == CMD_ERROR && $Net::FTPSSL::ERRSTR =~ m/Unexpected EOF/ ) {
      diag ("\nThis server has issues with the HELP Command.");
      diag ("You Must use OverrideHELP when calling new() for this server!");
      diag ("Adding this option for all further testing.");
      $opts->{OverrideHELP} = 1;   # Assume all FTP commands supported.
   }
   $ftps->quit ();
}

# -----------------------------------------------------------------------------
# Test for Bug # 61432 (Where PASV returns wrong IP Address)
# Bug's not in my software, but on the server side!
# But still need tests for it in this script so all test cases will work.
# On success, it does no calls to ok() on purpose ...
# On failure, it calls ok(0,...) since all further test fail and we want the
# failure to show up in "make test".  Otherwise the tester thinks all is OK
# when all the other tests are skipped over!
# -----------------------------------------------------------------------------
sub check_for_pasv_issue {
   my $server = shift;
   my $opts   = shift;
   my $user   = shift;
   my $pass   = shift;
   my $crypt  = shift;

   print STDERR "\nTrying to determine if PASV returns wrong IP Address ...\n";

   # Uncomment the line below to force the failure case (to debug this code)
   # I don't have a server to test against where this happens ...
   # $opts->{OverridePASV} = "abigbadservername";

   my $ftps = Net::FTPSSL->new( $server, $opts );
   $ftps->login ($user, $pass);

   # WARNING: Do not copy this code, it calls internal undocumented functions
   # that probably change between releases.  I'm the developer, so I will keep
   # any changes here in sync with future releases.  But I need this low
   # level access to see if the server set up PASV correctly through the
   # firewall. (Bug 61432)  Should be fairly rare to see it fail ...

   if ( $crypt ne CLR_CRYPT ) {
      $ftps->_pbsz ();
      unless ($ftps->_prot ()) {
         ok2( 0, "Setting up data channel in check_for_pasv_issue() failed!" );
         --$skipper;
         return (0)
      }
   }

   my ($h, $p) = $ftps->_pasv ();

   print STDERR "Calling _open_data_channel ($h, $p)\n";

   # Can we open up the returned data channel ?
   if ( $ftps->_open_data_channel ($h, $p) ) {
      $ftps->_abort();
      $ftps->quit ();
      print STDERR "\nPASV works fine ...\n";
      return (1);    # Yes, we don't have to worry about it.
   }

   # Very, very rare to get this far ...

   print STDERR "Attempting to reopen the same data channel using OveridePASV\n";

   # Now let's see if OverridePASV would have worked .... (server changed)
   if ( $ftps->_open_data_channel ($server, $p) ) {
      print STDERR "Success!\n";
      diag ("\nThis server has issues with returning the correct IP Address via PASV.");
      diag ("You Must use OverridePASV when calling new() for this server!");
      diag ("Adding this option for all further testing.");

      $opts->{OverridePASV} = $server;      # Things should now work!

      $ftps->_abort();
      $ftps->quit ();
      print STDERR "\nMust use OverridePASV ...\n";
      return (1);
   }

   # It's even rarer to get here ...

   $ftps->quit();
   print STDERR "Failure!\n";

   ok2( 0, "Passive doesn't seem to work in check_for_pasv_issue() after all!" );
   --$skipper;

   return (0);    # PASV doesn't seem to work at all!
}

# -------------------------------------------------------------------------
# Verifying if the server implements MDFT & MDTM correctly.
# The specs say the Date/Time must be in UTC/GMT timezone.
# But some serveres are using their local timezone instead!
# -------------------------------------------------------------------------
# Assumes that MDFT/MDTM both use the same timezone if implemented
# on the server.
# Also assumes that the clocks on the client & server are not too
# far out of sync.
# -------------------------------------------------------------------------
sub test_mdtm_in_gmt {
   my $ftps = shift;    # The open FTP/S connection ...

   print STDERR "\nPerforming the MDTM TimeZone check ...\n";

   # Get file timestamp supported?
   unless ( $ftps->supported ("MDTM" ) ) {
      return ("MDTM isn't supported, so can't check if the Server Timezone uses UTC/GMT.");
   }

   # Disable so don't preserve the timestamp during an upload ...
   my $cnt = $ftps->fix_supported (0, "MFMT");
   my $save = ${*$ftps}{_FTPSSL_arguments}->{FixPutTs};
   ${*$ftps}{_FTPSSL_arguments}->{FixPutTs} = 0;

   my $file = File::Spec->catfile ("t", "scratch.txt");
   open (FH, ">", $file) or die ("Can't create zero byte scratch file!\n");
   close (FH);

   my $now = time () ;    # Get the time on the client ...

   $ftps->put ($file);
   my $tm = $ftps->mdtm (basename ($file));  # The time on the remote file.
   $ftps->delete (basename ($file));
   unlink ($file);

   # Restore the "supported" settings ...
   $ftps->fix_supported (1, "MFMT")  if ( $cnt );
   ${*$ftps}{_FTPSSL_arguments}->{FixPutTs} = $save;

   my $msg;
   my $gmt = 1;
   if ( defined $tm &&
        $tm =~ m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/ ) {
      my ($yr, $mon, $day, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6);
      my $gm = timegm ( $sec, $min, $hr, $day, $mon - 1, $yr - 1900 );
      my $loc = timelocal ( $sec, $min, $hr, $day, $mon - 1, $yr - 1900 );

      if ( abs ($gm - $now) <= abs ($loc - $now) ) {
         $msg = "The FTP/S server correctly uses UTC/GMT time for MDTM.";
      } else {
         $msg = "The FTP/S server incorrectly uses it's local time for MDTM.";
         $msg .= sprintf ("  (Offset off by %0.2f hrs)", ($now - $gm) / 3600.0);
         $gmt = -1;     # Flag as local time ...
      }
   } else {
      $msg = "Can't parse the results of the MDTM call.";
   }

   return ($gmt, $msg);
}

# -------------------------------------------------------------------------
# Just ignore these connections, just verifying that it's not sharing/stealing
# the log file.  Must manually examine the logs to be sure it's correct.
# Also checks the 2 override options in various modes ...
# Just be aware that OverrideHELP & OverridePASV may already be overriden!
# -------------------------------------------------------------------------
sub test_log_redirection {
   my $server   = shift;
   my $loc_opts = shift;
   my $user     = shift;
   my $pass     = shift;
   my $psv_flg  = shift;   # P, 1 or 2.  For opening data channels.

   print STDERR "\nCreating secondary connections for other log files ...\n";
   my @help = ("MFMT", "NOOP");

   my $hlp_ovr_flg = (exists $loc_opts->{OverrideHELP});
   my $psv_ovr_flg = (exists $loc_opts->{OverridePASV});

   $loc_opts->{PreserveTimestamp} = 0;
   $loc_opts->{DebugLogFile} = $debug_log1;
   my $badftp1 = Net::FTPSSL->new( $server, $loc_opts );

   $loc_opts->{PreserveTimestamp} = 1;
   $loc_opts->{DebugLogFile} = $debug_log2;
   $loc_opts->{OverridePASV} = $server;
   my $badftp2 = Net::FTPSSL->new( $server, $loc_opts );

   $loc_opts->{PreserveTimestamp} = 1;
   $loc_opts->{DebugLogFile} = $debug_log3;
   delete ($loc_opts->{OverridePASV}) unless ($psv_ovr_flg);
   $loc_opts->{OverrideHELP} = 1;    # All commands valid
   my $badftp3 = Net::FTPSSL->new( $server, $loc_opts );

   isa_ok( $badftp1, 'Net::FTPSSL', '2nd Net::FTPSSL object creation' );
   isa_ok( $badftp2, 'Net::FTPSSL', '3rd Net::FTPSSL object creation' );
   isa_ok( $badftp3, 'Net::FTPSSL', '4th Net::FTPSSL object creation' );
   ok2( $badftp1->login ($user, $pass), "2nd Login to $server" );
   ok2( $badftp2->login ($user, $pass), "3rd Login to $server" );
   ok2( $badftp3->login ($user, $pass), "4th Login to $server" );
   $badftp1->set_croak (0);
   $badftp2->set_croak (0);
   $badftp3->set_croak (0);

   $badftp2->force_epsv ($psv_flg)  if ($psv_flg ne "P");

   $badftp1->pwd ();
   $badftp2->list ();    # Uses a data channel
   $badftp3->noop ();
   $badftp1->quit ();
   $badftp2->quit ();
   $badftp3->quit ();

   $loc_opts->{OverrideHELP} = \@help;  # Some commands valid
   $loc_opts->{Debug} = 2;
   $badftp3 = Net::FTPSSL->new( $server, $loc_opts );

   isa_ok( $badftp3, 'Net::FTPSSL', 'Appending to 4th Net::FTPSSL object logs' );
   ok2( $badftp3->login ($user, $pass), "Repeat 4th Login to $server" );
   $badftp3->set_croak (0);
   $badftp3->pwd ();
   $badftp3->quit ();

   $loc_opts->{OverrideHELP} = 0;        # No commands valid
   $badftp3 = Net::FTPSSL->new( $server, $loc_opts );

   isa_ok( $badftp3, 'Net::FTPSSL', 'Appending to 4th Net::FTPSSL object logs again' );
   ok2( $badftp3->login ($user, $pass), "Repeat 4th Login to $server again" );
   $badftp3->set_croak (0);
   $badftp3->pwd ();
   my $t = $badftp3->force_epsv (1);
   $t = $badftp3->force_epsv (2)   unless ( $t );
   if ( $t ) {
      ok2 ( 1, "Force Extended Passive Mode ( secondary )" );
   } else {
      ok2 ( 1, "Warning: Force Extended Passive Mode not supported ( secondary )" );
   }
   my @lst = $badftp3->list ();
   push (@lst, "SUB-TEST-LIST-RESULTS-FROM-OTHER-SECTION");
   print_result (\@lst);   # Display's the list in the main log, not this one!
   $badftp3->quit ();

   print STDERR "End of secondary connections for other log files ...\n\n";

   return;
}

# Does an automatic shift to upper case for all answers
sub ask {
  my $question = shift;
  my $default  = uc (shift);
  my $values   = uc (shift);

  my $answer = uc (prompt ($question, $default, $values));

  if ( $values && $answer !~ m/^$values$/ ) {
     $answer = $default;   # Change invalid value to default answer!
  }

  # diag ("ANS: [$answer]");

  return $answer;
}

# This version doesn't do an automatic upshift
# Also provides a way to enter "" as a valid value!
# The Alternate Default is from an optional environment variable
sub ask2 {
  my $question = shift;
  my $default  = shift || "";
  my $values   = shift || "";
  my $altdef   = shift || $default;

  my $answer = prompt ($question, $altdef, $values);

  if ( $answer =~ m/^\s+$/ ) {
     $answer = "";         # Overriding any defaults ...
  } elsif ( $values && $answer !~ m/^$values$/ ) {
     $answer = $altdef;    # Change invalid value to default answer!
  }

  # diag ("ANS2: [$answer]");

  return $answer;
}

sub ask_yesno {
  my $question = shift;

  my $answer = prompt ("$question", "N", "(Y|N)");

  # diag ("ANS-YN: [$answer]");

  return $answer =~ /^y(es)*$/i ? 1 : 0;
}

# Save the results from the list() & nlst() calls.
# Remember that STDERR should be redirected to a log file by now.
sub print_result {
   my $lst = shift;

   # Tell the max number of entries you may print out.
   # Just in case the list is huge!
   my $cnt = 5;

   my $max = scalar (@{$lst});
   print STDERR "------------- Found $max file(s) -----------------\n";
   foreach (@{$lst}) {
      if ($cnt <= 0) {
         print STDERR "...\n";
         print STDERR "($lst->[-1])\n";
         last;
      }
      print STDERR "($_)\n";
      --$cnt;
   }
   print STDERR "-----------------------------------------------\n";
}

# Testing out the call back functionality as of v0.07 on ...
sub callback_func {
   my $ftps_function_name = shift;
   my $data_ref     = shift;      # The data to/from the data channel.
   my $data_len_ref = shift;      # The size of the data buffer.
   my $total_len    = shift;      # The number of bytes to date.
   my $callback_data_ref = shift; # The callback work space.

   if ( $ftps_function_name =~ m/:list$/ ) {
      ${$data_ref} =~ s/[a-z]/\U$&/g;    # Convert to upper case!
      # Reformat #'s Ex: 1234567 into 1,234,567.
      while ( ${$data_ref} =~ s/(\d)(\d{3}\D)/$1,$2/ ) { }
      ${$data_len_ref} = length (${$data_ref});  # May have changed data length!

   } elsif ( $ftps_function_name =~ m/:nlst$/ ) {
      ${$data_ref} =~ s/[a-z]/\U$&/g;    # Convert to upper case!
      ${$data_ref} =~ s/^/[0]: /gm;      # Add a prefix per line.

      # Make the prefix unique per line ...
      my $cnt = ++$callback_data_ref->{counter};
      while ( ${$data_ref} =~ s/\[0\]/[$cnt]/) {
         $cnt = ++$callback_data_ref->{counter};
      }

      # Fix so counter is correct for next time called!
      --$callback_data_ref->{counter};

      ${$data_len_ref} = length (${$data_ref});  # Changed length of data!

   } else {
      print STDERR " *** Unexpected callback for $ftps_function_name! ***\n";
   }

   return ();
}

# Testing out the end call back functionality as of v0.07 on ...
sub end_callback_func {
   my $ftps_function_name = shift;
   my $total_len          = shift;   # The total number of bytes sent out
   my $callback_data_ref  = shift;   # The callback work space.

   my $tail;   # Additional data channel data to provide ...

   if ( $ftps_function_name =~ m/:nlst$/ ) {
      my $cnt;
      my $sep = "";
      $tail = "";
      foreach ("Junker", "T-Bird", "Coup", "Model-T", "Horse & Buggy") {
         $cnt = ++$callback_data_ref->{counter};
         $tail .= $sep . "[$cnt]: $_!";
         $sep = "\n";
      }

      # So the next nlst call will start counting all over again!
      delete ($callback_data_ref->{counter});
   }

   return ( $tail );
}


# Based on ExtUtils::MakeMaker::prompt
# (can't use since "make test" doesn't display questions!)

sub prompt {
   my ($question, $def, $opts) = (shift, shift, shift);

   my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

   my $dispdef = defined $def ? "[$def] " : " ";
   $def = defined $def ? $def : "";

   if (defined $opts && $opts !~ m/^\s*$/) {
      diag ("\n$question ? $opts $dispdef");
   } else {
      diag ("\n$question ? $dispdef");
   }

   my $ans;
   if ( $ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
      diag ("$def\n");
   } else {
      $ans = <STDIN>;
      chomp ($ans);
      unless (defined $ans) {
         diag ("\n");
      }
   }

   $ans = $def  unless ($ans);

   return ( $ans );
}

# Check if using a proxy server is supported ...
sub proxy_supported {
   eval {
      require Net::HTTPTunnel;
   };
   if ($@) {
      diag ("NOTE: Using a proxy server is not supported without first installing Net::HTTPTunnel\n");
      return 0;
   }

   return 1;
}

# Ask the proxy server related questions ...
sub ask_proxy_questions {
   my $ans = ask_yesno ("Will you be FTP'ing through a proxy server?");
   unless ($ans) {
      return undef;
   }

   my %proxy_args;
   $proxy_args{'proxy-host'} = ask2 ("\tEnter your proxy server name", undef, undef, $ENV{FTPSSL_PROXY_HOST});
   $proxy_args{'proxy-port'} = ask2 ("\tEnter your proxy port", undef, undef, $ENV{FTPSSL_PROXY_PORT});
   $ans = ask_yesno ("\tDoes your proxy server require a user name/password pair?", undef, undef, $ENV{FTPSSL_PROXY_USER_PWD_REQUIRED});
   if ($ans) {
      $proxy_args{'proxy-user'} = ask2 ("\tEnter your proxy user name", undef, undef, $ENV{FTPSSL_PROXY_USER});
      $proxy_args{'proxy-pass'} = ask2 ("\tEnter your proxy password", undef, undef, $ENV{FTPSSL_PROXY_PWD});
   }

   # diag ("Host: ", $proxy_args{'proxy-host'}, "   Port: ", $proxy_args{'proxy-port'}, "  User: ", ($proxy_args{'proxy-user'} || "undef"), "  Pwd: ", ($proxy_args{'proxy-pwd'} || "undef"));

   return \%proxy_args;
}

# vim:ft=perl:

