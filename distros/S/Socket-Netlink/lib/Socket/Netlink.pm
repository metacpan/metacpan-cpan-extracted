#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package Socket::Netlink;

use strict;
use warnings;

use Carp;

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(
   pack_sockaddr_nl unpack_sockaddr_nl
   pack_nlmsghdr    unpack_nlmsghdr
   pack_nlmsgerr    unpack_nlmsgerr
   pack_nlattrs     unpack_nlattrs
);

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Socket::Netlink> - interface to Linux's C<PF_NETLINK> socket family

=head1 SYNOPSIS

 use Socket;
 use Socket::Netlink qw( :DEFAULT pack_nlmsghdr unpack_nlmsghdr );

 socket( my $sock, PF_NETLINK, SOCK_RAW, 0 ) or die "socket: $!";

 send( $sock, pack_nlmsghdr( 18, NLM_F_REQUEST|NLM_F_DUMP, 0, 0,
      "\0\0\0\0\0\0\0\0" ), 0 )
    or die "send: $!";

 recv( $sock, my $buffer, 65536, 0 ) or die "recv: $!";

 printf "Received type=%d flags=%x:\n%v02x\n",
    ( unpack_nlmsghdr( $buffer ) )[ 0, 1, 4 ];

=head1 DESCRIPTION

This module contains the low-level constants and structure handling functions
required to use Linux's C<PF_NETLINK> socket family. It is suggested to use
the high-level object interface to this instead; see L<IO::Socket::Netlink>.

=cut

=head1 CONSTANTS

The following constants are exported

=over 8

=item PF_NETLINK

The packet family (for C<socket()> calls)

=item AF_NETLINK

The address family

=back

=cut

=head1 ADDRESS FUNCTIONS

The following pair of functions operate on C<AF_NETLINK> address structures.
The meainings of the parameters are:

=over 8

=item pid

The unique endpoint number for this netlink socket. If given as 0 to the
C<bind()> syscall, the kernel will allocate an endpoint number of the
process's PID.

=item groups

A 32-bit bitmask of the multicast groups to join.

=back

=head2 pack_sockaddr_nl

   $addr = pack_sockaddr_nl( $pid, $groups )

Returns a C<sockaddr_nl> structure with the fields packed into it.

=head2 unpack_sockaddr_nl

   ( $pid, $groups ) = unpack_sockaddr_nl( $addr )

Takes a C<sockaddr_nl> structure and returns the unpacked fields from it.

=cut

=head1 STRUCTURE FUNCTIONS

The following function pairs operate on structure types used by netlink

=head2 pack_nlmsghdr

   $buffer = pack_nlmsghdr( $type, $flags, $seq, $pid, $body )

=head2 unpack_nlmsghdr

   ( $type, $flags, $seq, $pid, $body, $morebuffer ) = unpack_nlmsghdr( $buffer )

Pack or unpack a C<struct nlmsghdr> and its payload body.

Because a single netlink message can contain more than payload body, the
C<unpack_nlmsghdr> function will return the remaining buffer after unpacking
the first message, in case there are others. If there are no more, the
C<$morebuffer> list element will not be returned.

 while( defined $buffer ) {
    ( my ( $type, $flags, $seq, $pid, $body ), $buffer ) = unpack_nlmsghdr( $buffer );
    ...
 }

There is no similar functionallity for C<pack_nlmsghdr>; simply concatenate
multiple results together to send more than one message.

=head2 pack_nlmsgerr

   $buffer = pack_nlmsgerr( $error, $msg )

=head2 unpack_nlmsgerr

   ( $error, $msg ) = unpack_nlmsgerr( $buffer )

Pack or unpack a C<struct nlmsgerr>. The kernel expects or reports negative
integers in its structures; these functions take or return normal positive
error values suitable for use with C<$!>.

=head2 pack_nlattrs

   $buffer = pack_nlattrs( %attrs )

=head2 unpack_nlattrs

   %attrs = unpack_nlattrs( $buffer )

Pack or unpack a list of netlink attributes.

These functions take or return even-sized lists of C<$type, $value> pairs.
The type will be the number in the netlink attribute message, and the value
will be a plain packed string buffer. It is the caller's responsibilty to
further pack/unpack this buffer as appropriate for the specific type.

Because these functions take/return even-sized lists, they may be passed or
returned into hashes.

=cut

=head1 SEE ALSO

=over 4

=item *

C<netlink(7)> - netlink - Communication between kernel and userspace (AF_NETLINK)

=item *

L<IO::Socket::Netlink> - Object interface to C<AF_NETLINK> domain sockets

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
