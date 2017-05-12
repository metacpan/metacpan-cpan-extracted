#
# $Id: Consts.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Consts;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
   desc => [qw(
      NP_DESC_IPPROTO_IP
      NP_DESC_IPPROTO_ICMPv4
      NP_DESC_IPPROTO_TCP
      NP_DESC_IPPROTO_UDP
      NP_DESC_IPPROTO_IPv6
      NP_DESC_IPPROTO_RAW
      NP_DESC_IP_HDRINCL
      NP_DESC_L2
      NP_DESC_L3
      NP_DESC_L4
   )],
   dump => [qw(
      NP_DUMP_LINK_NULL
      NP_DUMP_LINK_EN10MB
      NP_DUMP_LINK_RAW
      NP_DUMP_LINK_SLL
      NP_DUMP_LINK_PPP
      NP_DUMP_MODE_OFFLINE
      NP_DUMP_MODE_ONLINE
      NP_DUMP_MODE_WRITER
   )],
   layer => [qw(   
      NP_LAYER
      NP_LAYER_ETH
      NP_LAYER_NULL
      NP_LAYER_RAW
      NP_LAYER_SLL
      NP_LAYER_ARP
      NP_LAYER_IPv4
      NP_LAYER_IPv6
      NP_LAYER_VLAN
      NP_LAYER_TCP
      NP_LAYER_UDP
      NP_LAYER_ICMPv4
      NP_LAYER_7
      NP_LAYER_NONE
      NP_LAYER_UNKNOWN
      NP_LAYER_PPPoE
      NP_LAYER_PPP
      NP_LAYER_LLC     
      NP_LAYER_PPPLCP
      NP_LAYER_CDP
      NP_LAYER_STP
      NP_LAYER_OSPF
      NP_LAYER_IGMPv4
      NP_LAYER_N_2
      NP_LAYER_N_3
      NP_LAYER_N_4
      NP_LAYER_N_7
      NP_LAYER_N_UNKNOWN
   )],
   eth => [qw(
      NP_ETH_HDR_LEN
      NP_ETH_ADDR_BROADCAST
      NP_ETH_TYPE_IPv4
      NP_ETH_TYPE_IPv6
      NP_ETH_TYPE_VLAN
      NP_ETH_TYPE_ARP
      NP_ETH_TYPE_PPPoE
   )],
   null => [qw(
      NP_NULL_HDR_LEN
      NP_NULL_TYPE_IPv4
      NP_NULL_TYPE_IPv6
   )],
   sll => [qw(
      NP_SLL_HDR_LEN
      NP_SLL_PACKET_TYPE_SENT_BY_US
      NP_SLL_PACKET_TYPE_UNICAST_TO_US
      NP_SLL_ADDRESS_TYPE_512
      NP_SLL_PROTOCOL_IPv4
      NP_SLL_PROTOCOL_IPv6
      NP_SLL_PROTOCOL_ARP              
      NP_SLL_PROTOCOL_VLAN             
   )],
   vlan => [qw(
      NP_VLAN_HDR_LEN
      NP_VLAN_TYPE_ARP
      NP_VLAN_TYPE_IPv4
      NP_VLAN_TYPE_IPv6
      NP_VLAN_TYPE_VLAN
   )],
   arp => [qw(
      NP_ARP_HDR_LEN
      NP_ARP_HTYPE_ETH
      NP_ARP_PTYPE_IPv4
      NP_ARP_HSIZE_ETH
      NP_ARP_PSIZE_IPv4
      NP_ARP_OPCODE_REQUEST
      NP_ARP_OPCODE_REPLY
      NP_ARP_ADDR_BROADCAST
   )],
   ipv4 => [qw(
      NP_IPv4_HDR_LEN
      NP_IPv4_V4
      NP_IPv4_PROTOCOL_TCP
      NP_IPv4_PROTOCOL_UDP
      NP_IPv4_PROTOCOL_ICMPv4
      NP_IPv4_PROTOCOL_IPv6
      NP_IPv4_PROTOCOL_OSPF
      NP_IPv4_PROTOCOL_IGMPv4
      NP_IPv4_MORE_FRAGMENT
      NP_IPv4_DONT_FRAGMENT
      NP_IPv4_RESERVED_FRAGMENT
   )],
   ipv6 => [qw(
      NP_IPv6_HDR_LEN
      NP_IPv6_V6
      NP_IPv6_PROTOCOL_TCP
      NP_IPv6_PROTOCOL_UDP
   )],
   pppoe => [qw(
      NP_PPPoE_HDR_LEN
      NP_PPPoE_PPP_PROTOCOL_IPv4
      NP_PPPoE_PPP_PROTOCOL_PPPLCP
   )],
   ppp => [qw(
      NP_PPP_HDR_LEN
      NP_PPP_PROTOCOL_IPv4
      NP_PPP_PROTOCOL_PPPLCP
   )],
   llc => [qw(
      NP_LLC_HDR_LEN
      NP_LLC_OUI_CISCO
      NP_LLC_PID_CDP
      NP_LLC_PID_STP
      NP_LLC_DSAP_SNAP
      NP_LLC_SSAP_SNAP
   )],
   ppplcp => [qw(
      NP_PPPLCP_HDR_LEN
      NP_PPPLCP_CODE_ECHO_REQUEST
      NP_PPPLCP_CODE_ECHO_REPLY
   )],
   cdp => [qw(
      NP_CDP_HDR_LEN
      NP_CDP_TYPE_DEVICE_ID
      NP_CDP_TYPE_ADDRESSES
      NP_CDP_TYPE_PORT_ID
      NP_CDP_TYPE_CAPABILITIES
      NP_CDP_TYPE_SOFTWARE_VERSION
      NP_CDP_TYPE_PLATFORM
      NP_CDP_TYPE_UNKNOWN_0007
      NP_CDP_TYPE_UNKNOWN_0008
      NP_CDP_TYPE_VTP_MANAGEMENT_DOMAIN
      NP_CDP_TYPE_UNKNOWN_000a
      NP_CDP_TYPE_DUPLEX
      NP_CDP_TYPE_UNKNOWN_000c
      NP_CDP_TYPE_UNKNOWN_000d
      NP_CDP_TYPE_VOIP_VLAN_REPLY
      NP_CDP_TYPE_UNKNOWN_000f
      NP_CDP_TYPE_UNKNOWN_0010
      NP_CDP_TYPE_UNKNOWN_0011
      NP_CDP_TYPE_TRUST_BITMAP
      NP_CDP_TYPE_UNTRUSTED_PORT_COS
      NP_CDP_TYPE_SYSTEM_NAME
      NP_CDP_TYPE_SYSTEM_OBJECT_ID
      NP_CDP_TYPE_UNKNOWN_0016
      NP_CDP_TYPE_LOCATION
      NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID
      NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID
      NP_CDP_ADDRESS_PROTOCOL_IP
      NP_CDP_ADDRESS_ADDRESS_LENGTH_IP
   )],
   stp => [qw(
      NP_STP_HDR_LEN
      NP_STP_PROTOCOL_IDENTIFIER_STP
   )],
   ospf => [qw(
      NP_OSPF_HDR_LEN
      NP_OSPF_AUTH_TYPE_NULL
   )],
   igmpv4 => [qw(
      NP_IGMPv4_HDR_LEN
      NP_IGMPv4_v1_TYPE_QUERY
      NP_IGMPv4_v1_TYPE_REPORT
      NP_IGMPv4_v2_TYPE_QUERY
      NP_IGMPv4_v2_TYPE_QUERY_v1
      NP_IGMPv4_v2_TYPE_REPORT
      NP_IGMPv4_v2_TYPE_LEAVE_GROUP
      NP_IGMPv4_GROUP_ADDRESS_NO_HOSTS    
      NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS   
      NP_IGMPv4_GROUP_ADDRESS_ALL_ROUTERS 
   )],
   tcp => [qw(
      NP_TCP_HDR_LEN
      NP_TCP_FLAG_FIN
      NP_TCP_FLAG_SYN
      NP_TCP_FLAG_RST
      NP_TCP_FLAG_PSH
      NP_TCP_FLAG_ACK
      NP_TCP_FLAG_URG
      NP_TCP_FLAG_ECE
      NP_TCP_FLAG_CWR
   )],
   udp => [qw(
      NP_UDP_HDR_LEN
   )],
   icmpv4 => [qw(
      NP_ICMPv4_HDR_LEN
      NP_ICMPv4_CODE_ZERO
      NP_ICMPv4_TYPE_DESTINATION_UNREACHABLE
      NP_ICMPv4_CODE_NETWORK
      NP_ICMPv4_CODE_HOST
      NP_ICMPv4_CODE_PROTOCOL
      NP_ICMPv4_CODE_PORT
      NP_ICMPv4_CODE_FRAGMENTATION_NEEDED
      NP_ICMPv4_CODE_SOURCE_ROUTE_FAILED
      NP_ICMPv4_TYPE_REDIRECT
      NP_ICMPv4_CODE_FOR_NETWORK
      NP_ICMPv4_CODE_FOR_HOST
      NP_ICMPv4_CODE_FOR_TOS_AND_NETWORK
      NP_ICMPv4_CODE_FOR_TOS_AND_HOST
      NP_ICMPv4_TYPE_TIME_EXCEEDED
      NP_ICMPv4_CODE_TTL_IN_TRANSIT
      NP_ICMPv4_CODE_FRAGMENT_REASSEMBLY
      NP_ICMPv4_TYPE_ECHO_REQUEST
      NP_ICMPv4_TYPE_ECHO_REPLY
      NP_ICMPv4_TYPE_TIMESTAMP_REQUEST
      NP_ICMPv4_TYPE_TIMESTAMP_REPLY
      NP_ICMPv4_TYPE_INFORMATION_REQUEST
      NP_ICMPv4_TYPE_INFORMATION_REPLY
      NP_ICMPv4_TYPE_ADDRESS_MASK_REQUEST
      NP_ICMPv4_TYPE_ADDRESS_MASK_REPLY
   )],
);

our @EXPORT_OK = (
   @{$EXPORT_TAGS{desc}},
   @{$EXPORT_TAGS{dump}},
   @{$EXPORT_TAGS{layer}},
   @{$EXPORT_TAGS{eth}},
   @{$EXPORT_TAGS{ipv4}},
   @{$EXPORT_TAGS{ipv6}},
   @{$EXPORT_TAGS{null}},
   @{$EXPORT_TAGS{sll}},
   @{$EXPORT_TAGS{vlan}},
   @{$EXPORT_TAGS{arp}},
   @{$EXPORT_TAGS{tcp}},
   @{$EXPORT_TAGS{udp}},
   @{$EXPORT_TAGS{icmpv4}},
   @{$EXPORT_TAGS{pppoe}},
   @{$EXPORT_TAGS{ppp}},
   @{$EXPORT_TAGS{llc}},
   @{$EXPORT_TAGS{ppplcp}},
   @{$EXPORT_TAGS{cdp}},
   @{$EXPORT_TAGS{stp}},
   @{$EXPORT_TAGS{ospf}},
   @{$EXPORT_TAGS{igmpv4}},
);

use constant NP_DESC_IPPROTO_IP     => 0;
use constant NP_DESC_IPPROTO_ICMPv4 => 1;
use constant NP_DESC_IPPROTO_TCP    => 6;
use constant NP_DESC_IPPROTO_UDP    => 17;
use constant NP_DESC_IPPROTO_IPv6   => 41;
use constant NP_DESC_IPPROTO_RAW    => 255;
use constant NP_DESC_IP_HDRINCL     => 2;
use constant NP_DESC_L2             => 'DescL2';
use constant NP_DESC_L3             => 'DescL3';
use constant NP_DESC_L4             => 'DescL4';

use constant NP_DUMP_LINK_NULL   => 0;
use constant NP_DUMP_LINK_EN10MB => 1;
use constant NP_DUMP_LINK_PPP    => 9;
use constant NP_DUMP_LINK_RAW    => 12;
use constant NP_DUMP_LINK_SLL    => 113;
use constant NP_DUMP_MODE_ONLINE  => 0;
use constant NP_DUMP_MODE_OFFLINE => 1;
use constant NP_DUMP_MODE_WRITER  => 2;

use constant NP_LAYER         => 'Net::Packet::';
use constant NP_LAYER_ETH     => 'ETH';
use constant NP_LAYER_NULL    => 'NULL';
use constant NP_LAYER_RAW     => 'RAW';
use constant NP_LAYER_SLL     => 'SLL';
use constant NP_LAYER_ARP     => 'ARP';
use constant NP_LAYER_IPv4    => 'IPv4';
use constant NP_LAYER_IPv6    => 'IPv6';
use constant NP_LAYER_VLAN    => 'VLAN';
use constant NP_LAYER_TCP     => 'TCP';
use constant NP_LAYER_UDP     => 'UDP';
use constant NP_LAYER_ICMPv4  => 'ICMPv4';
use constant NP_LAYER_7       => 'Layer7';
use constant NP_LAYER_NONE    => 'NONE';
use constant NP_LAYER_UNKNOWN => 'UNKNOWN';
use constant NP_LAYER_PPPoE   => 'PPPoE';
use constant NP_LAYER_PPP     => 'PPP';
use constant NP_LAYER_LLC     => 'LLC';
use constant NP_LAYER_PPPLCP  => 'PPPLCP';
use constant NP_LAYER_CDP     => 'CDP';
use constant NP_LAYER_STP     => 'STP';
use constant NP_LAYER_OSPF    => 'OSPF';
use constant NP_LAYER_IGMPv4  => 'IGMPv4';
use constant NP_LAYER_N_2       => 'L2';
use constant NP_LAYER_N_3       => 'L3';
use constant NP_LAYER_N_4       => 'L4';
use constant NP_LAYER_N_7       => 'L7';
use constant NP_LAYER_N_UNKNOWN => 'L?';

use constant NP_ETH_HDR_LEN        => 14;
use constant NP_ETH_ADDR_BROADCAST => 'ff:ff:ff:ff:ff:ff';
use constant NP_ETH_TYPE_IPv4      => 0x0800;
use constant NP_ETH_TYPE_ARP       => 0x0806;
use constant NP_ETH_TYPE_VLAN      => 0x8100;
use constant NP_ETH_TYPE_IPv6      => 0x86dd;
use constant NP_ETH_TYPE_PPPoE     => 0x8864;

use constant NP_NULL_HDR_LEN   => 4;
use constant NP_NULL_TYPE_IPv4 => 0x02000000;
use constant NP_NULL_TYPE_IPv6 => 0x1c000000;

use constant NP_SLL_HDR_LEN                   => 16;
use constant NP_SLL_PACKET_TYPE_SENT_BY_US    => 4;
use constant NP_SLL_PACKET_TYPE_UNICAST_TO_US => 0;
use constant NP_SLL_ADDRESS_TYPE_512          => 512;
use constant NP_SLL_PROTOCOL_IPv4             => NP_ETH_TYPE_IPv4;
use constant NP_SLL_PROTOCOL_IPv6             => NP_ETH_TYPE_IPv6;
use constant NP_SLL_PROTOCOL_ARP              => NP_ETH_TYPE_ARP;
use constant NP_SLL_PROTOCOL_VLAN             => NP_ETH_TYPE_VLAN;

use constant NP_VLAN_HDR_LEN   => 4;
use constant NP_VLAN_TYPE_ARP  => NP_ETH_TYPE_ARP;
use constant NP_VLAN_TYPE_IPv4 => NP_ETH_TYPE_IPv4;
use constant NP_VLAN_TYPE_IPv6 => NP_ETH_TYPE_IPv6;
use constant NP_VLAN_TYPE_VLAN => NP_ETH_TYPE_VLAN;

use constant NP_ARP_HDR_LEN        => 28;
use constant NP_ARP_HTYPE_ETH      => 0x0001;
use constant NP_ARP_PTYPE_IPv4     => NP_ETH_TYPE_IPv4;
use constant NP_ARP_HSIZE_ETH      => 0x06;
use constant NP_ARP_PSIZE_IPv4     => 0x04;
use constant NP_ARP_OPCODE_REQUEST => 0x0001;
use constant NP_ARP_OPCODE_REPLY   => 0x0002;
use constant NP_ARP_ADDR_BROADCAST => '00:00:00:00:00:00';

use constant NP_IPv4_HDR_LEN           => 20;
use constant NP_IPv4_V4                => 4;
use constant NP_IPv4_PROTOCOL_ICMPv4   => 1;
use constant NP_IPv4_PROTOCOL_TCP      => 6;
use constant NP_IPv4_PROTOCOL_UDP      => 17;
use constant NP_IPv4_PROTOCOL_IPv6     => 41;
use constant NP_IPv4_PROTOCOL_OSPF     => 0x59;
use constant NP_IPv4_PROTOCOL_IGMPv4   => 0x02;
use constant NP_IPv4_MORE_FRAGMENT     => 1;
use constant NP_IPv4_DONT_FRAGMENT     => 2;
use constant NP_IPv4_RESERVED_FRAGMENT => 4;

use constant NP_IPv6_HDR_LEN      => 40;
use constant NP_IPv6_V6           => 6;
use constant NP_IPv6_PROTOCOL_TCP => NP_IPv4_PROTOCOL_TCP();
use constant NP_IPv6_PROTOCOL_UDP => NP_IPv4_PROTOCOL_UDP();

use constant NP_PPP_HDR_LEN         => 4;
use constant NP_PPP_PROTOCOL_IPv4   => 0x0021;
use constant NP_PPP_PROTOCOL_PPPLCP => 0xc021;

use constant NP_PPPoE_HDR_LEN => 8;
use constant NP_PPPoE_PPP_PROTOCOL_IPv4   => NP_PPP_PROTOCOL_IPv4();
use constant NP_PPPoE_PPP_PROTOCOL_PPPLCP => NP_PPP_PROTOCOL_PPPLCP();

use constant NP_LLC_HDR_LEN   => 8;
use constant NP_LLC_OUI_CISCO => 0x00000c;
use constant NP_LLC_PID_CDP   => 0x2000;
use constant NP_LLC_PID_STP   => 0x010b;
use constant NP_LLC_DSAP_SNAP => 0x2a;
use constant NP_LLC_SSAP_SNAP => NP_LLC_DSAP_SNAP();

use constant NP_PPPLCP_HDR_LEN           => 8;
use constant NP_PPPLCP_CODE_ECHO_REQUEST => 0x09;
use constant NP_PPPLCP_CODE_ECHO_REPLY   => 0x0a;

use constant NP_CDP_HDR_LEN                    => 4;
use constant NP_CDP_TYPE_DEVICE_ID             => 0x0001;
use constant NP_CDP_TYPE_ADDRESSES             => 0x0002;
use constant NP_CDP_TYPE_PORT_ID               => 0x0003;
use constant NP_CDP_TYPE_CAPABILITIES          => 0x0004;
use constant NP_CDP_TYPE_SOFTWARE_VERSION      => 0x0005;
use constant NP_CDP_TYPE_PLATFORM              => 0x0006;
use constant NP_CDP_TYPE_UNKNOWN_0007          => 0x0007;
use constant NP_CDP_TYPE_UNKNOWN_0008          => 0x0008;
use constant NP_CDP_TYPE_VTP_MANAGEMENT_DOMAIN => 0x0009;
use constant NP_CDP_TYPE_UNKNOWN_000a          => 0x000a;
use constant NP_CDP_TYPE_DUPLEX                => 0x000b;
use constant NP_CDP_TYPE_UNKNOWN_000c          => 0x000c;
use constant NP_CDP_TYPE_UNKNOWN_000d          => 0x000d;
use constant NP_CDP_TYPE_VOIP_VLAN_REPLY       => 0x000e;
use constant NP_CDP_TYPE_UNKNOWN_000f          => 0x000f;
use constant NP_CDP_TYPE_UNKNOWN_0010          => 0x0010;
use constant NP_CDP_TYPE_UNKNOWN_0011          => 0x0011;
use constant NP_CDP_TYPE_TRUST_BITMAP          => 0x0012;
use constant NP_CDP_TYPE_UNTRUSTED_PORT_COS    => 0x0013;
use constant NP_CDP_TYPE_SYSTEM_NAME           => 0x0014;
use constant NP_CDP_TYPE_SYSTEM_OBJECT_ID      => 0x0015;
use constant NP_CDP_TYPE_UNKNOWN_0016          => 0x0016;
use constant NP_CDP_TYPE_LOCATION              => 0x0017;
use constant NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID   => 0x01;
use constant NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID => 0x01;
use constant NP_CDP_ADDRESS_PROTOCOL_IP           => 0xcc;
use constant NP_CDP_ADDRESS_ADDRESS_LENGTH_IP     => 0x0004;

use constant NP_STP_HDR_LEN                 => 42;
use constant NP_STP_PROTOCOL_IDENTIFIER_STP => 0x0000;

use constant NP_OSPF_HDR_LEN        => 24;
use constant NP_OSPF_AUTH_TYPE_NULL => 0x0000;

use constant NP_IGMPv4_HDR_LEN             => 8;
use constant NP_IGMPv4_v1_TYPE_QUERY       => 1;
use constant NP_IGMPv4_v1_TYPE_REPORT      => 2;
use constant NP_IGMPv4_v2_TYPE_QUERY       => 0x11;
use constant NP_IGMPv4_v2_TYPE_QUERY_v1    => 0x12;
use constant NP_IGMPv4_v2_TYPE_REPORT      => 0x16;
use constant NP_IGMPv4_v2_TYPE_LEAVE_GROUP => 0x17;
use constant NP_IGMPv4_GROUP_ADDRESS_NO_HOSTS    => '224.0.0.0';
use constant NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS   => '224.0.0.1';
use constant NP_IGMPv4_GROUP_ADDRESS_ALL_ROUTERS => '224.0.0.2';

use constant NP_TCP_HDR_LEN  => 20;
use constant NP_TCP_FLAG_FIN => 0x01;
use constant NP_TCP_FLAG_SYN => 0x02;
use constant NP_TCP_FLAG_RST => 0x04;
use constant NP_TCP_FLAG_PSH => 0x08;
use constant NP_TCP_FLAG_ACK => 0x10;
use constant NP_TCP_FLAG_URG => 0x20;
use constant NP_TCP_FLAG_ECE => 0x40;
use constant NP_TCP_FLAG_CWR => 0x80;

use constant NP_UDP_HDR_LEN => 8;

use constant NP_ICMPv4_HDR_LEN   => 8;
use constant NP_ICMPv4_CODE_ZERO => 0;
use constant NP_ICMPv4_TYPE_DESTINATION_UNREACHABLE => 3;
use constant NP_ICMPv4_CODE_NETWORK                 => 0;
use constant NP_ICMPv4_CODE_HOST                    => 1;
use constant NP_ICMPv4_CODE_PROTOCOL                => 2;
use constant NP_ICMPv4_CODE_PORT                    => 3;
use constant NP_ICMPv4_CODE_FRAGMENTATION_NEEDED    => 4;
use constant NP_ICMPv4_CODE_SOURCE_ROUTE_FAILED     => 5;
use constant NP_ICMPv4_TYPE_TIME_EXCEEDED       => 11;
use constant NP_ICMPv4_CODE_TTL_IN_TRANSIT      => 0;
use constant NP_ICMPv4_CODE_FRAGMENT_REASSEMBLY => 1;
use constant NP_ICMPv4_TYPE_PARAMETER_PROBLEM => 12;
use constant NP_ICMPv4_CODE_POINTER           => 0;
use constant NP_ICMPv4_TYPE_SOURCE_QUENCH => 4;
use constant NP_ICMPv4_TYPE_REDIRECT            => 5;
use constant NP_ICMPv4_CODE_FOR_NETWORK         => 0;
use constant NP_ICMPv4_CODE_FOR_HOST            => 1;
use constant NP_ICMPv4_CODE_FOR_TOS_AND_NETWORK => 2;
use constant NP_ICMPv4_CODE_FOR_TOS_AND_HOST    => 3;
use constant NP_ICMPv4_TYPE_ECHO_REQUEST => 8;
use constant NP_ICMPv4_TYPE_ECHO_REPLY   => 0;
use constant NP_ICMPv4_TYPE_TIMESTAMP_REQUEST => 13;
use constant NP_ICMPv4_TYPE_TIMESTAMP_REPLY   => 14;
use constant NP_ICMPv4_TYPE_INFORMATION_REQUEST => 15;
use constant NP_ICMPv4_TYPE_INFORMATION_REPLY   => 16;
use constant NP_ICMPv4_TYPE_ADDRESS_MASK_REQUEST => 17; # RFC 950
use constant NP_ICMPv4_TYPE_ADDRESS_MASK_REPLY   => 18; # RFC 950

1;

__END__

=head1 NAME

Net::Packet::Consts - all constants used in Net::Packet framework

=head1 SYNPOSIS

   # Load IPv4 layer constants
   use Net::Packet::Consts qw(:ipv4);

   # Load Ethernet layer constants
   use Net::Packet::Consts qw(:eth);

   # Load Ethernet, IPv6 and TCP layers constants
   use Net::Packet::Consts qw(:eth :ipv6 :tcp);

=head1 DESCRIPTION

This module is the place to store all useful constants. If you want to see them all, simply `perldoc -m Net::Packet::Consts'.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
