#!/usr/bin/perl -w

# For bare-bones documentation, do "perldoc NewsClipper.pl". A user's manual
#   is included with the purchase of one of the commercial versions.
# To subscribe to the News Clipper mailing list, visit
#   http://www.NewsClipper.com/techsup.htm#MailingList
# Send bug reports or enhancements to bugs@newsclipper.com. Send in a
#   significant enhancement and you'll get a free license for News Clipper.

# Visit the News Clipper homepage at http://www.newsclipper.com/ for more
# information.

#------------------------------------------------------------------------------

# Written by: David Coppit http://coppit.org/ <david@coppit.org>

# This code is distributed under the GNU General Public License (GPL). See
# http://www.opensource.org/gpl-license.html and http://www.opensource.org/.

# ------------------------------------------------------------------------------

require 5.005;
use strict;

use Getopt::Long;
use FileHandle;
use File::Cache;

use vars qw( %config %opts $VERSION $COMPATIBLE_CONFIG_VERSION $lock_manager );

# These need to be predeclared so that this code can be parsed and run until
# we load the NewsClipper::Globals module. WARNING! Be careful to not use
# these until NewsClipper::Globals has been imported!
sub DEBUG();
sub dprint(@);
sub lprint(@);
sub reformat(@);
sub dequote($;$);

# To suppress warnings
use vars qw(&dprint &reformat &dequote);

# The version of the script
$VERSION = do {my @r=(q$ 1.3.2 $=~/\d+/g);sprintf"%d."."%1d"x$#r,@r};

# The version of configuration file that this version of News Clipper can use.
$COMPATIBLE_CONFIG_VERSION = 1.30;

# ------------------------------ MAIN PROGRAM ---------------------------------

sub SetupConfig();
sub print_usage();
sub HandleProxyPassword();
sub HandleClearCache();
sub ProcessFlagCommand();
sub ProcessFiles();
sub PrintDebugSummary(\@);

{
  # Store a copy of @INC for later debugging messages
  my @startingINC = @INC;

  SetupConfig();

  PrintDebugSummary(@startingINC);

  $config{start_time} = scalar localtime time;

  lprint "--------------------------------------------------------------------";
  lprint "News Clipper $VERSION started: $config{start_time}";
}

# Print the usage if the -h flag was used
print_usage() && exit if $opts{h};

# Set up the lockfile. SetupConfig() above created .NewsClipper, so we can
# lock on that. This feature can not be used in Windows because it doesn't
# have fork()
unless (($^O eq 'MSWin32') || ($^O eq 'dos'))
{
  require LockFile::Simple;
  $lock_manager = LockFile::Simple->make('-autoclean' => 1, '-nfs' => 1,
    '-stale' => 1, '-warn' => 0, '-wfunc' => undef, '-efunc' => undef,
    '-hold' => $config{script_timeout} + 10,
    '-max' => 2 * ($config{script_timeout} + 10),
    '-format' => "$NewsClipper::Globals::home/.NewsClipper/lock");
  $lock_manager->lock("$NewsClipper::Globals::home/.NewsClipper")
    or die reformat dequote<<"    EOF";
      There is already another copy of News Clipper running. This copy of News
      Clipper waited 60 seconds for the other copy to finish. Aborting. (You
      should delete $NewsClipper::Globals::home/.NewsClipper/lock if you are
      sure that no other News Clipper is running.)
    EOF
}

HandleProxyPassword();
HandleClearCache();

my $exit_value = 0;

# Do timers unless we are in debug mode or on the broken Windows platform
if (DEBUG || ($^O eq 'MSWin32') || ($^O eq 'dos'))
{
  if ($opts{e})
  {
    ProcessFlagCommand();
  }
  else
  {
    ProcessFiles();
  }
}
else
{
  $SIG{ALRM} = sub { die "newsclipper timeout" };

  eval
  {
    alarm($config{script_timeout});
    if ($opts{e})
    {
      ProcessFlagCommand();
    }
    else
    {
      ProcessFiles();
    }
    alarm(0);
  };

  if ($@)
  {
    # See if it was our timeout
    if ($@ =~ /newsclipper timeout/)
    {
      die "News Clipper script timeout has expired. News Clipper killed.\n";
    }
    else
    {
      # The eval got aborted, so we need to stop the alarm
      alarm (0);
      # and print the error. (I'm not simply die'ing here because I don't like
      # the annoying ...propagated message. I don't know if this is the right
      # way to do this, but it works.)
      warn $@;
      lprint $@;
      $exit_value = 1;
    }
  }
}

$lock_manager->unlock("$NewsClipper::Globals::home/.NewsClipper")
  if defined $lock_manager;

exit($exit_value);

#------------------------------------------------------------------------------

# This is the real meat of the main program. For each file, we parse it,
# executing and News Clipper commands. We also do some work to redirect STDOUT
# to the output file.

sub ProcessFiles()
{
  # Make unbuffered for easier debugging.
  $| = 1 if DEBUG;

  for (my $i=0;$i <= $#{$config{input_files}};$i++)
  {
    dprint "Now processing $config{input_files}[$i] => $config{output_files}[$i]";
    lprint "Processing $config{input_files}[$i] => $config{output_files}[$i]";

    # Print a warning and skip if the file doesn't exist and isn't a text file.
    # However, don't do the checks if the file is STDIN.
    unless ($config{input_files}[$i] eq 'STDIN')
    {
      warn reformat "Input file $config{input_files}[$i] can't be found.\n"
        and next unless -e $config{input_files}[$i];
      warn reformat "Input file $config{input_files}[$i] is a directory.\n"
        and next if -d $config{input_files}[$i];
      warn reformat "Input file $config{input_files}[$i] is empty.\n"
        and next if -z $config{input_files}[$i];
    }

    # We'll write to the file unless we're in DEBUG mode.
    my $writeToFile = 1;
    $writeToFile = 0
      if DEBUG || $config{output_files}[$i] eq 'STDOUT';

    $config{input_files}[$i] = *STDIN if $config{input_files}[$i] eq 'STDIN';

    my $oldSTDOUT = new FileHandle;

    # Redirect STDOUT to a temp file.
    if ($writeToFile)
    {
      # Store the old STDOUT so we can replace it later.
      $oldSTDOUT->open(">&STDOUT") or die "Couldn't save STDOUT: $!\n";

      # If the user wants to see a copy of the output... (Doesn't work in
      # Windows or DOS)
      if ($opts{v} && ($^O ne 'MSWin32') && ($^O ne 'dos'))
      {
        # Make unbuffered
        $| = 2;
        open (STDOUT,"| tee $config{output_files}[$i].temp") 
          or die reformat dequote<<"          EOF";
            Couldn't create temporary output file
            $config{output_files}[$i].temp using "tee": $!
          EOF
      }
      else
      {
        open (STDOUT,">$config{output_files}[$i].temp")
          or die reformat dequote<<"          EOF";
            Couldn't create temporary output file
            $config{output_files}[$i].temp: $!
          EOF
      }
    }

    require NewsClipper::Parser;

    # Okay, now do the magic. Parse the input file, calling the handlers
    # whenever a special tag is seen.

    my $p = new NewsClipper::Parser;
    $p->parse_file($config{input_files}[$i]);

    # Restore STDOUT to the way it was
    if ($writeToFile)
    {
      close (STDOUT);
      open(STDOUT, ">&" . $oldSTDOUT->fileno())
        or die "Can't restore STDOUT: $!.\n";

      # Replace the output file with the temp file. Move it to .del for OSes
      # that have delayed deletes.
      unlink ("$config{output_files}[$i].del");
      rename ($config{output_files}[$i], "$config{output_files}[$i].del");
      rename ("$config{output_files}[$i].temp",$config{output_files}[$i])
        or die "Could not rename $config{output_files}[$i].temp " .
          "to $config{output_files}[$i]: $!";
      unlink ("$config{output_files}[$i].del");

      if ($config{make_output_files_executable} =~ /^y/i)
      {
        chmod 0755, $config{output_files}[$i];
      }
      else
      {
        chmod 0644, $config{output_files}[$i];
      }

      FTP_File($config{output_files}[$i],$config{ftp_files}[$i])
        if defined $config{ftp_files}[$i] &&
           exists $config{ftp_files}[$i]{server};

      Email_File($config{output_files}[$i],$config{email_files}[$i])
        if defined $config{email_files}[$i];
    }
  }
}

#------------------------------------------------------------------------------

# This is a special handler which does parse any files. Instead it creates a
# simple News Clipper command for the handler specified with -e and executes
# that.

sub ProcessFlagCommand()
{
  # Make unbuffered for easier debugging.
  $| = 1 if DEBUG;

  dprint "Now processing handler \"$opts{e}\" => STDOUT";
  lprint "Processing handler \"$opts{e}\" => STDOUT";

  my $oldSTDOUT = new FileHandle;

  require NewsClipper::Parser;

  my $inputCommand;
  # Construct the input command
  if ($opts{e} =~ /<.*>/s)
  {
    $inputCommand = dequote<<"    EOF";
    <!-- newsclipper
      $opts{e}
    -->
    EOF
  }
  else
  {
    $inputCommand .= "<!-- newsclipper\n";

    # Each News Clipper command is separated by a comma
    my @handlers = split /,/,$opts{e};
    for (my $i=0 ; $i <= $#handlers ; $i++)
    {
      if ($i == 0)
      {
        $inputCommand .= "  <input name=$handlers[$i]>\n";
      }
      elsif ($i != $#handlers)
      {
        $inputCommand .= "  <filter name=$handlers[$i]>\n";
      }
      else
      {
        $inputCommand .= "  <output name=$handlers[$i]>\n";
      }
    }

    $inputCommand .= "-->\n";
  }

  my $p = new NewsClipper::Parser;
  $p->parse($inputCommand);
}

# ------------------------------------------------------------------------------

# Send the file to the server. Prints and error to STDERR and returns 0 if
# something goes wrong. Returns 1 otherwise.

sub FTP_File()
{
  my $filename = shift;
  my %ftp_info = %{shift @_};

  dprint "FTP'ing file $filename to server $ftp_info{server}";
  lprint "FTP'ing file $filename to server $ftp_info{server}";

  use Net::FTP;

  my $numTriesLeft = $config{socket_tries};

  my $ftp;    

  do
  {
    $ftp = Net::FTP->new($ftp_info{server},Timeout => $config{socket_timeout});
  } until ($numTriesLeft == 0 || $ftp);

  unless ($ftp)
  {
    warn "FTP connection failed: $@";
    return 0;
  }

  unless ($ftp->login($ftp_info{username},$ftp_info{password}))
  {
    warn "FTP login failed for user $ftp_info{username} on host " .
      "$ftp_info{server}: $@";
    $ftp->quit; 
    return 0;
  }

  unless ($ftp->cwd($ftp_info{dir}))
  {
    warn "Couldn't change to directory $ftp_info{dir} during FTP: $@";
    $ftp->quit; 
    return 0;
  }

  unless ($ftp->put($filename))
  {
    warn "Couldn't FTP file $filename: $@";
    $ftp->quit; 
    return 0;
  }

  $ftp->quit; 
}

# ------------------------------------------------------------------------------

# Send the file to an email address. Prints and error to STDERR and returns 0
# if something goes wrong. Returns 1 otherwise.

sub Email_File()
{
  my $filename = shift;
  my %email_info = %{ shift @_ };

  dprint "Emailing file $filename to $email_info{To}";
  lprint "Emailing file $filename to $email_info{To}";

  open HTML,$filename;
  my $message = join '', <HTML>;
  close HTML;

  $email_info{'content-type'} = 'text/html; charset="iso-8859-1"'
    unless defined $email_info{'content-type'};

  $email_info{'body'} = $message;

  require Mail::Sendmail;

  unless (Mail::Sendmail::sendmail(%email_info))
  {
    warn "Could not send email: $Mail::Sendmail::error";

    # To shut up the warning
    { my $dummy = $Mail::Sendmail::error; }

    return 0;
  }

  return 1;
}

# ------------------------------------------------------------------------------

sub get_exe_name
{
  my $exe_name = $0;
  # Fix the $exe_name if it's the compiled version.
  ($exe_name) = $ENV{sourceExe} =~ /([^\/\\]*)$/ if defined $ENV{sourceExe};

  return $exe_name;
}

# ------------------------------------------------------------------------------

# Prints the usage information

sub print_usage()
{
  my $exeName = get_exe_name();

  my $version = "$VERSION, $config{product}";

  if ($config{product} eq "Personal")
  {
    $version .= " ($config{number_pages} page";
    $version .= "s" if $config{number_pages} > 1;
    $version .= ", $config{number_handlers} handlers)";
  }

  print dequote<<"  EOF";
    This is News Clipper version $version

    usage: $exeName [-adnrvPC] [-i inputfile] [-o outputfile]
           [-c configfile] [-H homepath]
           [-e command,command,...] [command,command,...]

    -i The template file to use as input (overrides value in configuration file)
    -o The output file (overrides value in configuration file)
    -e Run the specified handler and output the results. (Overrides -i and -o.)
    -c The configuration file to use
    -a Automatically download handlers as needed
    -n Check for new versions of the handlers
    -r Forces caching proxies to reload data
    -d Enable debug mode
    -P Pause after completion
    -v Output to STDOUT in addition to the file. (Unix only.)
    -C Clear the cache, handler state, or News Clipper state
    -H Set the user's home directory
  EOF
}

# ------------------------------------------------------------------------------

use File::Spec::Functions qw(splitdir catdir);

# Find the parent directory of a directory. Returns undef if there is no
# parent

sub _Get_Parent_Directory
{
  my ($directory) = @_;

  defined($directory) or
    die("directory required");

  my @directories = splitdir($directory);
  pop @directories;

  return undef unless @directories;

  return catdir(@directories);
}

# ------------------------------------------------------------------------------

# Calls LoadSysConfig and LoadUserConfig to load the system-wide and user
# configuration information.  It then tweaks a few of the configuration
# parameters and loads the News Clipper global functions and constants. Then
# it prints a summary if we're running in DEBUG mode.  Finally, it validates
# the parameters to make sure they are valid.

sub SetupConfig()
{
  SetupSSI();

  ProcessFlags();

  # We load the configuration, being careful not to use any of the stuff in
  # NewsClipper::Globals. (Like dprint, for example.)
  LoadConfigFiles();

  ValidateConfigFiles();

  # Translate the cache size into bytes from megabytes
  $config{max_cache_size} *= 1048576 if defined $config{max_cache_size};

  # Put the handler locations on the include search path
  foreach my $dir (@{$config{handler_locations}})
  {
    unshift @INC,@{$config{handler_locations}} if -d $dir;
  }

  # Override the config values if the user specified -i or -o.
  $config{input_files} = [$opts{i}] if defined $opts{i};
  $config{output_files} = [$opts{o}] if defined $opts{o};

  # This should be in ValidateSetup, but we need to check it before slurping
  # in the NewsClipper::Globals. (We don't need module_path in the compiled
  # version.)
  foreach my $directory (split /\s+/,$config{module_path})
  {
    die "\"$directory\" in module_path setting of NewsClipper.cfg must be a directory.\n"
      unless -d $directory;
  }

  # Put the News Clipper module file location on @INC
  unshift @INC,split(/\s+/,$config{module_path})
    if defined $config{module_path} && $config{module_path} ne '';

  # Now we slurp in the global functions and constants.
  require NewsClipper::Globals;
  NewsClipper::Globals->import;

  $NewsClipper::Globals::home = GetHomeDirectory();

  # Make the .NewsClipper directory if it doesn't exist already.
  mkdir "$NewsClipper::Globals::home/.NewsClipper", 0700
    unless -e "$NewsClipper::Globals::home/.NewsClipper";

  # Make the logfile directories if they don't exist already.
  {
    use File::Path;
    my $debug_log_directory = _Get_Parent_Directory($config{'debug_log_file'});
    my $run_log_directory = _Get_Parent_Directory($config{'run_log_file'});
    mkpath $debug_log_directory unless -e $debug_log_directory;
    mkpath $run_log_directory unless -e $run_log_directory;
  }

  # Initialize the HTML cache, News Clipper state, and handler factory
  require NewsClipper::Cache;
  $NewsClipper::Globals::cache = new NewsClipper::Cache;
  # To shut up the warning
  { my $dummy = $NewsClipper::Globals::cache; }

  # Be sure to do a require here to load our own version of File::Cache.
  # (Remove later when File::Cache supports persistence mechanism choice.)
  $NewsClipper::Globals::state = new File::Cache (
               { cache_key => "$NewsClipper::Globals::home/.NewsClipper/state",
                 namespace => 'NewsClipper',
                 username => '',
                 filemode => 0666,
                 auto_remove_stale => 0,
                 persistence_mechanism => 'Data::Dumper',
               } );
  # To shut up the warning
  { my $dummy = $NewsClipper::Globals::state; }

  require NewsClipper::HandlerFactory;
  $NewsClipper::Globals::handlerFactory = new NewsClipper::HandlerFactory;
  # To shut up the warning
  { my $dummy = $NewsClipper::Globals::handlerFactory; }

  ValidateSetup();
}

# ------------------------------------------------------------------------------

# This function sets up few things for the case when News Clipper is run as
# a server-side include. (We don't support running News Clipper as a CGI
# program.)

sub SetupSSI()
{
  return unless exists $ENV{SCRIPT_NAME};

  # First, we redirect STDERR to STDOUT so errors go to the browser.
  open(STDERR,">&STDOUT");
}

# ------------------------------------------------------------------------------

sub ProcessFlags
{
  # Get the command line flags. Localize @ARGV since getopt destroys it. We
  # do this before loading the configuration in order to get the -c flag.
  local @ARGV = @ARGV;
  Getopt::Long::Configure(
    qw(bundling noignore_case auto_abbrev prefix_pattern=-));
  GetOptions(\%opts, qw(i:s o:s c:s e:s a h d n r v P C H:s));

  # Treat left-over arguments as -e arguments.
  if (@ARGV)
  {
    my $joined_args = join ",",@ARGV;
    @ARGV = ('-e',$joined_args);
  }

  my %extra_opts;
  GetOptions(\%extra_opts, qw(i:s o:s c:s e:s a h d n r v P C H:s));

  if (defined $opts{e})
  {
    $opts{e} .= ",$extra_opts{e}" if defined $extra_opts{e};
  }
  else
  {
    $opts{e} = $extra_opts{e} if defined $extra_opts{e};
  }
}

# ------------------------------------------------------------------------------

# This function loads the system-wide config and the user's config. It dies
# with an error if a configuration file could not be loaded. If the user's
# configuration file can't be found or loaded in Unix, this is okay. But on
# Windows, it is an error.

sub LoadConfigFiles()
{
  my ($sysStatus,$sysConfigMessage) = LoadSysConfig();
  my ($userStatus,$userConfigMessage) = LoadUserConfig();

  # Okay situations
  return if $sysStatus eq 'okay' && $userStatus eq 'okay';
  return if $sysStatus eq 'okay' && ($userStatus eq 'open error' && !$opts{c});
  return if $sysStatus eq 'no env variable' && $userStatus eq 'okay';
  return if $sysStatus eq 'windows' && $userStatus eq 'okay';

  warn $sysConfigMessage if $sysStatus ne 'okay';
  warn "\n" if $sysStatus ne 'okay' && $userStatus ne 'okay';
  warn $userConfigMessage if $userStatus ne 'okay';
  die "\n";
}

# ------------------------------------------------------------------------------

# Loads the system-wide configuration file, storing the location of that file
# in $config{sys_config_file}. The location is specified by the NEWSCLIPPER
# environment variable.

sub LoadSysConfig()
{
  my $warnings;

  $config{sys_config_file} = 'Not specified';

  unless (exists $ENV{NEWSCLIPPER})
  {
    $warnings = <<"    EOF";
News Clipper could not open your system-wide configuration file
because your NEWSCLIPPER environment variable is not set.
    EOF
    return ('no env variable',$warnings);
  }

  return ('windows','') if $^O eq 'MSWin32' || $^O eq 'dos';

  my $configFile = "$ENV{NEWSCLIPPER}/NewsClipper.cfg";

  my ($evalWarnings,$evalResult) = ('',0);

  # Hide any warnings that occur from parsing the config file.
  local $SIG{__WARN__} = sub { $evalWarnings .= $_[0] };
  my $home = GetHomeDirectory();

  # We do an eval instead of doing a "do $configFile" because we want to
  # slurp in $home from the enclosing block. "do $configFile" doesn't slurp
  # $home.
  my $openResult = open CONFIGFILE, $configFile;
  if ($openResult)
  {
    my $code = join '', <CONFIGFILE>;
    close CONFIGFILE;
    $evalResult = eval $code;
  }
  else
  {
    $warnings = <<"    EOF";
News Clipper could not open your system-wide configuration file
"$configFile". Make sure your NEWSCLIPPER environment
variable is set correctly. The error is:
$!
    EOF
    return ('open error',$warnings);
  }

  # Check that the config file wasn't a directory or something.
  if (!-f $configFile)
  {
    $warnings = <<"    EOF";
News Clipper could not open your system-wide configuration file
because "$configFile" is not a plain file.
    EOF

    return ('open error',$warnings);
  }

  # Check if there were any syntax errors while eval'ing the configuration
  # file.
  if ($@)
  {
    $warnings = <<"    EOF";
News Clipper found your system-wide configuration file
"$configFile", but it could not be processed
because of the following error:
$@
    EOF
    return ('compile error',$warnings);
  }

  if ($warnings)
  {
    $warnings = <<"    EOF";
News Clipper found your system-wide configuration file
"$configFile", but encountered some warnings
while processing it:
$evalWarnings
    EOF
    return ('compile error',$warnings);
  }

  # No error message means we found it
  if ($evalResult)
  {
    $config{sys_config_file} = $configFile;
    return ('okay','');
  }
  else
  {
    # Can't get here, since there would have been errors or warnings above.
    die "Whoa! You shouldn't be here! Send email describing what you ".
      "were doing";
  }
}

# ------------------------------------------------------------------------------

# Loads the user's configuration file, storing the location of that file in
# $config{user_config_file}. The location of this file is
# $home/.NewsClipper/NewsClipper.cfg.

sub LoadUserConfig()
{
  $config{user_config_file} = 'Not found';

  my $home = GetHomeDirectory();
  my $configFile = $opts{c} || "$home/.NewsClipper/NewsClipper.cfg";

  my ($evalWarnings,$evalResult,$warnings) = ('',0,'');

  # Hide any warnings that occur from parsing the config file.
  local $SIG{__WARN__} = sub { $evalWarnings .= $_[0] };

  # We do an eval instead of doing a "do $configFile" because we want to
  # slurp in $home from the enclosing block. "do $configFile" doesn't slurp
  # $home.
  my $openResult = open CONFIGFILE, $configFile;
  if ($openResult)
  {
    my $code = join '', <CONFIGFILE>;
    close CONFIGFILE;

    # This is kinda tricky. We don't want the %config in $configFile to
    # totally redefine %main::config, so we wrap the "eval" in a package
    # declaration, which will put the config file's %config in the
    # NewsClipper::config package for later use.
    my $outerPackage = __PACKAGE__;
    package NewsClipper::config;
    use vars qw(%config);

    $evalResult = eval $code;

    # Restore outer package, being careful that the eval doesn't overwrite the
    # $@ result of the previous eval
    {
      local $@;
      eval "package $outerPackage";
    }
  }
  else
  {
    if ($^O eq 'MSWin32' || $^O eq 'dos')
    {
      $warnings = <<"      EOF";
News Clipper could not open your personal configuration file
"$configFile". 
Your registry value for "InstallDir" in
"HKEY_LOCAL_MACHINE\\SOFTWARE\\Spinnaker Software\\News
Clipper\\$VERSION" (or your HOME environment variable) may not be
correct.
      EOF
    }
    else
    {
      $warnings = <<"      EOF";
News Clipper could not open your personal configuration file
"$configFile". The error is:
$!
      EOF
    }

    return ('open error',$warnings);
  }

  # Check that the config file wasn't a directory or something.
  if (!-f $configFile)
  {
    if ($^O eq 'MSWin32' || $^O eq 'dos')
    {
      $warnings = <<"      EOF";
News Clipper could not open your personal configuration file
because "$configFile" is not a plain file.  Your registry
value for "InstallDir" in
"HKEY_LOCAL_MACHINE\\SOFTWARE\\Spinnaker Software\\News
Clipper\\$VERSION" (or your HOME environment variable) may not be
correct.
      EOF
    }
    else
    {
      $warnings = <<"      EOF";
News Clipper could not open your personal configuration file
because "$configFile" is not a plain file. Make sure the file
NewsClipper.cfg is in your <HOME>/.NewsClipper directory.
      EOF
    }

    return ('open error',$warnings);
  }

  # Check if there were any syntax errors while eval'ing the configuration
  # file.
  if ($@)
  {
    $warnings = <<"    EOF";
News Clipper found your personal configuration file
"$configFile", but it could not be processed
because of the following error:
$@
    EOF
    return ('compile error',$warnings);
  }

  if ($evalWarnings)
  {
    $warnings = <<"    EOF";
News Clipper found your personal configuration file
"$configFile", but encountered some warnings
while processing it:
$evalWarnings
    EOF
    return ('compile error',$warnings);
  }

  # No error message means we found it
  if ($evalResult)
  {
    $config{user_config_file} = $configFile;

    # Now override main's %config
    while (my ($key,$value) = each %NewsClipper::config::config)
    {
      $main::config{$key} = $value;
    }

    undef %NewsClipper::config::config;
    return ('okay','');
  }
  else
  {
    # Can't get here, since there would have been errors or warnings above.
    die "Whoa! You shouldn't be here! Send email describing what you ".
      "were doing";
  }
}

# ------------------------------------------------------------------------------

# Simply gets the home directory. First it tries to get it from the password
# file, then from the Windows registry, and finally from the HOME environment
# variable.

sub GetHomeDirectory()
{
  # Get the user's home directory. First try the password info, then the
  # registry (if it's a Windows machine), then any HOME environment variable.
  my $home = $opts{H} || eval { (getpwuid($>))[7] } || 
    GetWinInstallDir() || $ENV{HOME};

  # "s cause problems in Windows. Sometimes people set their home variable as
  # "c:\Program Files\NewsClipper", which causes when the path is therefore
  # "c:\Program Files\NewsClipper"\.NewsClipper\Handler\Acquisition
  $home =~ s/"//g if defined $home;

  die <<"  EOF"
News Clipper could not determine your home directory. On non-Windows
machines, News Clipper attempts to get your home directory using getpwuid,
then the HOME environment variable. On Windows machines, it attempts to
read the registry entry "HKEY_LOCAL_MACHINE\\SOFTWARE\\Spinnaker
Software\\News Clipper\\$VERSION" then tries the HOME environment
variable.
  EOF
    unless defined $home;

    return $home;
}

# ------------------------------------------------------------------------------

sub ValidateConfigFiles
{
  die <<"  EOF"
Could not find either a system-wide configuration file or a personal
configuration file.
  EOF
    if $config{sys_config_file} eq 'Not specified' &&
       $config{user_config_file} eq 'Not found';

  if (!defined $config{for_news_clipper_version} ||
      ($config{for_news_clipper_version} < $COMPATIBLE_CONFIG_VERSION))
  {
    my $version_string = $config{for_news_clipper_version};
    $version_string = 'pre-1.21' unless defined $version_string;

    die <<"    EOF";
Your NewsClipper.cfg configuration file is incompatible with this
version of News Clipper (need $COMPATIBLE_CONFIG_VERSION, have $version_string).
Please run "ConvertConfig /path/NewsClipper.cfg" using the ConvertConfig that
came with this distribution of News Clipper.
    EOF
  }
}

# ------------------------------------------------------------------------------

# Checks the setup (system-wide modified by user's) to make sure everything is
# okay.

sub ValidateSetup()
{
  die "\"handler_locations\" in NewsClipper.cfg must be non-empty.\n"
    if $#{$config{handler_locations}} == -1;

  foreach my $dir (@{$config{handler_locations}})
  {
    die "\"$dir\" from handler_locations in NewsClipper.cfg is not ".
      "a directory.\n" unless -d $dir;
  }

  CheckRegistration();

  # Check that the user isn't trying to use the -i and -o flags for the Trial
  # and Personal versions
  if (($config{product} eq "Trial" ||
       $config{product} eq "Personal") &&
      (defined $opts{i} || defined $opts{o}))
  {
    die reformat dequote<<"    EOF";
      The -i and -o flags are disabled in the Trial and Personal versions of
      News Clipper. Please specify your input and output files in the
      NewsClipper.cfg file.
    EOF
  }

  # Check that the input files and output files match
  if ($#{$config{input_files}} != $#{$config{output_files}})
  {
    die reformat dequote <<"    EOF";
      Your input and output files are not correctly specified. Check your
      configuration file NewsClipper.cfg.
    EOF
  }

  # Check that if the user is using ftp_files, the number matches
  if ($#{$config{ftp_files}} != -1 &&
      $#{$config{ftp_files}} != $#{$config{output_files}})
  {
    die reformat dequote <<"    EOF";
      Your ftp information is not correctly specified. If you do not want to
      ftp any files, there should be nothing specified. If you want to ftp any
      files, you must specify the information for each file, or use "{}" to
      indicate that a file should not be sent.
    EOF
  }

  # Check that if the user is using email_files, the number matches
  if ($#{$config{email_files}} != -1 &&
      $#{$config{email_files}} != $#{$config{output_files}})
  {
    die reformat dequote <<"    EOF";
      Your email information is not correctly specified. If you do not want to
      email any files, there should be nothing specified. If you want to email
      any files, you must specify the information for each file, or use "{}"
      to indicate that a file should not be emailed.
    EOF
  }

  # Check that the user isn't trying to process more than one input file for
  # the Trial version
  if ($#{$config{input_files}} > 0 && $config{product} eq "Trial")
  {
    die reformat dequote <<"    EOF";
      Sorry, but the Trial version of News Clipper can only process one input
      file.
    EOF
  }

  # Check that the user isn't trying to process more than the registered
  # number of files for the Personal version
  if ($config{product} eq "Personal" &&
      $#{$config{input_files}}+1 > $config{number_pages} )
  {
    die reformat dequote<<"    EOF";
      Sorry, but this Personal version of News Clipper is only registered to
      process $config{number_pages} input files.
    EOF
  }

  die "No input files specified.\n" if $#{$config{input_files}} == -1;

  # Check that they specified cache_location and max_cache_size
  die "cache_location not specified in NewsClipper.cfg\n"
    unless defined $config{cache_location} &&
           $config{cache_location} ne '';
  die "max_cache_size not specified in NewsClipper.cfg\n"
    unless defined $config{max_cache_size} &&
           $config{max_cache_size} != 0;

  # Check socket_tries, and set it if necessary
  $config{socket_tries} = 1 unless defined $config{socket_tries};
  die "socket_tries must be 1 or more\n" unless $config{socket_tries} > 0;
}

# ------------------------------------------------------------------------------

# Prints some useful information when running in DEBUG mode.

sub PrintDebugSummary(\@)
{
  my @startingINC = @{shift @_};

  return unless DEBUG;

  my $exe_name = get_exe_name();

  dprint "Operating system:\n  $^O";
  dprint "Version:\n  $VERSION, $config{product}";
  dprint "Command line was:\n  $exe_name @ARGV";
  dprint "Options are:";

  foreach my $key (sort keys %opts)
  {
    dprint "  $key: $opts{$key}";
  }

  dprint "\$ENV{NEWSCLIPPER}:\n";
  if (defined $ENV{NEWSCLIPPER})
  {
    dprint "  $ENV{NEWSCLIPPER}";
  }
  else
  {
    dprint "  <NOT SPECIFIED>";
  }

  dprint "Home directory:\n  " . GetHomeDirectory();
  
  require Cwd;
  dprint "Current directory:\n  ",Cwd::cwd(),"\n";

  dprint "System-wide configuration file found as:\n  $config{sys_config_file}\n";
  dprint "Personal configuration file found as:\n  $config{user_config_file}\n";

  dprint "\@INC before loading configuration:";
  dprint "  $_" foreach @startingINC;

  dprint "\@INC after loading configuration:";
  foreach my $i (@INC)
  {
    dprint "  $i";
  }

  dprint "Configuration is:";

  DumpData(\%config,'  ');
}

# ------------------------------------------------------------------------------

# Recursively outputs a data structure, with indentation. First argument is
# a ref to the data, and the second argument is the prefix to append to the
# output.

sub DumpData
{
  my $data = shift;
  my $prefix = shift;

  if (!defined $data)
  {
    dprint "$prefix<NOT SPECIFIED>\n";
  }
  elsif (!ref $data)
  {
    if (defined $data && $data ne '')
    {
      dprint "$prefix$data\n";
    }
    else
    {
      dprint "$prefix<NOT SPECIFIED>\n";
    }
  }
  elsif (UNIVERSAL::isa($data,'SCALAR'))
  {
    if (defined $$data && $$data ne '')
    {
      dprint "$prefix$$data\n";
    }
    else
    {
      dprint "$prefix<NOT SPECIFIED>\n";
    }
  }
  elsif (UNIVERSAL::isa($data,'ARRAY'))
  {
    foreach my $temp (@$data)
    {
      DumpData($temp,$prefix);
    }
  }
  elsif (UNIVERSAL::isa($data,'HASH'))
  {
    foreach my $temp (keys %$data)
    {
      dprint "$prefix$temp:";
      DumpData($$data{$temp},"$prefix  ");
    }
  }
  else
  {
print STDERR "6\n";
    dprint "$prefix<UNKNOWN TYPE>\n";
  }
}

# ------------------------------------------------------------------------------

# Checks the registration key to make sure it's a valid one.

sub CheckRegistration()
{
  # Set the default product type
  $config{product} = "Trial";
  $config{number_pages} = 1;
  $config{number_handlers} = 1;

  # Override the product type in the Open Source version.
  $config{product} = "Open Source", return;

  # Extract the date, license type, and crypt'd code from the key
  my ($date,$license,$numPages,$numHandlers,$code) =
    $config{registration_key} =~ /^(.*?)#(.*?)#(.*?)#(.*)#(.*)$/;

  # In case the registration_key isn't valid
  $date = '' unless defined $date;
  $license = '' unless defined $license;
  $numPages = '' unless defined $numPages;
  $numHandlers = '' unless defined $numHandlers;
  $code = '' unless defined $code;

  # We will try two strings--one with the operating system (pre-1.32) and one
  # without the operating system (after-1.32).
  my $licensestring1 =
    "$date#$license#$^O#$config{email}#$numPages#$numHandlers";
  my $licensestring2 =
    "$date#$license#$config{email}#$numPages#$numHandlers";

  # Mash groups of eight together to help hash the string for crypt, which can
  # only use up to eight characters
  my $hashed1 = "";
  my $hashed2 = "";

  foreach ($licensestring1 =~ /(.{1,8})/gs) { $hashed1 ^= $_ }
  foreach ($licensestring2 =~ /(.{1,8})/gs) { $hashed2 ^= $_ }

  # Now check the key.
  if ((crypt($hashed1,$code) eq $code) || (crypt($hashed2,$code) eq $code))
  {
    if ($license eq 'p')
    {
      $config{product} = "Personal";
      $config{number_pages} = $numPages;
      $config{number_handlers} = $numHandlers;
    }

    if ($license eq 'c')
    {
      $config{product} = "Corporate";
    }
  }
  elsif ($config{registration_key} ne 'YOUR_REG_KEY_HERE')
  {
    warn reformat dequote<<"    EOF";
      ERROR: Your registration key appears to be incorrect. Here is the
      information News Clipper was able to determine:
    EOF
    die dequote '  ',<<"    EOF";
      System-wide configuration file: $config{sys_config_file}
      Personal configuration file: $config{user_config_file}
      Email: $config{email}
      Key: $config{registration_key}
      Date Issued: $date
      License Type: $license
      Number of pages: $numPages
      Number of Handlers: $numHandlers
    EOF
  }
  else
  {
    # Stays the trial version
  }
}

# ------------------------------------------------------------------------------

# Clear the cache, prompting the user if necessary.
#
# DO NOT REMOVE THE PROMPT! We don't want hordes of websites calling us
# because someone is clearing their cache and hitting the servers every 5
# minutes of the day.

sub HandleClearCache()
{
  use File::Path;

  if ($opts{C})
  {
    my $response;

    # Clear HTML cache
    print "Do you want to clear the HTML cache? ";
    $response = <STDIN>;

    while ($response !~ /^[yn]/i)
    {
      print "Yes or no? ";
      $response = <STDIN>;
    }

    if ($response =~ /^y/i)
    {
      rmtree (["$config{cache_location}/html"]);
    }

    # Clear handler state
    print "Do you want to clear the handler-specific data storage? ";
    $response = <STDIN>;

    while ($response !~ /^[yn]/i)
    {
      print "Yes or no? ";
      $response = <STDIN>;
    }

    if ($response =~ /^y/i)
    {
      rmtree (["$NewsClipper::Globals::home/.NewsClipper/state/Acquisition"]);
      rmtree (["$NewsClipper::Globals::home/.NewsClipper/state/Filter"]);
      rmtree (["$NewsClipper::Globals::home/.NewsClipper/state/Output"]);
    }

    # Clear News Clipper state
    print reformat "Do you want to clear News Clipper's data storage " .
      "(which includes the times that handlers were last checked for updates)? ";
    $response = <STDIN>;

    while ($response !~ /^[yn]/i)
    {
      print "Yes or no? ";
      $response = <STDIN>;
    }

    if ($response =~ /^y/i)
    {
      rmtree (["$NewsClipper::Globals::home/.NewsClipper/state/NewsClipper"]);
    }

    # Clear debug log
    print reformat "Do you want to clear the debug log? ";
    $response = <STDIN>;

    while ($response !~ /^[yn]/i)
    {
      print "Yes or no? ";
      $response = <STDIN>;
    }

    if ($response =~ /^y/i)
    {
      open DEBUG_LOG, ">$config{'debug_log_file'}";
      close DEBUG_LOG;
    }

    # Clear run log
    print reformat "Do you want to clear the run log? ";
    $response = <STDIN>;

    while ($response !~ /^[yn]/i)
    {
      print "Yes or no? ";
      $response = <STDIN>;
    }

    if ($response =~ /^y/i)
    {
      open DEBUG_LOG, ">$config{'run_log_file'}";
      close DEBUG_LOG;
    }

    exit(0);
  }
}

# ------------------------------------------------------------------------------

# This routine allows the user to enter a username and password for a proxy.

sub HandleProxyPassword()
{
  # Handle the proxy password, if a username was given but not a password, and
  # a tty is available.
  if (($config{proxy_username} ne '') &&
      (($config{proxy_password} eq '') && (-t STDIN)))
  {
    unless (eval "require Term::ReadKey")
    {
      die reformat dequote<<"      EOF";
        You need Term::ReadKey for password authorization.\nGet it from
        CPAN.\n";
      EOF
    }

    # Make unbuffered
    my $oldBuffer = $|;
    $|=1;

    print "Please enter your proxy password: ";

    # Turn off echo to read in password
    Term::ReadKey::ReadMode('noecho');

    $config{proxy_password} = <STDIN>;
    chomp($config{proxy_password});

    # Turn echo back on
    Term::ReadKey::ReadMode ('restore');

    # Give the user a visual cue that their password has been entered
    print "\n";

    $| = $oldBuffer;
  }
}

# ------------------------------------------------------------------------------

# Attempts to grab the installation from the registry for Windows machines. It
# returns nothing if anything goes wrong, otherwise the installation path.

sub GetWinInstallDir()
{
  return if ($^O ne 'MSWin32') && ($^O ne 'dos');

  require Win32::Registry;

  # To get rid of "main::HKEY_LOCAL_MACHINE" used only once warning.
  $main::HKEY_LOCAL_MACHINE = $main::HKEY_LOCAL_MACHINE;

  my $key = "SOFTWARE\\Spinnaker Software\\News Clipper\\$VERSION";
  my $TempKey;

  # Return if we can't find the key in the registry.
  $main::HKEY_LOCAL_MACHINE->Open($key, $TempKey) || return;

  my ($class, $nSubKey, $nVals);
  $TempKey->QueryKey($class, $nSubKey, $nVals);

  # Return if there are no values for the key.
  return if $nVals <= 0;

  my ($value,$type);

  # Return if we can't find the value.
  $TempKey->QueryValueEx('InstallDir',$type,$value) || return;

  # Return if the value is there, but is the wrong type.
  return unless $type == 1;

  return $value;
}

#-------------------------------------------------------------------------------

# If we're in DEBUG mode, output the modules we used during this run. Be
# careful not to try to do this if something bad happened before we loaded
# NewsClipper::Globals, which set the DEBUG constant.

END
{
  # Only do this if we got far enough to define dprint and lprint;
  if (defined &DEBUG)
  {
    # Print the modules used to the debug log
    dprint "Here are all the modules used during this run, and their locations:";
    foreach my $key (sort keys %INC)
    {
      dprint "  $key =>\n    $INC{$key}";
    }

    # Print process completion status to the status and run logs
    my $end_time = scalar localtime time;

    if ($? == 0)
    {
      lprint "News Clipper completed normally: $end_time";
    }
    else
    {
      lprint "News Clipper completed but had an error: $end_time";
    }
  }

  if ($opts{P})
  {
    $| = 1;
    print "News Clipper has finished processing the input files.\n" .
          "Press enter to continue...";
    <STDIN>;
  }
}

# ------------------------------------------------------------------------------

# Needed by compiler

#perl2exe_include constant
#perl2exe_include NewsClipper/AcquisitionFunctions
#perl2exe_include NewsClipper/Cache
#perl2exe_include NewsClipper/HTMLTools
#perl2exe_include NewsClipper/Handler
#perl2exe_include NewsClipper/HandlerFactory
#perl2exe_include NewsClipper/Interpreter
#perl2exe_include NewsClipper/Parser
#perl2exe_include NewsClipper/Types
#perl2exe_include Time/CTime
#perl2exe_include Date/Format
#perl2exe_include Net/NNTP
#perl2exe_include File/Spec/Win32.pm

#-------------------------------------------------------------------------------

__END__

=head1 NAME

News Clipper - downloads and integrates dynamic information into web pages

=head1 SYNOPSIS

 Using the input and output files specified in either the system-wide
 NewsClipper.cfg file, or the personal NewsClipper.cfg file in
 ~/.NewsClipper

 $ NewsClipper.pl [-anrv] [-c configfile]

 Override the input and output files

 $ NewsClipper.pl [-anrv] [-c configfile] \
   -i inputfile -o outputfile

 Provide a sequence of News Clipper commands on the command line

 $ NewsClipper.pl [-anrv] [-c configfile] \
   -e "handlername, handlername, handlername"


=head1 DESCRIPTION

I<News Clipper> grabs dynamic information from the internet and integrates it
into your webpage. Features include modular extensibility, timeouts to handle
dead servers without hanging the script, user-defined update times, and
automatic installation of modules. 

News Clipper takes an input HTML file, which includes special tags of the
form:

  <!--newsclipper
    <input name=X>
    <filter name=Y>
    <output name=Z>
  -->

where I<X> represents a data source, such as "yahootopstories", "slashdot",
etc. When such a tag is encountered, News Clipper attempts to load and execute
the handler to acquire the data. Then the data is sent to the filter named by
I<Y>, and then on to the output handler named by I<Z>.  If the handler can not
be found, the script asks for permission to attempt to download it from the
central repository.


=head1 HANDLERS

News Clipper has a modular architecture, in which I<handlers> implement the
acquisition and output of data gathered from the internet. To use new data
sources, first locate an interesting one at
http://www.newsclipper.com/handlers.html, then place
the News Clipper tag in your input file. Then run News Clipper once manually,
and it will prompt you for permission to download and install the handler.

You can control, at a high level, the format of the output data by using the
built-in filters and handlers described on the handlers web page. For more
control over the style of output data, you can write your own handlers in
Perl. 

To help handler developers, a utility called I<MakeHandler.pl> is included with
the News Clipper distribution. It is a generator that asks several questions,
and then creates a basic handler.  Handler development is supported by two
APIs, I<AcquisitionFunctions> and I<HTMLTools>. For a complete description of
these APIs, as well as suggestions on how to write handlers, visit
http://www.newsclipper.com/handlers.html.

News Clipper has the ability to automatically download handlers whose
functionality did not change relative to the currently installed version.
This means that you can safely download the update and be guaranteed that it
will not break your existing News Clipper commands.  These "bugfix updates"
are controlled by the auto_download_bugfix_updates value in the
NewsClipper.cfg file.

You can also tell News Clipper to download "functional updates", which are
handlers whose interface has changes relative to the version you have. These
updates are the most recent versions of the handler, but they contain changes
that may break existing News Clipper commands.


=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<-i> inputfile

Override the input file specified in the configuration file. The special
filename "STDIN" gets input from standard input (useful for piping commands to
News Clipper).

=item B<-o> outputfile

Override the output file specified in the configuration file. The special
filename "STDOUT" sends output to standard output instead of a file.

=item B<-e> commands

Run the specified handler using the default filters and output handlers, and
output the result to STDOUT. This option overrides B<-i> and B<-o>. Commands
can be in the form of a normal News Clipper bracket syntax, or as a
comma-separated list. For example, the following are equivalent:

 $ echo '<!-- newsclipper <input name=date style=day><output name=string> -->' | \
   NewsClipper.pl -i STDIN -o STDOUT

 $ NewsClipper.pl -e 'date style=day,string'

 $ NewsClipper.pl -e '<input name=date style=day><output name=string>'

Note that commas can not be escaped -- commas that appear in quotes, for
example, B<will> be interpreted as delimiters between commands.

=item B<-c>

Use the specified file as the configuration file, instead of NewsClipper.cfg.

=item B<-n>

Check for new bugfix and functional updates to any handlers encountered.

=item B<-a>

Automatically download any bugfix or functional updates to handlers News
Clipper processes. Use the auto_download_bugfix_updates in the configuration
file to always download bugfix versions, but not functional updates. This flag
should only be used when News Clipper is run interactively, since functional
updates can break web pages that rely on the older functionality.

=item B<-P>

Pause after News Clipper has completed execution. (This is useful when running
News Clipper in a window that automatically closes upon program exit.)

=item B<-r>

Reload the content from the proxy server even on a cache hit. This prevents
News Clipper from using stale data when constructing the output file.

=item B<-d>

Enable debug mode, which prints extra information about the execution of News
Clipper. Output is sent to the screen instead of the output file.

=item B<-v>

Verbose output. Output a copy of the information sent to the output file to
standard output. Does not work on Windows or DOS.

=item B<-H>

Use the specified path as the user's home directory, instead of auto-detecting
the path. This is useful for specifying the location of the .NewsClipper
directory.

=item B<-C>

Clear the News Clipper cache, handler-specific state, or News Clipper state.
The cache contains information acquired by acquisition handlers.
Handler-specific state is any information that handlers store between runs.
News Clipper state is any information that News Clipper stores between runs,
such as the last time a handler was checked for an update.

Clearing the cache significantly slows down News Clipper and increases network
traffic on remote servers---use with care. Similarly, clearing News Clipper
state forces News Clipper to check for updates to handlers.

=back

=head1 Configuration

The file NewsClipper.cfg contains the configuration. News Clipper will first
look for this file in the system-wide location specified by the NEWSCLIPPER
environment variable. News Clipper will then load the user's NewsClipper.cfg
from $home/.NewsClipper. Any options that appear in the personal configuration
file override those in the system-wide configuration file, except for the
module_path option. In this file you can specify the following:

=over 2

=item $ENV{TZ}

The timezone for Windows. (This is automatically detected on Unix-like
platforms.)

=item email

The user's email address. This is used for registration for the commercial
version.

=item registration_key

The registration key. This is used for registration for the commercial
version.

=item input_files, output_files

Multiple input and output files. The first input file is transformed into the
first output file, the second input file to the second output file, etc.

=item handler_locations

The locations of handlers. For example, ['dir1','dir2'] would look for
handlers in dir1/NewsClipper/Handler/ and dir2/NewsClipper/Handler/. Note that
while installing handlers, the first directory is used. This can be used to
provide a location for a single repository of handlers, which can be shared
by all users.

=item module_path

The location of News Clipper's modules, in case the aren't in the standard
Perl module path. (Set during installation.) For pre-compiled versions of News
Clipper, this setting also includes extra directories, separated by
whitespace, which are paths in which to search for any additional Perl
modules.

=item cache_location

The location of the cache in the file system.

=item max_cache_size

The maximum size of the cache in megabytes. It should be at least 5.

=item script_timeout

The timeout value for the script. This puts a limit on the total time the
script can execute, which prevents it from hanging. This does not work on
Windows or DOS.

=item socket_timeout

The timeout value for socket connections. This allows the script to recover
from unresponsive servers.

=item socket_tries

The number of times to try a connection before giving up.

=item proxy

Your proxy host. For example, "http://proxy.host.com:8080/"

=item proxy_username

=item proxy_password

Your proxy username and password.

=item auto_download_bugfix_updates

Set to "yes" to automatically download bugfix updates to handlers.

=item tag_text

The keyword to indicate News Clipper commands. The default is "newsclipper",
which results in <!-- newsclipper ... --> as the default command comment.

=item make_output_files_executable

Set to "yes" to make output files executable.

=item debug_log_file

=item run_log_file

The file (with path) to which the debug and run logs should be appended.

=item max_number_of_log_files

=item max_log_file_size

The maximum number of log files to maintain, and the maximum size of any log
file.

=back

NewsClipper.cfg also contains handler-specific configuration options. These
options are generally documented in the handler's syntax documentation.

The NewsClipper.cfg that comes with the distribution contains default
configuration information for the cacheimages handler:

=over 2

=item imgcachedir

The location in the filesystem of the image cache. This location should be
visible from the web.

=item imgcacheurl

The URL that corresponds to the image cache directory specified by
imgcachedir. 

=item maximgecacheage

The maximum age of images in the image cache. Old images will be removed from
the cache.

=back

=head1 RUNNING

You can run NewsClipper.pl from the command line. The B<-e>, B<-i>, and B<-o>
flags allow you to test your input files. When you are happy with the way
things are working, you should run News Clipper as a cron job. To do this,
create a .crontab file with something similar to the following:

=over 4

0 7,10,13,16,19,22 * * * /path/NewsClipper.pl

=back

"man cron" for more information.

=head1 PREREQUISITES

This script requires the C<Time::CTime>, C<Time::ParseDate>, C<LWP::UserAgent>
(part of libwww), C<URI>, C<HTML-Tree>, and C<HTML::Parser> modules, in
addition to others that are included in the standard Perl distribution.
See the News Clipper distribution's README file for more information.

Handlers that you download may require additional modules.

=head1 NOTES

News Clipper has 2 web sites: the open source homepage at
http://newsclipper.sourceforge.net, and the commercial homepage at
http://www.newsclipper.com/ The open source homepage has instructions for
getting the source via CVS, and has documentation aimed at developers. The
commercial web site contains a FAQ, information for buying the commercial
version, and more.

=head1 AUTHOR

David Coppit, <david@coppit.org>, http://coppit.org/
Spinnaker Software, Inc.

=begin CPAN

=pod COREQUISITES

none

=pod OSNAMES

any

=pod SCRIPT
