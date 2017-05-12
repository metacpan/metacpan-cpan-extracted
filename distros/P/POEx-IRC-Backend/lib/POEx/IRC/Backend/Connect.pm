package POEx::IRC::Backend::Connect;
$POEx::IRC::Backend::Connect::VERSION = '0.030003';
use strictures 2;
use Types::Standard -all;


use Moo; use MooX::TypeTiny;
with 'POEx::IRC::Backend::Role::Socket',
     'POEx::IRC::Backend::Role::CheckAvail';


has alarm_id => (
  ## Idle alarm ID.
  lazy      => 1,
  is        => 'rw',
  predicate => 'has_alarm_id',
  default   => sub { 0 },
);

has compressed => (
  ## zlib filter added.
  lazy    => 1,
  is      => 'rwp',
  isa     => Bool,
  writer  => 'set_compressed',
  default => sub { !!0 },
);

has idle => (
  ## Idle delay.
  lazy    => 1,
  is      => 'ro',
  isa     => StrictNum,
  default => sub { 180 },
);

has is_client => (
  lazy    => 1,
  is      => 'rw',
  isa     => Bool,
  default => sub { !!0 },
);

has is_peer => (
  lazy    => 1,
  is      => 'rw',
  isa     => Bool,
  default => sub { !!0 },
);

has is_disconnecting => (
  ## Bool or string (disconnect message)
  is      => 'rw',
  isa     => (Bool | Str),
  default => sub { !!0 },
);

has is_pending_compress => (
  ## Wheel needs zlib filter after a socket flush.
  is      => 'rw',
  isa     => Bool,
  default => sub { !!0 },
);

has peeraddr => (
  required => 1,
  isa      => Str,
  is       => 'ro',
  writer   => 'set_peeraddr',
);

has peerport => (
  required => 1,
  is       => 'ro',
  writer   => 'set_peerport',
);

has ping_pending => (
  lazy    => 1,
  is      => 'rw',
  default => sub { 0 },
);

has seen => (
  ## TS of last activity on this Connect.
  lazy    => 1,
  is      => 'rw',
  default => sub { 0 },
);

has sockaddr => (
  required => 1,
  isa      => Str,
  is       => 'ro',
  writer   => 'set_sockaddr',
);

has sockport => (
  required => 1,
  is       => 'ro',
  writer   => 'set_sockport',
);


sub ssl_object {
  my ($self) = @_;
  return undef 
    unless $self->ssl
    and $self->has_ssl_support
    and $self->has_wheel;

  POE::Component::SSLify::SSLify_GetSSL( $self->wheel->get_output_handle )
}

sub ssl_cipher {
  my ($self) = @_;
  return ''
    unless $self->ssl
    and $self->has_ssl_support
    and $self->has_wheel;

  POE::Component::SSLify::SSLify_GetCipher( $self->wheel->get_output_handle )
}

sub get_socket {
  my ($self) = @_;
  return undef unless $self->has_wheel;
  $self->ssl ?
    POE::Component::SSLify::SSLify_GetSocket( $self->wheel->get_output_handle )
    : $self->wheel->get_output_handle
}


1;

=pod

=for Pod::Coverage has_\w+ set_\w+

=head1 NAME

POEx::IRC::Backend::Connect - A connected IRC socket

=head1 DESCRIPTION

These objects contain details regarding connected socket
L<POE::Wheel::ReadWrite> wheels managed by L<POEx::IRC::Backend>.

These objects are typically created by a successfully connected
L<POEx::IRC::Backend::Connector> or an accepted connection to a
L<POEx::IRC::Backend::Listener>.

=head2 CONSUMES

This class consumes the following roles:

L<POEx::IRC::Backend::Role::HasWheel>

L<POEx::IRC::Backend::Role::Socket>

=head2 ATTRIBUTES

=head3 alarm_id

Connected socket wheels normally have a POE alarm ID attached for an idle 
timer.

Predicate: C<has_alarm_id>

B<rw> attribute.

=head3 compressed

Boolean true if the Zlib filter has been added.

See also: L<POEx::IRC::Backend/set_compressed_link>

=head3 set_compressed

Change the boolean value of the L</compressed> attrib.

=head3 idle

Idle time used for connection check alarms.

See also: L</ping_pending>, L<POEx::IRC::Backend/ircsock_connection_idle>

=head3 is_disconnecting

Boolean false if the Connect is not in a disconnecting state; if it is 
true, it is the disconnect message (for use by higher-level layers):

  $obj->is_disconnecting("Client quit")

B<rw> attribute.

See also: L<POEx::IRC::Backend/disconnect>

=head3 is_client

Boolean true if the connection wheel has been marked as a client; for use by
higher-level layers to help tag Connects.

B<rw> attribute.

=head3 is_peer

Boolean true if the connection wheel has been marked as a peer; for use by
higher-level layers to help tag Connects.

B<rw> attribute.

=head3 is_pending_compress

Primarily for internal use; boolean true if the Wheel needs a Zlib filter on
next buffer flush.

B<rw> attribute.

=head3 ping_pending

The C<ping_pending> attribute can be used to manage standard IRC
PING/PONG heartbeating; a server can call C<< $conn->ping_pending(1) >> upon
dispatching a PING to a client (because of an C<ircsock_connection_idle>
event, for example) and C<< $conn->ping_pending(0) >> when a
response is received.

If C<< $conn->ping_pending >> is true on the next C<ircsock_connection_idle>,
the client can be considered to have timed out and your server-side C<Backend>
can issue a disconnect; this emulates standard IRCD behavior.

B<rw> attribute.

See also: L<POEx::IRC::Backend/ircsock_connection_idle>

=head3 peeraddr

The remote peer address.

Writer: C<set_peeraddr>

=head3 peerport

The remote peer port.

Writer: C<set_peerport>

=head3 seen

Timestamp of last socket activity; updated by L<POEx::IRC::Backend> when
traffic is seen from this Connect.

B<rw> attribute.

=head3 sockaddr

Our socket address.

Writer: C<set_sockaddr>

=head3 sockport

Our socket port.

Writer: C<set_sockport>

=head2 METHODS

=head3 get_socket

Returns the actual underlying socket handle, or undef if one is not open.

If this is a SSLified socket, the real handle is retrieved via
L<POE::Component::SSLify/SSLify_GetSocket>.

=head3 ssl_cipher

Returns the cipher in use by calling
L<POE::Component::SSLify/SSLify_GetCipher>, or the empty string if this is not
an SSLified connection.

=head3 ssl_object

Returns the underlying L<Net::SSLeay> object via
L<POE::Component::SSLify/SSLify_GetSSL>, or undef if this is not an SSLified
connection.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
