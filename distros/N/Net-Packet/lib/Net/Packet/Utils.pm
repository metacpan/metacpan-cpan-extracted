#
# $Id: Utils.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Utils;
use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
   getHostIpv4Addr
   getHostIpv4Addrs
   getHostIpv6Addr
   getRandomHighPort
   getRandom32bitsInt
   getRandom16bitsInt
   convertMac
   unpackIntFromNet
   packIntToNet
   inetChecksum
   inetAton
   inetNtoa
   inet6Aton
   inet6Ntoa
   explodeIps
   explodePorts
   getGatewayIp
   getGatewayMac
   getIpMac
   debugDeviceList
);

our %EXPORT_TAGS = (
   all => [ @EXPORT_OK ],
);

use Socket;
use Socket6 qw(NI_NUMERICHOST NI_NUMERICSERV inet_pton inet_ntop getaddrinfo getnameinfo);
require Net::Libdnet;
require Net::IPv4Addr;
require Net::IPv6Addr;
require Net::Packet::Env;

sub getHostIpv4Addr {
   my $name  = shift;

   return undef unless $name;
   return $name if $name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

   my @addrs = (gethostbyname($name))[4];
   @addrs ? return join('.', unpack('C4', $addrs[0]))
          : carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");
   return undef;
}

sub getHostIpv4Addrs {
   my $name  = shift;

   return undef unless $name;
   return $name if $name =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

   my @addrs = (gethostbyname($name))[4];
   @addrs ? return @addrs
          : carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");
   return ();
}

sub getHostIpv6Addr {
   my $name = shift;

   return undef unless $name;
   return $name if Net::IPv6Addr::is_ipv6($name);

   my @res = getaddrinfo($name, 'ssh', AF_INET6, SOCK_STREAM);
   if (@res >= 5) {
      my ($ipv6) = getnameinfo($res[3], NI_NUMERICHOST | NI_NUMERICSERV);
      $ipv6 =~ s/%.*$//;
      return $ipv6;
   }
   else {
      carp("@{[(caller(0))[3]]}: unable to resolv `$name' hostname\n");
   }
   return undef;
}

sub inetAton  { inet_aton(shift())           }
sub inetNtoa  { inet_ntoa(shift())           }
sub inet6Aton { inet_pton(AF_INET6, shift()) }
sub inet6Ntoa { inet_ntop(AF_INET6, shift()) }

sub getRandomHighPort {
   my $highPort = int rand 0xffff;
   $highPort += 1024 if $highPort < 1025;
   return $highPort;
}

sub getRandom32bitsInt { int rand 0xffffffff }
sub getRandom16bitsInt { int rand 0xffff     }

sub convertMac {
   my $mac = shift;
   $mac =~ s/(..)/$1:/g;
   $mac =~ s/:$//;
   return lc $mac;
}

sub unpackIntFromNet {
   my ($net, $format, $offset, $pad, $bit) = @_;
   unpack($format, pack('B*', 0 x $pad . substr($net, $offset, $bit)));
}

sub packIntToNet {
   my ($int, $format, $offset, $bit) = @_;
   substr(unpack('B*', pack($format, $int << $bit)), $offset, $bit);
}

sub inetChecksum {
   my $phpkt = shift;

   $phpkt      .= "\x00" if length($phpkt) % 2;
   my $len      = length $phpkt;
   my $nshort   = $len / 2;
   my $checksum = 0;
   $checksum   += $_ for unpack("S$nshort", $phpkt);
   $checksum   += unpack('C', substr($phpkt, $len - 1, 1)) if $len % 2;
   $checksum    = ($checksum >> 16) + ($checksum & 0xffff);

   unpack('n', pack('S', ~(($checksum >> 16) + $checksum) & 0xffff));
}

sub explodePorts {
   my @ports;
   do { s/-/../g; push @ports, $_ for eval } for split /,/, shift();
   @ports;
}

sub explodeIps {
   my @ips;
   for (split(/,/, shift())) {
      my @bytes;
      do { s/-/../g; push @bytes, $_ } for split(/\./);
      for my $b1 (eval($bytes[0])) {
         for my $b2 (eval($bytes[1])) {
            for my $b3 (eval($bytes[2])) {
               for my $b4 (eval($bytes[3])) {
                  push @ips, "$b1.$b2.$b3.$b4";
               }
            }
         }
      }
   }
   @ips;
}

sub _getMacFromCache { Net::Libdnet::arp_get(shift()) }

sub getGatewayIp { Net::Libdnet::route_get(shift() || '1.1.1.1') || '0.0.0.0' }

sub getGatewayMac {
   my ($ip) = @_;
   my $mac = _getMacFromCache($ip) || _arpLookup($ip);
   $mac;
}

sub getIpMac {
   my ($ip) = @_;

   my $mac = _getMacFromCache($ip);
   return $mac if $mac;

   my $env = Net::Packet::Env->new;
   $env->updateDevInfo($ip);

   if (Net::IPv4Addr::ipv4_in_network($env->subnet, $ip)) {
      $mac = _arpLookup($ip, $env);
   }
   else {
      $mac = getGatewayMac($env->gatewayIp);
   }
   $mac;
}

sub _arpLookup {
   my ($ip, $env) = @_;

   require Net::Packet::DescL2;
   require Net::Packet::Dump;
   require Net::Packet::Frame;
   require Net::Packet::ETH;
   require Net::Packet::ARP;
   use Net::Packet::Consts qw(:eth :arp);

   $env = Net::Packet::Env->new unless $env;

   my $pEnv = $env->cgClone;
   $pEnv->updateDevInfo($ip);
   $pEnv->desc(undef);
   $pEnv->dump(undef);
   $pEnv->noFrameAutoDesc(1);
   $pEnv->noFrameAutoDump(1);
   $pEnv->noDescAutoSet(1);
   $pEnv->noDumpAutoSet(1);
   $pEnv->debug(0);

   my $d2 = Net::Packet::DescL2->new(
      dev => $pEnv->dev,
      ip  => $pEnv->ip,
      mac => $pEnv->mac,
   );

   my $dump = Net::Packet::Dump->new(
      dev       => $pEnv->dev,
      env       => $pEnv,
      overwrite => 1,
      filter    => 'arp and dst '.$pEnv->ip,
   );
   $dump->start;
   $pEnv->dump($dump);

   my $eth = Net::Packet::ETH->new(
      src  => $pEnv->mac,
      dst  => 'ff:ff:ff:ff:ff:ff',
      type => NP_ETH_TYPE_ARP,
   );

   my $arp = Net::Packet::ARP->new(
      dstIp  => $ip,
      srcIp  => $pEnv->ip,
      hType  => NP_ARP_HTYPE_ETH,
      pType  => NP_ARP_PTYPE_IPv4,
      hSize  => NP_ARP_HSIZE_ETH,
      pSize  => NP_ARP_PSIZE_IPv4,
      opCode => NP_ARP_OPCODE_REQUEST,
   );

   my $frame = Net::Packet::Frame->new(
      l2 => $eth,
      l3 => $arp,
   );

   my $mac;
   for (1..3) {
      $frame->send;
      until ($dump->timeout) {
         if (my $reply = $frame->recv) {
            $mac = $reply->l3->src;
            last;
         }
      }

      last if $mac;
      $dump->timeoutReset;
   }

   $d2->close;
   $dump->stop;
   $dump->clean;

   if ($mac) {
      Net::Libdnet::arp_add($ip, $mac);
      return $mac;
   }

   '00:00:00:00:00:00';
}

# Thanx to Maddingue
sub _toDotQuad {
   my ($i) = @_;
   ($i >> 24 & 255).'.'.($i >> 16 & 255).'.'.($i >> 8 & 255).'.'.($i & 255);
}

sub debugDeviceList {
   use Data::Dumper;
   require Net::Pcap;

   my %dev;
   my $err;
   Net::Pcap::findalldevs(\%dev, \$err);
   print STDERR "findalldevs: error: $err\n" if $err;

   # Net::Pcap stuff
   for my $d (keys %dev) {
      my ($net, $mask);
      if (Net::Pcap::lookupnet($d, \$net, \$mask, \$err) < 0) {
         print STDERR "lookupnet: error: $d: $err\n";
         $err = undef; next;
      }
      print STDERR "[$d] => subnet: "._toDotQuad($net)."\n";
   }

   # Net::Libdnet stuff
   for my $i (0..5) {
      my $eth = 'eth'.$i;
      my $dnet = Net::Libdnet::intf_get($eth);
      last unless keys %$dnet > 0;
      $dnet->{subnet} = Net::Libdnet::addr_net($dnet->{addr})
         if $dnet->{addr};
      print STDERR Dumper($dnet)."\n";
   }
}

1;

=head1 NAME

Net::Packet::Utils - useful subroutines used in Net::Packet

=head1 SYNOPSIS

   # Load all subroutines
   use Net::Packet::Utils qw(:all);

   # Load only specific subroutines
   use Net::Packet::Utils qw(explodeIps explodePorts);

   my @ips   = explodeIps('192.168.0.1-254,192.168.1.1');
   my @ports = explodePorts('1-1024,6000');

   print "@ips\n";
   print "@ports\n";

=head1 DESCRIPTION

This module is not object oriented, it just implements some utilities used accros Net::Packet framework. They may be useful in other modules too, so here lies their descriptions.

=head1 SUBROUTINES

=over 4

=item B<getHostIpv4Addr> (scalar)

Tries to resolve hostname passed as an argument. Returns its IP address.

=item B<getHostIpv4Addrs> (scalar)

Tries to resolve hostname passed as an argument. Returns an array of IP addresses.

=item B<getHostIpv6Addr> (scalar)

Tries to resolve hostname passed as an argument. Returns its IPv6 address.

=item B<inetAton> (scalar)

Returns numeric value of IP address passed as an argument.

=item B<inetNtoa> (scalar)

Returns IP address of numeric value passed as an argument.

=item B<inet6Aton> (scalar)

Returns numeric value of IPv6 address passed as an argument.

=item B<inet6Ntoa> (scalar)

Returns IPv6 address of numeric value passed as an argument.

=item B<getRandomHighPort>

Returns a port number for direct use as source in a TCP or UDP header (that is a port between 1025 and 65535).

=item B<getRandom32bitsInt>

Returns a random integer of 32 bits in length.

=item B<getRandom16bitsInt>

Returns a random integer of 16 bits in length.

=item B<convertMac> (scalar)

Converts a MAC address from network format to human format.

=item B<unpackIntFromNet> (scalar, scalar, scalar, scalar, scalar)

Almost used internally, to convert network bits to integers. First argument is what to convert, second is an unpack format, third the offset of first argument where bits to get begins, the fourth are padding bits to achieve the length we need, and the last is the number of bits to get from offset argument.

=item B<packIntToNet> (scalar, scalar, scalar, scalar)

Almost used internally, to convert integers to network bits. First argument is what to convert, second is a pack format, third the offset where to store the first argument, and the last the number of bits the integer will be once packed.

=item B<inetChecksum> (scalar)

Compute the INET checksum used in various layers.

=item B<explodePorts>

=item B<explodeIps>

See B<SYNOPSIS>.

=item B<getGatewayIp> [ (scalar) ]

Returns the gateway IP address for IP address passed as a parameter. If none provided, returns the default gateway IP address.

=item B<getGatewayMac> (scalar)

Returns the gateway MAC address of specified gateway IP address. It first looks up from ARP cache table, then tries an ARP lookup if none was found, and adds it to ARP cache table.

=item B<getIpMac> (scalar)

Returns the MAC address of specified IP address. It first looks up from ARP cache table. If nothing is found, it checks to see if the specified IP address is on the same subnet. If not, it returns the gateway MAC address, otherwise does an ARP lookup. Then, the ARP cache table is updated if an ARP resolution has been necessary.

=item B<debugDeviceList>

If you have problem under Windows concerning network interfaces, please send me the output of this method.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret
   
You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.
   
=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>   
   
=cut
