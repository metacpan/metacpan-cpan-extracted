#!/usr/bin/perl -w
# vim: ts=2 sw=2 expandtab

# Exercises Wheel::FollowTail, Wheel::ReadWrite, and Filter::Block.
# TODO - Needs tests for Seek and SeekBack.

use strict;
use lib qw(./mylib ../mylib);
use Socket;

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }

BEGIN {
  package
  POE::Kernel;
  use constant TRACE_DEFAULT => exists($INC{'Devel/Cover.pm'});
}

use Test::More;

plan tests => 10;

use POE qw(
  Component::Server::TCP
  Wheel::FollowTail
  Wheel::ReadWrite
  Wheel::SocketFactory
  Filter::Line
  Filter::Block
  Driver::SysRW
);

sub DEBUG () { 0 }

my $tcp_server_port;
my $max_send_count  = 10;    # expected to be even

###############################################################################
# A generic server session.

sub sss_new {
  my ($socket, $peer_addr, $peer_port) = @_;
  POE::Session->create(
    inline_states => {
      _start      => \&sss_start,
      _stop       => \&sss_stop,
      got_error   => \&sss_error,
      got_block   => \&sss_block,
      ev_timeout  => sub {
        DEBUG and warn "=== handle tail got timeout";
        delete $_[HEAP]->{wheel};
      },
    },
    args => [ $socket, $peer_addr, $peer_port ],
  );
}

sub sss_start {
  my ($heap, $socket, $peer_addr, $peer_port) = @_[HEAP, ARG0..ARG2];

  delete $heap->{wheel};
  $heap->{wheel} = POE::Wheel::FollowTail->new(
    Handle       => $socket,
    Driver       => POE::Driver::SysRW->new( BlockSize => 24 ),
    Filter       => POE::Filter::Block->new( BlockSize => 16 ),
    InputEvent   => 'got_block_nonexistent',
    ErrorEvent   => 'got_error_nonexistent',
  );

  # Test event changing.
  $heap->{wheel}->event(
    InputEvent => 'got_block',
    ErrorEvent => 'got_error',
  );

  $heap->{test_two} = 1;
  $heap->{wheel_id} = $heap->{wheel}->ID;
  $heap->{read_count} = 0;
}

sub sss_block {
  my ($kernel, $heap, $block) = @_[KERNEL, HEAP, ARG0];
  DEBUG and warn "=== handle tail got block ($block)";

  if ($block eq 'DONEDONEDONEDONE') {
    $kernel->delay( ev_timeout => 1 );
    return;
  }

  $heap->{read_count}++;
  $kernel->delay( ev_timeout => 10 );
}

sub sss_error {
  my ($heap, $syscall, $errnum, $errstr, $wheel_id) = @_[HEAP, ARG0..ARG3];
  DEBUG and warn "=== handle tail got $syscall error $errnum: $errstr";
  $_[HEAP]->{test_two} = 0 if $errnum;
}

sub sss_stop {
  my $heap = $_[HEAP];
  DEBUG and warn "=== handle tail stopped";
  ok($heap->{test_two}, "handle tail test two");
  is(
    $heap->{read_count}, $max_send_count,
    "handle tail read everything we were sent " .
    "did($heap->{read_count}) wanted($max_send_count)"
  );
}

###############################################################################
# A TCP socket client.

sub client_tcp_start {
  my $heap = $_[HEAP];

  DEBUG and warn "=== client tcp started";

  $heap->{wheel} = POE::Wheel::SocketFactory->new(
    RemoteAddress  => '127.0.0.1',
    RemotePort    => $tcp_server_port,
    SuccessEvent  => 'got_server_nonexistent',
    FailureEvent  => 'got_error_nonexistent',
  );

  # Test event changing.
  $heap->{wheel}->event(
    SuccessEvent => 'got_server',
    FailureEvent => 'got_error',
  );

  $heap->{socketfactory_wheel_id} = $heap->{wheel}->ID;
  $heap->{test_three} = 1;
}

sub client_tcp_stop {
  my $heap =$_[HEAP];
  ok(
    $heap->{test_three},
    "test three"
  );
  ok(
    $heap->{put_count} == $max_send_count,
    "sent everything we should"
  );

  my $sent_count = $_[HEAP]->{put_count} / 2;
  ok(
    $heap->{flush_count} == $sent_count,
    "flushed what we sent (flush=$heap->{flush_count}; sent=$sent_count)"
  );
  ok(
    $heap->{test_six},
    "test six"
  );
}

sub client_tcp_connected {
  my ($kernel, $heap, $server_socket) = @_[KERNEL, HEAP, ARG0];

  delete $heap->{wheel};
  $heap->{wheel} = POE::Wheel::ReadWrite->new(
    Handle       => $server_socket,
    Driver       => POE::Driver::SysRW->new( BlockSize => 32 ),
    Filter       => POE::Filter::Block->new( BlockSize => 16 ),
    ErrorEvent   => 'got_error_nonexistent',
    FlushedEvent => 'got_flush_nonexistent',
  );

  DEBUG and warn "=== client tcp connected";

  # Test event changing.
  $heap->{wheel}->event(
    ErrorEvent   => 'got_error',
    FlushedEvent => 'got_flush',
  );

  $heap->{test_six} = 1;
  $heap->{readwrite_wheel_id} = $heap->{wheel}->ID;

  $heap->{flush_count} = 0;
  $heap->{put_count}   = 0;

  $kernel->yield( 'next_send' );
}

sub client_tcp_next_send {
  my ($kernel, $heap, $line) = @_[KERNEL, HEAP, ARG0];

  DEBUG and warn "=== client tcp got alarm";

  $heap->{wheel}->put( '0123456789ABCDEF0123456789ABCDEF' );
  $heap->{put_count} += 2;

  # Trigger shutdown after the last test send.
  if ($heap->{put_count} >= $max_send_count) {
    $heap->{wheel}->put( 'DONEDONEDONEDONE' );
  }
}

sub client_tcp_got_error {
  my ($heap, $operation, $errnum, $errstr, $wheel_id) = @_[HEAP, ARG0..ARG3];

  if ($wheel_id == $heap->{socketfactory_wheel_id}) {
    $heap->{test_three} = 0;
  }

  if ($wheel_id == $heap->{readwrite_wheel_id}) {
    $heap->{test_six} = 0;
  }

  delete $heap->{wheel};
  warn "$operation error $errnum: $errstr";
}

sub client_tcp_got_flush {
  $_[HEAP]->{flush_count}++;
  DEBUG and warn "=== client_tcp_got_flush";

  if ($_[HEAP]->{put_count} < $max_send_count) {
    # Puts a little delay between puts.
    $_[KERNEL]->delay( next_send => 0.100 );
  }
  else {
    # Delays destruction until all data is out.
    delete $_[HEAP]->{wheel};
  }
}

###############################################################################
# Start the TCP server and client.

SKIP: {
  unless (-f "run_network_tests") {
    skip "network access (and permission) required to run this test", 7;
  }

  POE::Component::Server::TCP->new(
    Port     => 0,
    Address  => '127.0.0.1',
    Acceptor => sub {
      &sss_new(@_[ARG0..ARG2]);
      # This next badness is just for testing.
      my $sockname = $_[HEAP]->{listener}->getsockname();
      delete $_[HEAP]->{listener};

      my ($port, $addr) = sockaddr_in($sockname);
      $addr = inet_ntoa($addr);

      ok(
        ($addr eq '127.0.0.1') && ($port == $tcp_server_port),
        "received connection"
      );
    },
    Started  => sub {
      $tcp_server_port = (
        sockaddr_in($_[HEAP]->{listener}->getsockname())
      )[0];
    },
  );

  POE::Session->create(
    inline_states => {
      _start     => \&client_tcp_start,
      _stop      => \&client_tcp_stop,
      got_server => \&client_tcp_connected,
      got_error  => \&client_tcp_got_error,
      got_flush  => \&client_tcp_got_flush,
      next_send  => \&client_tcp_next_send,
    }
  );
}

### Test a file that appears and disappears.

SKIP: {
  if (($^O eq 'MSWin32' or $^O eq 'cygwin') and not $ENV{POE_DANTIC}) {
    skip "Can't test file reset on $^O because the OS locks opened files", 2;
  }

  POE::Session->create(
    inline_states => {
      _start => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];

        unlink "./test-tail-file";
        $heap->{wheel} = POE::Wheel::FollowTail->new(
          Filter        => POE::Filter::Line->new(Literal => "\n"),
          Filename      => "./test-tail-file",
          InputEvent    => "got_input",
          ErrorEvent    => "got_error",
          ResetEvent    => "got_reset",
          IdleEvent     => "create_file",
          PollInterval  => 0.500,
        );
        $heap->{sent_count}  = 0;
        $heap->{recv_count}  = 0;
        $heap->{reset_count} = 0;
        DEBUG and warn "=== file tail start";
      },

      create_file => sub {
        open(FH, ">./test-tail-file") or die $!;
        print FH "moo\n";
        close FH;
        DEBUG and warn "=== file tail create file";
        $_[HEAP]->{sent_count}++;

        # Make file creation a one-shot occurrence.
        $_[HEAP]->{wheel}->event( IdleEvent => undef );
      },

      got_input => sub {
        my ($kernel, $heap) = @_[KERNEL, HEAP];
        $heap->{recv_count}++;

        DEBUG and warn "=== file tail input: $_[ARG0]\n";

        unlink "./test-tail-file";

        if ($heap->{recv_count} == 1) {
          # Trigger a new one-shot file creation.
          $heap->{wheel}->event( IdleEvent => 'create_file' );
          return;
        }

        delete $heap->{wheel};
      },

      got_error => sub { warn "$_[ARG0] error $_[ARG1]: $_[ARG2]"; die },

      got_reset => sub {
        DEBUG and warn "=== file tail got reset";
        $_[HEAP]->{reset_count}++;
      },

      _stop => sub {
        DEBUG and warn "=== file tail stop";
        my $heap = $_[HEAP];
        ok(
          ($heap->{sent_count} == $heap->{recv_count}) &&
          ($heap->{sent_count} == 2),
          "file tail sent and received everything we should " .
          "sent($heap->{sent_count}) recv($heap->{recv_count}) wanted(2)"
        );
        is($heap->{reset_count}, 2, "file tail resets detected");
      },
    },
  );
}

### main loop

POE::Kernel->run();

pass("run() returned successfully");

1;
