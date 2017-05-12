#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::H2PM 0.04;
use ExtUtils::CChecker;

my $cc = ExtUtils::CChecker->new;

my $HAVE_IF_LINK = $cc->try_compile_run(
   source => <<EOF );
#include <sys/socket.h>
#include <linux/if_link.h>
int main(int argc, char *argv[]) {
  struct rtnl_link_stats stats;
  return 0;
}
EOF

module "Socket::Netlink::Route";

include "sys/socket.h";
include "linux/netlink.h";
include "linux/rtnetlink.h";

if( $HAVE_IF_LINK ) {
   include "linux/if_link.h"; # for struct rtnl_link_stats
}

use_export;

constant "NETLINK_ROUTE";

constant "RTM_NEWLINK";
constant "RTM_DELLINK";
constant "RTM_GETLINK";
constant "RTM_SETLINK";

structure "struct ifinfomsg",
   with_tail => 1,
   members => [
      ifi_family => member_numeric,
      ifi_type   => member_numeric,
      ifi_index  => member_numeric,
      ifi_flags  => member_numeric,
      ifi_change => member_numeric,
   ];

constant "IFLA_$_" for qw( UNSPEC ADDRESS BROADCAST IFNAME MTU LINK QDISC
   STATS COST PRIORITY MASTER WIRELESS PROTINFO TXQLEN MAP WEIGHT OPERSTATE
   LINKMODE LINKINFO NET_NS_PID );

# Later addition
constant "IFLA_$_", ifdef => "IFLA_$_" for qw( IFALIAS );

if( $HAVE_IF_LINK ) {
   structure "struct rtnl_link_stats",
      arg_style => "hashref",
      members => [
         map { $_ => member_numeric } qw(
            rx_packets tx_packets rx_bytes tx_bytes rx_errors tx_errors
            rx_dropped tx_dropped multicast collisions
            rx_length_errors rx_over_errors rx_crc_errors rx_frame_errors
            rx_fifo_errors rx_missed_errors
            tx_aborted_errors tx_carrier_errors tx_fifo_errors
            tx_heartbeat_errors tx_window_errors
            rx_compressed tx_compressed
         ),
      ];
}

constant "RTM_NEWADDR";
constant "RTM_DELADDR";
constant "RTM_GETADDR";

structure "struct ifaddrmsg",
   with_tail => 1,
   members => [
      ifa_family    => member_numeric,
      ifa_prefixlen => member_numeric,
      ifa_flags     => member_numeric,
      ifa_scope     => member_numeric,
      ifa_index     => member_numeric,
   ];

constant "IFA_$_" for qw( UNSPEC ADDRESS LOCAL LABEL BROADCAST ANYCAST CACHEINFO );

structure "struct ifa_cacheinfo",
   arg_style => "hashref",
   members => [
      map { $_ => member_numeric } qw( ifa_prefered ifa_valid cstamp tstamp ),
   ];

constant "RTM_NEWROUTE";
constant "RTM_DELROUTE";
constant "RTM_GETROUTE";

structure "struct rtmsg",
   with_tail => 1,
   members => [
      rtm_family   => member_numeric,
      rtm_dst_len  => member_numeric,
      rtm_src_len  => member_numeric,
      rtm_tos      => member_numeric,
      rtm_table    => member_numeric,
      rtm_protocol => member_numeric,
      rtm_scope    => member_numeric,
      rtm_type     => member_numeric,
      rtm_flags    => member_numeric,
   ];

constant "RTN_$_" for qw( UNSPEC UNICAST LOCAL BROADCAST ANYCAST MULTICAST
   BLACKHOLE UNREACHABLE PROHIBIT THROW NAT XRESOLVE );

constant "RTPROT_$_" for qw( UNSPEC REDIRECT KERNEL BOOT STATIC );

constant "RT_SCOPE_$_" for qw( UNIVERSE SITE LINK HOST NOWHERE );

constant "RTM_F_$_" for qw( NOTIFY CLONED EQUALIZE );

constant "RT_TABLE_$_" for qw( UNSPEC DEFAULT MAIN LOCAL );

constant "RTA_$_" for qw( UNSPEC DST SRC IIF OIF GATEWAY PRIORITY PREFSRC
   METRICS MULTIPATH PROTOINFO FLOW CACHEINFO );

constant "RTM_NEWNEIGH";
constant "RTM_DELNEIGH";
constant "RTM_GETNEIGH";

structure "struct ndmsg",
   with_tail => 1,
   members => [
      ndm_family  => member_numeric,
      ndm_ifindex => member_numeric,
      ndm_state   => member_numeric,
      ndm_flags   => member_numeric,
      ndm_type    => member_numeric,
   ];

constant "NUD_$_" for qw( INCOMPLETE REACHABLE STALE DELAY PROBE FAILED NOARP
   PERMANENT );

constant "NTF_$_" for qw( PROXY ROUTER );

constant "NDA_$_" for qw( UNSPEC DST LLADDR CACHEINFO );

structure "struct nda_cacheinfo",
   arg_style => "hashref",
   members => [
      map { $_ => member_numeric } qw( ndm_confirmed ndm_used ndm_updated ndm_refcnt ),
   ];

constant "RTMGRP_$_" for qw( LINK NOTIFY NEIGH TC IPV4_IFADDR IPV4_MROUTE
   IPV4_ROUTE IPV4_RULE IPV6_IFADDR IPV6_MROUTE IPV6_ROUTE IPV6_IFINFO );

write_output $ARGV[0];
