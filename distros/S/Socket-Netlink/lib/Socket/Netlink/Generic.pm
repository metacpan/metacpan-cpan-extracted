#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2016 -- leonerd@leonerd.org.uk

package Socket::Netlink::Generic;

use strict;
use warnings;

our $VERSION = '0.05';

use Exporter 'import';

use Socket::Netlink::Generic_const;

=head1 NAME

C<Socket::Netlink::Generic> - interface to Linux's C<NETLINK_GENERIC> netlink
socket protocol

=head1 SYNOPSIS

 use Socket;
 use Socket::Netlink qw( :DEFAULT
    pack_nlmsghdr unpack_nlmsghdr pack_nlattrs unpack_nlattrs );
 use Socket::Netlink::Generic qw( :DEFAULT pack_genlmsghdr unpack_genlmsghdr );

 socket( my $sock, PF_NETLINK, SOCK_RAW, NETLINK_GENERIC ) or die "socket: $!";

 send( $sock, pack_nlmsghdr( NETLINK_GENERIC, NLM_F_REQUEST, 0, 0,
                 pack_genlmsghdr( CTRL_CMD_GETFAMILY, 0,
                    pack_nlattrs( CTRL_ATTR_FAMILY_NAME, "TASKSTATS\0" )
                 ),
              ),
    0 ) or die "send: $!";

 recv( $sock, my $buffer, 65536, 0 ) or die "recv: $!";

 my %attrs = unpack_nlattrs( 
               (unpack_genlmsghdr( (unpack_nlmsghdr $buffer )[4] ) )[2]
             );

 printf "TASKSTATS family ID is %d\n",
    unpack( "S", $attrs{CTRL_ATTR_FAMILY_ID()} );

=head1 DESCRIPTION

This module contains the low-level constants and structure handling functions
required to use the C<NETLINK_GENERIC> protocol of Linux's C<PF_NETLINK>
socket family. It is suggested to use the high-level object interface to this
instead; see L<IO::Socket::Netlink::Generic>.

=cut

=head1 CONSTANTS

The following sets of constants are exported:

The netlink protocol constant:

 NETLINK_GENERIC

Control commands:

 CTRL_CMD_NEWFAMILY    CTRL_CMD_DELFAMILY    CTRL_CMD_GETFAMILY
 CTRL_CMD_NEWOPS       CTRL_CMD_DELOPS       CTRL_CMD_GETOPS
 CTRL_CMD_NEWMCAST_GRP CTRL_CMD_DELMCAST_GRP CTRL_CMD_GETMCAST_GRP

Attribute IDs:

 CTRL_ATTR_FAMILY_ID    CTRL_ATTR_FAMILY_NAME CTRL_ATTR_VERSION
 CTRL_ATTR_HDRSIZE      CTRL_ATTR_MAXATTR     CTRL_ATTR_OPS
 CTRL_ATTR_MCAST_GROUPS

Nested attribute IDs:

 CTRL_ATTR_OP_ID CTRL_ATTR_OP_FLAGS
 CTRL_ATTR_MCAST_GRP_NAME CTRL_ATTR_MCAST_GRP_ID

Note that if the kernel headers are particularly old, not all of these
constants may be available. If they are unavailable at compile time, no
constant functions will be generated.

=cut

=head1 STRUCTURE FUNCTIONS

=head2 pack_genlmsghdr

   $buffer = pack_genlmsghdr( $cmd, $version, $body )

=head2 unpack_genlmsghdr

   ( $cmd, $version, $body ) = unpack_genlmsghdr( $buffer )

Pack or unpack a C<struct genlmsghdr> and its payload body.

=cut

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink> - interface to Linux's C<PF_NETLINK> socket family

=item *

L<IO::Socket::Netlink::Generic> - Object interface to C<NETLINK_GENERIC>
netlink protocol sockets

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
