#!/usr/bin/perl
# vim: ts=2 sw=2 expandtab

use strict;
use warnings;

use Term::ReadLine 1.09;
use Reflex 0.097; # bug in 0.096 that keeps this from working.
use Reflex::Filehandle;
use Reflex::Interval;

use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);

# Create a Term::ReadLine object.
# Initialize completion to test whether tab-completion works.

my $term = Term::ReadLine->new('...');
initialize_completion($term);

# Drive the Term::ReadLine object with a Reflex::Filehandle watcher.

$term->event_loop(

  # This callback is a "wait function".  It's invoked every time
  # Term::ReadLine wants to read something from its input.  The
  # parameter is the data returned from the "registration function",
  # below.

  sub {
    my $input_watcher = shift();
    $input_watcher->next();
  },

  # This callback is a "registration function".  It's invoked as
  # Term::ReadLine is starting up for the first time.  It sets up an
  # input watcher for the terminal's input file handle.
  #
  # This registration function returns the input watcher.
  # Term::ReadLine passes the watcher to the wait function (above).

  sub {
    my $input_handle  = shift();
    my $input_watcher = Reflex::Filehandle->new(
      handle => $input_handle,
      rd     => 1,
    );
    return $input_watcher;
  },
);

# Mark time with a single-purpose Reflex::Interval timer.

my $ticker = Reflex::Interval->new(
  interval => 1,
  on_tick  => \&update_time,
);

# Get a line of input while POE continues to dispatch events.
# Display the line and the time it took to receive.
# Exit.

my $input = $term->readline('> ');
print_input($input);

# Unhook Term::ReadLine from Reflex.  The Reflex::Filehandle object
# associated with Term::ReadLine will stop watching for input and be
# destroyed.  This isn't usually needed, but it has its uses.
#
# Unhooking Term::ReadLine may reduce memory usage slightly by
# destroying the associated Reflex::Filehandle object.  This also
# turns off the terminal's input watcher in the underlying event loop,
# which may improve runtime performance slightly.  These benefits are
# moot if the program is about to exit anyway.
#
# Turning off the terminal's Reflex::Filehandle may be necessary for
# some of the event loops Reflex supports, even if the program is
# about to exit.  Rumor has it that some event loops may not exit
# cleanly unless their I/O watchers are first turned off.
#
# This is a one-time deal.  There is no going back.  This is because
# Term::ReadLine cannot currently create more than one object per run.
# Not concurrently (two or more active at once).  Not serially (create
# a new one after the previous one is DESTROYed).

$term->event_loop(undef);

exit;
