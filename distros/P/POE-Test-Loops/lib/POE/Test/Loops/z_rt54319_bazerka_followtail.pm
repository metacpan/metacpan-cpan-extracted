#! /usr/bin/env perl
# vim: ts=2 sw=2 expandtab

use strict;
use warnings;

sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }
sub POE::Kernel::ASSERT_DEFAULT () { 1 }

use Time::HiRes qw(time);
use IO::Handle;
use POE qw(Wheel::FollowTail);

use constant {
  TESTS               => 6,
  TIME_BETWEEN_WRITES => 0.5,
};

use Test::More;
use File::Temp;

# Sanely generate the tempfile
my $write_fh;
eval { $write_fh = File::Temp->new( UNLINK => 1 ) };
plan skip_all => "Unable to create tempfile for testing" if $@;

$write_fh->autoflush(1);
my $write_count = 0;

plan tests => TESTS;

# Write to the log 2x as fast as it's polled.
# Make sure none of the lines is delayed overly long.

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[KERNEL]->yield("on_tick");
    },
    on_tick => sub {
      print $write_fh ++$write_count, " ", time(), "\n";
      $_[KERNEL]->delay("on_tick" => TIME_BETWEEN_WRITES) if $write_count < TESTS;
    },
    _stop => sub { undef },
  }
);

# Read from the log at one check every 3 seconds.

my $poll_interval    = TIME_BETWEEN_WRITES * 2;
my $per_test_timeout = TIME_BETWEEN_WRITES * 3;

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
        Filename     => $write_fh->filename,
        InputEvent   => "got_log_line",
        PollInterval => $poll_interval,
      );

      # A long timeout to begin with.
      $_[KERNEL]->delay(timeout => $poll_interval * TESTS);
    },
    got_log_line => sub {
      my ($write, $time) = split /\s+/, $_[ARG0];
      my $elapsed = sprintf("%.2f", time() - $time);
      ok(
        $elapsed <= $per_test_timeout,
        "response time <= $per_test_timeout sec ($elapsed)"
      );
      return if $write < TESTS;

      # Stop the timeout when we're done.
      $_[KERNEL]->delay(timeout => undef);
      delete $_[HEAP]{tailor};
    },
    timeout => sub {
      delete $_[HEAP]{tailor};
    },
    _stop => sub { undef },
  }
);

POE::Kernel->run();

1;
