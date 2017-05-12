#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Net::Async::Tangence;

use strict;
use warnings;

our $VERSION = '0.14';

=head1 NAME

C<Net::Async::Tangence> - use C<Tangence> with C<IO::Async>

=head1 DESCRIPTION

This distribution provides concrete implementations of the L<Tangence> base
classes, allowing either servers or clients to be written based on
L<IO::Async>.

To implement a server, see L<Net::Async::Tangence::Server>.

To implement a client, see L<Net::Async::Tangence::Client>.

This module itself does not provide any code, and exists only to provide the
module C<$VERSION> and top-level documentation.

=cut

=head1 SEE ALSO

=over 8

=item *

L<Tangence> - attribute-oriented server/client object remoting framework

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
