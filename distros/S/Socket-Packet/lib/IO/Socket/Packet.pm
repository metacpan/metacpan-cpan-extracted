#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package IO::Socket::Packet;

use strict;
use warnings;
use base qw( IO::Socket );

our $VERSION = '0.10';

use Carp;

use POSIX qw( EAGAIN );
use Socket qw( AF_INET SOCK_STREAM SOCK_RAW );

use Socket::Packet qw( 
   AF_PACKET ETH_P_ALL
   pack_sockaddr_ll unpack_sockaddr_ll
   pack_packet_mreq
   unpack_tpacket_stats
   siocgstamp siocgstampns
   siocgifindex siocgifname
   recv_len

   SOL_PACKET

   PACKET_ADD_MEMBERSHIP
   PACKET_DROP_MEMBERSHIP
   PACKET_STATISTICS

   PACKET_MR_MULTICAST
   PACKET_MR_PROMISC
   PACKET_MR_ALLMULTI
);

__PACKAGE__->register_domain( AF_PACKET );

=head1 NAME

C<IO::Socket::Packet> - Object interface to C<AF_PACKET> domain sockets

=head1 SYNOPSIS

 use IO::Socket::Packet;
 use Socket::Packet qw( unpack_sockaddr_ll );

 my $sock = IO::Socket::Packet->new( IfIndex => 0 );

 while( my ( $protocol, $ifindex, $hatype, $pkttype, $addr ) = 
    $sock->recv_unpack( my $packet, 8192, 0 ) ) {

    ...
 }

=head1 DESCRIPTION

This class provides an object interface to C<PF_PACKET> sockets on Linux. It
is built upon L<IO::Socket> and inherits all the methods defined by this base
class.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $sock = IO::Socket::Packet->new( %args )

Creates a new C<IO::Socket::Packet> object. If any arguments are passed it
will be configured to contain a newly created socket handle, and be C<bind>ed
as required by the arguments. The recognised arguments are:

=over 8

=item Type => INT

The socktype to use; should be either C<SOCK_RAW> or C<SOCK_DGRAM>. It not
supplied a default of C<SOCK_RAW> will be used.

=item Protocol => INT

Ethernet protocol number to bind to. To capture all protocols, use the
C<ETH_P_ALL> constant (or omit this key, which implies that as a default).

=item IfIndex => INT

If supplied, binds the socket to the specified interface index. To bind to all
interfaces, use 0 (or omit this key, which implies that as a default).

=item IfName => STRING

If supplied, binds the socket to the interface with the specified name.

=back

=cut

sub configure
{
   my $self = shift;
   my ( $arg ) = @_;

   my $type = $arg->{Type} || SOCK_RAW;

   $self->socket( AF_PACKET, $type, 0 ) or return undef;

   # bind() arguments
   my ( $protocol, $ifindex );

   $protocol = $arg->{Protocol} if exists $arg->{Protocol};
   $ifindex  = $arg->{IfIndex}  if exists $arg->{IfIndex};

   if( !defined $ifindex and exists $arg->{IfName} ) {
      $ifindex = siocgifindex( $self, $arg->{IfName} );
      defined $ifindex or return undef;
   }

   $self->bind( pack_sockaddr_ll( 
         defined $protocol ? $protocol : ETH_P_ALL,
         $ifindex || 0,
         0, 0, '' ) ) or return undef;

   return $self;
}

=head1 METHODS

=cut

=head2 ( $addr, $len ) = $sock->recv_len( $buffer, $maxlen, $flags )

Similar to Perl's C<recv> builtin, except it returns the packet length as an
explict return value. This may be useful if C<$flags> contains the
C<MSG_TRUNC> flag, obtaining the true length of the packet on the wire, even
if this is longer than the data written in the buffer.

=cut

# don't actually need to implement it; the imported symbol works fine

=head2 ( $protocol, $ifindex, $hatype, $pkttype, $addr, $len ) = $sock->recv_unpack( $buffer, $size, $flags )

This method is a combination of C<recv_len> and C<unpack_sockaddr_ll>. If it
successfully receives a packet, it unpacks the address and returns the fields
from it, and the length of the received packet. If it fails, it returns an
empty list.

If the ring-buffer has been set using C<setup_rx_ring>, it will automatically
be used by this method.

=cut

sub recv_unpack
{
   my $self = shift;

   if( defined ${*$self}{packet_rx_ring} ) {
      defined $self->wait_ring_frame( my $buffer, \my %info ) or return;

      # Copy to caller
      $_[0] = $buffer;

      $self->done_ring_frame;

      ${*$self}{packet_ts_sec}  = $info{tp_sec};
      ${*$self}{packet_ts_nsec} = $info{tp_nsec};

      return ( $info{sll_protocol},
               $info{sll_ifindex},
               $info{sll_hatype},
               $info{sll_pkttype},
               $info{sll_addr},
               $info{tp_len} );
   }

   my ( $addr, $len ) = $self->recv_len( @_ ) or return;
   return unpack_sockaddr_ll( $addr ), $len;
}

=head2 $protocol = $sock->protocol

Returns the ethertype protocol the socket is bound to.

=cut

sub protocol
{
   my $self = shift;
   return (unpack_sockaddr_ll($self->sockname))[0];
}

=head2 $ifindex = $sock->ifindex

Returns the interface index the socket is bound to.

=cut

sub ifindex
{
   my $self = shift;
   return (unpack_sockaddr_ll($self->sockname))[1];
}

=head2 $ifname = $sock->ifname

Returns the name of the interface the socket is bound to.

=cut

sub ifname
{
   my $self = shift;
   return siocgifname( $self, $self->ifindex );
}

=head2 $hatype = $sock->hatype

Returns the hardware address type for the interface the socket is bound to.

=cut

sub hatype
{
   my $self = shift;
   return (unpack_sockaddr_ll($self->sockname))[2];
}

=head2 $time = $sock->timestamp

=head2 ( $sec, $usec ) = $sock->timestamp

Returns the timestamp of the last received packet on the socket (as obtained
by the C<SIOCGSTAMP> C<ioctl>). In scalar context, returns a single
floating-point value in UNIX epoch seconds. In list context, returns the
number of seconds, and the number of microseconds.

If the ring-buffer has been set using C<setup_rx_ring>, this method returns
the timestamp of the last packet received from it.

=cut

sub timestamp
{
   my $self = shift;

   if( defined ${*$self}{packet_ts_sec} ) {
      my $sec  = delete ${*$self}{packet_ts_sec};
      my $nsec = delete ${*$self}{packet_ts_nsec};

      return wantarray ? ( $sec, int($nsec/1000) ) : $sec + $nsec/1_000_000_000;
   }

   return siocgstamp( $self );
}

=head2 $time = $sock->timestamp_nano

=head2 ( $sec, $nsec ) = $sock->timestamp_nano

Returns the nanosecond-precise timestamp of the last received packet on the
socket (as obtained by the C<SIOCGSTAMPNS> C<ioctl>). In scalar context,
returns a single floating-point value in UNIX epoch seconds. In list context,
returns the number of seconds, and the number of nanoseconds.

If the ring-buffer has been set using C<setup_rx_ring>, this method returns
the timestamp of the last packet received from it.

=cut

sub timestamp_nano
{
   my $self = shift;

   if( defined ${*$self}{packet_ts_sec} ) {
      my $sec  = delete ${*$self}{packet_ts_sec};
      my $nsec = delete ${*$self}{packet_ts_nsec};

      return wantarray ? ( $sec, $nsec ) : $sec + $nsec/1_000_000_000;
   }

   return siocgstampns( $self );
}

=head1 INTERFACE NAME UTILITIES

The following methods are utilities around C<siocgifindex> and C<siocgifname>.
If called on an object, they use the encapsulated socket. If called as class
methods, they will create a temporary socket to pass to the kernel, then close
it again.

=cut

=head2 $ifindex = $sock->ifname2index( $ifname )

=head2 $ifindex = IO::Socket::Packet->ifname2index( $ifname )

Returns the name for the given interface index, or C<undef> if it doesn't
exist.

=cut

sub ifname2index
{
   my $self = shift;
   my ( $ifname ) = @_;

   my $sock;
   if( ref $self ) {
      $sock = $self;
   }
   else {
      socket( $sock, AF_INET, SOCK_STREAM, 0 ) or
         croak "Cannot socket(AF_INET) - $!";
   }

   return siocgifindex( $sock, $ifname );
}

=head2 $ifname = $sock->ifindex2name( $ifindex )

=head2 $ifname = IO::Socket::Packet->ifindex2name( $ifindex )

Returns the index for the given interface name, or C<undef> if it doesn't
exist.

=cut

sub ifindex2name
{
   my $self = shift;
   my ( $ifindex ) = @_;

   my $sock;
   if( ref $self ) {
      $sock = $self;
   }
   else {
      socket( $sock, AF_INET, SOCK_STREAM, 0 ) or
         croak "Cannot socket(AF_INET) - $!";
   }

   return siocgifname( $sock, $ifindex );
}

sub _make_sockopt_int
{
   my ( $optname ) = @_;

   # IO::Socket automatically handles the pack/unpack in this case

   sub {
      my $sock = shift;

      if( @_ ) {
         $sock->setsockopt( SOL_PACKET, $optname, $_[0] );
      }
      else {
         return $sock->getsockopt( SOL_PACKET, $optname );
      }
   };
}

=head1 SOCKET OPTION ACCESSORS

=cut

=head2 $sock->add_multicast( $addr, $ifindex )

Adds the given multicast address on the given interface index. If the
interface index is not supplied, C<< $sock->ifindex >> is used.

=cut

sub add_multicast
{
   my $self = shift;
   my ( $addr, $ifindex ) = @_;
   defined $ifindex or $ifindex = $self->ifindex;

   $self->setsockopt( SOL_PACKET, PACKET_ADD_MEMBERSHIP,
      pack_packet_mreq( $ifindex, PACKET_MR_MULTICAST, $addr )
   );
}

=head2 $sock->drop_multicast( $addr, $ifindex )

Drops the given multicast address on the given interface index. If the
interface index is not supplied, C<< $sock->ifindex >> is used.

=cut

sub drop_multicast
{
   my $self = shift;
   my ( $addr, $ifindex ) = @_;
   defined $ifindex or $ifindex = $self->ifindex;

   $self->setsockopt( SOL_PACKET, PACKET_DROP_MEMBERSHIP,
      pack_packet_mreq( $ifindex, PACKET_MR_MULTICAST, $addr )
   );
}

=head2 $sock->promisc( $promisc, $ifindex )

Sets or clears the PACKET_MR_PROMISC flag on the given interface. If the
interface index is not supplied, C<< $sock->ifindex >> is used.

=cut

sub promisc
{
   my $self = shift;
   my ( $value, $ifindex ) = @_;
   defined $ifindex or $ifindex = $self->ifindex;

   $self->setsockopt( SOL_PACKET, $value ? PACKET_ADD_MEMBERSHIP : PACKET_DROP_MEMBERSHIP,
      pack_packet_mreq( $ifindex, PACKET_MR_PROMISC, "" )
   );
}

=head2 $sock->allmulti( $allmulti, $ifindex )

Sets or clears the PACKET_MR_ALLMULTI flag on the given interface. If the
interface index is not supplied, C<< $sock->ifindex >> is used.

=cut

sub allmulti
{
   my $self = shift;
   my ( $value, $ifindex ) = @_;
   defined $ifindex or $ifindex = $self->ifindex;

   $self->setsockopt( SOL_PACKET, $value ? PACKET_ADD_MEMBERSHIP : PACKET_DROP_MEMBERSHIP,
      pack_packet_mreq( $ifindex, PACKET_MR_ALLMULTI, "" )
   );
}

=head2 $stats = $sock->statistics

Returns the socket statistics. This will be a two-field hash containing
counts C<packets>, the total number of packets the socket has seen, and
C<drops>, the number of packets that could not stored because the buffer was
full.

=cut

sub statistics
{
   my $self = shift;

   my $stats = $self->getsockopt( SOL_PACKET, PACKET_STATISTICS )
      or return;

   my %stats;
   @stats{qw( packets drops)} = unpack_tpacket_stats( $stats );

   return \%stats;
}

=head2 $val = $sock->origdev

=head2 $sock->origdev( $val )

Return or set the value of the C<PACKET_ORIGDEV> socket option.

=cut

if( defined &Socket::Packet::PACKET_ORIGDEV ) {
   *origdev = _make_sockopt_int( Socket::Packet::PACKET_ORIGDEV() );
}

=head1 RING-BUFFER METHODS

These methods operate on the high-performance memory-mapped capture buffer.

An example of how to use these methods for packet capture is included in the
module distribution; see F<examples/capture-rxring.pl> for more detail.

=cut

=head2 $size = $sock->setup_rx_ring( $frame_size, $frame_nr, $block_size )

Sets up the ring-buffer on the object. This method is identical to the
C<Socket::Packet> function C<setup_rx_ring>, except that the ring-buffer
variable is stored transparently within the C<$sock> object; the caller does
not need to manage it.

Once this buffer is enabled, the C<recv_len>, C<timestamp> and
C<timestamp_nano> methods will automatically use it instead of the regular
C<recv()>+C<ioctl()> interface.

=cut

sub setup_rx_ring
{
   my $self = shift;
   my ( $frame_size, $frame_nr, $block_size ) = @_;

   my $ret = Socket::Packet::setup_rx_ring( $self, $frame_size, $frame_nr, $block_size );
   ${*$self}{packet_rx_ring} = 1 if defined $ret;

   return $ret;
}

=head2 $len = $sock->get_ring_frame( $buffer, \%info )

Receives the next packet from the ring-buffer. If there are no packets waiting
it will return undef. This method aliases the C<$buffer> variable to the
C<mmap()>ed packet buffer.

For detail on the C<%info> hash, see L<Socket::Packet>'s C<get_ring_frame()>
function.

Once the caller has finished with the C<$buffer> data, the C<done_ring_frame>
method should be called to hand the frame buffer back to the kernel.

=cut

sub get_ring_frame
{
   my $self = shift;

   return Socket::Packet::get_ring_frame( $self, $_[0], $_[1] );
}

=head2 $len = $sock->wait_ring_frame( $buffer, \%info )

If a packet is ready, this method sets C<$buffer> and C<%info> as per the
C<get_ring_frame> method. If there are no packets waiting and the socket is
in blocking mode, it will C<select()> on the socket until a packet is
available. If the socket is in non-blocking mode, it will return false with
C<$!> set to C<EAGAIN>.

For detail on the C<%info> hash, see L<Socket::Packet>'s C<get_ring_frame()>
function.

Once the caller has finished with the C<$buffer> data, the C<done_ring_frame>
method should be called to hand the frame buffer back to the kernel.

=cut

sub wait_ring_frame
{
   my $self = shift;

   my $len;
   while( !defined( $len = $self->get_ring_frame( $_[0], $_[1] ) ) ) {
      $! = EAGAIN, return if not $self->blocking;

      my $rvec = '';
      vec( $rvec, fileno $self, 1 ) = 1;
      select( $rvec, undef, undef, undef ) or return;
   }

   return $len;
}

=head2 $sock->done_ring_frame

Hands the current ring-buffer frame back to the kernel.

=cut

sub done_ring_frame
{
   my $self = shift;

   Socket::Packet::done_ring_frame( $self );
}

=head1 SEE ALSO

=over 4

=item *

L<Socket::Packet> - interface to Linux's C<PF_PACKET> socket family

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
