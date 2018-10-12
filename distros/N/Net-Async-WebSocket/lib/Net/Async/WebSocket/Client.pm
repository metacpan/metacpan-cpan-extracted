#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::Client;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Protocol );
use 5.010;  # //

IO::Async::Notifier->VERSION( '0.63' ); # ->adopt_future

use Carp;

use Scalar::Util qw( blessed );

use URI;

BEGIN {
   eval {
      require URI::wss;
   } or do {
      # In case URI doesn't know that ws:// and wss:// URIs use host/port
      require URI::_server;

      @URI::ws::ISA = qw( URI::_server );
      *URI::ws::default_port = sub { 80 };

      @URI::wss::ISA = qw( URI::_server );
      *URI::wss::default_port = sub { 443 };
      *URI::wss::secure = sub { 1 };
   };

   # We also need to support ->resource_name, which the CPAN module does not
   # understand as of 2017-01-01
   no warnings 'once';
   *URI::wss::resource_name = sub {
      shift->path_query
   } unless URI::wss->can( "resource_name" );
}

our $VERSION = '0.13';

use Protocol::WebSocket::Handshake::Client;

=head1 NAME

C<Net::Async::WebSocket::Client> - connect to a WebSocket server using
C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::Client;

 my $client = Net::Async::WebSocket::Client->new(
    on_text_frame => sub {
       my ( $self, $frame ) = @_;
       print $frame;
    },
 );

 my $loop = IO::Async::Loop->new;
 $loop->add( $client );

 $client->connect(
    url => "ws://$HOST:$PORT/",
 )->then( sub {
    $client->send_text_frame( "Hello, world!\n" );
 })->get;

 $loop->run;

=head1 DESCRIPTION

This subclass of L<Net::Async::WebSocket::Protocol> connects to a WebSocket
server to establish a WebSocket connection for passing frames.

=cut

sub new
{
   my $class = shift;
   return $class->SUPER::new(
      masked => 1,
      @_,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub _do_handshake
{
   my $self = shift;
   my %params = @_;

   my $hs = Protocol::WebSocket::Handshake::Client->new(
      url => $params{url},
      req => $params{req},
   );

   $self->debug_printf( "HANDSHAKE start" );
   $self->write( $hs->to_string );

   my $f = $self->loop->new_future;
   $self->SUPER::configure( on_read => sub {
      my ( undef, $buffref, $closed ) = @_;

      $hs->parse( $$buffref ); # modifies $$buffref

      if( $hs->is_done ) {
         $self->debug_printf( "HANDSHAKE done" );
         $self->SUPER::configure( on_read => undef );

         $f->done( $self );
      }

      return 0;
   } );

   return $f;
}

=head2 connect

   $self->connect( %params )->get

Connect to a WebSocket server. Takes the following named parameters:

=over 8

=item url => STRING

URL to provide to WebSocket handshake. This is also used to infer the host and
service name (port number) if not otherwise supplied.

=item req => Protocol::WebSocket::Request

Optional. If provided, gives the L<Protocol::WebSocket::Request> instance used
for performing the handshake.

=back

The returned L<Future> returns the client instance itself, making it useful
in chaining constructors.

=head2 connect (void)

   $self->connect( %params )

When not returning a C<Future>, the following additional parameters provide
continuations:

=over 8

=item on_connected => CODE

CODE reference to invoke when the handshaking is complete.

=back

=cut

sub connect
{
   my $self = shift;
   my %params = @_;

   if( my $url = $params{url} ) {
      $url = URI->new( $url ) unless blessed $url and $url->isa( "URI" );

      $params{host}    //= $url->host;
      $params{service} //= $url->port;

      if( $url->secure ) {
         require IO::Async::SSL;
         push @{ $params{extensions} }, qw( SSL );
         $params{SSL_hostname} //= $url->host;
      }
   }

   my $on_connected = delete $params{on_connected};

   my $f = $self->SUPER::connect( %params )->then( sub {
      my ( $self ) = @_;

      $self->_do_handshake( %params );
   });

   $f->on_done( $on_connected ) if $on_connected;

   return $f if defined wantarray;

   $self->adopt_future( $f );
}

=head2 connect_handle

   $client->connect_handle( $handle, %params )->get

Sets the read and write handles to the IO reference given, then performs the
initial handshake using the parameters given. These are as for C<connect>.

=cut

sub connect_handle
{
   my $self = shift;
   my ( $handle, %params ) = @_;

   $self->set_handle( $handle );

   $self->_do_handshake( %params );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
