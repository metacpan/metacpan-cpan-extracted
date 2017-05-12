package Test::Statsd;
$Test::Statsd::VERSION = '0.20';
use 5.008;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::Strict;
use AnyEvent::Handle;
use AnyEvent::Socket;
use IO::Socket::INET ();
use Time::HiRes;

sub new {
  my ($class, $opt) = @_;
  $class = ref $class || $class;
  $opt ||= {};
  my $self = {
    binary      => $opt->{binary},
    config      => $opt->{config},
    _statsd_pid => undef,
  };
  bless $self, $class;
}

# A read callback (read_cb) can optionally be used in special
# cases when you don't want the TCP server to be shut down
# when the first flush data is received (see delete-idle-stats test
# for an example).

sub wait_and_collect_flush_data {
  my ($self, $port, $read_cb) = @_;

  $self->{_flush_data} = "";

  # Pretend to be a carbon/graphite daemon
  $port ||= 40003;

  my $srv;
  my $cv = AE::cv;

  $srv = tcp_server undef, $port, sub {
    my ($fh, $host, $port) = @_;
    my $hdl;
    $hdl = AnyEvent::Handle->new(
      fh => $fh,
      on_error => sub {
        warn "Socket error: $!\n";
        $_[0]->destroy
      },
      on_read => sub {
        my ($ae_handle) = @_;
        # Store graphite data into a private object member
        $self->{_flush_data} .= $ae_handle->rbuf;
        if ($read_cb) {
          $read_cb->($hdl, $cv, $self->{_flush_data});
          # We need to clear the received data now, or our
          # reader will be surprised receiving the old + new
          # buffer in the n > 1 round.
          $self->{_flush_data} = "";
          $ae_handle->{rbuf} = "";
        } else {
          # Calling send() on the condvar stops the TCP server
          $cv->send();
        }
      },
      on_eof => sub { $hdl->destroy },
    );
  };
  $cv->recv();
  return $self->{_flush_data};
}

sub hashify {
  my ($self, $str) = @_;
  my @lines = split m{\r?\n}, $str;
  my $stats;
  for (@lines) {
    $_ =~ s{^ \s* (\S*) \s* $}{$1}x;
    next unless defined;
    my ($key, $val, $ts) = split;
    $stats->{$key} = $val;
  }
  return $stats;
}

sub start_statsd {
  my ($self) = @_;

  my $pid = fork;
  if (! defined $pid) {
    die "Fork failed: $! Aborting.";
  }

  # Child
  elsif ($pid == 0) {
    my @binary = split " ", $self->{binary};
    my $config = $self->{config};
    exec @binary, $config, '2>&1 1>/dev/null';
  }

  # Parent
  else {
    $self->{_statsd_pid} = $pid;
    # Allow for child statsd to start up
    Time::HiRes::usleep(500_000);
  }
}

sub stop_statsd {
  my ($self) = @_;

  my $pid = $self->{_statsd_pid};
  if (! $pid) {
    die "Statsd was never started?";
  }

  if (! kill(15, $pid)) {
    die "Failed to stop statsd (pid: $pid). "
      . "Please do something manually ($!)";
  }

  return 1;
}

sub send_udp {
  my ($self, $host, $port, $payload) = @_;

  my $sock = IO::Socket::INET->new(
    Proto => 'udp',
    PeerAddr => $host,
    PeerPort => $port,
  );

  my $len = $sock->send($payload);
  $sock->close();

  return $len == length($payload);
}

1;

=pod

=head1 NAME

Test::Statsd - Test harness for any statsd server daemon

=head1 DESCRIPTION

Embeds the logic to perform integration tests of any statsd
daemon that can be launched from the command line.

Usage:

    my $t = Test::Statsd->new({
        binary => './bin/statsd',
        config => './bin/sample-config.json'
    });

    # Brings up the statsd server in the background
    # with the specified configuration, and stores its pid
    $t->start_statsd();

    
=cut
