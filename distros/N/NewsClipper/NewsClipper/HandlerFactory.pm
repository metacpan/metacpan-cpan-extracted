# -*- mode: Perl; -*-
package NewsClipper::HandlerFactory;

# This package implements a "Handler Factory", which is used to find and
# return handler objects.

use strict;
use Carp;
# For UserAgent
use LWP::UserAgent;
# For mkpath
use File::Path;

use vars qw( $VERSION );

$VERSION = 0.91;

use NewsClipper::Globals;
use NewsClipper::Server;

my $userAgent = new LWP::UserAgent;

my $TIME_BETWEEN_FUNCTIONAL_UPDATES = 24 * 60 * 60;
my $TIME_BETWEEN_BUGFIX_UPDATES = 8 * 60 * 60;

# A reference to the server object
my $SERVER;

# Caches used to avoid unnecessary processing of handlers
my @UPDATED_HANDLERS;
my @ALLOWED_HANDLERS;
my %COMPATIBLE_HANDLERS;

# Avoid multiple warnings about the server being down
my $ALREADY_WARNED_SERVER_DOWN = 0;

# This version of News Clipper uses handlers of this type
my $COMPATIBLE_NEWS_CLIPPER_VERSION = 1.18;

# ------------------------------------------------------------------------------

sub new
{
  my $proto = shift;

  # We take the ref if "new" was called on an object, and the class ref
  # otherwise.
  my $class = ref($proto) || $proto;

  # Create an "object"
  my $self = {};

  # Make the object a member of the class
  bless ($self, $class);

  # Initialize the server connection
  $SERVER = new NewsClipper::Server;

  return $self;
}

# ------------------------------------------------------------------------------

# Finds and creates a handler object for the given name. Downloads a new
# handler from the server if the handler is not installed on the system, or if
# an update is needed. Returns undef if the handler can not be loaded and
# created.

sub Create
{
  my $self = shift;
  my $handler_name = shift;

  croak "You must supply a handler name to HandlerFactory\n"
    unless defined $handler_name;

  $handler_name = lc($handler_name);

  # First see if the handler is okay to use given the trial/personal
  # restrictions.
  _Check_Registration_Restriction($handler_name);

  # Download the handler if we need to, either because ours is
  # out of date, or because we don't have it installed.
  _Update_Handler($handler_name);

  # Check that the handler version is compatible
  return undef unless _Handler_Version_Is_Compatible($handler_name);

  my $loadResult;

  # Try to load the handler
  $loadResult = _Load_Handler($handler_name);

  if ($loadResult =~ /^found/)
  {
    dprint "Creating handler \"$handler_name\"";
    my ($fullHandler) = $loadResult =~ /found as (.*)/;
    return "$fullHandler"->new;
  }
  elsif ($loadResult eq 'not found')
  {
    return undef;
  }
}

# ------------------------------------------------------------------------------

# Downloads or updates the handler from the remote server if necessary.
# Updates are necessary if:
# * the handler isn't anywhere on the system
# * auto_download_bugfix_updates is 'yes' and there is a bugfix version
# * -n was specified and a functional or bugfix version is available.

sub _Update_Handler
{
  my $handler_name = shift;

  dprint "Checking if handler \"$handler_name\" needs to be updated.";

  # Skip this handler if we've already processed it.
  if (grep { /^$handler_name$/i } @UPDATED_HANDLERS)
  {
    dprint "Skipping already updated handler \"$handler_name\".";
    return;
  }

  push @UPDATED_HANDLERS,$handler_name;

  # First check if the handler isn't on the system.
  if (_Load_Handler($handler_name) eq 'not found')
  {
    dprint "Handler isn't installed, so we need to download it.";
    _Download_New_Handler($handler_name);
    return;
  }

  # The handler is on the system, so do an update if we need to.
  my $update_status;

  $update_status = _Do_Handler_Functional_Update($handler_name);
  return if $update_status =~ /^(updated|failed)$/;

  $update_status = _Do_Handler_Bugfix_Update($handler_name);
}

# ------------------------------------------------------------------------------

# Downloads and installs the latest version of a handler

sub _Download_New_Handler($)
{
  my $handler_name = shift;

  my ($versionStatus,$newVersion,$updateType) =
    $SERVER->Get_New_Handler_Version($handler_name, 'functional',
      undef, $COMPATIBLE_NEWS_CLIPPER_VERSION);

  if ($versionStatus eq 'not found')
  {
    warn reformat dequote <<"    EOF";
      Can't download handler $handler_name.
      The handler server reports that the handler $handler_name is not in
      the database.
    EOF
    return;
  }

  if ($versionStatus eq 'no update')
  {
    die "News Clipper encountered a \"no update\" when there is no local " .
      "version of handler $handler_name";
  }

  if ($versionStatus eq 'failed')
  {
    return if $ALREADY_WARNED_SERVER_DOWN;
    $ALREADY_WARNED_SERVER_DOWN = 1;

    warn reformat dequote <<"    EOF";
      Couldn't determine which version of the handler $handler_name to
      download because the server is down. Try again in a while, and send
      email to bugreport\@newsclipper.com if the problem persists.
      Additional warnings regarding this problem will not be displayed.
    EOF
    return;
  }

  if ($versionStatus ne 'okay')
  {
    die "News Clipper encountered an unknown \$versionStatus";
  }

  dprint "There is a remote handler available.";

  my $download_result = _Download_Handler_By_Version($handler_name,$newVersion);

  if ($download_result eq 'okay')
  {
    _Unload_Handler($handler_name);
    return;
  }
  elsif ($download_result eq 'not found')
  {
    warn reformat dequote <<"    EOF";
      Couldn't install the handler $handler_name. The handler server reports
      that the handler is not in the database.
    EOF
    return;
  }
  elsif ($download_result =~ /failed: (.*)/s)
  {
    warn reformat dequote $1;
    return;
  }
  else
  {
    die "News Clipper encountered an unknown \$download_result";
  }
}

# ------------------------------------------------------------------------------

# Checks for and does a functional update for a handler. Returns 'updated',
# 'not updated', or 'failed'. Handles any error messages to the user.

sub _Do_Handler_Functional_Update
{
  my $handler_name = shift;

  # Functional updates are only prompted by -n
  unless ($opts{n})
  {
    dprint "Skipping functional update check -- -n not specified";
    return 'not updated';
  }

  # Check if we've already done a functional check in the last time period
  {
    my $lastCheck =
      $NewsClipper::Globals::state->get("last_functional_check_$handler_name");

    if (defined $lastCheck &&
             (time - $lastCheck < $TIME_BETWEEN_FUNCTIONAL_UPDATES))
    {
      dprint "Don't need to check for a functional update yet.";
      return 'not updated';
    }
  }

  # Now do the check
  my $localVersion = _Get_Local_Handler_Version($handler_name);
  my ($versionStatus,$newVersion,$updateType) =
    $SERVER->Get_New_Handler_Version($handler_name,'functional',$localVersion,
    $COMPATIBLE_NEWS_CLIPPER_VERSION);

  if ($versionStatus eq 'not found')
  {
    dprint reformat (65,dequote <<"    EOF");
      Can't do functional update of handler $handler_name.
      Handler server reports that handler $handler_name is not in the database.
    EOF
    $NewsClipper::Globals::state->set("last_functional_check_$handler_name",time);
    $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);
    return 'not updated';
  }

  if ($versionStatus eq 'no update')
  {
    dprint "There is a no new functional or bugfix update version.";
    $NewsClipper::Globals::state->set("last_functional_check_$handler_name",time);
    $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);
    return 'not updated';
  }

  # Failed, so we check next time too instead of waiting
  if ($versionStatus eq 'failed')
  {
    return 'failed' if $ALREADY_WARNED_SERVER_DOWN;
    $ALREADY_WARNED_SERVER_DOWN = 1;

    $errors{"handler#$handler_name"} = reformat dequote <<"    EOF";
      Couldn't determine if there is a newer functional update version of
      $handler_name available because the server is down. Try again in a while,
      and send email to bugreport\@newsclipper.com if the problem persists.
      Additional warnings regarding this problem will not be displayed.
    EOF
    return 'failed';
  }

  dprint "There is a new " . $updateType . " version.";
  $NewsClipper::Globals::state->set("last_functional_check_$handler_name",time);
  $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);

  return 'not updated' unless _Okay_To_Download($handler_name,$updateType);

  my $download_result = _Download_Handler_By_Version($handler_name,$newVersion);

  if ($download_result eq 'okay')
  {
    _Unload_Handler($handler_name);
    return 'updated';
  }

  if ($download_result eq 'not found')
  {
    $errors{"handler#$handler_name"} = reformat dequote <<"    EOF";
      Couldn't do a functional update of the handler $handler_name. The handler
      server reports that the handler is not in the database.
    EOF
    return 'failed';
  }

  if ($download_result =~ /failed: (.*)/s)
  {
    $errors{"handler#$handler_name"} = reformat dequote $1;
    return 'failed';
  }
}

# ------------------------------------------------------------------------------

# Checks for and does a bugfix update for a handler. Returns 'updated',
# 'not updated', or 'failed'. Handles any error messages to the user.

sub _Do_Handler_Bugfix_Update
{
  my $handler_name = shift;

  # Bugfix updates are only prompted by -n or auto_download_bugfix_updates
  unless ($opts{n} || $config{auto_download_bugfix_updates} =~ /^y/i)
  {
    dprint "Skipping bugfix update check -- neither -n nor " .
      "auto_download_bugfix_updates was specified";
    return 'not updated';
  }

  # Check if we've already done a bugfix check in the last time period
  {
    my $lastCheck =
      $NewsClipper::Globals::state->get("last_bugfix_check_$handler_name");

    if (defined $lastCheck &&
             (time - $lastCheck < $TIME_BETWEEN_BUGFIX_UPDATES))
    {
      dprint "Don't need to check for a bugfix update yet.";
      return 'not updated';
    }
  }

  # Now do the check
  my $localVersion = _Get_Local_Handler_Version($handler_name);
  my ($versionStatus,$newVersion,$updateType) =
    $SERVER->Get_New_Handler_Version($handler_name,'bugfix',$localVersion,
    $COMPATIBLE_NEWS_CLIPPER_VERSION);

  if ($versionStatus eq 'not found')
  {
    dprint reformat (65,dequote <<"    EOF");
      Can't do bugfix update of handler $handler_name.
      Handler server reports that handler $handler_name is not in the database.
    EOF
    $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);
    return 'not updated';
  }

  if ($versionStatus eq 'no update')
  {
    dprint "There is a no new bugfix update version.";
    $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);
    return 'not updated';
  }

  if ($versionStatus eq 'failed')
  {
    return 'failed' if $ALREADY_WARNED_SERVER_DOWN;
    $ALREADY_WARNED_SERVER_DOWN = 1;

    $errors{"handler#$handler_name"} = reformat dequote <<"    EOF";
      Couldn't determine if there is a newer bugfix update version of
      $handler_name available because the server is down. Try again in a while,
      and send email to bugreport\@newsclipper.com if the problem persists.
      Additional warnings regarding this problem will not be displayed.
    EOF
    return 'failed';
  }

  dprint "There is a new bugfix version.";
  $NewsClipper::Globals::state->set("last_bugfix_check_$handler_name",time);

  return 'not updated' unless _Okay_To_Download($handler_name,$updateType);

  my $download_result = _Download_Handler_By_Version($handler_name,$newVersion);

  if ($download_result eq 'okay')
  {
    _Unload_Handler($handler_name);
    return 'updated';
  }

  if ($download_result eq 'not found')
  {
    $errors{"handler#$handler_name"} = reformat dequote <<"    EOF";
      Couldn't do a bugfix update of the handler $handler_name. The handler
      server reports that the handler is not in the database.
    EOF
    return 'failed';
  }

  if ($download_result =~ /failed: (.*)/s)
  {
    $errors{"handler#$handler_name"} = reformat dequote $1;
    return 'failed';
  }
}

# ------------------------------------------------------------------------------

# Checks to see if the -a flag or auto_download_bugfix_updates config option
# allow the handler update to be downloaded. Also tries to ask the user
# interactively.

sub _Okay_To_Download
{
  my $handler_name = shift;
  my $updateType = shift;

  if ($updateType eq 'bugfix')
  {
    if ($opts{a} || $config{auto_download_bugfix_updates} =~ /^y/i)
    {
      dprint "Doing automatic download for handler \"$handler_name\"";
      return 1;
    }

    # Prompt the user if run interactively, and the user didn't specify one of
    # the auto download options
    if (-t STDIN)
    {
      warn "There is a newer version of handler \"$handler_name\".\n";
      warn "Would you like News Clipper to attempt to download it? [y/n]\n";
      my $response = <STDIN>;

      if ($response =~ /^y/i)
      {
        return 1;
      }
      else
      {
        return 0;
      }
    }
    # Otherwise we just warn the user we can't do a download
    else
    {
      $errors{"handler#$handler_name"} = reformat dequote <<"      EOF";
        A bugfix update to handler "$handler_name" is available, but it can't be
        downloaded because auto_download_bugfix_updates is not "yes" in your
        configuration file, and since News Clipper can't ask you interactively.
      EOF
      return 0;
    }
  }
  # It's a functional update
  else
  {
    if ($opts{a})
    {
      dprint "Doing automatic download for handler \"$handler_name\"";
      return 1;
    }
    else
    {
      $errors{"handler#$handler_name"} = reformat dequote <<"      EOF";
        A functional update to handler "$handler_name" is available, but it can't
        be downloaded because the -a flag was not specified, and since News
        Clipper can't ask you interactively.
      EOF
      return 0;
    }
  }
}

# ------------------------------------------------------------------------------

# This routine checks that a handler on the system is for the current version
# of News Clipper. Returns 1 if the handler is compatible, 0 if it is not or
# if it wasn't found.

sub _Handler_Version_Is_Compatible($)
{
  my $handler_name = shift;

  dprint "Checking if handler \"$handler_name\" is of a compatible version.";

  # Skip this handler if we've already processed it.
  if (exists $COMPATIBLE_HANDLERS{$handler_name})
  {
    dprint reformat (65,
      "Skipping handler \"$handler_name\" (already checked compatibility).");
    return $COMPATIBLE_HANDLERS{$handler_name};
  }

  my $local_handler_nc_version = _Get_Local_Handler_NC_Version($handler_name);
  unless (defined $local_handler_nc_version)
  {
    dprint "Could not get local handler version for $handler_name";
    $COMPATIBLE_HANDLERS{$handler_name} = 0;
    return 0;
  }

  dprint reformat (65,dequote <<"  EOF");
    Handler "$handler_name" was written for News Clipper version 
    $local_handler_nc_version, and this version of News Clipper is
    compatible with version $COMPATIBLE_NEWS_CLIPPER_VERSION.
  EOF

  if ($local_handler_nc_version != $COMPATIBLE_NEWS_CLIPPER_VERSION)
  {
    dprint "Handler $handler_name is incompatible";
    $errors{"handler#$handler_name"} = reformat dequote <<"    EOF";
       Handler $handler_name is incompatible with this version of News Clipper.
       (The handler is compatible with News Clipper versions that take handlers
       from version $local_handler_nc_version, but this version of News Clipper
       uses handlers from version $COMPATIBLE_NEWS_CLIPPER_VERSION).
    EOF
    $COMPATIBLE_HANDLERS{$handler_name} = 0;
    return 0;
  }
  else
  {
    dprint "Handler $handler_name is compatible";
    $COMPATIBLE_HANDLERS{$handler_name} = 1;
    return 1;
  }
}

# ------------------------------------------------------------------------------

# This function finds the News Clipper compatible version of the locally
# installed handler. Returns the version number or undef if the handler could
# not be found.

sub _Get_Local_Handler_NC_Version($)
{
  my $handler_name = shift;

  # Find the handler
  my $foundDirectory = _Get_Handler_Path($handler_name);
  return undef unless defined $foundDirectory;

  open LOCALHANDLER, "$foundDirectory/$handler_name.pm";
  my $handler_code = join '',<LOCALHANDLER>;
  close LOCALHANDLER;

  # Really there should be underscores between the words, but there are a few
  # handlers out there with the wrong thing.
  my ($for_news_clipper_version) =
    $handler_code =~ /'For.News.Clipper.Version'} *= *'(.*?)' *;/s;

  my $nc_version;

  # Ug. Pre "For_News_Clipper_Version" days...
  if (!defined $for_news_clipper_version)
  {
    return '1.00';
  }
  else
  {
    return $for_news_clipper_version;
  }
}

# ------------------------------------------------------------------------------

# This function finds the version of the locally installed handler. Returns
# the version number or undef if the handler could not be found.

sub _Get_Local_Handler_Version($)
{
  my $handler_name = shift;

  my $foundDirectory = _Get_Handler_Path($handler_name);
  return undef unless defined $foundDirectory;

  dprint "Found local copy of handler $handler_name in:\n  $foundDirectory";

  open LOCALHANDLER, "$foundDirectory/$handler_name.pm";
  my $localHandler = join '',<LOCALHANDLER>;
  close LOCALHANDLER;

  my ($versionCode) = $localHandler =~ /\$VERSION\s*=\s*do\s*({.*?});/;
  my $localVersion = eval "$versionCode";

  dprint "Local version for handler \"$handler_name\" is: $localVersion";

  return $localVersion;
}

# ------------------------------------------------------------------------------

# This routine restricts the trial version to use only the yahootopstories
# handler, and restricts the personal versions to use only the number of
# handlers they have registered to use. It dies if the user is trying to use
# more than their registration allows.

sub _Check_Registration_Restriction($)
{
  my $handler_name = shift;

  dprint "Checking if handler \"$handler_name\" is okay to use.";

  return if ($config{product} ne 'Personal') &&
            ($config{product} ne 'Trial');

  # Skip this handler if we've already processed it.
  if (grep { /^$handler_name$/i } @ALLOWED_HANDLERS)
  {
    dprint "Skipping already checked handler \"$handler_name\".";
    return;
  }

  if (!_Is_Acquisition_Handler($handler_name))
  {
    dprint "$handler_name isn't an acquisition handler -- okay to use.";
    push @ALLOWED_HANDLERS,$handler_name;

    return;
  }

  # Trial version can only use yahootopstories
  if ($config{product} eq 'Trial')
  {
    if ($handler_name eq 'yahootopstories')
    {
      push @ALLOWED_HANDLERS,$handler_name;
      return;
    }
    else
    {
      die reformat dequote <<"      EOF";
        You can not use the "$handler_name" handler. The trial version of News
        Clipper only allows you to use the yahootopstories handler.
      EOF
    }
  }

  # Now process personal licenses

  my @installedHandlers;

  foreach my $dir (@INC)
  {
    push @installedHandlers, glob("$dir/NewsClipper/Handler/Acquisition/*.pm");
  }

  dprint $#installedHandlers+1," total acquisition handlers found.";

  # Yell if they have more than the registered number of handlers on their
  # system.
  if ($#installedHandlers+1 > $config{number_handlers})
  {
    local $" = "\n";
    warn reformat dequote <<"    EOF";
      You currently have more than the allowed number of handlers on your
      system.  This personal version of News Clipper is only registered to
      use $config{number_handlers} handlers.

      Please delete one or more of the following files:
    EOF
    die "@installedHandlers\n";
  }

  # Yell if they have the registered number of handlers on their system, and
  # the current handler isn't one of them.
  if (($#installedHandlers+1 == $config{number_handlers}) &&
      (!grep {/$handler_name.pm$/} @installedHandlers))
  {
    local $" = "\n";
    warn reformat dequote <<"    EOF";
      You currently have $config{number_handlers} handlers on your
      system, and are trying to use a handler that is not one of these
      $config{number_handlers}
      ($handler_name). This personal version of News Clipper is only registered
      to use $config{number_handlers} handlers.

      Please delete one or more of the following files if you want to be able
      to use this handler:
    EOF
    die "@installedHandlers\n";
  }
}

# ------------------------------------------------------------------------------

# Checks to see if a handler is an acquisition handler. First it looks
# locally, then checks the list of remote acquisition handlers. Dies (in
# Server::Get_Handler_Type) if the handler is not installed locally and the
# handler type can not be determined from the server.

sub _Is_Acquisition_Handler
{
  my $handler_name = shift;

  # First look locally
  my $loadResult = _Load_Handler($handler_name);

  if ($loadResult =~ /^found/)
  {
    if ($loadResult =~ /Acquisition/)
    {
      return 1;
    }
    else
    {
      return 0;
    }
  }
  else
  {
    my ($remoteStatus,$remoteResult) = $SERVER->Get_Handler_Type($handler_name);

    if ($remoteStatus == 0)
    {
      die reformat dequote <<"      EOF"
        Couldn't download the handler type for handler $handler_name. Maybe
        the server is down. This version of News Clipper can only use a limited
        number of acquisition handlers, and must contact the server to determine
        if the handler is an acquisition handler. Try again in a while, and send
        email to bugreport\@newsclipper.com if the problem persists.
      EOF
    }

    if ($remoteResult eq 'Acquisition')
    {
      return 1;
    }
    else
    {
      return 0;
    }
  }
}

# ------------------------------------------------------------------------------

# Figure out where the handler is in the file system. Returns undef if not
# found.

sub _Get_Handler_Path($)
{
  my $handler_name = shift;

  # Try to load the handler so we can figure out where to put the replacement
  my $loadResult = _Load_Handler($handler_name);

  if ($loadResult eq 'not found')
  {
    dprint "Handler \"$handler_name\" not found locally. Can't get path.";
    return undef;
  }

  my @dirs = qw(Acquisition Filter Output);

  foreach my $dir (@INC)
  {
    return "$dir/NewsClipper/Handler/Acquisition"
      if -e "$dir/NewsClipper/Handler/Acquisition/$handler_name.pm";
    return "$dir/NewsClipper/Handler/Filter"
      if -e "$dir/NewsClipper/Handler/Filter/$handler_name.pm";
    return "$dir/NewsClipper/Handler/Output"
      if -e "$dir/NewsClipper/Handler/Output/$handler_name.pm";
  }

  return undef;
}

# ------------------------------------------------------------------------------

# "Unloads" a handler by deleting the entry in %INC and undefining any
# subroutines.

sub _Unload_Handler($)
{
  my $handler_name = shift;

  dprint "Unloading handler \"$handler_name\"";

  my $handler_type = undef;

  # Find out what kind of handler it is
  $handler_type = 'Acquisition'
    if exists $INC{"NewsClipper/Handler/Acquisition/$handler_name.pm"};
  $handler_type = 'Filter'
    if exists $INC{"NewsClipper/Handler/Filter/$handler_name.pm"};
  $handler_type = 'Output'
    if exists $INC{"NewsClipper/Handler/Output/$handler_name.pm"};

  return unless defined $handler_type;

  # Delete it from %INC
  delete $INC{"NewsClipper/Handler/$handler_type/$handler_name.pm"};

  # Now undef the package
  no strict 'refs';
  my %oldconfig =
    %{"NewsClipper::Handler::${handler_type}::${handler_name}::handlerconfig"};
  Symbol::delete_package("NewsClipper::Handler::${handler_type}::${handler_name}::");
  %{"NewsClipper::Handler::${handler_type}::${handler_name}::handlerconfig"} =
    %oldconfig;
}

# ------------------------------------------------------------------------------

# Loads a handler.  Returns "found as
# NewsClipper::Handler::${dir}::$handler_name" if the handler is found on the
# system, and "not found" if it can't be found.  Dies if the handler is found
# but has errors.

sub _Load_Handler($)
{
  my $handler_name = shift;

  my @dirs = qw(Acquisition Filter Output);

  dprint "Trying to load handler \"$handler_name\"";

  # Return if it has already been loaded before. This helps speed things up.
  foreach my $dir (@dirs)
  {
    if (defined $INC{"NewsClipper/Handler/$dir/$handler_name.pm"})
    {
      dprint "Handler \"$handler_name\" already loaded";
      return "found as NewsClipper::Handler::${dir}::$handler_name" 
    }
  }

  foreach my $dir (@dirs)
  {
    # Try to load it in $dir
    dprint "Looking for handler as:";
    dprint "  NewsClipper::Handler::${dir}::$handler_name";

    # Here we need to store errors.
    my $errors;
    {
      local $SIG{__WARN__} = sub { $errors .= $_[0] };

      eval "require \"NewsClipper/Handler/${dir}/$handler_name.pm\"";
    }

# At this point, the possibilities are:
# $errors     empty, $@ non-empty, $INC{} non-empty: impossible
# $errors non-empty, $@ non-empty, $INC{} non-empty: compile error on eval
# $errors     empty, $@     empty, $INC{} non-empty: winner!
# $errors non-empty, $@     empty, $INC{} non-empty: $errors holds warnings
# $errors     empty, $@ non-empty, $INC{}     empty: handler not found, etc.
# $errors non-empty, $@ non-empty, $INC{}     empty: $errors holds errors?
# $errors     empty, $@     empty, $INC{}     empty: impossible
# $errors non-empty, $@     empty, $INC{}     empty: eval had syntax error

    # Something went wrong
    if ($@)
    {
      # We'll skip can't locate messages, but stop on everything else
      if ($@ !~ /Can't locate NewsClipper.Handler.$dir.$handler_name/)
      {
        $@ =~ s/Compilation failed in require at \(eval.*?\n//s;

        warn "Handler $handler_name was found in:\n";
        warn "  ",$INC{"NewsClipper/Handler/$dir/$handler_name.pm"},"\n";
        warn "  but could not be loaded because of the following error:\n\n";
        warn "$errors\n" if defined $errors;
        die "$@\n";
      }
    }

    if (defined $INC{"NewsClipper/Handler/$dir/$handler_name.pm"})
    {
      dprint "Found handler as:\n ",
                  $INC{"NewsClipper/Handler/$dir/$handler_name.pm"};

      # If there's anything in $errors, it must be warnings. Store them
      # for later printing.
      $errors{"handler#$handler_name"} = $errors if defined $errors;

      return "found as NewsClipper::Handler::${dir}::$handler_name"
    }

    # We can get here if the eval has a syntax error. (e.g. if someone tries
    # to use handler.pm as the handler name)
    if ($errors)
    {
      warn "Handler $handler_name could not be loaded. The error was:\n";
      die "$errors\n";
    }
  }

  # Darn. Couldn't find it anywhere!
  dprint "Couldn't find handler";
  return 'not found';
}

# ------------------------------------------------------------------------------

# This function downloads and saves a remote handler, if one exists. Returns
# 'okay', 'not found', or 'failed: error message'

sub _Download_Handler_By_Version($$)
{
  my $handler_name = shift;
  my $version = shift;

  dprint "Downloading handler $handler_name, version $version";

  my ($getResult,$code) = $SERVER->Get_Handler($handler_name,$version,
    $COMPATIBLE_NEWS_CLIPPER_VERSION);
  return $getResult if $getResult ne 'okay';

  my $foundDirectory = _Get_Handler_Path($handler_name);

  # Use the old directory, or create a new one based on what the handler calls
  # itself.
  my $destDirectory;
  if (defined $foundDirectory)
  {
    dprint "Replacing handler located in\n  $foundDirectory";

    # Remove the outdated one.
    unlink "$foundDirectory/$handler_name.pm";

    $destDirectory = $foundDirectory;
  }
  else
  {
    my ($subDir) = $code =~ /package NewsClipper::Handler::([^:]*)::/;
    $destDirectory =
      "$config{handler_locations}[0]/NewsClipper/Handler/$subDir";

    dprint "Saving new handler to $destDirectory";
  }

  mkpath $destDirectory unless -e $destDirectory;

  # Write the handler.
  open HANDLER,">$destDirectory/$handler_name.pm"
    or return "failed: Handler $handler_name was downloaded, but could " .
      " not be saved. The message from the operating system is:\n\n$!";
  print HANDLER $code;
  close HANDLER;

  lprint "The $handler_name handler has been downloaded and saved as\n";
  lprint "  $destDirectory/$handler_name.pm\n";

  # Figure out if the handler needs any other modules.
  my @uses = $code =~ /\nuse (.*?);/g;

  @uses = grep {!/(vars|constant|NewsClipper|strict)/} @uses;

  if ($#uses != -1)
  {
    lprint "The handler uses the following modules:\n";
    $" = "\n  ";
    lprint "  @uses\n";
    lprint "Make sure you have them installed.\n";
  }

  return 'okay';
}

# ------------------------------------------------------------------------------

1;
