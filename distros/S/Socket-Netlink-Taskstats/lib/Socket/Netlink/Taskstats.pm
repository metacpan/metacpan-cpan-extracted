#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Socket::Netlink::Taskstats;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';

use Socket::Netlink::Taskstats_const;

=head1 NAME

C<Socket::Netlink::Taskstats> - interface to Linux's C<Taskstats> generic
netlink socket protocol

=head1 DESCRIPTION

This module contains the low-level constants and structure handling functions
required to use the C<Taskstats> protocol of Linux's C<NETLINK_GENERIC>
netlink socket protocol. It is suggested to use the high-level object
interface to this protocol instead; see L<IO::Socket::Netlink::Taskstats>.

=cut

=head1 SEE ALSO

=over 4

=item *

L<IO::Socket::Netlink::Taskstats> - Object interface to C<Taskstats> generic
netlink protocol sockets

=item *

L<Socket::Netlink> - interface to Linux's C<PF_NETLINK> socket family

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
