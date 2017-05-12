package Tak::Daemon::ListenerService;

use Scalar::Util qw(weaken);
use Moo;

with 'Tak::Role::Service';

has listen_on => (is => 'ro', required => 1);
has router => (is => 'ro', required => 1);

has state => (is => 'rw', default => sub { 'down' }, init_arg => undef);

has _start_in_progress => (is => 'lazy', clearer => '_clear_start_in_progress');

has listener => (is => 'rw', clearer => 'clear_listener');

has connections => (is => 'ro', default => sub { {} });

sub start_start_request {
  my ($self, $req) = @_;
  $req->result('already_started') if $self->state eq 'running';
  push(@{$self->_start_in_progress->{requests}}, $req);
  $self->_start_in_progress->{start}();
}

sub _build__start_in_progress {
  my ($self) = @_;
  weaken($self);
  my %start = (requests => (my $requests = []));
  my $listen_on = $self->listen_on;
  my %addr = (
    socktype => "stream",
    map +(
      ref($_)
        ? (family => "inet", %$_)
        : (family => "unix", path => $_)
    ), $listen_on
  );
  $start{start} = sub {
    $self->state('starting');
    Tak->loop_upgrade;
    Tak->loop->listen(
      addr => \%addr,
      on_notifier => sub {
        $self->listener($_[0]);
        $_->success('started') for @$requests;
        $self->_clear_start_in_progress;
        $self->state('running');
      },
      on_resolve_error => sub { # no-op until we add non-unix
        $_->failure(resolve => @_) for @$requests;
        $self->_clear_start_in_progress;
        $self->state('stopped');
      },
      on_listen_error => sub {
        $_->failure(listen => @_) for @$requests;
        $self->_clear_start_in_progress;
        $self->state('stopped');
      },
      on_accept => sub {
        $self->setup_connection($_[0]);
      },
      on_accept_error => sub {
        $self->handle_stop;
      },
    );
    $start{start} = sub {}; # delete yourself
  };
  \%start;
}

sub handle_stop {
  my ($self) = @_;
  return 'already_stopped' if $self->state eq 'down';
  # there's probably something more intelligent to do here, but meh
  die failure => 'starting' if $self->state eq 'starting';
  Tak->loop->remove($self->clear_listener);
  !ref and unlink($_) for $self->listen_on;
  $self->state('down');
  return 'stopped';
}

sub DEMOLISH {
  my ($self, $in_global_destruction) = @_;

  return unless $self->state eq 'running';

  !ref and unlink($_) for $self->listen_on;

  return if $in_global_destruction;

  Tak->loop->remove($self->listener);
}

sub setup_connection {
  my ($self, $socket) = @_;
  my $conn_set = $self->connections;
  my $conn_str;
  my $connection = Tak::ConnectionService->new(
    read_fh => $socket, write_fh => $socket,
    listening_service => $self->router->clone_or_self,
    on_close => sub { delete $conn_set->{$conn_str} }
  );
  $conn_str = "$connection";
  $connection->receiver->service->service->register_weak(remote => $connection);
  $conn_set->{$conn_str} = $connection;
  return;
}

1;
