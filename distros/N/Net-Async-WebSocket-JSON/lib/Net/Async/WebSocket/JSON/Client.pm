#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::JSON::Client;

use strict;
use warnings;
use mro 'c3';
use base qw( Net::Async::WebSocket::Client Net::Async::WebSocket::JSON::Protocol );

our $VERSION = '0.01';

=head1 NAME

C<Net::Async::WebSocket::JSON::Client> - connect to a WebSocket server using JSON and C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::WebSocket::JSON::Client;
 use Data::Dump;

 my $client = Net::Async::WebSocket::JSON::Client->new(
    on_json => sub {
       my ( $self, $data ) = @_;
       print Data::Dump::pp( $data );
    },
 );

 my $loop = IO::Async::Loop->new;
 $loop->add( $client );

 $client->connect(
    url => "ws://$HOST:$PORT/",
 )->then( sub {
    $client->send_json( { message => "Hello, world!\n" } );
 })->get;

 $loop->run;

=head1 DESCRIPTION

This subclass of L<Net::Async::WebSocket::Client> provides conveniences for
using JSON-encoded data sent over text frames.

It should be used identically to C<Net::Async::WebSocket::Client>, except that
it has the new C<send_json> method and C<on_json> event defined by
L<Net::Async::WebSocket::JSON::Protocol>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
