package POEx::ZMQ::Socket;
$POEx::ZMQ::Socket::VERSION = '0.005007';
use v5.10;
use strictures 2;

use Carp;
use Scalar::Util 'reftype';


use List::Objects::WithUtils;

use List::Objects::Types -types;
use POEx::ZMQ::Types     -types;
use Types::Standard      -types;

use POEx::ZMQ::Constants -all;
use POEx::ZMQ::Buffered;
use POEx::ZMQ::FFI::Context;

use POE;

use Try::Tiny;


use Moo; use MooX::late;


with 'MooX::Role::POE::Emitter';

# Emitter:
has '+event_prefix'    => ( default => sub { 'zmq_' } );
has '+shutdown_signal' => ( default => sub { 'SHUTDOWN_ZMQ' } );

# Pluggable:
has '+register_prefix' => ( default => sub { 'ZMQ_' } );


has type => (
  required  => 1,
  is        => 'ro',
  isa       => ZMQSocketType,
  coerce    => 1,
);

has context => (
  lazy      => 1,
  is        => 'ro',
  isa       => ZMQContext,
  builder   => sub { POEx::ZMQ::FFI::Context->new },
);

has ipv6    => (
  lazy      => 1,
  is        => 'ro',
  isa       => Bool,
  builder   => sub { 0 },
);

has max_queue_size => (
  lazy      => 1,
  is        => 'ro',
  isa       => Int,
  builder   => sub { 0 },
);

has max_queue_action => (
  lazy      => 1,
  is        => 'ro',
  # A default action or a CodeRef passed the buffer ArrayObj ->
  isa       => (Enum[qw/drop warn die/] | CodeRef),
  builder   => sub { 'die' },
);



has zsock => (
  lazy      => 1,
  is        => 'ro',
  isa       => ZMQSocketBackend,
  clearer   => '_clear_zsock',
  builder   => sub {
    my ($self) = @_;
    $self->context->create_socket( $self->type )
  },
);

has _zsock_buf => (
  lazy      => 1,
  is        => 'ro',
  isa       => ArrayObj,
  coerce    => 1,
  writer    => '_set_zsock_buf',
  builder   => sub { array },
);

sub get_buffered_items { shift->_zsock_buf->copy }

sub _zsock_fh { shift->zsock->get_handle }

sub start {
  my ($self) = @_;

  $self->set_object_states([
    $self => +{
      emitter_started   => '_pxz_emitter_started',
      emitter_stopped   => '_pxz_emitter_stopped',

      pxz_sock_watch    => '_pxz_sock_watch',
      pxz_sock_unwatch  => '_pxz_sock_unwatch',
      pxz_ready         => '_pxz_ready',
      pxz_nb_read       => '_pxz_nb_read',
      pxz_nb_write      => '_pxz_nb_write',

      bind            => '_px_bind',
      connect         => '_px_connect',
      unbind          => '_px_unbind',
      disconnect      => '_px_disconnect',
      send            => '_px_send',
      send_multipart  => '_px_send_multipart',
    },
    
    ( $self->has_object_states ? @{ $self->object_states } : () ),
  ]);

  $self->_start_emitter
}

sub stop {
  my ($self) = @_;
  $self->call( 'pxz_sock_unwatch' );
  $self->set_sock_opt(ZMQ_LINGER, 0);
  $self->_clear_zsock;
  $self->_shutdown_emitter;
}

sub _pxz_emitter_started {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  if ($self->ipv6) {
    $self->set_sock_opt(
      $self->context->get_zmq_version->string =~ /^(4|3\.3)/ ?
        (ZMQ_IPV6, 1) : (ZMQ_IPV4ONLY, 0)
    )
  }

  $self->call( 'pxz_sock_watch' );
}

sub _pxz_emitter_stopped {

}


=for Pod::Coverage (?:get|set)_(?:ctx|sock)_opt

=cut

sub get_context_opt {
  shift->context->get_ctx_opt(@_)
}
sub set_context_opt {
  my $self = shift;
  $self->context->set_ctx_opt(@_);
  $self
}
{ no warnings 'once';
  *get_ctx_opt = *get_ctx_opt;
  *set_ctx_opt = *set_ctx_opt;
}

sub get_socket_opt {
  shift->zsock->get_sock_opt(@_)
}
sub set_socket_opt {
  my $self = shift; 
  $self->zsock->set_sock_opt(@_); 
  $self 
}
{ no warnings 'once'; 
  *get_sock_opt = *get_socket_opt;
  *set_sock_opt = *set_socket_opt;
}

sub zmq_version { shift->context->get_zmq_version }

sub unbind {
  my $self = shift;
  for my $endpt (@_) {
    $self->zsock->unbind($endpt);
    $self->emit( bind_removed => $endpt )
  }
  $self
}
sub _px_unbind { $_[OBJECT]->unbind(@_[ARG0 .. $#_]) }

sub bind { 
  my $self = shift;
  for my $endpt (@_) {
    $self->zsock->bind($endpt);
    $self->emit( bind_added => $endpt )
  }
  $self
}
sub _px_bind { $_[OBJECT]->bind(@_[ARG0 .. $#_]) }

sub connect {
  my $self = shift;
  for my $endpt (@_) {
    $self->zsock->connect($endpt);
    $self->emit( connect_added => $endpt )
  }
  $self
}
sub _px_connect { $_[OBJECT]->connect(@_[ARG0 .. $#_]) }

sub disconnect {
  my $self = shift;
  for my $endpt (@_) {
    $self->zsock->disconnect($_);
    $self->emit( disconnect_issued => $endpt )
  }
  $self
}
sub _px_disconnect { $_[OBJECT]->disconnect(@_[ARG0 .. $#_]) }


sub _message_not_sendable {
  my ($self, $msg, $flags, $is_multipart) = @_;

  return unless $self->max_queue_size > 0
    and $self->_zsock_buf->count == $self->max_queue_size;

  my $action = $self->max_queue_action;

  if (reftype $action eq 'CODE') {
    my $bufitem = (blessed $msg && $msg->isa('POEx::ZMQ::Buffered')) ? $msg
      : POEx::ZMQ::Buffered->new(
        item_type => ($is_multipart ? 'multipart' : 'single'),
        item      => $msg,
        ( defined $flags ? (flags => $flags) : () ),
      );

    if ( $action->($bufitem, $self->_zsock_buf) ) {
      # coderef action can return true to cause an event check ->
      $self->yield('pxz_ready')
    }

    return 1
  }

  if ($action eq 'die') {
    my $id = $self->alias;
    confess "Attempted to send on socket with filled queue (session $id)" 
  }

  if ($action eq 'warn') {
    my $id = $self->alias;
    warn "WARNING; send queue filled (session $id), dropping message\n";
    return 1
  }

  # $action eq 'drop' returns 1:
  1
}

sub send {
  my ($self, $msg, $flags) = @_;

  return if $self->_message_not_sendable($msg, $flags);

  if (blessed $msg && $msg->isa('POEx::ZMQ::Buffered')) {
    $self->_zsock_buf->push($msg);
  } else {
    $self->_zsock_buf->push( 
      POEx::ZMQ::Buffered->new(
        item      => $msg,
        item_type => 'single',
        ( defined $flags ? (flags => $flags) : () ),
      )
    );
  }

  $self->call('pxz_nb_write');
}
sub _px_send { $_[OBJECT]->send(@_[ARG0 .. $#_]) }

sub send_multipart {
  my ($self, $parts, $flags) = @_;

  confess "Expected an ARRAY of message parts"
    unless ref $parts and reftype $parts eq 'ARRAY' and @$parts;

  return if $self->_message_not_sendable($parts, $flags, 'IS_MULTIPART');

  $self->_zsock_buf->push(
    POEx::ZMQ::Buffered->new(
      item      => $parts,
      item_type => 'multipart',
      ( defined $flags ? (flags => $flags) : () ),
    )
  );

  $self->call('pxz_nb_write');
}
sub _px_send_multipart { $_[OBJECT]->send_multipart(@_[ARG0 .. $#_]) }


sub _pxz_sock_watch {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->select( $self->_zsock_fh, 'pxz_ready' );
  1
}

sub _pxz_sock_unwatch {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->select( $self->_zsock_fh );
}

sub _pxz_ready {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  #  - Try to write pending
  #    - Return if we have nothing queued
  #    - yield another pxz_ready if successful
  #    - delay another pxz_ready if EAGAIN, EINTR, EFSM
  #  - Try to read pending
  #    - Return if ZeroMQ has nothing queued
  #    - yield another pxz_ready if successful
  $self->call('pxz_nb_write')
    unless $self->type == ZMQ_SUB or $self->type == ZMQ_PULL;

  $self->call('pxz_nb_read')
    unless $self->type == ZMQ_PUB or $self->type == ZMQ_PUSH;
}



sub _pxz_nb_read {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  return unless $self->zsock->has_event_pollin;

  my $recv_err;
  try {
    my $msg = $self->zsock->recv(ZMQ_DONTWAIT);
    my @parts;
    while ( $self->zsock->get_sock_opt(ZMQ_RCVMORE) ) {
      push @parts, $self->zsock->recv;
    }

    if (@parts) {
      $self->emit( recv_multipart => array( $msg, @parts ) );
    } else {
      $self->emit( recv => $msg )
    }
    1
  } catch {
    my $maybe_fatal = $_;
    if (blessed $maybe_fatal) {
      my $errno = $maybe_fatal->errno;
      unless ($errno == EAGAIN || $errno == EINTR) {
        $recv_err = $maybe_fatal->errstr;
      }
    } else {
      $recv_err = $maybe_fatal;
    }
    undef
  };

  confess $recv_err if $recv_err;

  # yield back to check for pollin / pending sends ->
  $self->yield('pxz_ready');
}

sub _pxz_nb_write {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  return unless $self->_zsock_buf->has_any;

  my $send_error;
  WRITE: until ($self->_zsock_buf->is_empty || $send_error) {
    my $maybe_fatal;

    my $msg = $self->_zsock_buf->get(0);
    my $flags = $msg->flags | ZMQ_DONTWAIT;

    try {
      if ($msg->item_type eq 'single') {
        $self->zsock->send( $msg->item, $msg->flags );
      } elsif ($msg->item_type eq 'multipart') {
        $self->zsock->send_multipart( $msg->item, $msg->flags );
      }
      $self->_zsock_buf->shift;
    } catch {
      $maybe_fatal = $_
    };

    next WRITE unless $maybe_fatal; 

    # FIXME tests:
    if (blessed $maybe_fatal) {
      my $errno = $maybe_fatal->errno;

      if ($errno == EAGAIN || $errno == EINTR) {
        $poe_kernel->delay(pxz_ready => 0.1);
        return
      } elsif ($errno == EFSM) {
        warn "Requeuing message on bad socket state (EFSM) -- ".
             "your app is probably misusing a socket!";
        $poe_kernel->delay(pxz_ready => 0.1);
        return
      }

      $send_error = $maybe_fatal->errstr;
      last WRITE
    } else {
      $send_error = $maybe_fatal;
      last WRITE
    } 
  } # WRITE

  confess $send_error if defined $send_error;

  $self->yield('pxz_ready');
}

# FIXME monitor support needs a look,
#  also changed upstream in 4.1.0rc
#
# basic outline:
#  - FFI::Socket method that calls zmq_socket_monitor
#  - spawn a child POEx::ZMQ::Socket for our side of ZMQ_PAIR,
#     give it a special event prefix
#  - accept & unpack recv_multipart events from the PAIR sock
#     first frame is a 16-bit event id matching a const,
#      prepending a 32-bit event value
#     second frame is the affected endpoint string
#  - switch emitting more useful events

1;

=pod

=head1 NAME

POEx::ZMQ::Socket - A POE-enabled ZeroMQ socket

=head1 SYNOPSIS

  use POE;
  # Imports POEx::ZMQ::Socket and POEx::ZMQ::Constants ->
  use POEx::ZMQ;

  POE::Session->create(
    inline_states => +{
      _start => sub {
        # Set up a Context and save it for creating sockets later:
        $_[HEAP]->{ctx} = POEx::ZMQ->context;

        # Create a ZMQ_ROUTER socket associated with our Context:
        $_[HEAP]->{rtr} = POEx::ZMQ::Socket->new(
          context => $_[HEAP]->{ctx},
          type    => ZMQ_ROUTER,
        );

        # Set up the backend socket and start accepting/emitting events:
        $_[HEAP]->{rtr}->start;

        # Bind to a local TCP endpoint:
        $_[HEAP]->{rtr}->bind( 'tcp://127.0.0.1:1234' );
      },

      zmq_recv_multipart => sub {
        # ROUTER got message from REQ / DEALER
        # parts are available as a List::Objects::WithUtils::Array ->
        my $parts = $_[ARG0];

        # ROUTER receives [ IDENTITY, NULL, MSG .. ]:
        my $route = $parts->items_before(sub { $_ eq '' });
        my $body  = $parts->items_after(sub { $_ eq '' });

        my $response;
        # ... do work ...
        # Send a response back:
        $_[KERNEL]->post( $_[SENDER], send_multipart =>
          [ $route->all, '', $response ]
        );
      },
    },
  );

  POE::Kernel->run;

=head1 DESCRIPTION

An asynchronous L<POE>-powered L<ZeroMQ|http://www.zeromq.org> socket.

These objects are event emitters powered by L<MooX::Role::POE::Emitter>. That
means they come with flexible event processing / dispatch / multiplexing
options. See the L<MooX::Role::Pluggable> and L<MooX::Role::POE::Emitter>
documentation for details.

=head2 ATTRIBUTES

=head3 type

B<Required>; the socket type, as a constant.

See L<zmq_socket(3)> for details on socket types.

See L<POEx::ZMQ::Constants> for a ZeroMQ constant exporter.

=head3 ipv6

If set to true, IPv6 support is enabled via the appropriate socket option
(C<ZMQ_IPV4ONLY> or C<ZMQ_IPV6> depending on your ZeroMQ version) when the
emitter is started.

Defaults to false.

=head3 max_queue_size

Socket types that would normally block or return C<EFSM> (for example,
out-of-order REP/REQ communication) will queue messages instead to avoid
blocking the event loop; C<max_queue_size> is the maximum number of messages
queued application-side before L</max_queue_action> is invoked.

This is not related to messages queued on the ZeroMQ side; see
L<zmq_socket(3)> for details on socket behavior.

Defaults to 0 (unlimited)

=head3 max_queue_action

The action to take during L</send> invocation when the application-side
outgoing message queue reaches L</max_queue_size>.

If set to B<drop>, new messages will be dropped.

If set to B<warn>, a warning will be issued and new messages will be dropped.

If set to B<die>, a stack trace is thrown.

If set to a coderef:

  max_queue_action => sub {
    my ($buf_item, $queue) = @_;
    # Drop old and try again, for example:
    $queue->shift;
    1
  },

... the subroutine is invoked and passed the
L<POEx::ZMQ::Buffered> object for the message and the current application-side
outgoing message queue as a L<List::Objects::WithUtils::Array> (respectively).
This can be used to manually munge your outgoing queue yourself or perform
some other action; if the given subroutine returns a boolean true value, another
socket write will be attempted after the subroutine returns.

Defaults to C<die>.

=head3 context

The L<POEx::ZMQ::FFI::Context> backend context object.

=head3 zsock

The L<POEx::ZMQ::FFI::Socket> backend socket object.

=head2 METHODS

=head3 start

Start the emitter and set up the associated socket.

B<< This method must be called >> to create the backend ZeroMQ socket and start
the emitter's L<POE::Session>.

Returns the object.

=head3 stop

Stop the emitter; a L<zmq_close(3)> will be issued for the socket and
L</zsock> will be cleared.

Buffered items are not removed; L</get_buffered_items> can be used to retrieve
them for feeding to a new socket object's L</send> method. See
L<POEx::ZMQ::Buffered>.

=head3 zmq_version

Returns the ZeroMQ version as a struct-like object; see
L<POEx::ZMQ::FFI/get_version>.

=head3 get_buffered_items

Returns (a shallow copy of) the L<List::Objects::WithUtils::Array> containing
messages currently buffered B<on the POE component> (due to a backend ZeroMQ
socket's blocking behavior; see L<zmq_socket(3)>).

This will not return messages queued on the ZeroMQ side.

Each item is a L<POEx::ZMQ::Buffered> object; look there for attribute
documentation. These can also be fed back to L</send> after retrieval from a
dead socket, for example:

  $old_socket->stop;  # Shut down this socket
  my $pending = $old_socket->get_buffered_items;
  $new_socket->send($_) for $pending->all;

=head3 get_context_opt

Retrieve context option values.

See L<POEx::ZMQ::FFI::Context/get_ctx_opt> & L<zmq_ctx_get(3)>

=head3 set_context_opt

Set context option values.

See L<POEx::ZMQ::FFI::Context/set_ctx_opt> & L<zmq_ctx_set(3)>

Returns the invocant.

=head3 get_socket_opt

  my $last_endpt = $sock->get_sock_opt( ZMQ_LAST_ENDPOINT );

Get socket option values.

See L<POEx::ZMQ::FFI::Socket/get_sock_opt> & L<zmq_getsockopt(3)>.

=head3 set_socket_opt

  $sock->set_sock_opt( ZMQ_LINGER, 0 );

Set socket option values.

See L<POEx::ZMQ::FFI::Socket/set_sock_opt> & L<zmq_setsockopt(3)>.

Returns the invocant.

=head3 bind

  $sock->bind( @endpoints );

Call a L<zmq_bind(3)> for one or more specified endpoints.

A L</bind_added> event is emitted for each added endpoint.

Returns the invocant.

=head3 unbind

  $sock->unbind( @endpoints );

Call a L<zmq_unbind(3)> for one or more specified endpoints.

A L</bind_removed> event is emitted for each removed endpoint.

Returns the invocant.

=head3 connect

  $sock->connect( @endpoints );

Call a L<zmq_bind(3)> for one or more specified endpoints.

A L</connect_added> event is emitted for each added endpoint.

Returns the invocant.

=head3 disconnect

  $sock->disconnect( @endpoints );

Call a L<zmq_disconnect(3)> for one or more specified endpoints.

A L</disconnect_issued> event is emitted for each removed endpoint.

Returns the invocant.

=head3 send

  $sock->send( $msg, $flags );

Send a single-part message (without blocking).

Sending will not block, regardless of the typical behavior of the ZeroMQ
socket. See L</max_queue_size> for details on queuing behavior.

Returns the invocant.

=head3 send_multipart

  $sock->send_multipart( [ @parts ], $flags );
  # A ROUTER sending to $id ->
  $rtr->send_multipart( [ $id, '', $msg ], $flags );

Send a multi-part message.

Applies the same application-side queuing behavior as L</send>; see
L</max_queue_size>.

Returns the invocant.

=head2 ACCEPTED EVENTS

These L<POE> events take the same arguments as their object-oriented
counterparts documented in L</METHODS>:

=over

=item bind

=item unbind

=item connect

=item disconnect

=item send

=item send_multipart

=back

=head2 EMITTED EVENTS

Emitted events are prefixed with the value of the
L<MooX::Role::POE::Emitter/event_prefix> attribute; by default, C<zmq_>.

=head3 bind_added

Emitted when a L</bind> is issued for an endpoint; C<$_[ARG0]> is the bound
endpoint.

=head3 bind_removed

Emitted when a L</unbind> is issued for an endpoint; C<$_[ARG0]> is the
unbound endpoint.

=head3 connect_added

Emitted when a L</connect> is issued for an endpoint; C<$_[ARG0]> is the
target endpoint.

=head3 disconnect_issued

Emitted when a L</disconnect> is issued for an endpoint; C<$_[ARG0]> is the
disconnecting endpoint.

=head3 recv

  sub zmq_recv {
    my $msg = $_[ARG0];
    $_[KERNEL]->post( $_[SENDER], send => 'bar' ) if $msg eq 'foo';
  }

Emitted when a single-part message is received; C<$_[ARG0]> is the message
item.

=head3 recv_multipart

  # A ROUTER receiving from REQ, for example:
  sub zmq_recv_multipart {
    my $parts = $_[ARG0];
    my ($id, undef, $content) = @$parts;

    my $response = 'bar' if $content eq 'foo';

    $_[KERNEL]->post( $_[SENDER], send_multipart =>
      [ $id, '', $response ]
    );
  }

  # ... or with more complex routing envelopes:
  sub zmq_recv_multipart {
    my $parts = $_[ARG0];
    # pop() the application-relevant body:
    my $body = $parts->pop;
    # Then include the envelope (including empty delimiter msg) later:
    $_[KERNEL]->post( $_[SENDER], send_multipart =>
      [ $parts->all, $response ]
    );
  }

Emitted when a multipart message is received.

C<$_[ARG0]> is a L<List::Objects::WithUtils::Array> array-type object
containing the message parts. This makes basic handling tasks easy, such as
splitting multipart bodies and the routing envelope on an empty part
delimiter:

  my $envelope = $parts->items_before(sub { $_ eq '' });
  my $content  = $parts->items_after(sub { $_ eq '' });
  # ... returning a reply later:
  $zsock->send_multipart(
    [ $envelope->all, '', @parts ]
  );

=head1 CONSUMES

L<MooX::Role::POE::Emitter>, which in turn consumes L<MooX::Role::Pluggable>.

=head1 SEE ALSO

L<zmq(7)>

L<zmq_socket(3)>

L<POEx::ZMQ::FFI::Context> for details on the ZeroMQ context backend.

L<POEx::ZMQ::FFI::Socket> for details on the ZeroMQ socket backend.

L<ZMQ::FFI> for a loop-agnostic ZeroMQ implementation.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
