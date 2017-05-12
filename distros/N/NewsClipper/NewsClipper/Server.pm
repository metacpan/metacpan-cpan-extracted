# -*- mode: Perl; -*-
package NewsClipper::Server;

# This package contains the Server class. This class will automatically
# determine which of its implementations to load and then load it.
# Implementations are contained, not inherited.

use strict;
use Carp;

use NewsClipper::Globals;

use vars qw( $VERSION );

my $HANDLER_SERVER = 'handlers.newsclipper.com';
#my $HANDLER_SERVER = '192.168.0.1';

$VERSION = 0.10;

# ------------------------------------------------------------------------------

sub new
{
  my $implementation = _Load_Implementation();

  $implementation->{handler_server} = $HANDLER_SERVER;

  return $implementation;
}

# ------------------------------------------------------------------------------

sub _Load_Implementation()
{
  my $implementation;

  # Try to load the MySQL implementation, which is a lot faster.
  if (eval "require NewsClipper::Server::MySQL")
  {
    $implementation = NewsClipper::Server::MySQL->new();

    if (defined $implementation)
    {
      dprint "Using MySQL implementation of server class.";
    }
    else
    {
      dprint "Tried to create MySQL implementation, but failed";
    }
  }
  # Otherwise fall back on the CGI implementation
  else
  {
    dprint "Tried to load MySQL implementation, but failed: $@";
    require NewsClipper::Server::CGI;

    $implementation = new NewsClipper::Server::CGI;
    dprint "Using CGI implementation of server class."
  }

  return $implementation;
}

# ------------------------------------------------------------------------------

# These should be overridden by the implementation class
sub Get_Handler_Type
{
  die "Get_Handler_Type not overridden by implementation!";
}

# ------------------------------------------------------------------------------

sub Get_Handler
{
  die "Get_Handler not overridden by implementation!";
}

# ------------------------------------------------------------------------------

sub _Get_Compatible_Working_Handler_Version
{
  die "_Get_Compatible_Working_Handler_Version not overridden by implementation!";
}

# ------------------------------------------------------------------------------

sub _Get_Latest_Working_Handler_Version
{
  die "_Get_Latest_Working_Handler_Version not overridden by implementation!";
}

# ------------------------------------------------------------------------------

# Checks if a new version of the handler is available, taking consideration of
# -n flag into account.
# Params:
# 1) the handler name
# 2) whether you want only a bugfix update, not a functional update too
#    ('bugfix','functional')
# Returns:
# 1) status: okay, failed, not found, no update
# 2) the version
# 3) type of update it is ("bugfix" or "functional")
#    if $needBugfix == 0, type can be either bugfix or functional.
#    if $needBugfix == 1, type can be only bugfix.

sub Get_New_Handler_Version($$$$$)
{
  my $self = shift;
  my $handler_name = shift;
  my $needBugfix = shift;
  my $localVersion = shift;
  my $ncversion = shift;

  dprint "Checking for a new version for handler \"$handler_name\"";

  my ($status,$newVersion);

  if ($needBugfix eq 'bugfix' && defined $localVersion)
  {
    ($status,$newVersion) =
      $self->_Get_Compatible_Working_Handler_Version($handler_name,
      $ncversion, $localVersion);
  }
  else
  {
    ($status,$newVersion) =
      $self->_Get_Latest_Working_Handler_Version($handler_name,$ncversion);
  }

  if ($status eq 'no update')
  {
    dprint "Server reports that handler \"$handler_name\" doesn't have an update.\n";
    return 'no update';
  }

  if ($status eq 'not found')
  {
    dprint "Server reports that handler \"$handler_name\" doesn't exist.\n";
    return 'not found';
  }

  return 'failed' if $status eq 'failed';

  if (defined $localVersion && $newVersion <= $localVersion)
  {
    dprint "No new version is available";
    return 'no update';
  }

  # We actually got a version
  my $updateType;

  if (defined $localVersion)
  {
    if (int($newVersion * 100) == int($localVersion * 100))
    {
      $updateType = 'bugfix';
    }
    else
    {
      $updateType = 'functional';
    }

    dprint "A new version is available.\n  New version:$newVersion " .
      "Old version: $localVersion Update type: $updateType\n";
  }
  else
  {
    $updateType = 'functional';

    dprint "A new version is available.\n  New version:$newVersion " .
      "Old version: <NONE FOUND> Update type: $updateType\n";
  }

  return ('okay',$newVersion,$updateType);
}

# ------------------------------------------------------------------------------

1;
