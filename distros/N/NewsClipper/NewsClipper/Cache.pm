# -*- mode: Perl; -*-
package NewsClipper::Cache;

# This package implements a cache for HTML files.

use strict;
# To parse dates
use Time::CTime;
use Time::ParseDate;
# To get the local time zone
use POSIX ();
use File::Cache;

use vars qw( $VERSION @ISA );

@ISA = qw(File::Cache);
$VERSION = 0.35;

use NewsClipper::Globals;

# ------------------------------------------------------------------------------

sub new
{
  my $proto = shift;

  my $self = $proto->SUPER::new( { cache_key => $config{cache_location},
                                   namespace => 'html',
                                   username => '',
                                   filemode => 0666,
                                   auto_remove_stale => 0,
                                   max_size => $config{max_cache_size},
                                   persistence_mechanism => 'Data::Dumper',
                                 });

  return $self;
}

# ------------------------------------------------------------------------------

# Gets the data from the cache, if it is available, as well as the status. The
# possible return combinations are:
# DATA, valid: Data is in cache and not stale
# DATA, stale: Data is in cache but stale
# undef, not found: Data is not in cache

sub get($$@)
{
  my $self = shift;
  my $url = shift;
  my @updateTimes = shift;

  # Since the expiration time is infinite, any data in the cache will always
  # be fresh (i.e. we don't have to check get_stale)
  return ($self->SUPER::get($url),$self->_IsStillValid($url,@updateTimes));
}

# ------------------------------------------------------------------------------

# Determine when the content was cached. Return the time in seconds since the
# epoch, or undef if the cached item can't be found.

sub GetTimeCached
{
  my $self = shift;
  my $url = shift;

  return $self->SUPER::get_creation_time($url);
}

# ------------------------------------------------------------------------------

# Updates the last modified time of the information associated with the key.

sub UpdateTime($$)
{
  my $self = shift;
  my $url = shift;

  # This is a slow way to do it, but let's do it until the File::Cache module
  # provides support.
  my $data = $self->SUPER::get($url);
  $self->SUPER::set($url,$data);
}
# ------------------------------------------------------------------------------

# Checks the cache for the url's data.  One of three return values are
# possible:
# valid: The data exists and isn't old
# stale: The data is exists but is old
# not found: The data is not in the cache

sub _IsStillValid($@)
{
  my $self = shift;
  my $url = shift;
  my @updateTimes = shift;

  dprint "Checking cache for data for URL:\n  $url";

  my $lastUpdated = $self->get_creation_time($url);

  # Return 'not found' if we couldn't find it in the cache.
  unless (defined $lastUpdated)
  {
    dprint "Couldn't find cached data ";
    return 'not found';
  }

  if (_Outdated(\@updateTimes,$lastUpdated))
  {
    dprint "Data is stale";
    return 'stale';
  }
  else
  {
    dprint "Reusing cached data";
    return 'valid';
  }
}

# ------------------------------------------------------------------------------

# Figures out whether the cached data is out of date

sub _Outdated($$)
{
  # Get the times that the user has specified, or the default times.
  my @relativeUpdateTimes = @{shift @_};
  my $lastUpdated = shift;

  # Iterate over the times to find out which is the most recent time we should
  # have updated.
  my $mostRecentUpdateTime = 0;
  foreach my $timeSpec (@relativeUpdateTimes)
  {
    # Extract the day and timezone from the time specification from the
    # handler. Replace $timeSpec with the middle, which should be the hours.
    my ($day,$timezone);
    ($day,$timeSpec,$timezone) =
      $timeSpec =~ /^([a-z]*)\D*([\d ,]*)\s*([a-z]*)/i;

    # Move all the hours from 2,3,4,5 form into an array.
    my @hours = split /\D+/,$timeSpec;

    # chop off extra characters on the day, just in case they did thurs
    # instead of thu.
    $day =~ s/^(...).*/$1/;

    # If they didn't specify a day, it's today
    $day = 'today'
      if $day eq '' || lc(strftime("%a",localtime(time))) eq lc($day);

    # If they didn't specify a timezone, it's pacific (in recognition of the
    # multitude of internet companies in California)
    $timezone = 'PST' if $timezone eq '';

    # Set the timezone for the current timezone if LOCAL_TIME_ZONE is specified
    $timezone = POSIX::strftime("%Z",localtime)
      if $timezone eq 'LOCAL_TIME_ZONE';

    # Now iterate through each hour in the list, looking for the most recent
    # update hour.
    foreach my $hour (@hours)
    {
      $day = "last $day"
        unless $day =~ /(today|yesterday)/i || $day =~ /^last /i;
      my $tempDate = parsedate("$day $hour:00", ZONE => $timezone);

      # Correct apparently future times. Basically, they meant "yesterday at
      # 2pm", not "today at 2pm" (if it's earlier than 2pm)
      if ($tempDate > parsedate('now'))
      {
        if ($day eq 'today')
        {
          $day = 'yesterday';
        }
        elsif ($day eq 'yesterday')
        {
          $day = "-2 days";
        }
      }

      # Parse the date again, in case we corrected the day.
      my $parsedDate = parsedate("$day $hour:00", ZONE => $timezone);

      $mostRecentUpdateTime = $parsedDate
        if $parsedDate > $mostRecentUpdateTime;
    }
  }

  dprint ("Comparing dates:");
  dprint ("  Last Updated: $lastUpdated");
  dprint ("  Most Recent Update Time: $mostRecentUpdateTime");
  dprint ("  Now: ",parsedate('now'));

  if ($lastUpdated < $mostRecentUpdateTime)
  {
    dprint "Update is needed";
    return 1;
  }
  else
  {
    dprint "Update is not needed";
    return 0;
  }
}

1;
