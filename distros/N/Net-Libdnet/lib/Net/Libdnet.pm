#
# $Id: Libdnet.pm 59 2012-11-22 19:21:36Z gomor $
#
# Copyright (c) 2004 Vlad Manilici
# Copyright (c) 2008-2012 Patrice <GomoR> Auffret
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Net::Libdnet;
use strict; use warnings;

use base qw(Exporter DynaLoader);

our $VERSION = '0.98';

our %EXPORT_TAGS = (
   obsolete => [qw(
      addr_cmp
      addr_bcast
      addr_net
      arp_add
      arp_delete
      arp_get
      intf_get
      intf_get_src
      intf_get_dst
      route_add
      route_delete
      route_get
   )],
   route => [qw(
      dnet_route_open
      dnet_route_add
      dnet_route_delete
      dnet_route_get
      dnet_route_loop
      dnet_route_close
   )],
   intf => [qw(
      dnet_intf_open
      dnet_intf_get
      dnet_intf_get_src
      dnet_intf_get_dst
      dnet_intf_set
      dnet_intf_loop
      dnet_intf_close
   )],
   arp => [qw(
      dnet_arp_open
      dnet_arp_add
      dnet_arp_delete
      dnet_arp_get
      dnet_arp_loop
      dnet_arp_close
   )],
   fw => [qw(
      dnet_fw_open
      dnet_fw_add
      dnet_fw_delete
      dnet_fw_loop
      dnet_fw_close
   )],
   tun => [qw(
      dnet_tun_open
      dnet_tun_fileno
      dnet_tun_name
      dnet_tun_send
      dnet_tun_recv
      dnet_tun_close
   )],
   eth => [qw(
      dnet_eth_open
      dnet_eth_get
      dnet_eth_set
      dnet_eth_send
      dnet_eth_close
   )],
   ip => [qw(
      dnet_ip_open
      dnet_ip_checksum
      dnet_ip_send
      dnet_ip_close
   )],
   consts => [qw(
      DNET_ADDR_TYPE_NONE
      DNET_ADDR_TYPE_ETH
      DNET_ADDR_TYPE_IP
      DNET_ADDR_TYPE_IP6
      DNET_FW_OP_ALLOW
      DNET_FW_OP_BLOCK
      DNET_FW_DIR_IN
      DNET_FW_DIR_OUT
      DNET_INTF_TYPE_OTHER
      DNET_INTF_TYPE_ETH
      DNET_INTF_TYPE_LOOPBACK
      DNET_INTF_TYPE_TUN
      DNET_INTF_FLAG_UP
      DNET_INTF_FLAG_LOOPBACK
      DNET_INTF_FLAG_POINTOPOINT
      DNET_INTF_FLAG_NOARP
      DNET_INTF_FLAG_BROADCAST
      DNET_INTF_FLAG_MULTICAST
   )],
);
our @EXPORT = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{obsolete}},
   @{$EXPORT_TAGS{route}},
   @{$EXPORT_TAGS{intf}},
   @{$EXPORT_TAGS{arp}},
   @{$EXPORT_TAGS{fw}},
   @{$EXPORT_TAGS{tun}},
   @{$EXPORT_TAGS{eth}},
   @{$EXPORT_TAGS{ip}},
);

__PACKAGE__->bootstrap($VERSION);

use constant DNET_ADDR_TYPE_NONE => 0;
use constant DNET_ADDR_TYPE_ETH  => 1;
use constant DNET_ADDR_TYPE_IP   => 2;
use constant DNET_ADDR_TYPE_IP6  => 3;

use constant DNET_FW_OP_ALLOW => 1;
use constant DNET_FW_OP_BLOCK => 2;
use constant DNET_FW_DIR_IN   => 1;
use constant DNET_FW_DIR_OUT  => 2;

use constant DNET_INTF_TYPE_OTHER       => 1;
use constant DNET_INTF_TYPE_ETH         => 6;
use constant DNET_INTF_TYPE_LOOPBACK    => 24;
use constant DNET_INTF_TYPE_TUN         => 53;
use constant DNET_INTF_FLAG_UP          => 0x01;
use constant DNET_INTF_FLAG_LOOPBACK    => 0x02;
use constant DNET_INTF_FLAG_POINTOPOINT => 0x04;
use constant DNET_INTF_FLAG_NOARP       => 0x08;
use constant DNET_INTF_FLAG_BROADCAST   => 0x10;
use constant DNET_INTF_FLAG_MULTICAST   => 0x20;

sub addr_cmp     { _obsolete_addr_cmp    (@_) }
sub addr_bcast   { _obsolete_addr_bcast  (@_) }
sub addr_net     { _obsolete_addr_net    (@_) }
sub arp_add      { _obsolete_arp_add     (@_) }
sub arp_delete   { _obsolete_arp_delete  (@_) }
sub arp_get      { _obsolete_arp_get     (@_) }
sub intf_get     { _obsolete_intf_get    (@_) }
sub intf_get_src { _obsolete_intf_get_src(@_) }
sub intf_get_dst { _obsolete_intf_get_dst(@_) }
sub route_add    { _obsolete_route_add   (@_) }
sub route_delete { _obsolete_route_delete(@_) }
sub route_get    { _obsolete_route_get   (@_) }

1;

__END__

=head1 NAME

Net::Libdnet - binding for Dug Song's libdnet

=head1 SYNOPSIS

   #
   # This will just import every functions and constants
   #
   use Net::Libdnet;

   #
   # Network interface manipulation
   #
   # !!! ADVICE: you should use Net::Libdnet::Intf instead
   #
   use Net::Libdnet qw(:intf);
   my $intf = dnet_intf_open();

   my $eth  = dnet_intf_get($intf, { intf_name => 'eth0' });
   print "IP:  ".$eth->{intf_addr}."\n";
   print "MAC: ".$eth->{intf_link_addr}."\n";

   my $dst  = dnet_intf_get_dst($intf, '192.168.0.10');
   print "Name: ".$dst->{intf_name}."\n";
   print "IP:   ".$dst->{intf_addr}."\n";
   print "MAC:  ".$dst->{intf_link_addr}."\n";

   my $src = dnet_intf_get_src($intf, '192.168.0.1');
   print "Name: ".$src->{intf_name}."\n";
   print "IP:   ".$src->{intf_addr}."\n";
   print "MAC:  ".$src->{intf_link_addr}."\n";

   dnet_intf_close($intf);

   #
   # Arp cache manipulation
   #
   # !!! ADVICE: you should use Net::Libdnet::Arp instead
   #
   use Net::Libdnet qw(:arp);
   my $arp   = dnet_arp_open();

   my $entry = dnet_arp_get($arp, {arp_pa => '10.0.0.1'});
   print "MAC: ".$entry->{arp_ha}."\n";

   dnet_arp_add   ($arp,
      {arp_ha => '00:11:22:33:44:55', arp_pa => '10.0.0.10'});
   dnet_arp_delete($arp,
      {arp_ha => '00:11:22:33:44:55', arp_pa => '10.0.0.10'});
   dnet_arp_close($arp);

   #
   # Route table manipulation
   #
   # !!! ADVICE: you should use Net::Libdnet::Route instead
   #
   use Net::Libdnet qw(:route);
   my $route = dnet_route_open();
   dnet_route_add   ($route,
      {route_gw => '10.0.0.1', route_dst => '192.168.0.1'});
   dnet_route_delete($route,
      {route_gw => '10.0.0.1', route_dst => '192.168.0.1'});

   my $get = dnet_route_get($route, {route_dst => '192.168.0.10'});
   print "GW: ".$get->{route_gw}."\n";

   dnet_route_close($route);

   #
   # Firewall rules manipulation
   #
   # !!! ADVICE: you should use Net::Libdnet::Fw instead
   #
   use Net::Libdnet qw(:fw :consts);
   my $fw = dnet_fw_open();
   # This is quite complex. This rule blocks TCP as input to 10.0.0.1
   # You should really use Net::Libdnet::Fw instead.
   dnet_fw_add   ($fw,
      {fw_op => FW_DIR_IN, fw_proto => 6, fw_dst => '10.0.0.1'});
   dnet_fw_delete($fw,
      {fw_op => FW_DIR_IN, fw_proto => 6, fw_dst => '10.0.0.1'});
   dnet_fw_close($fw);

   #
   # Send at IP level
   #
   # !!! ADVICE: you should use Net::Libdnet::Ip instead
   #
   use Net::Libdnet qw(:ip);
   my $ip = dnet_ip_open();
   my $raw = "\x47\x47\x47\x47";
   dnet_ip_send($ip, $raw, length($raw));
   dnet_ip_close($ip);

   #
   # Send at Ethernet level
   #
   # !!! ADVICE: you should use Net::Libdnet::Eth instead
   #
   use Net::Libdnet qw(:eth);
   my $eth = dnet_eth_open('eth0');
   dnet_eth_send($eth, $raw, length($raw));
   dnet_eth_close($eth);

   #
   # Traffic interception
   #
   # !!! ADVICE: you should use Net::Libdnet::Tun instead
   #
   use Net::Libdnet qw(:tun);
   my $tun = dnet_tun_open('10.0.0.10', '192.168.0.10', 1500);
   my $buf = dnet_tun_recv($tun, 1500);
   # Do stuff with $buf
   dnet_tun_send($tun, $buf, length($buf));
   dnet_tun_close($tun);

   #
   # hash refs in dnet format
   #
   my $intf = {
      intf_alias_num   => 1,
      intf_mtu         => 1500,
      intf_len         => 112,
      intf_type        => 6,
      intf_name        => 'eth0',
      intf_dst_addr    => undef,
      intf_link_addr   => '00:11:22:33:44:55',
      intf_flags       => 49,
      intf_addr        => '10.100.0.10/24',
      intf_alias_addrs => [ 'fe80::211:2ff:fe33:4455/64' ]
   };
   my $arp = {
      arp_pa => '10.100.0.1',
      arp_ha => '11:22:33:44:55:66'
   };
   my $route = {
      route_gw  => '10.100.0.1',
      route_dst => '0.0.0.0/0'
   };
   my $fw = {
      fw_dir    => 2,
      fw_sport  => [ 0, 0 ],
      fw_dport  => [ 0, 0 ],
      fw_src    => '0.0.0.0/0',
      fw_dst    => '0.0.0.0/0',
      fw_proto  => 6,
      fw_device => 'eth0',
      fw_op     => 2
   };

=head1 DESCRIPTION

Net::Libdnet provides a simplified, portable interface to several low-level networking routines, including network address manipulation, kernel arp cache and route table lookup and manipulation, network firewalling, network interface lookup and manipulation, network traffic interception via tunnel interfaces, and raw IP packet and Ethernet frame transmission. It is intended to complement the functionality provided by libpcap.

All the original and obsolete functions return I<undef> and print a warning message to the standard error when a problem occurs. The obsolete functions are: B<addr_cmp>, B<addr_bcast>, B<addr_net>, B<arp_add>, B<arp_delete>, B<arp_get>, B<intf_get>, B<intf_get_src>, B<intf_get_dst>, B<route_add>, B<route_delete>, B<route_get>.

These obsolete functions will continue to work, to keep backward compatibility, but should not be used anymore. The new APIs should be preferred. There are two new APIs, one is the low-level one, matching libdnet functions, and the other one is a high-level API, matching a more Perl object oriented programming. This latest one is highly preferred.

Net::Libdnet module implements the low-level API. The high-level API is accessible by using the following modules: B<Net::Libdnet::Intf>, B<Net::Libdnet::Route>, B<Net::Libdnet::Fw>, B<Net::Libdnet::Arp>, B<Net::Libdnet::Eth>, B<Net::Libdnet::Ip> and B<Net::Libdnet::Tun>.

=head1 WHAT IS IMPLEMENTED

=over 4

=item B<Network addressing>

Nothing as of now.

=item B<Address Resolution Protocol>

All functions: arp_open, arp_add, arp_delete, arp_get, arp_loop, arp_close.

=item B<Binary buffers>

Nothing as of now.

=item B<Ethernet>

All functions: eth_open, eth_get, eth_set, eth_send, eth_close.

=item B<Firewalling>

All functions: fw_open, fw_add, fw_delete, fw_loop, fw_close.

=item B<Network interface>

All functions: intf_open, intf_get_set, intf_get_dst, intf_set, intf_loop, intf_close.

=item B<Internet Protocol>

All functions: ip_open, ip_checksum, ip_send, ip_close.

Except: ip_add_option.

=item B<Internet Protocol Version 6>

Nothing as of now.

=item B<Random number generation>

Nothing as of now.

=item B<Routing>

All functions: route_open, route_add, route_delete, route_get, route_loop, route_close.

=item B<Tunnel interface>

All functions: tun_open, tun_fileno, tun_name, tun_send, tun_recv, tun_close.

=back

=head1 SUBROUTINES

=over 4

=item B<dnet_intf_open> ()

Opens an interface handle. Returns a handle on success, undef on error.

=item B<dnet_intf_get> (scalar, hashref)

Takes an intf handle, and a hash ref in dnet format as parameters. Returns a hash in dnet format on success, undef on error.

=item B<dnet_intf_get_src> (scalar, scalar)

Takes an intf handle, and an IP address as parameters. Returns a hash in dnet format on success, undef on error.

=item B<dnet_intf_get_dst> (scalar, scalar)

Takes an intf handle, and an IP address as parameters. Returns a hash in dnet format on success, undef on error.

=item B<dnet_intf_set> (scalar, scalar)

Takes an intf handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_intf_loop> (scalar, subref, scalarref)

Takes an intf handle, a subref, and a scalar ref as parameters. Returns 1 on success, undef on error. The subref will be called with an intf hash ref in dnet format, and the scalar ref as parameters.

=item B<dnet_intf_close> (scalar)

Takes an intf handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_route_open> ()

Opens a route handle. Returns a handle on success, undef on error.

=item B<dnet_route_add> (scalar, hashref)

Takes a route handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_route_delete> (scalar, hashref)

Takes a route handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_route_get> (scalar, hashref)

Takes a route handle, and a hash ref in dnet format as parameters. Returns a hash ref in dnet format on success, undef on error.

=item B<dnet_route_loop> (scalar, subref, scalarref)

Takes a route handle, a subref, and a scalar ref as parameters. Returns 1 on success, undef on error. The subref will be called with a route hash ref in dnet format, and the scalar ref as parameters.

=item B<dnet_route_close> (scalar)

Takes a route handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_arp_open> ()

Opens an arp handle. Returns a handle on success, undef on error.

=item B<dnet_arp_add> (scalar, hashref)

Takes an arp handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_arp_delete> (scalar, hashref)

Takes an arp handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_arp_get> (scalar, hashref)

Takes an arp handle, and a hash ref in dnet format as parameters. Returns a hash ref in dnet format on success, undef on error.

=item B<dnet_arp_loop> (scalar, subref, scalarref)

Takes an arp handle, a subref, and a scalar ref as parameters. Returns 1 on success, undef on error. The subref will be called with an arp hash ref in dnet format, and the scalar ref as parameters.

=item B<dnet_arp_close> (scalar)

Takes an arp handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_fw_open> ()

Opens a fw handle. Returns a handle on success, undef on error.

=item B<dnet_fw_add> (scalar, hashref)

Takes a fw handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_fw_delete> (scalar, hashref)

Takes a fw handle, and a hash ref in dnet format as parameters. Returns 1 on success, undef on error.

=item B<dnet_fw_loop> (scalar, subref, scalarref)

Takes a fw handle, a subref, and a scalar ref as parameters. Returns 1 on success, undef on error. The subref will be called with a fw hash ref in dnet format, and the scalar ref as parameters.

=item B<dnet_fw_close> (scalar)

Takes a fw handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_tun_open> (scalar, scalar, scalar)

Creates a tunnel between src and dst IP addresses. Captured packets will have specified size. First argument is the source IP address, second the destination IP address, and the third is the cpature size. Returns a handle on success, undef on error.

=item B<dnet_tun_fileno> (scalar)

Takes a tun handle as parameter. Returns the file number on success, undef on error.

=item B<dnet_tun_name> (scalar)

Takes a tun handle as parameter. Returns the interface name on success, undef on error.

=item B<dnet_tun_send> (scalar, scalar, scalar)

Takes a tun handle, the raw data to send, and its size as parameters. Returns the number of bytes sent on success, undef on error.

=item B<dnet_tun_recv> (scalar, scalar)

Takes a tun handle, and the maximum size to read as parameters. Returns the read buffer on success, undef on error.

=item B<dnet_tun_close> (scalar)

Takes a tun handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_eth_open> (scalar)

Opens an eth handle. Takes an interface name as parameter. Returns a handle on success, undef on error.

=item B<dnet_eth_get> (scalar)

Takes an eth handle as parameter. Returns the hardware address of currently opened eth handle on success, undef on error.

=item B<dnet_eth_set> (scalar, scalar)

Takes an eth handle, and the hardware address to set as parameters. Returns 1 on success, undef on error.

=item B<dnet_eth_send> (scalar, scalar, scalar)

Takes an eth handle, the raw data to send, and its size as parameters. Returns the number of bytes sent on success, undef on error.

=item B<dnet_eth_close> (scalar)

Takes an eth handle as parameter. Returns the handle on success, undef on error.

=item B<dnet_ip_open> ()

Opens an ip handle. Returns a handle on success, undef on error.

=item B<dnet_ip_checksum> (scalar, scalar)

Takes a raw IPv4 frame as the first parameter, and its size as a second parameter. It then updates the frame with the good checksum. Returns nothing.

=item B<dnet_ip_send> (scalar, scalar, scalar)

Takes an ip handle, the raw data to send, and its size as parameters. Returns the number of bytes sent on success, undef on error.

=item B<dnet_ip_close> (scalar)

Takes an ip handle as parameter. Returns the handle on success, undef on error.

=back

=head1 OBSOLETE FUNCTIONS

They should not be used anymore. You have been warned.

=over 4

=item B<addr_bcast>

=item B<addr_cmp>

=item B<addr_net>

=item B<arp_add>

=item B<arp_delete>

=item B<arp_get>

=item B<intf_get>

=item B<intf_get_dst>

=item B<intf_get_src>

=item B<route_add>

=item B<route_delete>

=item B<route_get>

=back

=head1 CONSTANTS

=over 4

=item B<DNET_ADDR_TYPE_NONE>

=item B<DNET_ADDR_TYPE_ETH>

=item B<DNET_ADDR_TYPE_IP>

=item B<DNET_ADDR_TYPE_IP6>

=item B<DNET_FW_OP_ALLOW>

=item B<DNET_FW_OP_BLOCK>

=item B<DNET_FW_DIR_IN>

=item B<DNET_FW_DIR_OUT>

=item B<DNET_INTF_TYPE_OTHER>

=item B<DNET_INTF_TYPE_ETH>

=item B<DNET_INTF_TYPE_LOOPBACK>

=item B<DNET_INTF_TYPE_TUN>

=item B<DNET_INTF_FLAG_UP>

=item B<DNET_INTF_FLAG_LOOPBACK>

=item B<DNET_INTF_FLAG_POINTOPOINT>

=item B<DNET_INTF_FLAG_NOARP>

=item B<DNET_INTF_FLAG_BROADCAST>

=item B<DNET_INTF_FLAG_MULTICAST>

=back

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2004, Vlad Manilici

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=head1 SEE ALSO

L<dnet(3)>

=cut
