# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ./t/-5-readonly.t'

#########################

# Goal here is to preform a simple read only test that doesn't upload anything
# to the test server.  Recently ran into an issue on a test server that I've
# been asked not to upload anything to, so just proving I can access the server
# here and performing simple tests.

use strict;
use warnings;

# Uncomment if you need to trace issues with IO::Socket:SSL methods as well.
# Proper values are: debug0, debug1, debug2 & debug3.  3 is the most verbose!
# use IO::Socket::SSL qw(debug3);

use Test::More tests => 17;   # Also update skipper (one less)
use File::Copy;
use File::Basename;

my $skipper = 16;

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

diag( "" );
diag ("\nThis allows you to do a Simple basic read-only test.");
diag( "Some information will be required for this test:" );
diag( "A secure ftp server address, a user, a password and a directory" );
diag( "where the user has at least read-only permissions.  This test doesn't");
diag( "upload anything to the test server.  It just queries it." );

my $p_flag = proxy_supported ();

my $more_test = ask_yesno("Do you want to run the simple read-only test");

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

    # The log file ...
    my $log_file = $0;
    $log_file =~ s/[.]t/.log.txt/;

    # -----------------------------------------------------------
    # End of user interaction ...
    # -----------------------------------------------------------

    # Delete test files from previous run
    unlink ( $log_file );

    # So we can save the Debug trace in a file from this test.
    # We don't use DebugLogFile for this on purpose so that everything
    # written to STDERR is in the log file, including msgs from this test!
    # But doing it this way is very undesireable in a real program!
    open (OLDERR, ">&STDERR");
    open (STDERR, "> $log_file");

    # This hash provides the basic info for the FTPSSL connections
    # based on the user's answers above.
    my %ftps_opts = ( Port => $port, Encryption => $mode,
                      DataProtLevel => $data, useSSL => $encrypt_mode,
                      Timeout => 30, Debug => 1, Trace => 1,
                      OverrideHELP => 1, PreserveTimestamp => 1 );

    # Set if we are going through a proxy server ...
    if (defined $proxy) {
       $ftps_opts{ProxyArgs} = $proxy;
    }

    unless ( valid_credentials ( $server, \%ftps_opts, $user, $pass ) ) {
       skip("Can't log into the FTPS Server.  Skipping the remaining tests ...",
            $skipper );
    }

    print STDERR "\n**** Starting the real server test ****\n";
    ($trap_warnings, $trap_warnings2) = ("", "");

    # Writes logs to STDERR which this script redirects to a file ...
    my $ftp = Net::FTPSSL->new( $server, \%ftps_opts );

    isa_ok( $ftp, 'Net::FTPSSL', 'Net::FTPSSL object creation' );

    # Trap where the log file is so we can write warnings to it.
    $ftp->trapWarn (1); # Normally has no argument!  Special case for this prog!

    my $sts = $ftp->login ($user, $pass);
    ok2 ( $sts, "Login Successfull" );

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
    } else {
       ok2 ( 1, "Using PASV mode for data connections" );
    }

    # Ask for the user's HOME dir if it's not provided!
    $dir = $ftp->pwd ()  unless ($dir);

    ok2( $ftp->cwd( $dir ), "Changed the dir to $dir" );
    my $pwd = $ftp->pwd();
    ok2( defined $pwd, "Getting the directory: ($pwd)" );
    $dir = $pwd  if (defined $pwd);     # Convert relative to absolute path.

    my $res = $ftp->cdup ();
    $pwd = $ftp->pwd();
    ok2 ( $res, "Going up one level: ($pwd)" );

    $res = $ftp->cwd ( $dir );
    $pwd = $ftp->pwd();
    ok2 ( $res, "Returning to proper dir: ($pwd)" );

    ok2( $ftp->noop(), "Noop test" );

    # -----------------------------------------------
    # The List Commands open up a data channel!
    my @lst = $ftp->list ();
    # -----------------------------------------------
    ok2( $ftp->last_status_code() == CMD_OK, 'Call to list worked!' );
    print_result (\@lst);

    @lst = $ftp->nlst ();
    ok2( $ftp->last_status_code() == CMD_OK, 'Call to nlst worked!' );
    print_result (\@lst);

    my ( @dirs, @files, @unknown );
    my ( $cntDir, $cntFile, $cntUnkn ) = ( 0, 0, 0 );
    foreach ( @lst ) {
       if ( $ftp->is_file ($_) ) {
          push (@files, $_ );
          ++$cntFile;
       } elsif ( $ftp->is_dir ($_) ) {
          push (@dirs, $_ );
          ++$cntDir;
       } else {
          push (@unknown, $_ );
          ++$cntUnkn;
       }
    }
    ok2 ( 1, "Files: $cntFile,  Dirs: $cntDir,  Unknown: $cntUnkn" );

    ok2( $ftp->binary (), 'putting FTP back in binary mode' );

    # -----------------------------------------
    # Closing the connection ...
    # -----------------------------------------

    ok2 ($ftp->quit(), "Quit worked OK!");

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
}


sub valid_credentials {
   my $server = shift;
   my $opts = shift;
   my $user = shift;
   my $pass = shift;

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
         ok2 ($ftps->quit(), "Quit worked OK!");
      } else {
         diag ("\n=========================================================");
         diag ("=== Your FTPS login credentials are probably invalid! ===");
         diag ("=========================================================");
         diag ("\n");
      }
   }

   return ( $sts );
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

