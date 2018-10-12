#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2014 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Server;

use strict;
use warnings;
use base qw( IO::Async::Listener );

use Carp;

our $VERSION = '0.13';

use Net::Async::WebSocket::Protocol;

use Protocol::WebSocket::Handshake::Server;

=head1 NAME

C<Net::Async::WebSocket::Server> - serve WebSocket clients using C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::Server;

 my $server = Net::Async::WebSocket::Server->new(
    on_client => sub {
       my ( undef, $client ) = @_;

       $client->configure(
          on_text_frame => sub {
             my ( $self, $frame ) = @_;
             $self->send_text_frame( $frame );
          },
       );
    }
 );

 my $loop = IO::Async::Loop->new;
 $loop->add( $server );

 $server->listen(
    service => 3000,
 )->get;

 $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Listener> accepts WebSocket connections. When a
new connection arrives it will perform an initial handshake, and then pass the
connection on to the continuation callback or method.

=cut

=head1 EVENTS

The following events are invoked, either using subclass methods or CODE
references in parameters:

=head2 on_client

   $self->on_client( $client )
   $on_client->( $self, $client )

Invoked when a new client connects and completes its initial handshake.

It will be passed a new instance of a L<Net::Async::WebSocket::Protocol>
object, wrapping the client connection.

=head2 on_handshake

Invoked when a handshake has been requested.

   $self->on_handshake( $client, $hs, $continue )
   $on_handshake->( $self, $client, $hs, $continue )

Calling C<$continue> with a true value will complete the handshake, false will
drop the connection.

This is useful for filtering on origin, for example:

   on_handshake => sub {
      my ( $self, $client, $hs, $continue ) = @_;

      $continue->( $hs->req->origin eq "http://localhost" );
   }

=cut

sub new
{
   my $class = shift;
   return $class->SUPER::new(
      handle_class => "Net::Async::WebSocket::Protocol",
      @_,
   );
}

sub on_accept
{
   my $self = shift;
   my ( $client ) = @_;

   my $hs = Protocol::WebSocket::Handshake::Server->new;

   $client->configure(
      on_read => sub {
         my ( $client, $buffref, $closed ) = @_;

         $hs->parse( $$buffref ); # modifies $$buffref

         if( $hs->is_done ) {
            my $on_handshake = $self->can_event( "on_handshake" ) ||
               sub { $_[3]->( 1 ) };

            $on_handshake->( $self, $client, $hs, sub {
               my ( $ok ) = @_;

               unless( $ok ) {
                  $self->remove_child( $client );
                  return;
               }

               $client->configure( on_read => undef );
               $client->write( $hs->to_string );

               $client->debug_printf( "HANDSHAKE done" );
               $self->invoke_event( on_client => $client );
            } );
         }

         return 0;
      },
   );

   $self->add_child( $client );
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_client => CODE

=item on_handshake => CODE

CODE references for event handlers.

=back

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_client on_handshake )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub listen
{
   my $self = shift;
   my %params = @_;

   $self->SUPER::listen(
      socktype => 'stream',
      %params,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
