#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::JSON::Server;

use strict;
use warnings;
use base qw( Net::Async::WebSocket::Server );
Net::Async::WebSocket::Server->VERSION( '0.11' ); # respects subclasses changing handle_class

our $VERSION = '0.01';

use Net::Async::WebSocket::JSON::Protocol;

=head1 NAME

C<Net::Async::WebSocket::JSON::Server> - server WebSocket clients using JSON and C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::JSON::Server;

 my $server = Net::Async::WebSocket::JSON::Server->new(
    on_client => sub {
       my ( undef, $client ) = @_;

       $client->configure(
          on_json => sub {
             my ( $self, $frame ) = @_;
             $self->send_json( $frame );
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

This subclass of L<Net::Async::WebSocket::Server> provides conveniences for
using JSON-encoded data sent over text frames.

It should be used identically to C<Net::Async::WebSocket::Server>, except that
connected client instances will be instances of
L<Net::Async::WebSocket::JSON::Protocol>, and have the new C<send_json> method
and C<on_json> event available.

=cut

sub new
{
   my $class = shift;
   return $class->SUPER::new(
      handle_class => "Net::Async::WebSocket::JSON::Protocol",
      @_,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
