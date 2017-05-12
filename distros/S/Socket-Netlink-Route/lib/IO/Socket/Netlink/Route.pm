#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package IO::Socket::Netlink::Route;

use strict;
use warnings;
use IO::Socket::Netlink 0.04;
use base qw( IO::Socket::Netlink );

our $VERSION = '0.05';

use Carp;

use Socket::Netlink::Route;

__PACKAGE__->register_protocol( NETLINK_ROUTE );

=head1 NAME

C<IO::Socket::Netlink::Route> - Object interface to C<NETLINK_ROUTE> netlink
protocol sockets

=head1 DESCRIPTION

This subclass of L<IO::Socket::Netlink> implements the C<NETLINK_ROUTE>
protocol. This protocol allows communication with the Linux kernel's
networking stack, allowing querying or modification of interfaces, addresses,
routes, and other networking properties.

This module is currently a work-in-progress, and this documentation is fairly
minimal. The reader is expected to be familiar with C<NETLINK_ROUTE>, as it
currently only gives a fairly minimal description of the Perl-level wrapping
of the kernel level concepts. For more information see the documentation in
F<rtnetlink(7)>.

=cut

sub new
{
   my $class = shift;
   $class->SUPER::new( Protocol => NETLINK_ROUTE, @_ );
}

sub message_class
{
   return "IO::Socket::Netlink::Route::_Message";
}

=head1 MESSAGE CLASSES

Each message type falls into one of the following subclasses, chosen by the
value of the C<nlmsg_type> field. Each subclass provides access to the field
headers of its message body, and netlink attributes.

=cut

package IO::Socket::Netlink::Route::_Message;

use base qw( IO::Socket::Netlink::_Message );

use Carp;

use Socket::Netlink::Route qw( :DEFAULT );

__PACKAGE__->is_subclassed_by_type;

sub   pack_nlattr_lladdr { pack "C*", map hex($_), split /:/, $_[1] }
sub unpack_nlattr_lladdr { join ":", map sprintf("%02x",$_), unpack "C*", $_[1] }

sub   pack_nlattr_dottedhex { pack "C*", map hex($_), split /\./, $_[1] }  # hex() will strip leading 0x on first byte
sub unpack_nlattr_dottedhex { "0x" . join ".", map sprintf("%02x",$_), unpack "C*", $_[1] }

if( eval { require Socket && defined &Socket::inet_ntop } ) {
   *inet_ntop = \&Socket::inet_ntop;
   *inet_pton = \&Socket::inet_pton;
}
elsif( eval { require Socket6 } ) {
   *inet_ntop = \&Socket6::inet_ntop;
   *inet_pton = \&Socket6::inet_pton;
}
else {
   require Socket;
   *inet_ntop = sub {
      my ( $family, $addr ) = @_;
      return Socket::inet_ntoa($addr) if $family == Socket::AF_INET();
      return undef;
   };
   *inet_pton = sub {
      my ( $family, $protaddr ) = @_;
      return Socket::inet_aton($protaddr) if $family == Socket::AF_INET();
      return undef;
   };
}

sub pack_nlattr_protaddr
{
   my ( $self, $protaddr ) = @_;
   eval { defined $self->family and inet_pton( $self->family, $protaddr ) }
      or $self->pack_nlattr_dottedhex( $protaddr );
}

sub unpack_nlattr_protaddr
{
   my ( $self, $addr ) = @_;
   eval { defined $self->family and inet_ntop( $self->family, $addr ) }
      or $self->unpack_nlattr_dottedhex( $addr );
}

# Debug support
my @TYPES = grep m/^RTM_/, @Socket::Netlink::Route::EXPORT;

sub nlmsg_type_string
{
   my $self = shift;
   my $type = $self->nlmsg_type;
   $type == $self->$_ and return $_ for @TYPES;
   return $self->SUPER::nlmsg_type_string;
}

package IO::Socket::Netlink::Route::_IfinfoMsg;

use base qw( IO::Socket::Netlink::Route::_Message );
use Socket::Netlink::Route qw( :DEFAULT
   pack_ifinfomsg unpack_ifinfomsg
);
use Socket qw( AF_UNSPEC );

=head2 IfinfoMsg

Relates to a network interface. Used by the following message types

=over 4

=item * RTM_NEWLINK

=item * RTM_DELLINK

=item * RTM_GETLINK

=back

=cut

__PACKAGE__->register_nlmsg_type( $_ )
   for RTM_NEWLINK, RTM_DELLINK, RTM_GETLINK;

=pod

Provides the following header field accessors

=over 4

=item * ifi_family

=item * ifi_type

=item * ifi_index

=item * ifi_flags

=item * ifi_change

=back

=cut

__PACKAGE__->is_header(
   data   => "nlmsg",
   fields => [
      [ ifi_family => "decimal" ],
      [ ifi_type   => "decimal" ],
      [ ifi_index  => "decimal" ],
      [ ifi_flags  => "hex"     ],
      [ ifi_change => "hex"     ],
      [ ifinfo     => "bytes" ],
   ],
   pack   => \&pack_ifinfomsg,
   unpack => \&unpack_ifinfomsg,
);

=pod

Provides the following netlink attributes

=over 4

=item * address => STRING

=item * broadcast => STRING

=item * ifname => STRING

=item * mtu => INT

=item * qdisc => STRING

=item * stats => HASH

=item * txqlen => INT

=item * operstate => INT

=item * linkmode => INT

=back

=cut

__PACKAGE__->has_nlattrs(
   "ifinfo",
   address   => [ IFLA_ADDRESS,   "lladdr" ],
   broadcast => [ IFLA_BROADCAST, "lladdr" ],
   ifname    => [ IFLA_IFNAME,    "asciiz" ],
   mtu       => [ IFLA_MTU,       "u32" ],
   qdisc     => [ IFLA_QDISC,     "asciiz" ],
   stats     => [ IFLA_STATS,     "stats" ],
   txqlen    => [ IFLA_TXQLEN,    "u32" ],
   map       => [ IFLA_MAP,       "raw" ],
   operstate => [ IFLA_OPERSTATE, "u8" ],
   linkmode  => [ IFLA_LINKMODE,  "u8" ],
   linkinfo  => [ IFLA_LINKINFO,  "linkinfo" ],
);

BEGIN {
   if( defined &Socket::Netlink::Route::pack_rtnl_link_stats ) {
      *pack_nlattr_stats   = sub { Socket::Netlink::Route::pack_rtnl_link_stats $_[1] };
      *unpack_nlattr_stats = sub { Socket::Netlink::Route::unpack_rtnl_link_stats $_[1] };
   }
   else {
      # Just pass raw bytes
      *pack_nlattr_stats = *unpack_nlattr_stats = sub { $_[1] };
   }
}

sub   pack_nlattr_linkinfo { die }
sub unpack_nlattr_linkinfo { "LINKINFO" }

package IO::Socket::Netlink::Route::_IfaddrMsg;

use base qw( IO::Socket::Netlink::Route::_Message );
use Carp;
use Socket::Netlink::Route qw( :DEFAULT 
   pack_ifaddrmsg unpack_ifaddrmsg
   pack_ifa_cacheinfo unpack_ifa_cacheinfo
);

=head2 IfaddrMsg

Relates to an address present on an interface. Used by the following message
types

=over 4

=item * RTM_NEWADDR

=item * RTM_DELADDR

=item * RTM_GETADDR

=back

=cut

__PACKAGE__->register_nlmsg_type( $_ )
   for RTM_NEWADDR, RTM_DELADDR, RTM_GETADDR;

=pod

Provides the following header field accessors

=over 4

=item * ifa_family

=item * ifa_prefixlen

=item * ifa_flags

=item * ifa_scope

=item * ifa_index

=back

=cut

__PACKAGE__->is_header(
   data   => "nlmsg",
   fields => [
      [ ifa_family    => "decimal" ],
      [ ifa_prefixlen => "decimal" ],
      [ ifa_flags     => "hex"     ],
      [ ifa_scope     => "decimal" ],
      [ ifa_index     => "decimal" ],
      [ ifaddr        => "bytes" ],
   ],
   pack   => \&pack_ifaddrmsg,
   unpack => \&unpack_ifaddrmsg,
);

*family = \&ifa_family;

=pod

Provides the following netlink attributes

=over 4

=item * address => STRING

=item * local => STRING

=item * label => STRING

=item * broadcast => STRING

=item * anycast => STRING

=item * cacheinfo => HASH

=back

=cut

__PACKAGE__->has_nlattrs(
   "ifaddr",
   address   => [ IFA_ADDRESS,   "protaddr" ],
   local     => [ IFA_LOCAL,     "protaddr" ],
   label     => [ IFA_LABEL,     "asciiz" ],
   broadcast => [ IFA_BROADCAST, "protaddr" ],
   anycast   => [ IFA_ANYCAST,   "protaddr" ],
   cacheinfo => [ IFA_CACHEINFO, "cacheinfo" ],
);

sub   pack_nlattr_cacheinfo {   pack_ifa_cacheinfo $_[1] }
sub unpack_nlattr_cacheinfo { unpack_ifa_cacheinfo $_[1] }

=head3 $message->prefix

Sets or returns both the C<address> netlink attribute, and the
C<ifa_prefixlen> header value, in the form

 address/ifa_prefixlen

=cut

sub prefix
{
   my $self = shift;

   if( @_ ) {
      my ( $addr, $len ) = $_[0] =~ m{^(.*)/(\d+)$} or
         croak "Expected 'ADDRESS/PREFIXLEN'";
      $self->change_nlattrs( address => $addr );
      $self->ifa_prefixlen( $len );
   }
   else {
      sprintf "%s/%d", $self->get_nlattr( 'address' ), $self->ifa_prefixlen;
   }
}

package IO::Socket::Netlink::Route::_RtMsg;

use base qw( IO::Socket::Netlink::Route::_Message );
use Carp;
use Socket::Netlink::Route qw( :DEFAULT pack_rtmsg unpack_rtmsg );

=head2 RtMsg

Relates to a routing table entry. Used by the following message types

=over 4

=item * RTM_NEWROUTE

=item * RTM_DELROUTE

=item * RTM_GETROUTE

=back

=cut

__PACKAGE__->register_nlmsg_type( $_ )
   for RTM_NEWROUTE, RTM_DELROUTE, RTM_GETROUTE;

=pod

Provides the following header field accessors

=over 4

=item * rtm_family

=item * rtm_dst_len

=item * rtm_src_len

=item * rtm_tos

=item * rtm_table

=item * rtm_protocol

=item * rtm_scope

=item * rtm_type

=item * rtm_flags

=back

=cut

__PACKAGE__->is_header(
   data   => "nlmsg",
   fields => [
      [ rtm_family   => "decimal" ],
      [ rtm_dst_len  => "decimal" ],
      [ rtm_src_len  => "decimal" ],
      [ rtm_tos      => "hex" ],
      [ rtm_table    => "decimal" ],
      [ rtm_protocol => "decimal" ],
      [ rtm_scope    => "decimal" ],
      [ rtm_type     => "decimal" ],
      [ rtm_flags    => "hex" ],
      [ rtm          => "bytes" ],
   ],
   pack   => \&pack_rtmsg,
   unpack => \&unpack_rtmsg,
);

*family = \&rtm_family;

=pod

Provides the following netlink attributes

=over 4

=item * dst => STRING

=item * src => STRING

=item * iif => INT

=item * oif => INT

=item * gateway => STRING

=item * priority => INT

=item * metrics => INT

=back

=cut

__PACKAGE__->has_nlattrs(
   "rtm",
   dst      => [ RTA_DST,      "protaddr" ],
   src      => [ RTA_SRC,      "protaddr" ],
   iif      => [ RTA_IIF,      "u32" ],
   oif      => [ RTA_OIF,      "u32" ],
   gateway  => [ RTA_GATEWAY,  "protaddr" ],
   priority => [ RTA_PRIORITY, "u32" ],
   metrics  => [ RTA_METRICS,  "u32" ],
);

=head3 $message->src

Sets or returns the C<src> netlink attribute and the C<rtm_src_len> header
value, in the form

 address/prefixlen

if the address is defined, or C<undef> if not.

=head3 $message->dst

Sets or returns the C<dst> netlink attribute and the C<rtm_dst_len> header
value, in the form given above.

=cut

sub _srcdst
{
   my $self = shift;
   my $type = shift;

   my $rtm_len = "rtm_${type}_len";

   if( @_ ) {
      if( defined $_[0] ) {
         my ( $addr, $len ) = $_[0] =~ m{^(.*)/(\d+)$} or
            croak "Expected 'ADDRESS/PREFIXLEN'";
         $self->change_nlattrs( $type => $addr );
         $self->$rtm_len( $len );
      }
      else {
         $self->change_nlattrs( $type => undef );
         $self->$rtm_len( 0 );
      }
   }
   else {
      if( defined( my $addr = $self->get_nlattr( $type ) ) ) {
         sprintf "%s/%d", $addr, $self->$rtm_len;
      }
      else {
         undef;
      }
   }
}

sub src { shift->_srcdst('src',@_) }
sub dst { shift->_srcdst('dst',@_) }

package IO::Socket::Netlink::Route::_NdMsg;

use base qw( IO::Socket::Netlink::Route::_Message );
use Socket::Netlink::Route qw( :DEFAULT
   pack_ndmsg unpack_ndmsg
   pack_nda_cacheinfo unpack_nda_cacheinfo
);

=head2 NdMsg

Relates to a neighbour discovery table entry. Used by the following message types

=over 4

=item * RTM_NEWNEIGH

=item * RTM_DELNEIGH

=item * RTM_GETNEIGH

=back

=cut

__PACKAGE__->register_nlmsg_type( $_ )
   for RTM_NEWNEIGH, RTM_DELNEIGH, RTM_GETNEIGH;

=pod

Provides the following header field accessors

=over 4

=item * ndm_family

=item * ndm_ifindex

=item * ndm_state

=item * ndm_flags

=item * ndm_type

=back

=cut

__PACKAGE__->is_header(
   data => "nlmsg",
   fields => [
      [ ndm_family  => "decimal" ],
      [ ndm_ifindex => "decimal" ],
      [ ndm_state   => "decimal" ],
      [ ndm_flags   => "hex" ],
      [ ndm_type    => "decimal" ],
      [ ndm         => "bytes" ],
   ],
   pack   => \&pack_ndmsg,
   unpack => \&unpack_ndmsg,
);

*family = \&ndm_family;

=pod

Provides the following netlink attributes

=over 4

=item * dst => STRING

=item * lladdr => STRING

=item * cacheinfo => HASH

=back

=cut

__PACKAGE__->has_nlattrs(
   "ndm",
   dst       => [ NDA_DST,       "protaddr" ],
   lladdr    => [ NDA_LLADDR,    "lladdr" ],
   cacheinfo => [ NDA_CACHEINFO, "cacheinfo" ],
);

sub   pack_nlattr_cacheinfo {   pack_nda_cacheinfo $_[1] }
sub unpack_nlattr_cacheinfo { unpack_nda_cacheinfo $_[1] }

=head1 SEE ALSO

=over 4

=item *

L<Socket::Netlink::Route> - interface to Linux's C<NETLINK_ROUTE> netlink
socket protocol

=item *

L<IO::Socket::Netlink> - Object interface to C<AF_NETLINK> domain sockets

=item *

F<rtnetlink(7)> - rtnetlink, NETLINK_ROUTE - Linux IPv4 routing socket

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
