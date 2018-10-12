#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Protocol;

use strict;
use warnings;
use base qw( IO::Async::Stream );

use Carp;

our $VERSION = '0.13';

use Protocol::WebSocket::Frame;
use Sub::Util 1.40 qw( set_subname );

my %FRAMETYPES = (
   1 => "text",
   2 => "binary",
   0x8 => "close",
   0x9 => "ping",
   0xa => "pong",
);

my @ON_TYPE_FRAMES = map { "on_${_}_frame" } values %FRAMETYPES;

=head1 NAME

C<Net::Async::WebSocket::Protocol> - send and receive WebSocket frames

=head1 DESCRIPTION

This subclass of L<IO::Async::Stream> implements an established WebSocket
connection, that has already completed its setup handshaking and is ready to
pass frames.

Objects of this type would not normally be constructed directly. For WebSocket
clients, see L<Net::Async::WebSocket::Client>, which is a subclass of this.
For WebSocket servers, see L<Net::Async::WebSocket::Server>, which constructs
objects in this class when it accepts a new connection and passes it to its
event handler.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_text_frame

   $self->on_text_frame( $text )
   $on_text_frame->( $self, $text )

Invoked when a text frame is received. It is passed a Unicode character string
formed by decoding the received UTF-8 bytes.

=head2 on_frame

   $self->on_frame( $text )
   $on_frame->( $self, $text )

A synonym for C<on_text_frame>, provided for backward compatibility.

This may be removed in a later version.

=head2 on_binary_frame, on_ping_frame, on_pong_frame, on_close_frame

   $self->on_..._frame( $bytes )
   $on_..._frame->( $self, $bytes )

Invoked when other types of frame are received. These will be passed plain
byte strings.

=head2 on_raw_frame

   $self->on_raw_frame( $frame, $bytes )
   $on_raw_frame->( $self, $frame, $bytes )

Invoked when a frame is received that does not have a specific handler defined
of one of the above types. C<$frame> will be an instance of
L<Protocol::WebSocket::Frame>.

=cut

sub _init
{
   my $self = shift;
   $self->SUPER::_init;

   $self->{framebuffer} = Protocol::WebSocket::Frame->new;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_frame => CODE

=item on_text_frame => CODE

=item on_binary_frame, on_ping_frame, on_pong_frame, on_close_frame => CODE

=item on_raw_frame => CODE

CODE references for event handlers.

=item masked => BOOL

Whether frames constructed and sent by this instance will be masked.

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_frame on_raw_frame masked ), @ON_TYPE_FRAMES ) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   my $framebuffer = $self->{framebuffer};

   $framebuffer->append( $$buffref ); # modifies $$buffref

   while( defined( my $bytes = $framebuffer->next_bytes ) ) {
      my $type = $FRAMETYPES{$framebuffer->opcode};
      $self->debug_printf( "FRAME $type" );

      my $text = $framebuffer->is_text ? Encode::decode_utf8( $bytes ) : undef;

      $self->maybe_invoke_event( "on_${type}_frame" => $text // $bytes )
         or $self->maybe_invoke_event( on_raw_frame => $framebuffer, $bytes );

      $self->maybe_invoke_event( on_frame => $text ) if $framebuffer->is_text;
   }

   return 0;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 send_frame

   $self->send_frame( @args )->get

Sends a frame to the peer containing containing the given string. The
arguments are passed to L<Protocol::WebSocket::Frame>'s C<new> method.

This method is discouraged in favour of the more specific ones listed below,
and is only provided for back-compatibility or for sending new frame types not
recognised by the specific methods.

=cut

sub send_frame
{
   my $self = shift;

   $self->write( Protocol::WebSocket::Frame->new( @_ )->to_bytes );
}

=head2 send_text_frame

   $self->send_text_frame( $text, %params )->get

Sends a text frame to the peer. The given string will be treated as a Unicode
character string, and sent as UTF-8 encoded bytes.

Any additional arguments will be passed as parameters to the underlying
L<IO::Async::Stream/write> call.

=head2 send_I<TYPE>_frame

   $self->send_binary_frame( $bytes, %params )->get

   $self->send_ping_frame( $bytes, %params )->get

   $self->send_pong_frame( $bytes, %params )->get

   $self->send_close_frame( $bytes, %params )->get

Sends a frame of the given type to the peer.

Any additional arguments will be passed as parameters to the underlying
L<IO::Async::Stream/write> call.

=cut

sub send_text_frame
{
   my $self = shift;
   my ( $text, %params ) = @_;

   # Protocol::WebSocket::Frame will UTF-8 encode this for us
   $self->write(
      Protocol::WebSocket::Frame->new(
         type   => "text",
         buffer => $text,
         masked => $self->{masked},
      )->to_bytes,
      %params
   );
}

foreach my $type ( values %FRAMETYPES ) {
   next if $type eq "text";
   my $method = "send_${type}_frame";
   my $code = sub {
      my $self = shift;
      my ( $bytes, %params ) = @_;

      $self->write(
         Protocol::WebSocket::Frame->new(
            type   => $type,
            buffer => $bytes,
            masked => $self->{masked},
         )->to_bytes,
         %params
      );
   };

   no strict 'refs';
   *$method = set_subname $method => $code;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
