#
# $Id: Packet.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet;
use strict;
use warnings;

require v5.6.1;

our $VERSION = '3.28';

require Exporter;
our @ISA = qw(Exporter);

use Net::Packet::Env    qw($Env);
use Net::Packet::Utils  qw(:all);
use Net::Packet::Consts qw(:desc :dump :layer :eth :arp :vlan :null :ipv4
   :ipv6 :tcp :udp :icmpv4 :cdp :llc :ppplcp :pppoe :ppp);

require Net::Packet::Dump;

require Net::Packet::DescL2;
require Net::Packet::DescL3;
require Net::Packet::DescL4;

require Net::Packet::Frame;
require Net::Packet::ETH;
require Net::Packet::IPv4;
require Net::Packet::IPv6;
require Net::Packet::VLAN;
require Net::Packet::ARP;
require Net::Packet::TCP;
require Net::Packet::UDP;
require Net::Packet::ICMPv4;
require Net::Packet::NULL;
require Net::Packet::RAW;
require Net::Packet::SLL;
require Net::Packet::CDP;
require Net::Packet::CDP::Address;
require Net::Packet::CDP::TypeDeviceId;
require Net::Packet::CDP::TypeAddresses;
require Net::Packet::CDP::TypeCapabilities;
require Net::Packet::CDP::TypePortId;
require Net::Packet::CDP::TypeSoftwareVersion;
require Net::Packet::LLC;
require Net::Packet::PPPLCP;
require Net::Packet::PPPoE;
require Net::Packet::PPP;
require Net::Packet::STP;

our @EXPORT = (
   @Net::Packet::Env::EXPORT_OK,
   @Net::Packet::Utils::EXPORT_OK,
   @Net::Packet::Consts::EXPORT_OK,
);

1;

__END__

=head1 NAME

Net::Packet - a framework to easily send and receive frames from layer 2 to layer 7

=head1 SYNOPSIS

   # Load all modules, it also initializes a Net::Packet::Env object,
   # and imports all utility subs and constants in current namespace
   # WARNING: this is not the prefered way to use Net::Packet
   use Net::Packet;

   # Build IPv4 header
   my $ip = Net::Packet::IPv4->new(dst => '192.168.0.1');

   # Build TCP header
   my $tcp = Net::Packet::TCP->new(dst => 22);

   # Assamble frame, it will also open a Net::Packet::DescL3 descriptor
   # and a Net::Packet::Dump object
   my $frame = Net::Packet::Frame->new(l3 => $ip, l4 => $tcp);

   $frame->send;

   # Print the reply just when it has been received
   until ($Env->dump->timeout) {
      if ($frame->recv) {
         print $frame->reply->l3, "\n";
         print $frame->reply->l4, "\n";
         last;
      }
   }

   # Alternative way of using Net::Packet, which is the recommanded way
   # First thing to do, get a default Env object. It will contain all 
   # information regarding your default interface setup and some 
   # specific options regarding Net::Packet framework behaviour
   use Net::Packet::Env qw($Env);

   # Then, load modules you need to accomplish your work
   require Net::Packet::DescL3;
   require Net::Packet::Dump;
   require Net::Packet::Frame;
   require Net::Packet::IPv4;
   require Net::Packet::TCP;

   # We manually create Desc and Dump objects to have complete control 
   # on Net::Packet framework behaviour
   my $desc = Net::Packet::DescL3->new(
      target => '192.168.0.1',
   );

   my $dump = Net::Packet::Dump->new(
      filter        => 'tcp',
      keepTimestamp => 1,
   );
   $dump->start;

   # Build IPv4 header
   my $ip = Net::Packet::IPv4->new(dst => '192.168.0.1');

   # Build TCP header
   my $tcp = Net::Packet::TCP->new(dst => 22);

   # Assamble frame. Because we have created Desc and Dump objects, 
   # they will not be automatically created here
   my $frame = Net::Packet::Frame->new(l3 => $ip, l4 => $tcp);
   $frame->send;

   until ($dump->timeout) {
      if ($frame->recv) {
         print $frame->reply->l3, "\n";
         print $frame->reply->l4, "\n";
         last;
      }
   }

   $dump->stop;
   $dump->clean;

=head1 CLASS HIERARCHY

  Net::Packet

  Net::Packet::Env

  Net::Packet::Dump

  Net::Packet::Utils

  Net::Packet::Desc
     |
     +---Net::Packet::DescL2
     |
     +---Net::Packet::DescL3
     |
     +---Net::Packet::DescL4

  Net::Packet::Frame

  Net::Packet::Layer
     |
     +---Net::Packet::Layer2
     |      |
     |      +---Net::Packet::ETH
     |      |
     |      +---Net::Packet::NULL
     |      |
     |      +---Net::Packet::RAW
     |      |
     |      +---Net::Packet::SLL
     |      |
     |      +---Net::Packet::PPP
     |
     +---Net::Packet::Layer3
     |      |
     |      +---Net::Packet::ARP
     |      |
     |      +---Net::Packet::IPv4
     |      |
     |      +---Net::Packet::IPv6
     |      |
     |      +---Net::Packet::VLAN
     |      |
     |      +---Net::Packet::PPPoE
     |      |
     |      +---Net::Packet::PPPLCP
     |      |
     |      +---Net::Packet::LLC
     |
     +---Net::Packet::Layer4
     |      |
     |      +---Net::Packet::TCP
     |      |
     |      +---Net::Packet::UDP
     |      |
     |      +---Net::Packet::ICMPv4
     |      |
     |      +---Net::Packet::CDP
     |      |
     |      +---Net::Packet::STP
     |      |
     |      +---Net::Packet::OSPF
     |      |
     |      +---Net::Packet::IGMPv4
     |
     +---Net::Packet::Layer7

=head1 DESCRIPTION

This module is a unified framework to craft, send and receive packets at layers 2, 3, 4 and 7.

Basically, you forge each layer of a frame (B<Net::Packet::IPv4> for layer 3, B<Net::Packet::TCP> for layer 4; for example), and pack all of this into a B<Net::Packet::Frame> object. Then, you can send the frame to the network, and receive its response easily, because the response is automatically searched for and matched against the request (not implemented for all layers).

If you want some layer 2, 3 or 4 protocol encoding/decoding to be added, just ask, and give a corresponding .pcap file ;). You can also subscribe to netpacket-users@gomor.org by sumply sending an e-mail requesting for it.

You should study various pod found in all classes, example files found in B<examples> directory that come with this tarball, and also tests in B<t> directory.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES  

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
