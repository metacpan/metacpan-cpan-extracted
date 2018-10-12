#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Net::Async::WebSocket;

use strict;
use warnings;

our $VERSION = '0.13';

=head1 NAME

C<Net::Async::WebSocket> - use WebSockets with C<IO::Async>

=head1 DESCRIPTION

This distribution provides modules that implement the WebSocket protocol, and
allows either servers or clients to be written based on L<IO::Async>.

To implement a server, see L<Net::Async::WebSocket::Server>.

To implement a client, see L<Net::Async::WebSocket::Client>.

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
