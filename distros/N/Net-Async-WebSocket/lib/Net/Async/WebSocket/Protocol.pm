#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Protocol;

use strict;
use warnings;
use base qw( IO::Async::Stream );

use Carp;

our $VERSION = '0.10';

use Protocol::WebSocket::Frame;

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

A CODE reference for when a frame is received

 $on_frame->( $self, $frame )

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_frame )) {
      $self->{$_} = delete $params{$_} if exists $params{on_frame};
   }

   $self->SUPER::configure( %params );
}

my %FRAMETYPES = (
   1 => "text",
   2 => "binary",
   0x8 => "close",
   0x9 => "ping",
   0xa => "pong",
);

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   my $framebuffer = $self->{framebuffer};

   $framebuffer->append( $$buffref ); # modifies $$buffref

   while( defined( my $frame = $framebuffer->next ) ) {
      $self->debug_printf( "FRAME " . $FRAMETYPES{$framebuffer->opcode} );

      $self->invoke_event( on_frame => $frame );
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

=cut

sub send_frame
{
   my $self = shift;

   $self->write( Protocol::WebSocket::Frame->new( @_ )->to_bytes );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
