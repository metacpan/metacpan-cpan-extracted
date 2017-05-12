#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package Socket::Packet;

use strict;
use warnings;

use Carp;

our $VERSION = '0.10';

use Exporter 'import';
our @EXPORT_OK = qw(
   pack_sockaddr_ll unpack_sockaddr_ll
   pack_packet_mreq unpack_packet_mreq
   unpack_tpacket_stats
   siocgstamp
   siocgstampns
   siocgifindex
   siocgifname
   recv_len

   setup_rx_ring
   get_ring_frame_status
   get_ring_frame
   done_ring_frame
);

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Socket::Packet> - interface to Linux's C<PF_PACKET> socket family

=head1 SYNOPSIS

 use Socket qw( SOCK_RAW );
 use Socket::Packet qw(
    PF_PACKET
    ETH_P_ALL
    pack_sockaddr_ll unpack_sockaddr_ll
 );
 
 socket( my $sock, PF_PACKET, SOCK_RAW, 0 )
    or die "Cannot socket() - $!\n";
 
 bind( $sock, pack_sockaddr_ll( ETH_P_ALL, 0, 0, 0, "" ) )
    or die "Cannot bind() - $!\n";
 
 while( my $addr = recv( $sock, my $packet, 8192, 0 ) ) {
    my ( $proto, $ifindex, $hatype, $pkttype, $addr )
       = unpack_sockaddr_ll( $addr );

    ...
 }

=head1 DESCRIPTION

To quote C<packet(7)>:

 Packet sockets are used to receive or send raw packets at the device driver
 (OSI Layer 2) level. They allow the user to implement protocol modules in
 user space on top of the physical layer.

Sockets in the C<PF_PACKET> family get direct link-level access to the
underlying hardware (i.e. Ethernet or similar). They are usually used to
implement packet capturing, or sending of specially-constructed packets
or to implement protocols the underlying kernel does not recognise.

The use of C<PF_PACKET> sockets is usually restricted to privileged users
only.

This module also provides various other support functions which wrap
C<ioctl()>s or socket options. This includes support for C<PACKET_RX_RING>,
the high-performance zero-copy packet receive buffering, if the underlying
platform supports it.

=cut

=head1 CONSTANTS

The following constants are exported

=over 8

=item PF_PACKET

The packet family (for C<socket()> calls)

=item AF_PACKET

The address family

=item PACKET_HOST

This packet is inbound unicast for this host.

=item PACKET_BROADCAST

This packet is inbound broadcast.

=item PACKET_MULTICAST

This packet is inbound multicast.

=item PACKET_OTHERHOST

This packet is inbound unicast for another host.

=item PACKET_OUTGOING

This packet is outbound.

=item ETH_P_ALL

Pseudo-protocol number to capture all protocols.

=item SOL_PACKET

Socket option level for C<getsockopt> and C<setsockopt>.

=back

=cut

=head1 SOCKET OPTIONS

The following constants define socket options

=over 8

=item PACKET_STATISTICS (get; struct tpacket_stats)

Packet received and drop counters.

=item PACKET_ORIGDEV (get or set; int)

Received packets will indicate the originally-received device, rather than the
apparent one. This mainly relates to Ethernet bonding or VLANs.

This socket option is optional, and may not be provided on all platforms.

=item PACKET_ADD_MEMBERSHIP (set; struct packet_mreq)

=item PACKET_DROP_MEMBERSHIP (set; struct packet_mreq)

Membership of multicast or broadcast groups, or set promiscuous mode.

The C<packet_mreq> C<type> field should be one of the following:

=over 4

=item PACKET_MR_MULTICAST

A multicast group

=item PACKET_MR_PROMISC

Set or clear the promiscuous flag; the address is ignored

=item PACKET_MR_ALLMULTI

Set or clear the allmulti flag; the address is ignored

=back

=back

=cut

=head1 FUNCTIONS

The following pair of functions operate on C<AF_PACKET> address structures.
The meanings of the parameters are:

=over 8

=item protocol

An ethertype protocol number. When using an address with C<bind()>, the
constant C<ETH_P_ALL> can be used instead, to capture any protocol. The
C<pack_sockaddr_ll()> and C<unpack_sockaddr_ll()> functions byte-swap this
value to or from network endian order.

=item ifindex

The index number of the interface on which the packet was sent or received.
When using an address with C<bind()>, the value C<0> can be used instead, to
watch all interfaces.

=item hatype

The hardware ARP type of hardware address.

=item pkttype

The type of the packet; indicates if it was sent or received. Will be one of
the C<PACKET_*> values.

=item addr

The underlying hardware address, in the type given by C<hatype>.

=back

=head2 $a = pack_sockaddr_ll( $protocol, $ifindex, $hatype, $pkttype, $addr )

Returns a C<sockaddr_ll> structure with the fields packed into it.

=head2 ( $protocol, $ifindex, $hatype, $pkttype, $addr ) = unpack_sockaddr_ll( $a )

Takes a C<sockaddr_ll> structure and returns the unpacked fields from it.

=head2 $mreq = pack_packet_mreq( $ifindex, $type, $addr )

Returns a C<packet_mreq> structure with the fields packed into it.

=head2 ( $ifindex, $type, $addr ) = unpack_packet_mreq( $mreq )

Takes a C<packet_mreq> structure and returns the unpacked fields from it.

=head2 ( $packets, $drops ) = unpack_tpacket_stats( $stats )

Takes a C<tpacket_stats> structure from the C<PACKET_STATISTICS> sockopt and
returns the unpacked fields from it.

=head2 $time = siocgstamp( $sock )

=head2 ( $sec, $usec ) = siocgstamp( $sock )

Returns the timestamp of the last received packet on the socket (as obtained
by the C<SIOCGSTAMP> C<ioctl>). In scalar context, returns a single
floating-point value in UNIX epoch seconds. In list context, returns the
number of seconds, and the number of microseconds.

=head2 $time = siocgstampns( $sock )

=head2 ( $sec, $nsec ) = siocgstampns( $sock )

Returns the nanosecond-precise timestamp of the last received packet on the
socket (as obtained by the C<SIOCGSTAMPNS> C<ioctl>). In scalar context,
returns a single floating-point value in UNIX epoch seconds. In list context,
returns the number of seconds, and the number of nanoseconds.

=head2 $ifindex = siocgifindex( $sock, $ifname )

Returns the C<ifindex> of the interface with the given name if one exists, or
C<undef> if not. C<$sock> does not need to be a C<PF_PACKET> socket, any
socket handle will do.

=head2 $ifname = siocgifname( $sock, $ifindex )

Returns the C<ifname> of the interface at the given index if one exists, or
C<undef> if not. C<$sock> does not need to be a C<PF_PACKET> socket, any
socket handle will do.

=head2 ( $addr, $len ) = recv_len( $sock, $buffer, $maxlen, $flags )

Similar to Perl's C<recv> builtin, except it returns the packet length as an
explict return value. This may be useful if C<$flags> contains the
C<MSG_TRUNC> flag, obtaining the true length of the packet on the wire, even
if this is longer than the data written in the buffer.

=cut

=head1 RING-BUFFER FUNCTIONS

The following functions operate on the high-performance memory-mapped buffer
feature of C<PF_PACKET>, allowing efficient packet-capture applications to
share a buffer with the kernel directly, avoiding the need for per-packet
system calls to C<recv()> (and possibly C<ioctl()> to obtain the timestamp).

The ring-buffer is optional, and may not be implemented on all platforms. If
it is not implemented, then all the following functions will die with an error
message.

=cut

=head2 $size = setup_rx_ring( $sock, $frame_size, $frame_nr, $block_size )

Sets up the ring-buffer on the socket. The buffer will store C<$frame_nr>
frames of up to C<$frame_size> bytes each (including metadata headers), and
will be split in the kernel in blocks of C<$block_size> bytes.  C<$block_size>
should be a power of 2, at minimum, 4KiB.

If successful, the overall size of the buffer in bytes is returned. If not,
C<undef> is returned, and C<$!> will hold the error value.

=head2 $status = get_ring_frame_status( $sock )

Returns the frame status of the next frame in the ring.

The following constants are defined for the status:

=over 8

=item TP_STATUS_KERNEL

This frame belongs to the kernel and userland should not touch it.

=item TP_STATUS_USER

This frame belongs to userland and the kernel will not modify it.

=item TP_STATUS_LOSING

Bitwise-or'ed with the status if packet loss has occurred since the previous
frame.

=back

=head2 $len = get_ring_frame( $sock, $buffer, \%info )

If the next frame is ready for userland, fills in keys of the C<%info> hash
with its metadata, sets C<$buffer> to its contents, and return the length of
the data. The C<$buffer> variable has its string backing buffer aliased,
rather than the buffer copied into, for performance. The caller should not
modify the variable, nor attempt to access it after the socket has been
closed.

If the frame is not yet ready, this function returns undef.

The following fields are returned:

=over 8

=item tp_status

The status of the frame; see C<get_ring_frame_status()>

=item tp_len

The length of the packet on the wire, in bytes

=item tp_snaplen

The length of the packet captured and stored in the buffer, in bytes. This may
be shorter than C<tp_len> if, for example, a filter is set on the socket that
truncated the packet.

=item tp_sec

=item tp_nsec

The seconds and nanoseconds fields of the timestamp. If the underlying
platform does not support C<TPACKET_V2>, then this field will only have a
resolution of microseconds; i.e. it will be a whole multiple of 1000.

=item tp_vlan_tci

VLAN information about the packet, if the underlying platform supports
C<TPACKET_V2>. If this is not supported, the key will not be present in the
hash

=item sll_protocol

=item sll_ifindex

=item sll_hatype

=item sll_pkttype

=item sll_addr

Fields from the C<struct sockaddr_ll>; see above for more detail

=back

=head2 clear_ring_frame( $sock )

Clears the status of current frame to hand it back to the kernel and moves on
to the next.

=cut

=head1 SEE ALSO

=over 4

=item *

L<IO::Socket::Packet> - Object interface to C<AF_PACKET> domain sockets

=item *

L<Linux::SocketFilter> - interface to Linux's socket packet filtering

=item *

C<packet(7)> - packet, AF_PACKET - packet interface on device level

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
