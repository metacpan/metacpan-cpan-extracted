package Object::Remote::Handle;

use Object::Remote::Proxy;
use Scalar::Util qw(weaken blessed);
use Object::Remote::Logging qw ( :log :dlog router );
use Object::Remote::Future;
use Module::Runtime qw(use_module);
use Moo;

BEGIN { router()->exclude_forwarding }

has connection => (
  is => 'ro', required => 1, handles => ['is_valid'],
  coerce => sub {
    blessed($_[0])
      ? $_[0]
      : use_module('Object::Remote::Connection')->new_from_spec($_[0])
  },
);

has id => (is => 'rwp');

has disarmed_free => (is => 'rwp');

sub disarm_free { $_[0]->_set_disarmed_free(1); $_[0] }

sub proxy {
  bless({ remote => $_[0], method => 'call' }, 'Object::Remote::Proxy');
}

sub BUILD {
  my ($self, $args) = @_;
  log_trace { "constructing remote handle" };
  if ($self->id) {
    log_trace { "disarming free for this handle" };
    $self->disarm_free;
  } else {
    die "No id supplied and no class either" unless $args->{class};
    ref($_) eq 'HASH' and $_ = [ %$_ ] for $args->{args};
    log_trace { "fetching id for handle and disarming free on remote side" };
    $self->_set_id(
      await_future(
        $self->connection->send_class_call(
          0, $args->{class},
          $args->{constructor}||'new', @{$args->{args}||[]}
        )
      )->{remote}->disarm_free->id
    );
  }
  Dlog_trace { "finished constructing remote handle; id is $_" } $self->id;
  $self->connection->register_remote($self);
}

sub call {
  my ($self, $method, @args) = @_;
  my $w = wantarray;
  my $id = $self->id;

  $method = "start::${method}" if (caller(0)||'') eq 'start';
  log_trace { "call('$method') has been invoked on remote handle '$id'; creating future" };

  future {
    log_debug { "Invoking send on connection for handle '$id' method '$method'" };
    $self->connection->send(call => $id, $w, $method, @args)
  };
}

sub call_discard {
  my ($self, $method, @args) = @_;
  log_trace { "invoking send_discard() with 'call' for method '$method' on connection for remote handle" };
  $self->connection->send_discard(call => $self->id, $method, @args);
}

sub call_discard_free {
  my ($self, $method, @args) = @_;
  $self->disarm_free;
  log_trace { "invoking send_discard() with 'call_free' for method '$method' on connection for remote handle" };
  $self->connection->send_discard(call_free => $self->id, $method, @args);
}

sub DEMOLISH {
  my ($self, $gd) = @_;
  Dlog_trace { "Demolishing remote handle $_" } $self->id;
  return if $gd or $self->disarmed_free;
  #this could happen after the connection has gone away
  eval { $self->connection->send_free($self->id) };
  if ($@ && $@ !~ m/^Attempt to invoke _send on a connection that is not valid/) {
    die "Could not invoke send_free on connection for handle " . $self->id;
  }
}

1;
