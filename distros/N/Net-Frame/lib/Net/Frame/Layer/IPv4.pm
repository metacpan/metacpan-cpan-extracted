#
# $Id: IPv4.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::IPv4;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_IPv4_HDR_LEN
      NF_IPv4_PROTOCOL_ICMPv4
      NF_IPv4_PROTOCOL_IGMP
      NF_IPv4_PROTOCOL_IPIP
      NF_IPv4_PROTOCOL_TCP
      NF_IPv4_PROTOCOL_EGP
      NF_IPv4_PROTOCOL_IGRP
      NF_IPv4_PROTOCOL_CHAOS
      NF_IPv4_PROTOCOL_UDP
      NF_IPv4_PROTOCOL_IDP
      NF_IPv4_PROTOCOL_DCCP
      NF_IPv4_PROTOCOL_IPv6
      NF_IPv4_PROTOCOL_IPv6ROUTING
      NF_IPv4_PROTOCOL_IPv6FRAGMENT
      NF_IPv4_PROTOCOL_IDRP
      NF_IPv4_PROTOCOL_RSVP
      NF_IPv4_PROTOCOL_GRE
      NF_IPv4_PROTOCOL_ESP
      NF_IPv4_PROTOCOL_AH
      NF_IPv4_PROTOCOL_ICMPv6
      NF_IPv4_PROTOCOL_EIGRP
      NF_IPv4_PROTOCOL_OSPF
      NF_IPv4_PROTOCOL_ETHERIP
      NF_IPv4_PROTOCOL_PIM
      NF_IPv4_PROTOCOL_VRRP
      NF_IPv4_PROTOCOL_STP
      NF_IPv4_PROTOCOL_SCTP
      NF_IPv4_PROTOCOL_UDPLITE
      NF_IPv4_MORE_FRAGMENT
      NF_IPv4_DONT_FRAGMENT
      NF_IPv4_RESERVED_FRAGMENT
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_IPv4_HDR_LEN           => 20;
use constant NF_IPv4_PROTOCOL_ICMPv4       => 0x01;
use constant NF_IPv4_PROTOCOL_IGMP         => 0x02;
use constant NF_IPv4_PROTOCOL_IPIP         => 0x04;
use constant NF_IPv4_PROTOCOL_TCP          => 0x06;
use constant NF_IPv4_PROTOCOL_EGP          => 0x08;
use constant NF_IPv4_PROTOCOL_IGRP         => 0x09;
use constant NF_IPv4_PROTOCOL_CHAOS        => 0x10;
use constant NF_IPv4_PROTOCOL_UDP          => 0x11;
use constant NF_IPv4_PROTOCOL_IDP          => 0x16;
use constant NF_IPv4_PROTOCOL_DCCP         => 0x21;
use constant NF_IPv4_PROTOCOL_IPv6         => 0x29;
use constant NF_IPv4_PROTOCOL_IPv6ROUTING  => 0x2b;
use constant NF_IPv4_PROTOCOL_IPv6FRAGMENT => 0x2c;
use constant NF_IPv4_PROTOCOL_IDRP         => 0x2d;
use constant NF_IPv4_PROTOCOL_RSVP         => 0x2e;
use constant NF_IPv4_PROTOCOL_GRE          => 0x2f;
use constant NF_IPv4_PROTOCOL_ESP          => 0x32;
use constant NF_IPv4_PROTOCOL_AH           => 0x33;
use constant NF_IPv4_PROTOCOL_ICMPv6       => 0x3a;
use constant NF_IPv4_PROTOCOL_EIGRP        => 0x58;
use constant NF_IPv4_PROTOCOL_OSPF         => 0x59;
use constant NF_IPv4_PROTOCOL_ETHERIP      => 0x61;
use constant NF_IPv4_PROTOCOL_PIM          => 0x67;
use constant NF_IPv4_PROTOCOL_VRRP         => 0x70;
use constant NF_IPv4_PROTOCOL_STP          => 0x76;
use constant NF_IPv4_PROTOCOL_SCTP         => 0x84;
use constant NF_IPv4_PROTOCOL_UDPLITE      => 0x88;
use constant NF_IPv4_MORE_FRAGMENT     => 1;
use constant NF_IPv4_DONT_FRAGMENT     => 2;
use constant NF_IPv4_RESERVED_FRAGMENT => 4;

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

BEGIN {
   my $osname = {
      freebsd => [ \&_fixLenBsd, ],
      netbsd  => [ \&_fixLenBsd, ],
      openbsd => [ \&_fixLenBsd, ],
      darwin  => [ \&_fixLenBsd, ],
   };

   *_fixLen = $osname->{$^O}->[0] || \&_fixLenOther;
}

no strict 'vars';

use Carp;
use Bit::Vector;

sub _fixLenBsd   { pack('v', shift) }
sub _fixLenOther { pack('n', shift) }

sub new {
   shift->SUPER::new(
      version  => 4,
      tos      => 0,
      id       => getRandom16bitsInt(),
      length   => NF_IPv4_HDR_LEN,
      hlen     => 5,
      flags    => 0,
      offset   => 0,
      ttl      => 128,
      protocol => NF_IPv4_PROTOCOL_TCP,
      checksum => 0,
      src      => '127.0.0.1',
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

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($verHlen, $tos, $len, $id, $flagsOffset, $ttl, $proto, $cksum, $src,
      $dst, $payload) = $self->SUPER::unpack('CCnnnCCna4a4 a*', $self->[$__raw])
         or return undef;

   my $v8  = Bit::Vector->new_Dec(8,  $verHlen);
   my $v16 = Bit::Vector->new_Dec(16, $flagsOffset); 

   # Here, we unpack in this order: hlen, version (4 bits each)
   $self->[$__hlen]     = $v8->Chunk_Read(4, 0);
   $self->[$__version]  = $v8->Chunk_Read(4, 4);
   $self->[$__tos]      = $tos;
   $self->[$__length]   = $len;
   $self->[$__id]       = $id;
   # Here, we unpack in this order: offset (13 bits), flags (3 bits)
   $self->[$__offset]   = $v16->Chunk_Read(13,  0);
   $self->[$__flags]    = $v16->Chunk_Read( 3, 13);
   $self->[$__ttl]      = $ttl;
   $self->[$__protocol] = $proto;
   $self->[$__checksum] = $cksum;
   $self->[$__src]      = inetNtoa($src);
   $self->[$__dst]      = inetNtoa($dst);
   $self->[$__payload]  = $payload;

   my ($options, $payload2) = $self->SUPER::unpack(
      'a'. $self->getOptionsLength. 'a*', $self->[$__payload]
   ) or return undef;

   $self->[$__options] = $options;
   $self->[$__payload] = $payload2;

   $self;
}

sub getLength {
   my $self = shift;
   $self->[$__hlen] > 0 ? $self->[$__hlen] * 4 : 0;
}

sub getPayloadLength {
   my $self = shift;
   my $gLen = $self->getLength;
   $self->[$__length] > $gLen ? $self->[$__length] - $gLen : 0;
}

sub getOptionsLength {
   my $self = shift;
   my $gLen = $self->getLength;
   my $hLen = NF_IPv4_HDR_LEN;
   $gLen > $hLen ? $gLen - $hLen : 0;
}

sub computeLengths {
   my $self = shift;
   my ($layers) = @_;

   my $hLen = NF_IPv4_HDR_LEN;
   $hLen   += length($self->[$__options]) if $self->[$__options];
   $self->[$__hlen] = $hLen / 4;

   my $len = $hLen;
   my $last;
   my $start;
   for my $l (@$layers) {
      if (! $start) {
         $start++ if $l->layer eq 'IPv4';
         next;
      }
      $len += $l->getLength;
      $last = $l;
   }
   if (defined($last->payload)) {
      $len += length($last->payload);
   }

   $self->length($len);

   return 1;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   # Reset the checksum if already filled by a previous pack
   if ($self->[$__checksum]) {
      $self->[$__checksum] = 0;
   }

   $self->[$__checksum] = inetChecksum($self->pack);

   return 1;
}

our $Next = {
   NF_IPv4_PROTOCOL_ICMPv4()       => 'ICMPv4',
   NF_IPv4_PROTOCOL_IGMP()         => 'IGMP',
   NF_IPv4_PROTOCOL_IPIP()         => 'IPv4',
   NF_IPv4_PROTOCOL_TCP()          => 'TCP',
   NF_IPv4_PROTOCOL_EGP()          => 'EGP',
   NF_IPv4_PROTOCOL_IGRP()         => 'IGRP',
   NF_IPv4_PROTOCOL_CHAOS()        => 'CHAOS',
   NF_IPv4_PROTOCOL_UDP()          => 'UDP',
   NF_IPv4_PROTOCOL_IDP()          => 'IDP',
   NF_IPv4_PROTOCOL_DCCP()         => 'DCCP',
   NF_IPv4_PROTOCOL_IPv6()         => 'IPv6',
   NF_IPv4_PROTOCOL_IPv6ROUTING()  => 'IPv6Routing',
   NF_IPv4_PROTOCOL_IPv6FRAGMENT() => 'IPv6Fragment',
   NF_IPv4_PROTOCOL_IDRP()         => 'IDRP',
   NF_IPv4_PROTOCOL_RSVP()         => 'RSVP',
   NF_IPv4_PROTOCOL_GRE()          => 'GRE',
   NF_IPv4_PROTOCOL_ESP()          => 'ESP',
   NF_IPv4_PROTOCOL_AH()           => 'AH',
   NF_IPv4_PROTOCOL_ICMPv6()       => 'ICMPv6',
   NF_IPv4_PROTOCOL_EIGRP()        => 'EIGRP',
   NF_IPv4_PROTOCOL_OSPF()         => 'OSPF',
   NF_IPv4_PROTOCOL_ETHERIP()      => 'ETHERIP',
   NF_IPv4_PROTOCOL_PIM()          => 'PIM',
   NF_IPv4_PROTOCOL_VRRP()         => 'VRRP',
   NF_IPv4_PROTOCOL_STP()          => 'STP',
   NF_IPv4_PROTOCOL_SCTP()         => 'SCTP',
   NF_IPv4_PROTOCOL_UDPLITE()      => 'UDPLite',
};

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   return $Next->{$self->[$__protocol]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  hlen:%d  tos:0x%02x  length:%d  id:%d\n".
      "$l: flags:0x%02x  offset:%d  ttl:%d  protocol:0x%02x  checksum:0x%04x\n".
      "$l: src:%s  dst:%s",
         $self->[$__version], $self->[$__hlen], $self->[$__tos],
         $self->[$__length], $self->[$__id], $self->[$__flags],
         $self->[$__offset], $self->[$__ttl], $self->[$__protocol],
         $self->[$__checksum], $self->[$__src], $self->[$__dst];

   if ($self->[$__options]) {
      $buf .= sprintf "\n$l: optionsLength:%d  options:%s",
         $self->getOptionsLength,
         CORE::unpack('H*', $self->[$__options]);
   }

   $buf;
}

1;

__END__
   
=head1 NAME

Net::Frame::Layer::IPv4 - Internet Protocol v4 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::IPv4 qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::IPv4->new(
      version  => 4,
      tos      => 0,
      id       => getRandom16bitsInt(),
      length   => NF_IPv4_HDR_LEN,
      hlen     => 5,
      flags    => 0,
      offset   => 0,
      ttl      => 128,
      protocol => NF_IPv4_PROTOCOL_TCP,
      checksum => 0,
      src      => '127.0.0.1',
      dst      => '127.0.0.1',
      options  => '',
      noFixLen => 0,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::IPv4->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv4 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc791.txt
      
See also B<Net::Frame::Layer> for other attributes and methods.

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

Since the byte ordering of B<length> attribute varies from system to system, a subroutine inside this module detects which byte order to use. Sometimes, like when you build B<Net::Frame::Layer::8021Q> layers, you may have the need to avoid this. So set it to 1 in order to avoid fixing. Default is 0 (that is to fix).

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=item B<getHeaderLength>

Returns the header length in bytes, not including IP options.

=item B<getOptionsLength>

Returns the length in bytes of IP options. 0 if none.

=item B<computeLengths> ({ payloadLength => VALUE })

In order to compute lengths attributes within IPv4 header, you need to pass via a hashref the number of bytes contained in IPv4 payload (that is, the sum of all layers after the IPv4 one).

=item B<computeChecksums>

Computes the IPv4 checksum.

=back

The following are inherited methods. Some of them may be overridden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<computeChecksums>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::IPv4 qw(:consts);

=over 4

=item B<NF_IPv4_PROTOCOL_ICMPv4>

=item B<NF_IPv4_PROTOCOL_IGMP>

=item B<NF_IPv4_PROTOCOL_IPIP>

=item B<NF_IPv4_PROTOCOL_TCP>

=item B<NF_IPv4_PROTOCOL_EGP>

=item B<NF_IPv4_PROTOCOL_IGRP>

=item B<NF_IPv4_PROTOCOL_CHAOS>

=item B<NF_IPv4_PROTOCOL_UDP>

=item B<NF_IPv4_PROTOCOL_IDP>

=item B<NF_IPv4_PROTOCOL_DCCP>

=item B<NF_IPv4_PROTOCOL_IPv6>

=item B<NF_IPv4_PROTOCOL_IPv6ROUTING>

=item B<NF_IPv4_PROTOCOL_IPv6FRAGMENT>

=item B<NF_IPv4_PROTOCOL_IDRP>

=item B<NF_IPv4_PROTOCOL_RSVP>

=item B<NF_IPv4_PROTOCOL_GRE>

=item B<NF_IPv4_PROTOCOL_ESP>

=item B<NF_IPv4_PROTOCOL_AH>

=item B<NF_IPv4_PROTOCOL_ICMPv6>

=item B<NF_IPv4_PROTOCOL_EIGRP>

=item B<NF_IPv4_PROTOCOL_OSPF>

=item B<NF_IPv4_PROTOCOL_ETHERIP>

=item B<NF_IPv4_PROTOCOL_PIM>

=item B<NF_IPv4_PROTOCOL_VRRP>

=item B<NF_IPv4_PROTOCOL_STP>

=item B<NF_IPv4_PROTOCOL_SCTP>

=item B<NF_IPv4_PROTOCOL_UDPLITE>

Various protocol type constants.

=item B<NF_IPv4_MORE_FRAGMENT>

=item B<NF_IPv4_DONT_FRAGMENT>

=item B<NF_IPv4_RESERVED_FRAGMENT>

Various possible flags.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR
   
Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret
      
You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
