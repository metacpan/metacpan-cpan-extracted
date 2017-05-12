#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Protocol::Gearman;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp;
use Scalar::Util qw( reftype );

=head1 NAME

C<Protocol::Gearman> - abstract base class for both client and worker

=head1 DESCRIPTION

This base class is used by both L<Protocol::Gearman::Client> and
L<Protocol::Gearman::Worker>. It shouldn't be used directly by end-user
implementations. It is documented here largely to explain what methods an end
implementation needs to provide in order to create a Gearman client or worker.

For implementing a Gearman client or worker, see the modules

=over 2

=item *

L<Protocol::Gearman::Client>

=item *

L<Protocol::Gearman::Worker>

=back

For a simple synchronous Gearman client or worker module for use during
testing or similar, see

=over 2

=item *

L<Net::Gearman::Client>

=item *

L<Net::Gearman::Worker>

=back

=cut

=head1 REQUIRED METHODS

The implementation should provide the following methods:

=cut

=head2 $f = $gearman->new_future

Return a new L<Future> subclass instance, for request methods to use. This
instance should support awaiting appropriately.

=cut

sub new_future
{
   my $self = shift;
   reftype $self eq "HASH" and ref( my $code = $self->{gearman_method_new_future} ) eq "CODE" or
      croak "Can't locate object method \"new_future\" via package ".ref($self).", or it is not a prototypical object";

   $code->( $self, @_ );
}

=head2 $gearman->send( $bytes )

Send the given bytes to the server.

=cut

sub send
{
   my $self = shift;
   reftype $self eq "HASH" and ref( my $code = $self->{gearman_method_send} ) eq "CODE" or
      croak "Can't locate object method \"send\" via package ".ref($self).", or it is not a prototypical object";

   $code->( $self, @_ );
}

=head2 $h = $gearman->gearman_state

Return a HASH reference for the Gearman-related code to store its state on.
If not implemented, a default method will be provided which uses C<$gearman>
itself, for the common case of HASH-based objects. All the Gearman-related
state will be stored in keys whose names are prefixed by C<gearman_>, to avoid
clashes with other object state.

=cut

sub gearman_state { shift }

# These are used internally but not exported
use constant {
   MAGIC_REQUEST  => "\0REQ",
   MAGIC_RESPONSE => "\0RES",
};

my %CONSTANTS = (
   TYPE_CAN_DO             => 1,
   TYPE_CANT_DO            => 2,
   TYPE_RESET_ABILITIES    => 3,
   TYPE_PRE_SLEEP          => 4,
   TYPE_NOOP               => 6,
   TYPE_SUBMIT_JOB         => 7,
   TYPE_JOB_CREATED        => 8,
   TYPE_GRAB_JOB           => 9,
   TYPE_NO_JOB             => 10,
   TYPE_JOB_ASSIGN         => 11,
   TYPE_WORK_STATUS        => 12,
   TYPE_WORK_COMPLETE      => 13,
   TYPE_WORK_FAIL          => 14,
   TYPE_GET_STATUS         => 15,
   TYPE_ECHO_REQ           => 16,
   TYPE_ECHO_RES           => 17,
   TYPE_SUBMIT_JOB_BG      => 18,
   TYPE_ERROR              => 19,
   TYPE_STATUS_RES         => 20,
   TYPE_SUBMIT_JOB_HIGH    => 21,
   TYPE_SET_CLIENT_ID      => 22,
   TYPE_CAN_DO_TIMEOUT     => 23,
   TYPE_ALL_YOURS          => 24,
   TYPE_WORK_EXCEPTION     => 25,
   TYPE_OPTION_REQ         => 26,
   TYPE_OPTION_RES         => 27,
   TYPE_WORK_DATA          => 28,
   TYPE_WORK_WARNING       => 29,
   TYPE_GRAB_JOB_UNIQ      => 30,
   TYPE_JOB_ASSIGN_UNIQ    => 31,
   TYPE_SUBMIT_JOB_HIGH_BG => 32,
   TYPE_SUBMIT_JOB_LOW     => 33,
   TYPE_SUBMIT_JOB_LOW_BG  => 34,
);

require constant;
constant->import( $_, $CONSTANTS{$_} ) for keys %CONSTANTS;

=head1 INTERNAL METHODS

These methods are provided for the client and worker subclasses to use; it is
unlikely these will be of interest to other users but they are documented here
for completeness.

=cut

# All Gearman packet bodies follow a standard format, of a fixed number of
# string arguments (given by the packet type), separated by a single NUL byte.
# All but the final argument may not contain embedded NULs.

my %TYPENAMES = map { m/^TYPE_(.*)$/ ? ( $CONSTANTS{$_} => $1 ) : () } keys %CONSTANTS;

my %ARGS_FOR_TYPE = (
   # In order from doc/PROTOCOL
   # common
   ECHO_REQ           => 1,
   ECHO_RES           => 1,
   ERROR              => 2,
   # client->server
   SUBMIT_JOB         => 3,
   SUBMIT_JOB_BG      => 3,
   SUBMIT_JOB_HIGH    => 3,
   SUBMIT_JOB_HIGH_BG => 3,
   SUBMIT_JOB_LOW     => 3,
   SUBMIT_JOB_LOW_BG  => 3,
   GET_STATUS         => 1,
   OPTION_REQ         => 1,
   # server->client
   JOB_CREATED        => 1,
   STATUS_RES         => 5,
   OPTION_RES         => 1,
   # worker->server
   CAN_DO             => 1,
   CAN_DO_TIMEOUT     => 2,
   CANT_DO            => 1,
   RESET_ABILITIES    => 0,
   PRE_SLEEP          => 0,
   GRAB_JOB           => 0,
   GRAB_JOB_UNIQ      => 0,
   WORK_DATA          => 2,
   WORK_WARNING       => 2,
   WORK_STATUS        => 3,
   WORK_COMPLETE      => 2,
   WORK_FAIL          => 1,
   WORK_EXCEPTION     => 2,
   SET_CLIENT_ID      => 1,
   ALL_YOURS          => 0,
   # server->worker
   NOOP               => 0,
   NO_JOB             => 0,
   JOB_ASSIGN         => 3,
   JOB_ASSIGN_UNIQ    => 4,
);

=head2 ( $type, $body ) = $gearman->pack_packet( $name, @args )

Given a name of a packet type (specified as a string as the name of one of the
C<TYPE_*> constants, without the leading C<TYPE_> prefix; case insignificant)
returns the type value and the arguments for the packet packed into a body
string. This is intended for passing directly into C<build_packet> or
C<send_packet>:

 send_packet $fh, pack_packet( SUBMIT_JOB => $func, $id, $arg );

=cut

sub pack_packet
{
   shift;
   my ( $typename, @args ) = @_;

   my $typefn = __PACKAGE__->can( "TYPE_\U$typename" ) or
      croak "Unrecognised packet type '$typename'";

   my $n_args = $ARGS_FOR_TYPE{uc $typename};

   @args == $n_args or croak "Expected '\U$typename\E' to take $n_args args";
   $args[$_] =~ m/\0/ and croak "Non-final argument [$_] of '\U$typename\E' cannot contain a \\0"
      for 0 .. $n_args-2;

   my $type = $typefn->();
   return ( $type, join "\0", @args );
}

=head2 ( $name, @args ) = $gearman->unpack_packet( $type, $body )

Given a type code and body string, returns the type name and unpacked
arguments from the body. This function is the reverse of C<pack_packet> and is
intended to be used on the result of C<parse_packet> or C<recv_packet>:

The returned C<$name> will always be a fully-captialised type name, as one of
the C<TYPE_*> constants without the leading C<TYPE_> prefix.

This is intended for a C<given/when> control block, or dynamic method
dispatch:

 my ( $name, @args ) = unpack_packet( recv_packet $fh );

 $self->${\"handle_$name"}( @args )

=cut

sub unpack_packet
{
   shift;
   my ( $type, $body ) = @_;

   my $typename = $TYPENAMES{$type} or
      croak "Unrecognised packet type $type";

   my $n_args = $ARGS_FOR_TYPE{$typename};

   return ( $typename ) if $n_args == 0;
   return ( $typename, split m/\0/, $body, $n_args );
}

=head2 ( $name, @args ) = $gearman->parse_packet_from_string( $bytes )

Attempts to parse a complete message packet from the given byte string. If it
succeeds, it returns the type name and arguments. If it fails it returns an
empty list.

If successful, it will remove the bytes of the packet form the C<$bytes>
scalar, which must therefore be mutable.

If the byte string begins with some bytes that are not recognised as the
Gearman packet magic for a response, the function will immediately throw an
exception before modifying the string.

=cut

sub parse_packet_from_string
{
   my $self = shift;

   return unless length $_[0] >= 4;
   croak "Expected to find 'RES' magic in packet" unless
      unpack( "a4", $_[0] ) eq MAGIC_RESPONSE;

   return unless length $_[0] >= 12;

   my $bodylen = unpack( "x8 N", $_[0] );
   return unless length $_[0] >= 12 + $bodylen;

   # Now committed to extracting it
   my ( $type ) = unpack( "x4 N x4", substr $_[0], 0, 12, "" );
   my $body = substr $_[0], 0, $bodylen, "";

   return $self->unpack_packet( $type, $body );
}

=head2 ( $name, @args ) = $gearman->recv_packet_from_fh( $fh )

Attempts to read a complete packet from the given filehandle, blocking until
it is available. The results are undefined if this function is called on a
non-blocking filehandle.

If an IO error happens, an exception is thrown. If the first four bytes read
are not recognised as the Gearman packet magic for a response, the function
will immediately throw an exception. If either of these conditions happen, the
filehandle should be considered no longer valid and should be closed.

=cut

sub recv_packet_from_fh
{
   my $self = shift;
   my ( $fh ) = @_;

   $fh->read( my $magic, 4 ) or croak "Cannot read header - $!";
   croak "Expected to find 'RES' magic in packet" unless
      $magic eq MAGIC_RESPONSE;

   $fh->read( my $header, 8 ) or croak "Cannot read header - $!";
   my ( $type, $bodylen ) = unpack( "N N", $header );

   my $body = "";
   $fh->read( $body, $bodylen ) or croak "Cannot read body - $!" if $bodylen;

   return $self->unpack_packet( $type, $body );
}

=head2 $bytes = $gearman->build_packet_to_string( $name, @args )

Returns a byte string containing a complete packet with the given fields.

=cut

sub build_packet_to_string
{
   my $self = shift;
   my ( $type, $body ) = $self->pack_packet( @_ );

   return pack "a4 N N a*", MAGIC_REQUEST, $type, length $body, $body;
}

=head2 $gearman->send_packet_to_fh( $fh, $name, @args )

Sends a complete packet to the given filehandle. If an IO error happens, an
exception is thrown.

=cut

sub send_packet_to_fh
{
   my $self = shift;
   my $fh = shift;
   $fh->print( $self->build_packet_to_string( @_ ) ) or croak "Cannot send packet - $!";
}

=head2 $gearman->send_packet( $typename, @args )

Packs a packet from a list of arguments then sends it; a combination of
C<pack_packet> and C<build_packet>. Uses the implementation's C<send> method.

=cut

sub send_packet
{
   my $self = shift;
   $self->send( $self->build_packet_to_string( @_ ) );
}

=head2 $gearman->on_recv( $buffer )

The implementation should call this method when more bytes of data have been
received. It parses and unpacks packets from the buffer, then dispatches to
the appropriately named C<on_*> method. A combination of C<parse_packet> and
C<unpack_packet>.

The C<$buffer> scalar may be modified; if it still contains bytes left over
after the call these should be preserved by the implementation for the next
time it is called.

=cut

sub on_recv
{
   my $self = shift;

   while( my ( $type, @args ) = $self->parse_packet_from_string( $_[0] ) ) {
      $self->${\"on_$type"}( @args );
   }
}

*on_read = \&on_recv;

=head2 $gearman->on_ERROR( $name, $message )

Default handler for the C<TYPE_ERROR> packet. This method should be overriden
by subclasses to change the behaviour.

=cut

sub on_ERROR
{
   my $self = shift;
   my ( $name, $message ) = @_;

   die "Received Gearman error '$name' (\"$message\")\n";
}

=head2 $gearman->echo_request( $payload ) ==> ( $payload )

Sends an C<ECHO_REQ> packet to the Gearman server, and returns a future that
will eventually yield the payload when the server responds.

=cut

sub echo_request
{
   my $self = shift;
   my ( $payload ) = @_;

   my $state = $self->gearman_state;

   push @{ $state->{gearman_echos} }, my $f = $self->new_future;

   $self->send_packet( ECHO_REQ => $payload );

   return $f;
}

sub on_ECHO_RES
{
   my $self = shift;
   my ( $payload ) = @_;

   my $state = $self->gearman_state;

   ( shift @{ $state->{gearman_echos} } )->done( $payload );
}

=head1 PROTOTYPICAL OBJECTS

An alternative option to subclassing to provide the missing methods, is to use
C<Protocol::Gearman> (or rather, one of the client or worker subclasses) as a
prototypical object, passing in CODE references for the missing methods to a
special constructor that creates a concrete object.

This may be more convenient to use in smaller one-shot cases (like unit tests
or small scripts) instead of creating a subclass.

 my $socket = ...;

 my $client = Protocol::Gearman::Client->new_prototype(
    send       => sub { $socket->print( $_[1] ); },
    new_future => sub { My::Future::Subclass->new },
 );

=head2 $gearman = Protocol::Gearman->new_prototype( %methods )

Returns a new prototypical object constructed using the given methods. The
named arguments must give values for the C<send> and C<new_future> methods.

=cut

sub new_prototype
{
   my $class = shift;
   my %methods = @_;

   my $self = bless {}, $class;

   foreach (qw( send new_future )) {
      defined $methods{$_} and ref $methods{$_} eq "CODE" or
         croak "Expected to receive a CODE reference for '$_'";

      $self->{"gearman_method_$_"} = $methods{$_};
   }

   return $self;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
