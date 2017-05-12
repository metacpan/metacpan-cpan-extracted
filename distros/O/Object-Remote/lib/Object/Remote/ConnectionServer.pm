package Object::Remote::ConnectionServer;

use Scalar::Util qw(blessed weaken);
use Module::Runtime qw(use_module);
use Object::Remote;
use Object::Remote::Logging qw( :log :dlog );
use Future;
use IO::Socket::UNIX;
use Moo;

has listen_on => (
  is => 'ro',
  coerce => sub {
    return $_[0] if blessed($_[0]);
    unlink($_[0]);
    IO::Socket::UNIX->new(
      Local => $_[0],
      Listen => 1
    ) or die "Couldn't liten to $_[0]: $!";
  },
  trigger => sub {
    my ($self, $fh) = @_;
    log_debug { "adding connection server to run loop because the trigger has executed" };
    weaken($self);
    Object::Remote->current_loop
                  ->watch_io(
                      handle => $fh,
                      on_read_ready => sub { $self->_listen_ready($fh) }
                    );
  },
);

has connection_args => (
 is => 'ro', default => sub { [] }
);

has connection_callback => (
  is => 'ro', default => sub { sub { shift } }
);

sub BUILD {
  log_debug { "A connection server has been built; calling want_run on run loop" };
  Object::Remote->current_loop->want_run;
}

sub run {
  log_debug { "Connection server is calling run_while_wanted on the run loop" };
  Object::Remote->current_loop->run_while_wanted;
}

sub _listen_ready {
  my ($self, $fh) = @_;
  log_debug { "Got a connection, calling accept on the file handle" };
  my $new = $fh->accept or die "Couldn't accept: $!";
  log_trace { "Setting file handle non-blocking" };
  $new->blocking(0);
  my $f = Future->new;
  log_trace { "Creating a new connection with the remote node" };
  my $c = use_module('Object::Remote::Connection')->new(
    receive_from_fh => $new,
    send_to_fh => $new,
    on_close => $f, # and so will die $c
    @{$self->connection_args}
  )->${\$self->connection_callback};
  $f->on_ready(sub { undef($c) });
  log_trace { "marking the future as done" };
  $c->ready_future->done;
  Dlog_trace { "Sending 'Shere' to socket $_" } $new;
  print $new "Shere\n" or die "Couldn't send to new socket: $!";
  log_debug { "Connection has been fully handled" };
  return $c;
}

sub DEMOLISH {
  my ($self, $gd) = @_;
  log_debug { "A connection server is being destroyed; global destruction: '$gd'" };
  return if $gd;
  log_trace { "Removing the connection server IO watcher from run loop" };
  Object::Remote->current_loop
                ->unwatch_io(
                    handle => $self->listen_on,
                    on_read_ready => 1
                  );
  if ($self->listen_on->can('hostpath')) {
    log_debug { my $p = $self->listen_on->hostpath; "Removing '$p' from the filesystem" };
    unlink($self->listen_on->hostpath);
  }
  log_trace { "calling want_stop on the run loop" };
  Object::Remote->current_loop->want_stop;
}

1;
