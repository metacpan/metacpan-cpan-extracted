#
# $Id: IPv4.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::IPv4;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Carp;
use Net::Packet::Env qw($Env);
use Net::Packet::Utils qw(getRandom16bitsInt inetAton inetNtoa inetChecksum);
use Net::Packet::Consts qw(:ipv4 :layer);
require Bit::Vector;

our @AS = qw(
   id
   ttl
   src
   dst
   protocol
   checksum
   flags
   offset
   version
   tos
   length
   hlen
   options
   noFixLen
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);      

no strict 'vars';

BEGIN {
   my $osname = {
      freebsd => [ \&_fixLenBsd, ],
      netbsd  => [ \&_fixLenBsd, ],
   };

   *_fixLen = $osname->{$^O}->[0] || \&_fixLenOther;
}

sub _fixLenBsd   { pack('v', shift) }
sub _fixLenOther { pack('n', shift) }

sub new {
   shift->SUPER::new(
      version  => 4,
      tos      => 0,
      id       => getRandom16bitsInt(),
      length   => NP_IPv4_HDR_LEN,
      hlen     => 5,
      flags    => 0,
      offset   => 0,
      ttl      => 128,
      protocol => NP_IPv4_PROTOCOL_TCP,
      checksum => 0,
      src      => $Env->ip,
      dst      => '127.0.0.1',
      options  => '',
      noFixLen => 0,
      @_,
   );
}

sub pack {
   my $self = shift;

   # Here, we pack in this order: version, hlen (4 bits each)
   my $version = Bit::Vector->new_Dec(4, $self->[$__version]);
   my $hlen    = Bit::Vector->new_Dec(4, $self->[$__hlen]);
   my $v8      = $version->Concat_List($hlen);

   # Here, we pack in this order: flags (3 bits), offset (13 bits)
   my $flags  = Bit::Vector->new_Dec(3,  $self->[$__flags]);
   my $offset = Bit::Vector->new_Dec(13, $self->[$__offset]);
   my $v16    = $flags->Concat_List($offset);

   my $len = ($self->[$__noFixLen] ? _fixLenOther($self->[$__length])
                                   : _fixLen($self->[$__length]));

   $self->[$__raw] = $self->SUPER::pack('CCa*nnCCna4a4',
      $v8->to_Dec,
      $self->[$__tos],
      $len,
      $self->[$__id],
      $v16->to_Dec,
      $self->[$__ttl],
      $self->[$__protocol],
      $self->[$__checksum],
      inetAton($self->[$__src]),
      inetAton($self->[$__dst]),
   ) or return undef;

   my $opt;
   if ($self->[$__options]) {
      $opt = $self->SUPER::pack('a*', $self->[$__options])
         or return undef;
      $self->[$__raw] = $self->[$__raw].$opt;
   }

   1;
}

sub unpack {
   my $self = shift;

   my ($verHlen, $tos, $len, $id, $flagsOffset, $ttl, $proto, $cksum, $src,
      $dst, $payload) = $self->SUPER::unpack('CCnnnCCna4a4 a*', $self->[$__raw])
         or return undef;

   my $v8  = Bit::Vector->new_Dec(8,  $verHlen);
   my $v16 = Bit::Vector->new_Dec(16, $flagsOffset);

   # Here, we unpack in this order: hlen, version (4 bits each)
   $self->[$__hlen] = $v8->Chunk_Read(4, 0);
   $self->[$__version] = $v8->Chunk_Read(4, 4);
   $self->[$__tos] = $tos;
   $self->[$__length] = $len;
   $self->[$__id] = $id;
   # Here, we unpack in this order: offset (13 bits), flags (3 bits)
   $self->[$__offset] = $v16->Chunk_Read(13,  0);
   $self->[$__flags] = $v16->Chunk_Read( 3, 13);
   $self->[$__ttl] = $ttl;
   $self->[$__protocol] = $proto;
   $self->[$__checksum] = $cksum;
   $self->[$__src] = inetNtoa($src);
   $self->[$__dst] = inetNtoa($dst);
   $self->[$__payload] = $payload;

   my ($options, $payload2) = $self->SUPER::unpack(
      'a'. $self->getOptionsLength. 'a*', $self->[$__payload]
   ) or return undef;

   $self->[$__options] = $options;
   $self->[$__payload] = $payload2;

   1;
}

sub getLength {
   my $self = shift;
   $self->[$__hlen] > 0 ? $self->[$__hlen] * 4 : 0;
}
sub getHeaderLength  { NP_IPv4_HDR_LEN }
sub getPayloadLength {
   my $self = shift;
   my $gLen = $self->getLength;
   $self->[$__length] > $gLen ? $self->[$__length] - $gLen : 0;
}
sub getOptionsLength {
   my $self = shift;
   my $gLen = $self->getLength;
   my $hLen = $self->getHeaderLength;
   $gLen > $hLen ? $gLen - $hLen : 0;
}

sub _computeTotalLength {
   my $self  = shift;
   my ($l4, $l7) = @_;

   my $total = $self->getLength;
   $total += $l4->getLength if $l4;
   $total += $l7->getLength if $l7;
   $self->[$__length] = $total;
}

sub computeLengths {
   my $self = shift;
   my ($env, $l2, $l3, $l4, $l7) = @_;

   my $hLen = NP_IPv4_HDR_LEN;
   $hLen   += length($self->[$__options]) if $self->[$__options];
   $self->[$__hlen] = $hLen / 4;

   $l4 && ($l4->computeLengths($env, $l2, $l3, $l4, $l7) or return undef);

   $self->_computeTotalLength($l4, $l7);

   1;
}

sub computeChecksums {
   my $self = shift;

   # Reset the checksum if already filled by a previous pack
   $self->[$__checksum] = 0;

   return 1 if ! $Env->doIPv4Checksum;

   $self->pack;
   $self->[$__checksum] = inetChecksum($self->[$__raw]);

   1;
}

sub encapsulate {
   my $types = {
      NP_IPv4_PROTOCOL_TCP()    => NP_LAYER_TCP(),
      NP_IPv4_PROTOCOL_UDP()    => NP_LAYER_UDP(),
      NP_IPv4_PROTOCOL_ICMPv4() => NP_LAYER_ICMPv4(),
      NP_IPv4_PROTOCOL_IPv6()   => NP_LAYER_IPv6(),
      NP_IPv4_PROTOCOL_OSPF()   => NP_LAYER_OSPF(),
      NP_IPv4_PROTOCOL_IGMPv4() => NP_LAYER_IGMPv4(),
   };

   $types->{shift->protocol} || NP_LAYER_UNKNOWN();
}

sub getKey {
   my $self  = shift;
   $self->is.':'.$self->[$__src].'-'.$self->[$__dst];
}

sub getKeyReverse {
   my $self  = shift;
   $self->is.':'.$self->[$__dst].'-'.$self->[$__src];
}

sub print {
   my $self = shift;

   my $buf = '';

   my $i = $self->is;
   my $l = $self->layer;
   $buf .= sprintf
      "$l:+$i: version:%d  hlen:%d  tos:0x%02x  length:%d  id:%d\n".
      "$l: $i: flags:0x%02x  offset:%d  ttl:%d  protocol:0x%02x  checksum:0x%04x\n".
      "$l: $i: src:%s  dst:%s",
         $self->[$__version],
         $self->[$__hlen],
         $self->[$__tos],
         $self->[$__length],
         $self->[$__id],
         $self->[$__flags],
         $self->[$__offset],
         $self->[$__ttl],
         $self->[$__protocol],
         $self->[$__checksum],
         $self->[$__src],
         $self->[$__dst];

   if ($self->[$__options]) {
      $buf .= sprintf "\n$l: $i: optionsLength:%d  options:%s",
         $self->getOptionsLength,
         CORE::unpack('H*', $self->[$__options]);
   }

   $buf;
}

#
# Helpers
#

sub _haveFlag  { (shift->flags & shift()) ? 1 : 0            }
sub haveFlagDf { shift->_haveFlag(NP_IPv4_DONT_FRAGMENT)     }
sub haveFlagMf { shift->_haveFlag(NP_IPv4_MORE_FRAGMENT)     }
sub haveFlagRf { shift->_haveFlag(NP_IPv4_RESERVED_FRAGMENT) }

sub _isProtocol      { shift->protocol == shift()                  }
sub isProtocolTcp    { shift->_isProtocol(NP_IPv4_PROTOCOL_TCP)    }
sub isProtocolUdp    { shift->_isProtocol(NP_IPv4_PROTOCOL_UDP)    }
sub isProtocolIcmpv4 { shift->_isProtocol(NP_IPv4_PROTOCOL_ICMPv4) }
sub isProtocolIpv6   { shift->_isProtocol(NP_IPv4_PROTOCOL_IPv6)   }
sub isProtocolOspf   { shift->_isProtocol(NP_IPv4_PROTOCOL_OSPF)   }
sub isProtocolIgmpv4 { shift->_isProtocol(NP_IPv4_PROTOCOL_IGMPv4) }

1;

__END__
   
=head1 NAME

Net::Packet::IPv4 - Internet Protocol v4 layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:ipv4);
   require Net::Packet::IPv4;

   # Build a layer
   my $ip = Net::Packet::IPv4->new(
      flags => NP_IPv4_DONT_FRAGMENT,
      dst   => "192.168.0.1",
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::IPv4->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv4 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc791.txt
      
See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<id>

IP ID of the datagram.

=item B<ttl>

Time to live.

=item B<src>

=item B<dst>

Source and destination IP addresses.

=item B<protocol>

Of which type the layer 4 is.

=item B<checksum>

IP checksum.

=item B<flags>

IP Flags.

=item B<offset>

IP fragment offset.

=item B<version>

IP version, here it is 4.

=item B<tos>

Type of service flag.

=item B<length>

Total length in bytes of the packet, including IP headers (that is, layer 3 + layer 4 + layer 7).

=item B<hlen>

Header length in number of words, including IP options.

=item B<options>

IP options, as a hexadecimal string.

=item B<noFixLen>

Since the byte ordering of B<length> attribute varies from system to system, a subroutine inside this module detects which byte order to use. Sometimes, like when you build B<Net::Packet::VLAN> layers, you may have the need to avoid this. So set it to 1 in order to avoid fixing. Default is 0 (that is to fix).

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

version:  4

tos:      0

id:       getRandom16bitsInt()

length:   NP_IPv4_HDR_LEN

hlen:     5

flags:    0

offset:   0

ttl:      128

protocol: NP_IPv4_PROTOCOL_TCP

checksum: 0

src:      $Env->ip

dst:      "127.0.0.1"

options:  ""

noFixLen:   0

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1
 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<getHeaderLength>

Returns the header length in bytes, not including IP options.

=item B<getPayloadLength>

Returns the length in bytes of encapsulated layers (that is, layer 4 + layer 7).

=item B<getOptionsLength>

Returns the length in bytes of IP options.

=item B<haveFlagDf>

=item B<haveFlagMf>

=item B<haveFlagRf>

Returns 1 if the specified flag is set in B<flags> attribute, 0 otherwise.

=item B<isProtocolTcp>

=item B<isProtocolUdp>

=item B<isProtocolIpv6>

=item B<isProtocolOspf>

=item B<isProtocolIgmpv4>

=item B<isProtocolIcmpv4>

Returns 1 if the specified protocol is used at layer 4, 0 otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:ipv4);

=over 4

=item B<NP_IPv4_PROTOCOL_TCP>

=item B<NP_IPv4_PROTOCOL_UDP>

=item B<NP_IPv4_PROTOCOL_ICMPv4>

=item B<NP_IPv4_PROTOCOL_IPv6>

=item B<NP_IPv4_PROTOCOL_OSPF>

=item B<NP_IPv4_PROTOCOL_IGMPv4>

Various protocol type constants.

=item B<NP_IPv4_MORE_FRAGMENT>

=item B<NP_IPv4_DONT_FRAGMENT>

=item B<NP_IPv4_RESERVED_FRAGMENT>

Various possible flags.

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
