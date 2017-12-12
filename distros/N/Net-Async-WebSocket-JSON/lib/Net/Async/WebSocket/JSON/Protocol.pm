#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::JSON::Protocol;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Protocol );
Net::Async::WebSocket::Protocol->VERSION( '0.11' );  # on_text_frame

our $VERSION = '0.01';

=head1 NAME

C<Net::Async::WebSocket::Protocol> - send and receive JSON-encoded data over WebSockets

=head1 DESCRIPTION

This subclass of L<Net::Async::WebSocket::Protocol> provides some conveniences
for sending and receiving JSON-encoded data over WebSockets. Principly, it
provides one new method, L<send_json>, for encoding Perl values into JSON and
sending them, and one new method, L<on_json>, for decoding received JSON
content into Perl values when received.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_json

   $self->on_json( $data )
   $on_json->( $self, $data )

Invoked when a text frame is received and has been decoded from JSON. It is
passed the Perl data structure resulting from the decode operation.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;
   $self->SUPER::_init( $params );

   $params->{json} //= do {
      require JSON::MaybeXS;
      JSON::MaybeXS->new;
   };
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item json => OBJECT

Optional. The JSON codec instance. This must support C<encode> and C<decode>
methods compatible with those provided by L<JSON>, L<JSON::XS> or similar.

   $text = $json->encode( $data )
   $data = $json->decode( $text )

Note in particular that the C<$text> strings are Unicode character strings,
not UTF-8 encoded byte strings, and therefore the C<utf8> option must be
disabled.

If not provided, the L<< JSON::MaybeXS->new >> constructor is used to find a
suitable implementation.

=item on_json => CODE

CODE reference for event handler.

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( json on_json )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   # TODO: forbid on_text_frame

   $self->SUPER::configure( %params );
}

sub on_text_frame
{
   my $self = shift;
   my ( $text ) = @_;

   # TODO: try/catch
   my $data = $self->{json}->decode( $text );
   $self->invoke_event( on_json => $data );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 send_json

   $self->send_json( $data )->get

Sends a text frame containing a JSON encoding of the Perl data structure
provided.

=cut

sub send_json
{
   my $self = shift;
   my ( $data ) = @_;

   $self->send_text_frame( $self->{json}->encode( $data ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
