#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package Socket::Netlink::Route;

use strict;
use warnings;

our $VERSION = '0.05';

use Exporter 'import';

use Socket::Netlink::Route_const;

=head1 NAME

C<Socket::Netlink::Route> - interface to Linux's C<NETLINK_ROUTE> netlink
socket protocol

=head1 DESCRIPTION

This module contains the low-level constants and structure handling functions
required to use the C<NETLINK_ROUTE> protocol of Linux's C<PF_NETLINK> socket
family. It is suggested to use the high-level object interface to this
protocol instead; see L<IO::Socket::Netlink::Route>.

For more information, see the Linux kernel documentation about the
C<NETLINK_ROUTE> protocol family in F<rtnetlink(7)>

 $ man 7 rtnetlink

=cut

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink> - interface to Linux's C<PF_NETLINK> socket family

=item *

L<IO::Socket::Netlink::Route> - Object interface to C<NETLINK_ROUTE> netlink
protocol sockets

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
