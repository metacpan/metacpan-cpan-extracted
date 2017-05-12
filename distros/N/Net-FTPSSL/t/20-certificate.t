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

use Test::More tests => 11;   # Also update skipper (one less)
use File::Copy;

my $skipper = 10;

# plan tests => 10;  # Can't use due to BEGIN block

BEGIN {
   use_ok('Net::FTPSSL');    # Test # 1

   # For systems where $ENV{HOME} doesn't exist!
   if (! exists $ENV{HOME}) {
      eval {
         require File::HomeDir;
         $ENV{HOME} = File::HomeDir->my_home ();
      };
      if ($@) {
         $ENV{HOME} = ".";   # The current direcory is HOME!
      }
   }
}

sleep (1);  # So test 1 completes before the message prints!

# -----------------------------------------------------------
# This section initializes certificate feature in Net::FTPSSL.
# It's required in order to implement Client Certificates
# so that you can talk to FTPS servers that require them.
# -----------------------------------------------------------
# The client certificate is only used if your FTPS server
# asks for a copy.  Otherwise this certificate info is ignored!
# See the examples in the IO-Socket-SSL distro for more details!
# -----------------------------------------------------------
# NOTE: You no longer have to use a separate certificate hash.
#       You may set this info up in the main hash as well now.
#       Keeping separate here for ease up modifying the test.
# -----------------------------------------------------------
# **** THIS IS THE CODE SECTION TO MODIFY. ****
# **** SEE THE README FILE FOR INSTRUCTIONS ON WHAT LINES ****
# **** OF CODE YOU NEED TO CHANGE BELOW TO BE ABLE TO TALK ****
# **** TO YOUR FTPS SERVER USING CLIENT CERTIFICATES! ****
# -----------------------------------------------------------
my %certificate = ( SSL_version     => "SSLv23",   # Overridden later.
                    SSL_use_cert    => 1,
                    SSL_server      => 0,

                    # My Certificate information ...
                    SSL_cert_file   => "$ENV{HOME}/Certificate/pubkey.pem",
                    SSL_key_file    => "$ENV{HOME}/Certificate/private.pem",
                    SSL_passwd_cb   => sub { return ("my_password") },

                    # Tells if we've overriden where our trusted CA Store is.
                    # SSL_ca_file   => "$ENV{HOME}/Certificate/pubkey.pem",
                    # SSL_ca_path   => "$ENV{HOME}/Certificate",

                    SSL_verify_mode     => Net::SSLeay::VERIFY_NONE(),
                    SSL_verify_callback => \&check_certificate,
                    Timeout             => 30 );
# -----------------------------------------------------------
# **** END OF SECTION TO CUSTOMIZE! ****
# -----------------------------------------------------------


diag( "" );
diag( "\nYou can also perform a certificate test." );
diag( "Some information will be required for this test:" );
diag( "A secure ftps server expecting a client certificate,");
diag( "a user, a password and a directory where the user");
diag( "has permissions to read and write." );
diag ( "See the README file for instructions on how to fully" );
diag ( "enable this test!" );

my $p_flag = proxy_supported ();

my $more_test = ask_yesno("Do you want to do a certificate test");

SKIP: {
    skip ( "Certificate tests skipped for some reason ...", $skipper ) unless $more_test;

    if ( chk_cert_files ( \%certificate ) ) {
      skip ( "Deeper test skipped due to no client certificate defined ...",
             $skipper );
    }

    my( $address, $server, $port, $user, $pass, $dir, $mode, $data, $encrypt_mode, $psv_mode ); 

    $address = ask2("Server address ( host[:port] )", undef, undef, $ENV{FTPSSL_SERVER});
    ( $server, $port ) = split( /:/, $address );
    # $port = 21 unless $port;   # Let FTPSSL provide the default port.
    $port = "" unless (defined $port);

    $user = ask2("\tUser", "anonymous", undef, $ENV{FTPSSL_USER});

    $pass = ask2("\tPassword [a space for no password]", "user\@localhost", undef, $ENV{FTPSSL_PWD});

    $dir = ask2("\tDirectory", "<HOME>", undef, $ENV{FTPSSL_DIR});
    $dir = "" if ($dir eq "<HOME>");   # Will ask server for it later on.

    # Clear connections can't use certificates ...
    $mode = uc ($ENV{FTPSSL_MODE} || EXP_CRYPT);
    $mode = ask("\tConnection mode (I)mplicit or (E)xplicit.",
                $mode, "(I|E)");

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


    # The main certificate log file ...
    my $log_file = "./t/20-certificate.txt";

    # -----------------------------------------------------------
    # End of user interaction ...
    # -----------------------------------------------------------

    # Delete test files from previous run
    unlink ($log_file);

    # So we can save the Debug trace in a file from this test.
    # We don't use DebugLogFile for this on purpose so that everything
    # written to STDERR is in the log file, including msgs from this test!
    # But doing it this way is very undesireable in a real program!
    open (OLDERR, ">&STDERR");
    open (STDERR, "> $log_file");

    $certificate{SSL_version} = ($encrypt_mode ? "SSLv23" : "TLSv1");

    # My Net::FTPSSL connection options ...
    my %ftps_opts = ( Port => $port, Encryption => $mode,
                      DataProtLevel => $data, useSSL => $encrypt_mode,
                      SSL_Client_Certificate => \%certificate,
                      Croak => 0,
                      Timeout => 30, Debug => 1, Trace => 1 );

    # Set if we are going through a proxy server ...
    if (defined $proxy) {
       $ftps_opts{ProxyArgs} = $proxy;
    }

    print STDERR "\n**** Starting the Certificate server test ****\n";

    # Writes logs to STDERR which this script redirects to a file ...
    my $ftp = open_connection ( $server, \%ftps_opts );

    isa_ok( $ftp, 'Net::FTPSSL', 'Net::FTPSSL object creation' );

    skip ( "Can't create Net::FTPSSL connection ...", --$skipper ) unless ($ftp);

    # $SIG{__WARNING__} = "IGNORE";
    $ftp->trapWarn (1);   # Merges all warnings into the log file.  Uses special case option.

    ok2( $ftp->login ($user, $pass), "Login to $server" );

    # Turning off croak now that our environment is correct!
    $ftp->set_croak (0);

    if ( $psv_mode eq "P" ) {
       ok2 ( 1, "Using PASV mode for data connections" );
    } else {
       my $t = $ftp->force_epsv (1);
       $psv_mode = $t ? "1" : "2";
       $t = $ftp->force_epsv (2)  unless ( $t );
       ok2 ( $t, "Force Extended Passive Mode (EPSV $psv_mode)" );
       unless ( $t ) {
          --$skipper;
          skip ( "EPSV not supported, please rerun test using PASV instead!", $skipper );
       }
    }

    # Ask for the user's HOME dir if it's not provided!
    $dir = $ftp->pwd ()  unless ($dir);

    # -------------------------------------------------------------------------
    # Back to processing the real test cases ...
    # -------------------------------------------------------------------------
    ok2( $ftp->cwd( $dir ), "Changed the dir to $dir" );
    my $pwd = $ftp->pwd();
    ok2( defined $pwd, "Getting the directory: ($pwd)" );
    $dir = $pwd  if (defined $pwd);     # Convert relative to absolute path.

    my $res = $ftp->cdup ();
    $pwd = $ftp->pwd();
    ok2 ( $res, "Going up one level: ($pwd)" );

    # $res = $ftp->cwd ( $dir );
    # $pwd = $ftp->pwd();
    # ok2 ( $res, "Returning to proper dir: ($pwd)" );

    ok2( $ftp->noop(), "Noop test" );

    # Note: Both list funcs can return nothing if there nothing
    # to find.  So always check the status code for success!
    # Also on some servers nlst skips over sub-directories.
    my @lst;
    @lst = $ftp->nlst ();
    ok2( $ftp->last_status_code() == CMD_OK, 'nlst() command' );
    print_result (\@lst);

    @lst = $ftp->list ();
    ok2( $ftp->last_status_code() == CMD_OK, 'list() command' );
    print_result (\@lst);

    # -----------------------------------------
    # Closing the connection ...
    # -----------------------------------------

    ok2( $ftp->quit(), 'quit() command' );

    # Free so any context messages will still appear in the log file.
    $ftp = undef;

    # Restore STDERR now that the tests are done!
    open (STDERR, ">&OLDERR");
    if (1 == 2) {
       print OLDERR "\n";   # Perl gives warning if not present!  (Not executed)
    }
}

# =====================================================================
# Start of subroutines ...
# =====================================================================

sub open_connection {
   my $svr  = shift;
   my $opts = shift;

   my $cert = $opts->{SSL_Client_Certificate};

   my $ftps = Net::FTPSSL->new( $svr, $opts );

   # Try changing the cipher list if the connection fails ...
   # The defaults changed in recent releases of IO::Socket::SSL.
   if ( (! $ftps) &&
        $Net::FTPSSL::ERRSTR =~ m/:SSL3_CHECK_CERT_AND_ALGORITHM:/ ) {
      print STDERR "######################################################\n";
      $cert->{SSL_cipher_list} = 'HIGH:!DH';
      diag ("Adding: {SSL_cipher_list} = '$cert->{SSL_cipher_list}' for retry ...");
      $ftps = Net::FTPSSL->new( $svr, $opts );
      if ( $ftps ) {
         diag ("New SSL_cipher_list retry worked!");
      } else {
         diag ("New SSL_cipher_list retry failed!");
      }
   }

   # Does it look like the server could have been a self signed certificate?
   # Then to be able to verify it, we'd need to get it's fingerprint!
   # But currently I don't know how to do this without 1st creating
   # a Net::FTPSSL or IO::Socket::SSL object ...

   # Then get it's fingerprint ...
   # Since I'm asking for it, it's not protecting against the MITM attacks ...
   if ( $ftps && $cert->{SSL_verify_mode} == Net::SSLeay::VERIFY_NONE() ) {
      # The fingerprint of the server certificate ...
      $cert->{SSL_fingerprint} = $ftps->get_fingerprint ();
      $cert->{SSL_verify_mode} = Net::SSLeay::VERIFY_PEER();
      print STDERR "##########-###########-############-#########-########\n";
      diag ("Adding: {SSL_fingerprint} = '$cert->{SSL_fingerprint}' for VERIFY_PEER retry ...");

      my $ftp2 = Net::FTPSSL->new( $svr, $opts );
      if ( $ftp2 ) {
         $ftps->quit ();
         $ftps = $ftp2;
         diag ("Using the fingerprinted connection.");
      } else {
         diag ("The fingerprinted connection doesn't work.  Back to using VERIFY_NONE().");
      }
   }

   return ( $ftps );
}

sub ok2 {
   my $res = shift;
   my $msg = shift;

   ok ( $res, $msg );

   my $tag = $res ? "ok" : "not ok";

   $res = ""  unless (defined $res);
   $msg = ""  unless (defined $msg);
   print STDERR ".......... $tag (${res}, ${msg})\n";
}

# Just checks if the referenced files exist!
sub chk_cert_files {
   my $cert = shift;

   my $bad = 0;

   if ( exists $cert->{SSL_key_file} && ! -f $cert->{SSL_key_file} ) {
      $bad = 1;
   } elsif ( exists $cert->{SSL_cert_file} && ! -f $cert->{SSL_cert_file} ) {
      $bad = 1;
   } elsif ( exists $cert->{SSL_ca_file} && ! -f $cert->{SSL_ca_file} ) {
      $bad = 1;
   } elsif ( exists $cert->{SSL_ca_path} && ! -d $cert->{SSL_ca_path} ) {
      $bad = 1;
   }

   return ($bad);
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

  my $answer = prompt ($question, "N", "(Y|N)");

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
   $ans = ask2 ("\tEnter your proxy user name (or space if not required)", undef, undef, $ENV{FTPSSL_PROXY_USER});
   if ($ans ne "") {
      $proxy_args{'proxy-user'} = $ans;
      $proxy_args{'proxy-pass'} = ask2 ("\tEnter your proxy password", undef, undef, $ENV{FTPSSL_PROXY_PWD});
   }

   # diag ("Host: ", $proxy_args{'proxy-host'}, "   Port: ", $proxy_args{'proxy-port'}, "  User: ", ($proxy_args{'proxy-user'} || "undef"), "  Pwd: ", ($proxy_args{'proxy-pwd'} || "undef"));

   return \%proxy_args;
}

# --------------------------------------------------------------------------
# Only called if SSL_verify_mode => Net::SSLeay::VERIFY_PEER() is used!
# --------------------------------------------------------------------------
# This callback function prints out the FTPS Server's Certificate information
# and can also be used to override IO-Socket-SSL's decision on if the Server's
# Certificate is valid or not!
# --------------------------------------------------------------------------
sub check_certificate
{
   my $ret = $_[0];   # What SSL thinks the status is ... (1-good, 0-bad)

   my $lbl = "*** CALLBACK ***";
   my $len = length ($lbl);
   my $ind = " "x${len};

   # Uncomment if you wish to accept the certificate as valid no mater what!
   # $ret = 1;

   printf STDERR ( "\n%s: [%s]\n *** RETURN *** : %s\n\n",
                   $lbl, join ("],\n${ind}: [", @_), $ret );

   return ( $ret );
}

# vim:ft=perl:

