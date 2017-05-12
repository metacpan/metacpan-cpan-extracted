package POEx::ZMQ::FFI::Socket;
$POEx::ZMQ::FFI::Socket::VERSION = '0.005007';
use v5.10;
use Carp;
use strictures 2;

require bytes;
require IO::Handle;

use Time::HiRes ();

use List::Objects::WithUtils;
use List::Objects::WithUtils::Array;

use Types::Standard  -types;
use POEx::ZMQ::Types -types;

use POEx::ZMQ::Constants -all;
use POEx::ZMQ::FFI;
use POEx::ZMQ::FFI::Cached;
use POEx::ZMQ::FFI::Callable;

use FFI::Raw;


=pod

=for Pod::Coverage OPTVAL_MAXLEN ZMQ_MSG_SIZE

=for comment

OPTVAL_MAXLEN
Maximum length of binary/string type option values.
(Large enough to hold ZMQ_IDENTITY / ZMQ_LAST_ENDPOINT)

ZMQ_MSG_SIZE
Maximum zmg_msg_t_size plus wiggle room.

=cut

sub OPTVAL_MAXLEN () { 256 }
sub ZMQ_MSG_SIZE  () { 128 }


use Moo; use MooX::late;


has context => (
  required  => 1,
  is        => 'ro',
  isa       => ZMQContext,
);

has type    => (
  required  => 1,
  is        => 'ro',
  isa       => ZMQSocketType,
);

has soname  => (
  lazy      => 1,
  is        => 'ro',
  isa       => Str,
  builder   => sub { shift->context->soname },
);


has _ffi => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['POEx::ZMQ::FFI::Callable'],
  builder   => '_build_ffi',
);

sub _build_ffi {
  my ($self) = @_;
  my $soname = $self->soname;

  if (my $ffi = POEx::ZMQ::FFI::Cached->get(Socket => $soname)) {
    return $ffi
  }

  POEx::ZMQ::FFI::Cached->set(
    Socket => $soname => POEx::ZMQ::FFI::Callable->new(
      zmq_socket => FFI::Raw->new(
        $soname, zmq_socket =>
          FFI::Raw::ptr,  # <- socket ptr
          FFI::Raw::ptr,  # -> context ptr
          FFI::Raw::int,  # -> socket type
      ),

      zmq_getsockopt => FFI::Raw->new(
        $soname, zmq_getsockopt =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::int,  # -> opt (constant)
          FFI::Raw::ptr,  # -> opt value ptr
          FFI::Raw::ptr,  # -> value len ptr
      ),

      int_zmq_setsockopt => FFI::Raw->new(
        $soname, zmq_setsockopt =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::int,  # -> opt (constant)
          FFI::Raw::ptr,  # -> opt value ptr (int)
          FFI::Raw::int,  # -> opt value len
      ),
      str_zmq_setsockopt => FFI::Raw->new(
        $soname, zmq_setsockopt =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::int,  # -> opt (constant)
          FFI::Raw::str,  # -> opt value ptr (str)
          FFI::Raw::int,  # -> opt value len
      ),

      zmq_connect => FFI::Raw->new(
        $soname, zmq_connect =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::str,  # -> endpoint str
      ),

      zmq_disconnect => FFI::Raw->new(
        $soname, zmq_disconnect =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::str,  # -> endpoint str
      ),

      zmq_bind => FFI::Raw->new(
        $soname, zmq_bind =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::str,  # -> endpoint str
      ),

      zmq_unbind => FFI::Raw->new(
        $soname, zmq_unbind =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::str,  # -> endpoint str
      ),

      zmq_msg_init => FFI::Raw->new(
        $soname, zmq_msg_init =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
      ),

      zmq_msg_init_size => FFI::Raw->new(
        $soname, zmq_msg_init_size =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
          FFI::Raw::int,  # -> len
      ),

      zmq_msg_size => FFI::Raw->new(
        $soname, zmq_msg_size =>
          FFI::Raw::int,  # <- len
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
      ),

      zmq_msg_data => FFI::Raw->new(
        $soname, zmq_msg_data =>
          FFI::Raw::ptr,  # <- msg data ptr
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
      ),

      zmq_msg_close => FFI::Raw->new(
        $soname, zmq_msg_close =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
      ),

      zmq_msg_recv => FFI::Raw->new(
        $soname, zmq_msg_recv =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> zmq_msg_t ptr
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::int,  # -> flags
      ),

      zmq_send => FFI::Raw->new(
        $soname, zmq_send =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
          FFI::Raw::str,  # -> msg
          FFI::Raw::int,  # -> len
          FFI::Raw::int,  # -> flags
      ),

      zmq_close => FFI::Raw->new(
        $soname, zmq_close =>
          FFI::Raw::int,  # <- rc
          FFI::Raw::ptr,  # -> socket ptr
      ),

      memcpy => FFI::Raw->new(
        undef, memcpy =>
          FFI::Raw::ptr,  # <- dest ptr
          FFI::Raw::ptr,  # -> dest buf ptr
          FFI::Raw::ptr,  # -> src
          FFI::Raw::int,  # -> len
      ),
    )
  )
}

has _socket_ptr => (
  lazy      => 1,
  is        => 'ro',
  isa       => Defined,
  writer    => '_set_socket_ptr',
  predicate => '_has_socket_ptr',
  builder   => sub {
    my ($self) = @_;
    $self->_ffi->zmq_socket( $self->context->get_raw_context, $self->type )
  },
);

sub get_raw_socket { shift->_socket_ptr }


has _stored_handle => (
  lazy      => 1,
  is        => 'ro',
  isa       => FileHandle,
  writer    => '_set_stored_handle',
  clearer   => '_clear_stored_handle',
  builder    => sub {
    IO::Handle->new_from_fd( $_[0]->get_sock_opt(ZMQ_FD), 'r' );
  },
);

sub get_handle { $_[0]->_stored_handle }


with 'POEx::ZMQ::FFI::Role::ErrorChecking';


=for Pod::Coverage BUILD DEMOLISH

=cut

sub BUILD {
  my ($self) = @_;
  # Clean edge state ->
  $self->recv while $self->has_event_pollin;
}

sub DEMOLISH {
  my ($self, $gd) = @_;

  return if $gd;

  $self->warn_if_error( zmq_close =>
    $self->_ffi->zmq_close( $self->_socket_ptr )
  ) if $self->_has_socket_ptr;

  # race causes assertions during cleanup after a get_handle ->
  Time::HiRes::sleep 0.01;
  $self->_clear_stored_handle;
}


our $KnownTypes = hash;
$KnownTypes->set( $_, 'int' ) for (
  ZMQ_BACKLOG,            #
  ZMQ_CONFLATE,           # 4.0
  ZMQ_DELAY_ATTACH_ON_CONNECT,
  ZMQ_EVENTS,             #
  ZMQ_FD,                 #
  ZMQ_IMMEDIATE,          # 3.3
  ZMQ_IPV4ONLY,           # deprecated by ZMQ_IPV6 (3.3)
  ZMQ_IPV6,               # 3.3
  ZMQ_LINGER,             #
  ZMQ_MULTICAST_HOPS,     #
  ZMQ_PLAIN_SERVER,       # 4.0
  ZMQ_CURVE_SERVER,       # 4.0
  ZMQ_PROBE_ROUTER,       # 4.0
  ZMQ_RATE,               #
  ZMQ_RECOVERY_IVL,       #
  ZMQ_RECONNECT_IVL,      #
  ZMQ_RECONNECT_IVL_MAX,  #
  ZMQ_REQ_CORRELATE,      # 4.0
  ZMQ_REQ_RELAXED,        # 4.0
  ZMQ_ROUTER_MANDATORY,   #
  ZMQ_ROUTER_RAW,         # 3.3
  ZMQ_RCVBUF,             #
  ZMQ_RCVMORE,            #
  ZMQ_RCVHWM,             #
  ZMQ_RCVTIMEO,           #
  ZMQ_SNDHWM,             #
  ZMQ_SNDTIMEO,           #
  ZMQ_SNDBUF,             #
  ZMQ_XPUB_VERBOSE,       #
);
$KnownTypes->set( $_, 'uint64' ) for (
  ZMQ_AFFINITY,           #
  ZMQ_MAXMSGSIZE,         #
);
# ... doesn't really matter if we differentiate here, but:
$KnownTypes->set( $_, 'binary' ) for (
  ZMQ_IDENTITY,           #
  ZMQ_SUBSCRIBE,          #
  ZMQ_UNSUBSCRIBE,        #
  ZMQ_CURVE_PUBLICKEY,    # 4.0
  ZMQ_CURVE_SECRETKEY,    # 4.0
  ZMQ_CURVE_SERVERKEY,    # 4.0
  ZMQ_TCP_ACCEPT_FILTER,  #
);
$KnownTypes->set( $_, 'string' ) for (
  ZMQ_LAST_ENDPOINT,      #
  ZMQ_PLAIN_USERNAME,     # 4.0
  ZMQ_PLAIN_PASSWORD,     # 4.0
  ZMQ_ZAP_DOMAIN,         # 4.0
);

sub known_type_for_opt { $KnownTypes->get($_[1]) }

sub get_sock_opt {
  my ($self, $opt, $type) = @_;
  my ($val, $ptr, $len);

  $type //= $self->known_type_for_opt($opt)
        // confess "No return type specified and none known to us (opt $opt)";

  if ($type eq 'binary' || $type eq 'string') {
    $ptr = FFI::Raw::memptr( OPTVAL_MAXLEN );
    $len = pack 'L!', OPTVAL_MAXLEN;
  } else {
    $val = POEx::ZMQ::FFI->zpack($type, 0);
    $ptr = unpack 'L!', pack 'P', $val;
    $len = pack 'L!', length $val;
  }

  my $len_ptr = unpack 'L!', pack 'P', $len;
  $self->throw_if_error( zmq_getsockopt =>
    $self->_ffi->zmq_getsockopt(
      $self->_socket_ptr, $opt, $ptr, $len_ptr
    )
  );

  POEx::ZMQ::FFI->zunpack($type, $val, $ptr, $len)
}

sub set_sock_opt {
  my ($self, $opt, $val, $type) = @_;

  unless (defined $type) {
    $type = $self->known_type_for_opt($opt)
      // confess "No opt type specified and none known to us (opt $opt)"
  }

  if ($type eq 'binary' || $type eq 'string') {
    $self->throw_if_error( zmq_setsockopt =>
      $self->_ffi->str_zmq_setsockopt(
        $self->_socket_ptr, $opt, $val, length $val
      )
    );
  } else {
    my $packed = POEx::ZMQ::FFI->zpack($type, $val);
    my $ptr = unpack 'L!', pack 'P', $packed;
    $self->throw_if_error( zmq_setsockopt =>
      $self->_ffi->int_zmq_setsockopt(
        $self->_socket_ptr, $opt, $ptr, length $packed
      )
    )
  }

  $self
}




sub connect {
  my ($self, $endpoint) = @_;
  confess "Expected an endpoint" unless defined $endpoint;

  $self->throw_if_error( zmq_connect =>
    $self->_ffi->zmq_connect( $self->_socket_ptr, $endpoint )
  )
}

sub disconnect {
  my ($self, $endpoint) = @_;
  confess "Expected an endpoint" unless defined $endpoint;

  $self->throw_if_error( zmq_disconnect =>
    $self->_ffi->zmq_disconnect( $self->_socket_ptr, $endpoint )
  )
}

sub bind {
  my ($self, $endpoint) = @_;
  confess "Expected an endpoint" unless defined $endpoint;

  $self->throw_if_error( zmq_bind =>
    $self->_ffi->zmq_bind( $self->_socket_ptr, $endpoint )
  )
}

sub unbind {
  my ($self, $endpoint) = @_;
  confess "Expected an endpoint" unless defined $endpoint;

  $self->throw_if_error( zmq_unbind =>
    $self->_ffi->zmq_unbind( $self->_socket_ptr, $endpoint )
  )
}

sub send {
  my $len = bytes::length($_[1]);
  $_[0]->throw_if_error( zmq_send =>
    $_[0]->_ffi->zmq_send( $_[0]->_socket_ptr, $_[1], $len, ($_[2] // 0) )
  )
}

sub send_multipart {
  my ($self, $data, $flags) = @_;
  $flags //= 0;
  confess "Expected an ARRAY of message parts"
    unless Scalar::Util::reftype($data) eq 'ARRAY'
    and @$data;
  $self->send( $data->[$_], $flags | ZMQ_SNDMORE ) for 0 .. ($#$data - 1);
  $self->send( $data->[-1], $flags );
}

sub recv {
  my $self = $_[0];
  my ($ffi, $zmsg_ptr, $zmsg_len) 
    = ( $self->_ffi, FFI::Raw::memptr(ZMQ_MSG_SIZE) );

  $self->throw_if_error( zmq_msg_init => $ffi->zmq_msg_init($zmsg_ptr) );
  $self->throw_if_error( zmq_msg_recv => (
    $zmsg_len =
      $ffi->zmq_msg_recv( $zmsg_ptr, $self->_socket_ptr, ($_[1] // 0) )
    )
  );

  if ($zmsg_len) {
    my $content_ptr  = FFI::Raw::memptr($zmsg_len);
    $ffi->memcpy( $content_ptr, $ffi->zmq_msg_data($zmsg_ptr), $zmsg_len );
    $ffi->zmq_msg_close($zmsg_ptr);
    return $content_ptr->tostr($zmsg_len);
  } else {
    $ffi->zmq_msg_close($zmsg_ptr);
    return ''
  }
}

sub recv_multipart {
  my @parts = $_[0]->recv($_[1]);
  push @parts, $_[0]->recv($_[1]) while $_[0]->get_sock_opt(ZMQ_RCVMORE);
  List::Objects::WithUtils::Array->new(@parts)
}

sub has_event_pollin {
  !! ( $_[0]->get_sock_opt(ZMQ_EVENTS) & ZMQ_POLLIN )
}

sub has_event_pollout {
  !! ( $_[0]->get_sock_opt(ZMQ_EVENTS) & ZMQ_POLLOUT )
}

1;

=pod

=head1 NAME

POEx::ZMQ::FFI::Socket

=head1 SYNOPSIS

  # Used internally by POEx::ZMQ

=head1 DESCRIPTION

An object representing a ZeroMQ socket; used internally by L<POEx::ZMQ>.

These are typically created by your L<POEx::ZMQ::Socket> instance and are
accessible via the C<zsock> attribute:

  my $backend = $my_sock->zsock;
  my $sock_ptr = $backend->get_raw_socket;
  # ... make some manual FFI::Raw calls ...

This is essentially a minimalist reimplementation of Dylan Cali's L<ZMQ::FFI>;
see L<ZMQ::FFI> for a ZeroMQ FFI implementation intended for use outside
L<POE>.

=head2 ATTRIBUTES

=head3 context

The L<POEx::ZMQ::FFI::Context> object this socket belongs to.

=head3 type

The ZeroMQ socket type (as a constant value, see L<POEx::ZMQ::Constants>).

Required at creation time.

=head3 soname

The C<libzmq> dynamic library we are using.

Retrieved from our L</context> object by default.

=head2 METHODS

=head3 connect

  $zsock->connect( $endpoint );

See L<zmq_connect(3)>

=head3 disconnect

  $zsock->disconnect( $endpoint );

See L<zmq_disconnect(3)>

=head3 bind

  $zsock->bind( $endpoint );

See L<zmq_bind(3)>

=head3 unbind

  $zsock->unbind( $endpoint );

See L<zmq_unbind(3)>

=head3 send

  $zsock->send( $data, $flags );

Send a single-part message.

See L<zmq_msg_send(3)>.

=head3 send_multipart

Send a multi-part message via C<ZMQ_SNDMORE>.

See L<zmq_msg_send(3)>.

=head3 recv

  my $msg = $zsock->recv($flags);

Retrieve a single message part.

This could actually be the first part of a multi-part message.
Also see L</recv_multipart>.

=head3 recv_multipart

  my $parts = $zsock->recv_multipart;

Retrieve all available parts of a message and return them as a
L<List::Objects::WithUtils::Array>.

This is preferable over a L</recv>, as it handles RCVMORE semantics.
(If this was a single-part message, there is one item in the array.)

=head3 known_type_for_opt

  my $opt_type = $zsock->known_type_for_opt( $opt_constant );

Returns the type of an option for use with L</get_sock_opt> &
L</set_sock_opt>.

=head3 get_sock_opt

  my $val = $zsock->get_sock_opt( $opt_constant );
  
  # Or manually specify value type:
  my $val = $zsock->get_sock_opt( $opt_constant, 'int64' );

Retrieves the currently-set value of a ZeroMQ option constant (see
L<POEx::ZMQ::Constants>).

See the L<zmq_getsockopt(3)> man page for details regarding option constants and
their returned values.

You should typically be able to omit the option value's type -- this class will
try to Do The Right Thing.
The internal C<< option => type >> map is exposed via L</known_type_for_opt>;
it should be reasonably complete. B<< If you have to specify your own value
type for a new or missing option, file a bug >> via
L<< github|http://www.github.com/avenj/poex-zmq >> or RT.

=head3 set_sock_opt

  $zsock->set_sock_opt( $opt_constant, $val );
  $zsock->set_sock_opt( $opt_constant, $val, $type );

Set ZeroMQ options; all L</get_sock_opt> caveats apply here, also.

See the L<zmq_setsockopt(3)> man page.

=head3 get_handle

Returns a file handle (suitable for polling by an event loop such as L<POE>) by
performing an L<fdopen(3)> on the file descriptor returned by the C<ZMQ_FD>
socket option; see L<zmq_getsockopt(3)> and the
L<< zguide|http://zguide.zeromq.org >>.

=head3 get_raw_socket

Returns the raw socket ptr, suitable for use with direct L<FFI::Raw> calls.

=head3 has_event_pollin

Checks the C<ZMQ_EVENTS> socket option to determine if the socket is readable.

=head3 has_event_pollout

Checks the C<ZMQ_EVENTS> socket option to determine if the socket is writable.

=head2 CONSUMES

L<POEx::ZMQ::FFI::Role::ErrorChecking>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Significant portions of this code are inspired by or derived from L<ZMQ::FFI>
by Dylan Cali (CPAN: CALID).

=cut

