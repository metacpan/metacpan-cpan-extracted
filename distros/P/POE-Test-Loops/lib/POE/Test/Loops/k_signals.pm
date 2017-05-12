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

  plan tests => 8;
}

BEGIN { use_ok("POE") }

# This is the number of processes to fork.  Increase this number if
# your system can handle the resource use.  Also try increasing it if
# you suspect a problem with POE's SIGCHLD handling.  Be warned
# though: setting this too high can cause timing problems and test
# failures on some systems.

my $fork_count = 8;

use IO::Pipely qw(pipely);
my ($pipe_read, $pipe_write) = pipely();

# Set up a signal catching session.  This test uses plain fork(2) and
# POE's $SIG{CHLD} handler.

POE::Session->create(
  inline_states => {
    _start => sub {
      my ($kernel, $heap) = @_[KERNEL, HEAP];

      # Clear the status counters, and catch SIGCHLD.

      $heap->{forked} = $heap->{reaped} = 0;
      $kernel->sig( CHLD => 'catch_sigchld' );

      # Fork some child processes, all to exit at the same time.

      my $fork_start_time = time();

      for (my $child = 0; $child < $fork_count; $child++) {
        my $child_pid = fork;

        if (defined $child_pid) {
          if ($child_pid) {
            # Parent side keeps track of child IDs.
            $heap->{forked}++;
            $heap->{children}->{$child_pid} = 1;
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
        $heap->{forked} == $fork_count,
        "forked $heap->{forked} processes (out of $fork_count)"
      );

      # NOTE: This is bad form.  We're going to block here until all
      # children check in, or die trying.

      my $ready_count = 0;
      while (<$pipe_read>) {
        last if ++$ready_count >= $fork_count;
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
      if (++$heap->{reaped} >= $fork_count) {
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
    reaping_time_is_up => sub {
      $_[KERNEL]->sig( CHLD => undef );
    },
  },
);

# mstevens found a subtle incompatibility between nested sessions and
# SIGIDLE.  This should be fun to debug, but first I'll add the test
# case here.

sub spawn_server {
  POE::Session->create(
    inline_states => {
      _start => sub {
        $_[KERNEL]->alias_set("server");
      },
      do_thing => sub {
        $_[KERNEL]->post($_[SENDER], thing_done => $_[ARG0]);
      },
      _child  => sub { 0 },
      _stop   => sub { 0 },
    },
  );
}

POE::Session->create(
  inline_states => {
    _start => sub {
      spawn_server();
      $_[KERNEL]->post(server => do_thing => 1);
    },
    thing_done => sub { 0 },
    _child  => sub { 0 },
    _stop   => sub { 0 },
  },
);

# See how SIGPIPE gets handled.

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->sig(USR1 => "got_usr1");
      $_[KERNEL]->sig(PIPE => "got_pipe");
      $_[KERNEL]->yield("send_signals");
    },
    send_signals => sub {
      ok(kill("USR1", $$) == 1, "sent self SIGUSR1");
      ok(kill("PIPE", $$) == 1, "sent self SIGPIPE");
      $_[KERNEL]->delay(signal_wait_timeout => 1);
    },
    got_usr1 => sub {
      $_[HEAP]->{usr1}++;
      _reduce_signal_wait_timeout($_[HEAP]);
    },
    got_pipe => sub {
      $_[HEAP]->{pipe}++;
      _reduce_signal_wait_timeout($_[HEAP]);
    },
    signal_wait_timeout => sub {
      $_[KERNEL]->sig( USR1 => undef );
      $_[KERNEL]->sig( PIPE => undef );
    },
    _stop => sub {
      ok($_[HEAP]->{usr1} == 1, "caught SIGUSR1");
      ok($_[HEAP]->{pipe} == 1, "caught SIGPIPE");
    },
  },
);

sub _reduce_signal_wait_timeout {
  my ($heap) = @_;
  if ($heap->{usr1} and $heap->{pipe}) {
    POE::Kernel->delay(signal_wait_timeout => 0.100);
  }
}

# Run the tests.

POE::Kernel->run();

1;
