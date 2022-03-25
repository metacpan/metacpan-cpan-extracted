package Mojo::Server::DaemonControl::Worker;
use Mojo::Base 'Mojo::Server::Daemon', -signatures;

use IO::Socket::UNIX;
use Scalar::Util qw(weaken);

has heartbeat_interval => sub { $ENV{MOJO_SERVER_DAEMON_HEARTBEAT_INTERVAL} || 5 };
has silent             => 1;
has worker_pipe        => sub ($self) { $self->_build_worker_pipe };

sub run ($self, $app, @) {
  weaken $self;
  $0 = $app;
  my $loop         = $self->ioloop;
  my $heartbeat_cb = sub { $self->_heartbeat('h') };
  $loop->next_tick($heartbeat_cb);
  $loop->recurring($self->heartbeat_interval, $heartbeat_cb);
  $loop->on(finish => sub { $self->max_requests(1) });
  local $SIG{QUIT} = sub { $self->_stop_gracefully };
  return $self->tap(load_app => $app)->SUPER::run;
}

sub _build_worker_pipe ($self) {
  my $path = $ENV{MOJO_SERVER_DAEMON_CONTROL_SOCK}
    || die "Can't create a worker pipe: MOJO_SERVER_DAEMON_CONTROL_SOCK not set";
  return IO::Socket::UNIX->new(Peer => $path, Type => SOCK_DGRAM)
    || die "Can't create a worker pipe: $@";
}

sub _heartbeat ($self, $state) {
  $self->worker_pipe->syswrite("$$:$state\n") || die "ERR! $!";
}

sub _stop_gracefully ($self) {
  $self->ioloop->stop_gracefully;
  $self->_heartbeat('g');
  $0 .= '-' . time;    # Rename process to indicate which is going to be replaced
}

1;

=encoding utf8

=head1 NAME

Mojo::Server::DaemonControl::Worker - A Mojolicious daemon that can shutdown gracefully

=head1 SYNOPSIS

  use Mojo::Server::DaemonControl::Worker;
  my $daemon = Mojo::Server::DaemonControl::Worrker->new(listen => ['http://*:8080']);
  $daemon->run;

=head1 DESCRIPTION

L<Mojo::Server::DaemonControl::Worker> is a sub class of
L<Mojo::Server::Daemon>, that is used by L<Mojo::Server::DaemonControl>
to support graceful shutdown and hot deployment.

=head1 SIGNALS

The L<Mojo::Server::DaemonControl::Worker> process can be controlled by the
same signals as L<Mojo::Server::Daemon>, but it also supports the following
signals.

=head2 QUIT

Used to shut down the server gracefully.

=head1 EVENTS

L<Mojo::Server::DaemonControl::Worker> inherits all events from
L<Mojo::Server::Daemon>.

=head1 ATTRIBUTES

L<Mojo::Server::DaemonControl::Worker> inherits all attributes from
L<Mojo::Server::Daemon> and implements the following ones.

=head2 heartbeat_interval

  $int    = $daemon->heartbeat_interval;
  $daemon = $daemon->heartbeat_interval(2.5);

Heartbeat interval in seconds. See
L<Mojo::Server::DaemonControl::Worker/heartbeat_interval> for more details.

=head2 silent

  $bool   = $daemon->silent;
  $daemon = $daemon->silent(1);

Changes the default in L<Mojo::Server::Daemon/silent> to 1.

=head2 worker_pipe

  $socket = $daemon->worker_pipe;

Holds a L<IO::Socket::UNIX> object used to communicate with the manager. The
default socket path is read from the C<MOJO_SERVER_DAEMON_CONTROL_SOCK>
environment variable.

=head1 METHODS

L<Mojo::Server::DaemonControl::Worker> inherits all methods from
L<Mojo::Server::Daemon> and implements the following ones.

=head2 run

  $daemon->run($app);

Load C<$app> using L<Mojo::Server/load_app> and run server and wait for
L</SIGNALS>.

=head1 SEE ALSO

L<Mojo::Server::DaemonControl>.

=cut
