##
## Helper module to do common methods used between test cases ...
## So that the t/*.t programs don't get cluttered with these common functions!
## Also assumes you are not precounting the exact number of tests!
##
## Finally, it assumes your test programs are not changing directories.
## All file paths used are relative, not absolute paths!  So changing
## directories will break a lot of code in this test module!
##

package helper1234;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Test::More 0.88;
use File::Basename;
use File::Spec;

# Uses both IO::Socket::SSL & Net::SSLeay
use Net::FTPSSL;

$VERSION = "1.01";
@ISA = qw( Exporter );

@EXPORT = qw ( stop_testing
               bail_testing
               called_by_make_test
               get_log_name
               are_updates_allowed
               get_opts_set_in_init
               initialize_your_connection
               should_we_ask_1st_question
               should_we_run_test
               ask_config_questions
               write_to_log
               ok2
               add_extra_arguments_to_config
             );

@EXPORT_OK = qw( );


# The global variables ...
my $config_file;        # The name of the config file!
my %FTPSSL_Defaults;    # Matches what's in the config file of previous answers!
my $silent_mode;        # Only true if running via "make test"!
my $debug_log_file;     # What to call the log file ...

my $extra_args = 0;

my %opts_used_in_initialize_func;


# =====================================================================
# Since I don't count the test cases, I must end my test programs
# with a call to one of these 2 methods.
# Can't do any tests in any END blocks!
# ---------------------------------------------------------------------
# When you exit with a status of zero, Test::More overrides the exit
# status with a count of test failure cases.
# If you use an explicit non-zero value, it aborts with that value instead.

sub stop_testing
{
   done_testing ();
   exit (0);        # Always must be 0!
}

# If called, causes "make test" to stop calling test programs.
# The error was just that damming!
sub bail_testing
{
   my $msg = shift || "Uspecified reason!";

   done_testing ();
   BAIL_OUT ( $msg );
   exit (0);
}

# =====================================================================
# Tries to detect if called during "make test" or directly as perl t/xxxx.t
# Need multiple ways for different OS.
# No option is 100% reliable for everyone!
# Used to help determine if we should ask our questions after 1st try!

sub called_by_make_test
{
   my $ignore = shift || 0;   # Don't pass this arg from any t/xxx.t progs!

   # Usually set by "make test" on Unix ...
   return (1)  if ( $ENV{PERL_DL_NONLAZY} );

   # Set internally by this module when same test program
   # asks the same questions 2 or more times!
   return (1)  if ( $ENV{ALREADY_ASKED_ONCE_IN_PROGRAM} && ! $ignore );

   # Set during "gmake test" on windows (Strawberry Perl) ..
   return (1)  if ( $ENV{PERL_USE_UNSAFE_INC} );

   # ok (0, "PERL5LIB = $ENV{PERL5LIB}");

   # Last ditch effort to detect this ...
   if ( exists $ENV{PERL5LIB} ) {
      my $mod = 'Net-FTPSSL-[0-9]+[.][0-9]+';
      foreach my $dir ( File::Spec->catdir ($mod, "blib", "lib"),
                        File::Spec->catdir ($mod, "blib", "arch") ) {
         if ( $ENV{PERL5LIB} =~ m/${dir}($|;|:)/ ) {
            return (1);
         }
      }
   }

   # Assumes called directly via "perl t/xxx.t" ...
   return (0);
}

# =====================================================================

BEGIN {
   # Determine where to put the config file ...
   # Should be in the same directory as the helper module!
   foreach my $dir ( File::Spec->catdir (".", "t", "test-helper"),
                     File::Spec->catdir (".", "test-helper"),
                     "." ) {
      my $mod = File::Spec->catfile ( $dir, "helper1234.pm" );
      my $cfg = File::Spec->catfile ( $dir, "ftpssl.cfg" );
      if ( -f $mod ) {
         $config_file = $cfg;
         last;
      }
   }

   unless ( $config_file ) {
      bail_teseting ("Can't locate the helper module to create the config file!");
   }

   # If it's being run via a make file ...
   # Then don't ask any questions unless we have to ...
   $silent_mode = ( called_by_make_test(0) ) ? 1 : 0;

   # Build the log filename to use based on the program name ...
   my $log = basename ($0, '.t');
   $log = "perl"  if ( $log eq "-e" );
   $log .= '.log.txt';

   foreach my $dir ( File::Spec->catdir (".", "t", "logs"),
                     File::Spec->catdir (".", "logs"),
                     File::Spec->catdir ("..", "logs") ) {
      if ( -d $dir ) {
         $debug_log_file = File::Spec->catfile ( $dir, $log );
         last;
      }
   }

   unless ( $debug_log_file ) {
      bail_testing ("Can't locate where to put the Net::FTPSSL log file!");
   }
}


# =====================================================================
sub get_log_name
{
   return ( $debug_log_file );
}


# =====================================================================
# Tells if we're allowed to upload files to the FTPS server or not.

sub are_updates_allowed
{
   return ( ! $FTPSSL_Defaults{READ_ONLY} );
}


# =====================================================================
sub get_opts_set_in_init
{
   # Save a local copy a user may safely modify ...
   my %opts = %opts_used_in_initialize_func;

   return ( \%opts );
}


# =====================================================================
# Common initialization required by most test cases past t/07-prompt_validation.t.
# If any issues are encountered with your answers, the program automatically dies.

# Always returns a valid Net-FTPSSL object reference.

sub initialize_your_connection
{
   my $alt_log_file = shift;   # Use to override log file to use.
   my %extra_opts   = @_;      # Optional extra arguments needed for a particular test case.

   # Only program "t/01-ask-questions.t" should ever set this value to "1"!
   # All other test programs should set to zero!
   my $force = 0;

   if ( should_we_ask_1st_question ($force) ) {
       should_we_run_test ("Gathering common setup options");
   }

   my ( $host, $user, $pass, $dir, $ftps_opts, $psv_mode ) = ask_config_questions ();

   # Did a test case require extra options?  (not remembered between test runs)
   foreach ( sort keys %extra_opts ) {
      diag ("Overriding $_ => $extra_opts{$_}")  unless ( called_by_make_test(1) );
      $ftps_opts->{$_} = $extra_opts{$_};
   }

   # Save for later use by get_opts() ...
   %opts_used_in_initialize_func = %{$ftps_opts};

   # Set so when the same program makes multiple connections, only asks the 1st time!
   $silent_mode = $ENV{ALREADY_ASKED_ONCE_IN_PROGRAM} = 1;

   # -------------------------------------
   ok ( 1, "User Input Accepted!" );
   # -------------------------------------

   # Overriding what to call the log file?
   $ftps_opts->{DebugLogFile} = $alt_log_file  if ( $alt_log_file );

   my $ftps = Net::FTPSSL->new ( $host, $ftps_opts );
   my $res = isa_ok ( $ftps, 'Net::FTPSSL', 'Net::FTPSSL object created' ) or
       bail_testing ("Can't create a Net::FTPSSL object with the answers given!");

   $res = $ftps->trapWarn ();
   ok ( $res, "Warnings Trapped!" ) or
       bail_testing ("Net-FTPSSL can't trap any warinings!");

   $res = $ftps->login ($user, $pass);
   ok ( $res, "Login Successful!  Your credentials are good!" ) or
      bail_testing ("Can't login to the SFTP server.  Your credentials are probably bad!");

   if ( $psv_mode ne "P" ) {
      # Set via t/07-prompt_validation.t ... (Should be 1 or 2.)
      my $opt = $FTPSSL_Defaults{EXTRA_EPASV_OPT_VALUE} || 1;
      $res = $ftps->force_epsv ( $opt );
      ok ( $res, "Force Extended Pasive MODE (EPSV $opt)" ) or
         bail_testing ("EPSV ${opt} is not supported, please change your answer to use PASV instead!");
   }

   $res = $ftps->cwd ($dir);
   ok ( $res, "Change Dir Successful! ($dir)" ) or
      bail_testing ("Can't change into the test directory on the SFTP server!  Please change your answer for it!");

   if ( $ftps_opts->{Encryption} eq CLR_CRYPT ) {
      ok (1, "FTP connection established ...");
   } else {
      ok (1, "FTPSSL connection established ...");
   }

   return ( $ftps );    # Everyting initialized just fine!
}


# =====================================================================
# Call to determine if we need to ask any questions ...
# Never returns if the config file says to skip all tests!
# Returns:  1 - You must call should_we_run_test()
#           0 - Don't call it!

sub should_we_ask_1st_question
{
   my $force = shift || 0;

   if ( $ENV{PERL_MM_USE_DEFAULT} ) {
      ok (1, "Skipping all tests per smoke tester ENV setting ...");
      unlink ( $config_file );
      stop_testing ();
   }

   # Loads all defaults from a config file if it exists from a previous run.
   # The results are all stored in the global %FTPSSL_Defaults hash.
   my $status = read_config_file ();

   unless ( $status ) {
      ok ( 1, "No config file is present ..." );
      $silent_mode = 0;     # No, force the asking of the questions ...
      return (1);
   }

   if ( $force ) {
      ok ( 1, "Forcing the re-asking of all questions ..." );
      $silent_mode = 0;
      return (2);
   }

   return (3)  unless ( $silent_mode );

   unless ( $FTPSSL_Defaults{FTPSSL_RUN_TESTS} ) {
      ok ( 1, "Skipping all tests per config file settings ..." );
      stop_testing ();
   }

   # No need to call again ...
   return (0);
}


# =====================================================================
# Never returns if you say not to run the tests ...

sub should_we_run_test
{
   # Do you wish to force asking all the questions ???
   my $custom_msg = shift;

   diag ( "" );
   if ( $custom_msg ) {
      diag ( ${custom_msg} );
   } else {
      my $prog = basename ( $0 );
      diag ( "Preparing to run test t/${prog}" );
   }

   diag ( "Some information will be required for running any FTPS tests:" );
   diag ( "A secure ftps server address, a user, a password and a directory" );
   diag ( "where the user has permissions to read and/or write files to." );
   diag ( "Hopefully only the Net::FTPSSL tests have access to to this dir." );
   proxy_supported (1);

   my $copy = $silent_mode;
   $silent_mode = 0;
   my $ans = ask_yesno ("Do you want to run the server connectivity tests", 'FTPSSL_RUN_TESTS');
   $silent_mode = $copy;

   unless ( $ans ) {
      diag ( "Skipping all tests per user request ..." );
      write_config_file ();
      stop_testing ();
   }

   return;
}


# =====================================================================
# Asks all the configuration questions required by the test cases ...
# And then saves the answers to disk so that they are available
# as defaults the next time this method is called!
# These defaults can be found in the %FTPSSL_Defaults hash.
# ---------------------------------------------------------------------
# Returns: The options hash to use in call to Net::FTPSSL->new()
#          plus all other items prompted for.

sub ask_config_questions
{
   # The return values ...
   my ( $host, $user, $pass, $dir, %ftps_opts );

   my $p_flag = proxy_supported ();

   my $read_only = ask_yesno ("Are we restricted to read-only tests", 'READ_ONLY');

   my $server = askQW ("\tServer address ( host[:port] )", undef, undef, 'FTPSSL_SERVER');
   if ( $server =~ m/^([^:]+)[:](\d*)$/ ) {
      $host = $1;
      $ftps_opts{Port} = $2  if ( $2 ne "" );
   } else {
      $host = $server;
   }

   $user = askQW ("\tUser", "anonymous", undef, 'FTPSSL_USER');
   $pass = askQW ("\tPassword [a space for no password]", "user\@localhost", undef, 'FTPSSL_PWD', 0, 1);

   $dir = askQW ("\tDirectory", "<HOME>", undef, 'FTPSSL_DIR');
   $dir = "" if ($dir eq "<HOME>");   # Will ask server for it later on

   my $mode = askQW ("\tConnection mode (I)mplicit, (E)xplicit, or (C)lear.", "E", "(I|E|C)", 'FTPSSL_Encryption', 1);
   $ftps_opts{Encryption} = $mode;

   # If the connection is to be encrypted ...
   if ( $mode ne CLR_CRYPT ) {
      my $ans = askQW ("\tData Connection mode (C)lear or (P)rotected.", "P", "(C|S|E|P)", 'FTPSSL_DataProtLevel', 1);
      $ftps_opts{DataProtLevel} = $ans;

      my $ver = $IO::Socket::SSL::VERSION;
      my $opts;
      my $def = "TLSv12";

      # Values from IO::Socket::SSL.pm ...
      # Search for "my %SSL_OP_NO" initialization.
      if ( Net::SSLeay->can ("OP_NO_TLSv1_3") && $ver >= 2.060 ) {
         $opts = "(SSLv23|TLSv1|TLSv11|TLSv12|TLSv13)";
      } else {
         $opts = "(SSLv23|TLSv1|TLSv11|TLSv12)";
      }
      $ans = askQW ("\tWhat encryption protocal to use", $def, $opts, 'FTPSSL_SSL_version');
      $ftps_opts{SSL_version} = $ans;

   } else {
      delete $FTPSSL_Defaults{FTPSSL_DataProtLevel};
      delete $FTPSSL_Defaults{FTPSSL_SSL_version};
      delete $FTPSSL_Defaults{CERTIFICATE_USAGE};
   }

   my $psv_mode = askQW("\tUse (P)ASV or (E)PSV for data connections", "P", "(P|E)", 'FTPSSL_PASIVE', 1);

   if ( $p_flag ) {
      my $res = ask_proxy_questions ();
      $ftps_opts{ProxyArgs} = $res  if ( $res );
   }

   # Certificates require encrypted communication ...
   if ( $mode ne CLR_CRYPT ) {
      my %certificate;
      if ( ask_certificate_questions ( \%certificate ) ) {
         $ftps_opts{SSL_Client_Certificate} = \%certificate;
      }
   }

   # Hard code these options ...
   $ftps_opts{PreserveTimestamp} = 1;
   $ftps_opts{Timeout} = 30;
   $ftps_opts{Debug}   = 1;
   $ftps_opts{Croak}   = 0;
   # $ftps_opts{Trace}   = 1;

   # Assume help is broken for all connections & all FTP commands are supported.
   # If not needed, it will be removed later via an auto-added extra argument!
   # Found a server where HELP is broken for clear FTP as well.
   $ftps_opts{OverrideHELP} = 1;

   # The log file used by the Net::FTPSSL object in the current test program ...
   $ftps_opts{DebugLogFile} = $debug_log_file;

   # Do we keep any auto-added extra options?
   # Always Assume Yes if there are extra arguments!
   # No matter what was said last time!
   $FTPSSL_Defaults{QUESTION_EXTRA} = 1;

   if ( $extra_args ) {
      my $ans = ask_yesno ("Should we keep automatically-added extra Net::FTPSSL options from previous test runs", 'QUESTION_EXTRA');
      foreach my $key ( keys %FTPSSL_Defaults ) {
         next unless ( $key =~ m/^EXTRA_(.+)$/ );
         my $opt = $1;
         unless ( $ans ) {
            diag ("Removing:  $opt = $FTPSSL_Defaults{$key}");
            delete $FTPSSL_Defaults{$key};
         } elsif ( $opt eq "OverrideHELP" && $FTPSSL_Defaults{$key} == 99 ) {
            # diag ("OverrideHELP is no longer needed!");
            delete $ftps_opts{$opt};
         } else {
            diag ("Keeping:  $opt = $FTPSSL_Defaults{$key}");
            $ftps_opts{$opt} = $FTPSSL_Defaults{$key};
         }
      }
   }

   # Save any changes to our answers ...
   write_config_file ();

   return ( $host, $user, $pass, $dir, \%ftps_opts, $psv_mode );
}


# =====================================================================
# An undocumented way to write to Net::FTPSSL's log file ...
# I don't really recommend using this function yourself.
# But the test scripts are desparate to do this to ease validation
# of all the test cases!

sub write_to_log
{
   my $ftpssl_obj = shift;
   my $label      = shift;
   my $msg        = shift;

   if ( defined $ftpssl_obj &&  ref ($ftpssl_obj) eq "Net::FTPSSL" ) {
      $ftpssl_obj->_print_LOG ($label . ": ", $msg, "\n");
   } else {
      diag ($msg);
   }

   return;
}


# =====================================================================
# A replacement for Test::More::ok() ...
# Where the results of ok() also gets written to the Net::FTPSSL log file ...

sub ok2
{
   my $ftpssl_obj = shift;
   my $status     = shift;
   my $msg        = shift;

   my $sts = ok ( $status, $msg );

   my $lbl = ( $sts ) ? "OK" : "NOT OK";
   write_to_log ($ftpssl_obj, $lbl, $msg);
}

# =====================================================================
# Asks for the proxy information ...
# Only called if the required module is installed.

sub ask_proxy_questions
{
   my $ans = ask_yesno ("Will you be FTP'ing through a proxy server", 'FTPSSL_PROXY_ASK_USE_PROXY');
   unless ( $ans ) {
      delete $FTPSSL_Defaults{FTPSSL_PROXY_HOST};
      delete $FTPSSL_Defaults{FTPSSL_PROXY_PORT};
      delete $FTPSSL_Defaults{FTPSSL_PROXY_USER_PWD_REQUIRED};
      delete $FTPSSL_Defaults{FTPSSL_PROXY_USER};
      delete $FTPSSL_Defaults{FTPSSL_PROXY_PWD};
      return undef;
   }

   my %proxy_args;
   $proxy_args{'proxy-host'} = askQW ("\tEnter your proxy server name", undef, undef, 'FTPSSL_PROXY_HOST');
   $proxy_args{'proxy-port'} = askQW ("\tEnter your proxy port", undef, undef, 'FTPSSL_PROXY_PORT');

   $ans = ask_yesno ("\tDoes your proxy server require a user name/password pair?", 'FTPSSL_PROXY_USER_PWD_REQUIRED');
   if ($ans) {
      $proxy_args{'proxy-user'} = askQW ("\tEnter your proxy user name", undef, undef, 'FTPSSL_PROXY_USER');
      $proxy_args{'proxy-pass'} = askQW ("\tEnter your proxy password", undef, undef, 'FTPSSL_PROXY_PWD');
   } else {
      delete $FTPSSL_Defaults{FTPSSL_PROXY_USER};
      delete $FTPSSL_Defaults{FTPSSL_PROXY_PWD};
   }

   # diag ("Host: ", $proxy_args{'proxy-host'}, "   Port: ", $proxy_args{'proxy-port'}, "  User: ", ($proxy_args{'proxy-user'} || "undef"), "  Pwd: ", ($proxy_args{'proxy-pwd'} || "undef"));

   return \%proxy_args;
}


# =====================================================================
# Tells if we're allowed to use a proxy server ...

sub proxy_supported
{
   my $print_warn = shift;

   eval {
      require Net::HTTPTunnel;
   };
   if ($@) {
      if ( $print_warn ) {
         diag ("NOTE: Using a proxy server is not supported without first installing Net::HTTPTunnel\n");
      }
      return 0;
   }

   return 1;
}


# =====================================================================
# Ask for client certicate information ...
# ---------------------------------------------------------------------
# The client certificate is only used if your FTPS server
# asks for a copy.  Otherwise this certificate info is ignored!
# See the examples in the IO-Socket-SSL distro for more details!
# ---------------------------------------------------------------------
# NOTE: You may use a separate certificate hash or merge it into
#       the main hash.  It works either way these days.
# ---------------------------------------------------------------------

sub ask_certificate_questions
{
   my $ftps_hash = shift;

   my $ans = ask_yesno ("Will you be using Client Certificates", 'CERTIFICATE_USAGE');
   unless ( $ans ) {
      delete $FTPSSL_Defaults{SSL_cert_file};
      delete $FTPSSL_Defaults{SSL_key_file};
      delete $FTPSSL_Defaults{CERTIFICATE_PASSWORD};
      delete $FTPSSL_Defaults{CERTIFICATE_PEER};
      delete $FTPSSL_Defaults{CERTIFICATE_PEER_OVERRIDE};
      return 0;
   }

   $ftps_hash->{SSL_use_cert} = 1;
   $ftps_hash->{SSL_server}   = 0;

   # The developer's certificate location, not in the distribution!
   my $pubkey  = "$ENV{HOME}/Certificate/pubkey.pem";
   my $private = "$ENV{HOME}/Certificate/private.pem";

   # The hint to use when prompting for the password ...
   my $hint_pwd = "my_password";

   # Asks for the Client Certificate information ...
   $ftps_hash->{SSL_cert_file} = ask_for_file ("\tEnter path to public key (pubkey.pem)", 'SSL_cert_file', $pubkey);
   $ftps_hash->{SSL_key_file}  = ask_for_file ("\tEnter path to private key (private.pem)", 'SSL_key_file', $private);

   # Detects if the hint was really needed ...
   $hint_pwd = undef  if ( $ftps_hash->{SSL_key_file} ne $private );

   my $my_pwd = askQW ("\tWhat is your Certificate's password [a space for no password]", $hint_pwd, undef, 'CERTIFICATE_PASSWORD', 0, 1);
   $ftps_hash->{SSL_passwd_cb} = sub { return ( $my_pwd ); };

   $ftps_hash->{SSL_verify_callback} = \&check_certificate;

   $ans = ask_yesno ("\tWill you be using Peer Validation", 'CERTIFICATE_PEER');
   $ftps_hash->{SSL_verify_mode} = $ans ? Net::SSLeay::VERIFY_PEER() : Net::SSLeay::VERIFY_NONE();

   # If using the callback function & selected peer validation ...
   if ( $ans ) {
      $ans = ask_yesno ("\tFor Peer Validation, do you want to override IO-Socket-SSL's decision on if it's a valid certificate", 'CERTIFICATE_PEER_OVERRIDE');
   } else {
      delete $FTPSSL_Defaults{CERTIFICATE_PEER_OVERRIDE};
   }

   return 1;
}


# =====================================================================
# The certificate callback function ...
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

   # Detects if you wish to accept the certificate as valid no mater what!
   if ( $FTPSSL_Defaults{CERTIFICATE_PEER_OVERRIDE} ) {
      $ret = 1;
   }

   my $msg = sprintf ( "\n%s: [%s]\n *** RETURN *** : %s\n\n",
                       $lbl, join ("],\n${ind}: [", @_), $ret );
   diag ( $msg );

   return ( $ret );
}


# =====================================================================
# Returns 1/0 based on the quesion's answer.
# It then updates the given key's value with the return value!

sub ask_yesno
{
   my $question = shift;
   my $hash_key = shift || bail_testing ("Must provide a hash key!");

   my $default = ( $FTPSSL_Defaults{$hash_key} ) ? "Y" : "N";

   my $answer = promptW ($question, $default, "(Y|N)");

   if ( $answer =~ m/^y(es)*$/i ) {
      $FTPSSL_Defaults{$hash_key} = 1;
   } elsif ( $answer =~ m/^n(o)*$/i ) {
      $FTPSSL_Defaults{$hash_key} = 0;
   } else {
      $FTPSSL_Defaults{$hash_key} = ($default eq "Y") ? 1 : 0;
      diag (" *** Invalid Response [$answer].  Using \"$default\" instead!");
   }

   return ( $FTPSSL_Defaults{$hash_key} );
}


# =====================================================================
# A generic question is asked ...
# An answer of " " means to return the empty string "" if no validation is done.

# This is the wrapper function ...
sub askQW
{
   my $question              = shift;
   my $hard_coded_default    = shift;
   my $values_to_choose_from = shift;
   my $hash_key              = shift;
   my $upshift               = shift;
   my $allow_empty_string    = shift;

   my ($dynamic_default, $flag);
   if ( defined $hash_key && $hash_key !~ m/^\s*$/ ) {
      $dynamic_default = $FTPSSL_Defaults{$hash_key};
      $flag = 1;
   }

   my $ans = askQX ($question, $hard_coded_default, $values_to_choose_from, $dynamic_default, $upshift, $allow_empty_string);

   $FTPSSL_Defaults{$hash_key} = $ans   if ( $flag );

   return ($ans);
}


# Does the actual asking ...
sub askQX
{
   my $question              = shift;
   my $hard_coded_default    = shift;
   my $values_to_choose_from = shift || "";  # Ex: (Y|N)
   my $dynamic_default       = shift;
   my $upshift               = shift || 0;
   my $allow_empty_string    = shift || 0;

   # Protect against undef as an argument value ...
   $hard_coded_default = ""  unless (defined $hard_coded_default);
   $dynamic_default = $hard_coded_default  unless (defined $dynamic_default);

   $dynamic_default = uc ($dynamic_default)  if ( $upshift );

   my $answer = promptW ($question, $dynamic_default, $values_to_choose_from);
   $answer = uc ($answer)  if ( $upshift );

   if ( $allow_empty_string && $answer =~ m/^\s+$/ ) {
      $answer = "";     # Overrides any validation checks and/or defaults.

   # Validating the answer ???
   } elsif ( $values_to_choose_from ) {
      my $val;
      if ( $values_to_choose_from =~ m/^[(](.*)[)]$/ ) {
         $val = "|" . $1 . "|";
      } else {
         $val = "|" . $values_to_choose_from . "|";
      }
      $val =~ s/[|]/#/g;

      # If it's an invalid answer, use the default value instead!
      my $ans = "#" . $answer . "#";
      if ( $val !~ m/${ans}/ ) {
         diag (" *** Invalid Response [$answer]. Using \"$dynamic_default\" instead!");
         $answer = $dynamic_default;
      }
   }

   # diag ("ANS: [$answer]");

   return $answer;
}


# =====================================================================
# Asks the user for a valid filename ...

sub ask_for_file
{
   my $question = shift;
   my $hash_key = shift || bail_testing ("Must provide a hash key!");
   my $devDef   = shift;

   my $default = $FTPSSL_Defaults{$hash_key};

   unless ( defined $default ) {
      if ( $devDef && -f $devDef && -r _ ) {
         $default = $devDef;
      }
   }

   my $answer = promptW ($question, $default);

   while (! ( -f $answer && -r _ )) {
      diag ("*** Invalid file name! ***");
      $answer = promptW ($question, $default);
   }

   $FTPSSL_Defaults{$hash_key} = $answer;

   return ( $answer );
}


# =====================================================================
# Prompts the user for a response to a question.
# It doesn't validate the response.
# It can never return undef!

# Based on>> ExtUtils::MakeMaker::prompt (question, default)
# (can't use it since "make test" doesn't display the questions!)

sub prompt
{
   my ($question, $default, $opts) = (shift, shift, shift);

   my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

   my $dispdef = defined $default ? "[$default] " : " ";
   $default = defined $default ? $default : "";

   if (defined $opts && $opts !~ m/^\s*$/) {
      diag ("\n${question} ? $opts $dispdef");
   } else {
      diag ("\n${question} ? $dispdef");
   }

   my $ans;
   if ( $ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
      diag ("${default}\n");
   } else {
      $ans = <STDIN>;
      chomp ($ans);
      unless (defined $ans) {
         diag ("\n");
      }
   }

   $ans = $default  unless ($ans);

   return ( $ans );
}


# =====================================================================
# As a wrapper ...

sub promptW
{
   my ($question, $default, $opts) = (shift, shift, shift);

   my $ans;
   if ( $silent_mode ) {
      $ans = $default;     # Silently use the default ...
      # diag ("${ans}\n");

   } else {
      $ans = prompt ( $question, $default, $opts );
   }

   return ( $ans );
}


# =====================================================================
# Tells us to add the requested option to the config file ...
# Will show up as EXTRA_<option>.

sub add_extra_arguments_to_config
{
   my $option = shift;   # The Net::FTPSSL option to add ...
   my $value  = shift;   # The value to use ...

   my $key = "EXTRA_" . $option;
   $FTPSSL_Defaults{$key} = $value;

   $extra_args = 1;

   write_config_file ();

   return;
}


# =====================================================================
# Create the config file shared between all the test cases!

sub write_config_file
{
   open (FH, ">", $config_file) or bail_testing ("Can't save FTPSSL config settings! ($config_file)");

   foreach my $k (sort keys %FTPSSL_Defaults) {
      printf FH ("%s=%s\n", $k, $FTPSSL_Defaults{$k});
   }

   close (FH);

   # Make sure only readable by owner of file ... Unix:  -rw-------.
   # It contains passwords!
   chmod (0600, $config_file);

   return;
}


# =====================================================================
# Read the config file if it exists!
# And then load all values into the %FTPSSL_Defaults hash.
# Returns:  1 - Success,    0 - No config file or error reading it.

sub read_config_file
{
   unless ( -f $config_file && -r _ ) {
      return (0);    # No such config file or not readable.
   }

   # Reset global var to say no EXTRA_ tags found ...
   $extra_args = 0;

   open ( FH, "<", $config_file ) or return (0);
   while (<FH>) {
      chomp();
      my ($var, $val) = split (/\s*=\s*/, $_, 2);
      $FTPSSL_Defaults{$var} = $val;
      $extra_args = 1  if ( $var =~ m/^EXTRA_/ );
   }
   close (FH);

   return (1);   # It's been read into memory!
}


#required if module is included w/ require command;
1;

