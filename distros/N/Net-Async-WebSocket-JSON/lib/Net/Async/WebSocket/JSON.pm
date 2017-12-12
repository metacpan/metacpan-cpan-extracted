#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket::JSON;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

C<Net::Async::WebSocket::JSON> - use JSON-encoded data over WebSockets with C<IO::Async>

=head1 DESCRIPTION

This distribution provides subclasses of modules from L<Net::Async::WebSocket>
that add convenient wrappers for encoding or decoding JSON data in text frames
over websockets.

To implement a server, use L<Net::Async::WebSocket::JSON::Server> as if it was
L<Net::Async::WebSocket::Server>.

To implement a client, use L<Net::Async::WebSocket::JSON::Client> as if it was
L<Net::Async::WebSocket::Client>.

In either cases, connected client instances will be instances of
L<Net::Async::WebSocket::JSON::Protocol>, and have the new C<send_json> method
and C<on_json> event available.

This module itself does not provide any code, and exists only to provide the
module C<$VERSION> and top-level documentation.

=cut

=head1 SEE ALSO

=over 8

=item *

L<Protocol::WebSocket> - WebSocket protocol

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
