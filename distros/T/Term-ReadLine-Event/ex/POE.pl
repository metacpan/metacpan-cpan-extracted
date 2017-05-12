#!/usr/bin/perl
# vim: ts=2 sw=2 expandtab

use strict;
use warnings;

use POE;             # We're going to use POE here.
POE::Kernel->run();  # Silence run() warning.  See POE docs.

use File::Basename;
use lib dirname($0) . '/lib';
use ExampleHelpers qw(
  initialize_completion update_time print_input
);
use Term::ReadLine 1.09;

# Mark time with a single-purpose POE session.
#
# It's often better to divide programs with multiple concerns into
# loosely coupled units, each addressing a single concern.

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->delay(tick => 1);
      $_[KERNEL]->alias_set('ticker');
    },
    tick => sub {
      $_[KERNEL]->delay(tick => 1);
      update_time();
    },
    shutdown => sub {
      $_[KERNEL]->delay(tick => undef);
    },
  },
);

# Create a Term::ReadLine object.
# Initialize completion to test whether tab-completion works.
# Hook Term::ReadLine into POE so everybody is happy.
# Get a line of input while POE continues to dispatch events.
# Display the line and the time it took to receive.

my $term = Term::ReadLine->new('...');
initialize_completion($term);
drive_with_poe($term);

my $input = $term->readline('> ');
print_input($input);

# Unhook Term::ReadLine from POE.  This clears the POE::Session
# callbacks in Term::ReadLine.
#
# POE shuts down the Term::ReadLine driver session when it sees that
# the callbacks have been relinquished.  This happens automatically
# because the session isn't doing anything else.  If it were also
# doing other things, those would need to be shut down too.
#
# This is significant in programs that call POE::Kernel->run(), as the
# main event loop will not exit until all sessions shut down.

$term->event_loop(undef);

# As previously mentioned, POE::Kernel->run() will continue to run for
# as long as sessions are doing work.  We must shut down the separate
# time-keeping session so that POE::Kernel->run() will return.

POE::Kernel->post(ticker => 'shutdown');

# Actually call POE::Kernel->run().  This is only a test to verify
# whether the time-keeping and Term::ReadLine sessions do indeed shut
# down.  It's otherwise not needed in this very simple example.

POE::Kernel->run();
exit;

# This function takes a Term::ReadLine object and drives it with POE.
# Abstracted into a function for easy reuse.

sub drive_with_poe {
  my ($term_readline) = @_;

  my $waiting_for_input;

  POE::Session->create(
    inline_states => {

      # Initialize the session that will drive Term::ReadLine.
      # Tell Term::ReadLine to invoke a couple POE event handlers when
      # it's ready to wait for input, and when it needs to register an
      # I/O watcher.

      _start => sub {
        $term_readline->event_loop(
          $_[SESSION]->callback('term_readline_waitfunc'),
          $_[SESSION]->callback('term_readline_regfunc'),
        );
      },

      # This callback is invoked every time Term::ReadLine wants to
      # read something from its input file handle.  It blocks
      # Term::ReadLine until input is seen.
      #
      # It sets a flag indicating that input hasn't arrived yet.
      # It watches Term::ReadLine's input filehandle for input.
      # It runs while it's waiting for input.
      # It turns off the input watcher when it's no longer needed.
      #
      # POE::Kernel's run_while() dispatches other events (including
      # "term_readline_readable" below) until $waiting_for_input goes
      # to zero.

      term_readline_waitfunc => sub {
        my $input_handle = $_[ARG1][0];
        $waiting_for_input = 1;
        $_[KERNEL]->select_read($input_handle => 'term_readline_readable');
        $_[KERNEL]->run_while(\$waiting_for_input);
        $_[KERNEL]->select_read($input_handle => undef);
      },

      # This callback is invoked as Term::ReadLine is starting up for
      # the first time.  It saves the exposed input filehandle where
      # the "term_readline_waitfunc" callback can see it.

      term_readline_regfunc => sub {
        my $input_handle = $_[ARG1][0];
        return $input_handle;
      },

      # This callback is invoked when data is seen on Term::ReadLine's
      # input filehandle.  It clears the $waiting_for_input flag.
      # This causes run_while() to return in "term_readline_waitfunc".

      term_readline_readable => sub {
        $waiting_for_input = 0;
      },
    },
  );
}
