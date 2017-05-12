#!/usr/bin/perl -w
# vim: ts=2 sw=2 expandtab

# Tests various signals using POE's stock signal handlers.  These are
# plain Perl signals, so mileage may vary.

use strict;
use lib qw(./mylib ../mylib);

use Test::More;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }

BEGIN {
  package
  POE::Kernel;
  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
}

# This is the number of processes to fork.  Increase this number if
# your system can handle the resource use.  Also try increasing it if
# you suspect a problem with POE's SIGCHLD handling.  Be warned
# though: setting this too high can cause timing problems and test
# failures on some systems.

use constant FORK_COUNT => 8;

BEGIN {
  # We can't "plan skip_all" because that calls exit().  And Tk will
  # croak if you call BEGIN { exit() }.  And that croak will cause
  # this test to FAIL instead of skip.

  my $error;
  if ($^O eq "MSWin32" and not $ENV{POE_DANTIC}) {
    $error = "$^O does not support signals";
  }
  elsif ($^O eq "MacOS" and not $ENV{POE_DANTIC}) {
    $error = "$^O does not support fork";
  }

  if ($error) {
    print "1..0 # Skip $error\n";
    CORE::exit();
  }

  plan tests => FORK_COUNT+ 7;
}

use IO::Pipely qw(pipely);
my ($pipe_read, $pipe_write) = pipely();

BEGIN { use_ok("POE") }

# Set up a second session that watches for child signals.  This is to
# test whether a session with only sig_child() stays alive because of
# the signals.

POE::Session->create(
  inline_states => {
    _start => sub { $_[KERNEL]->alias_set("catcher") },
    catch  => sub {
      my ($kernel, $heap, $pid) = @_[KERNEL, HEAP, ARG0];
			$kernel->sig(CHLD => "got_sigchld");
      $kernel->sig_child($pid, "got_chld");
      $heap->{children}{$pid} = 1;
      $heap->{watched}++;
    },
    remove_alias => sub { $_[KERNEL]->alias_remove("catcher") },
    got_chld => sub {
      my ($heap, $pid) = @_[HEAP, ARG1];
      ok(delete($heap->{children}{$pid}), "caught SIGCHLD for watched pid $pid");
      $heap->{caught}++;
    },
		got_sigchld => sub {
			$_[HEAP]->{caught_sigchld}++;
		},
    _stop => sub {
      my $heap = $_[HEAP];

      ok(
        $heap->{watched} == $heap->{caught},
        "expected $heap->{watched} reaped children, got $heap->{caught}"
      );

			ok(
				$heap->{watched} == $heap->{caught_sigchld},
        "expected $heap->{watched} sig(CHLD), got $heap->{caught_sigchld}"
			);

      ok(!keys(%{$heap->{children}}), "all reaped children were watched");
    },
  },
);

# Set up a signal catching session.  This test uses plain fork(2) and
# POE's $SIG{CHLD} handler.

POE::Session->create(
  inline_states => {
    _start => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Clear the status counters, and catch SIGCHLD.

      $heap->{forked} = $heap->{reaped} = 0;

      # Fork some child processes, all to exit at the same time.

      my $fork_start_time = time();

      for (my $child = 0; $child < FORK_COUNT; $child++) {
        my $child_pid = fork;

        if (defined $child_pid) {
          if ($child_pid) {
            # Parent side keeps track of child IDs.
            $heap->{forked}++;
            $heap->{children}{$child_pid} = 1;
            $kernel->sig_child($child_pid, "catch_sigchld");
            $kernel->post(catcher => catch => $child_pid);
          }
          else {
            # A brief sleep so the parent has more opportunity to
            # finish forking.
            sleep 1;

            # Defensively make sure SIGINT will be fatal.
            $SIG{INT} = 'DEFAULT';

            # Tell the parent we're ready.
            print $pipe_write "$$\n";

            # Wait for SIGINT.
            sleep 3600;
            exit;
          }
        }
        else {
          die "fork error: $!";
        }
      }

      ok(
        $heap->{forked} == FORK_COUNT,
        "forked $heap->{forked} processes (out of " . FORK_COUNT . ")"
      );

      # NOTE: This is bad form.  We're going to block here until all
      # children check in, or die trying.

      my $ready_count = 0;
      while (<$pipe_read>) {
        last if ++$ready_count >= FORK_COUNT;
      }

      $kernel->yield( 'forking_time_is_up' );
    },

    _stop => sub {
      my $heap = $_[HEAP];

      # Everything is done.  See whether it succeeded.
      ok(
        $heap->{reaped} == $heap->{forked},
        "reaped $heap->{reaped} processes (out of $heap->{forked})"
      );
    },

    catch_sigchld => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Count the child reap.  If that's all of them, wait just a
      # little longer to make sure there aren't extra ones.
      if (++$heap->{reaped} >= FORK_COUNT) {
        $kernel->delay( reaping_time_is_up => 0.500 );
      }
    },

    forking_time_is_up => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Forking time is over.  We kill all the child processes as
      # immediately as possible.

      my $kill_count = kill INT => keys(%{$heap->{children}});
      ok(
        $kill_count == $heap->{forked},
        "killed $kill_count processes (out of $heap->{forked})"
      );

      # Start the reap timer.  This will tell us how long to wait
      # between CHLD signals.

      $heap->{reap_start} = time();

      # Cap the maximum time for failures.

      $kernel->delay( reaping_time_is_up => 10 );
    },

    # Do nothing here.  The timer exists just to keep the session
    # alive.  Once it's dispatched, the session can exit.
    reaping_time_is_up => sub { undef },
  },
);

# Run the tests.

POE::Kernel->run();

1;
