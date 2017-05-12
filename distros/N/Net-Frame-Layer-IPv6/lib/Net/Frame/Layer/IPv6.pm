#
# $Id: IPv6.pm,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
package Net::Frame::Layer::IPv6;
use strict;
use warnings;

our $VERSION = '1.08';

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_IPv6_HDR_LEN
      NF_IPv6_PROTOCOL_ICMPv4
      NF_IPv6_PROTOCOL_IGMP
      NF_IPv6_PROTOCOL_IPIP
      NF_IPv6_PROTOCOL_TCP
      NF_IPv6_PROTOCOL_EGP
      NF_IPv6_PROTOCOL_IGRP
      NF_IPv6_PROTOCOL_CHAOS
      NF_IPv6_PROTOCOL_UDP
      NF_IPv6_PROTOCOL_IDP
      NF_IPv6_PROTOCOL_DCCP
      NF_IPv6_PROTOCOL_IPv6
      NF_IPv6_PROTOCOL_IPv6ROUTING
      NF_IPv6_PROTOCOL_IPv6FRAGMENT
      NF_IPv6_PROTOCOL_IDRP
      NF_IPv6_PROTOCOL_RSVP
      NF_IPv6_PROTOCOL_GRE
      NF_IPv6_PROTOCOL_ESP
      NF_IPv6_PROTOCOL_AH
      NF_IPv6_PROTOCOL_ICMPv6
      NF_IPv6_PROTOCOL_EIGRP
      NF_IPv6_PROTOCOL_OSPF
      NF_IPv6_PROTOCOL_ETHERIP
      NF_IPv6_PROTOCOL_PIM
      NF_IPv6_PROTOCOL_VRRP
      NF_IPv6_PROTOCOL_STP
      NF_IPv6_PROTOCOL_SCTP
      NF_IPv6_PROTOCOL_UDPLITE
      NF_IPv6_PROTOCOL_IPv6HOPBYHOP
      NF_IPv6_PROTOCOL_GGP
      NF_IPv6_PROTOCOL_ST
      NF_IPv6_PROTOCOL_CBT
      NF_IPv6_PROTOCOL_PUP
      NF_IPv6_PROTOCOL_ARGUS
      NF_IPv6_PROTOCOL_EMCON
      NF_IPv6_PROTOCOL_XNET
      NF_IPv6_PROTOCOL_MUX
      NF_IPv6_PROTOCOL_DCNMEAS
      NF_IPv6_PROTOCOL_HMP
      NF_IPv6_PROTOCOL_PRM
      NF_IPv6_PROTOCOL_TRUNK1
      NF_IPv6_PROTOCOL_TRUNK2
      NF_IPv6_PROTOCOL_LEAF1
      NF_IPv6_PROTOCOL_LEAF2
      NF_IPv6_PROTOCOL_3PC
      NF_IPv6_PROTOCOL_IDPR
      NF_IPv6_PROTOCOL_XTP
      NF_IPv6_PROTOCOL_DDP
      NF_IPv6_PROTOCOL_IDPRCMTP
      NF_IPv6_PROTOCOL_TPPLUSPLUS
      NF_IPv6_PROTOCOL_IL
      NF_IPv6_PROTOCOL_SDRP
      NF_IPv6_PROTOCOL_IPv6NONEXT
      NF_IPv6_PROTOCOL_IPv6DESTINATION
      NF_IPv6_PROTOCOL_IPv6MOBILITY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

#
# http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xml
#
use constant NF_IPv6_HDR_LEN               => 40;
use constant NF_IPv6_PROTOCOL_IPv6HOPBYHOP => 0x00;
use constant NF_IPv6_PROTOCOL_ICMPv4       => 0x01;
use constant NF_IPv6_PROTOCOL_IGMP         => 0x02;
use constant NF_IPv6_PROTOCOL_GGP          => 0x03;
use constant NF_IPv6_PROTOCOL_IPIP         => 0x04;
use constant NF_IPv6_PROTOCOL_ST           => 0x05;
use constant NF_IPv6_PROTOCOL_TCP          => 0x06;
use constant NF_IPv6_PROTOCOL_CBT          => 0x07;
use constant NF_IPv6_PROTOCOL_EGP          => 0x08;
use constant NF_IPv6_PROTOCOL_IGRP         => 0x09;
use constant NF_IPv6_PROTOCOL_PUP          => 0x0c;
use constant NF_IPv6_PROTOCOL_ARGUS        => 0x0d;
use constant NF_IPv6_PROTOCOL_EMCON        => 0x0e;
use constant NF_IPv6_PROTOCOL_XNET         => 0x0f;
use constant NF_IPv6_PROTOCOL_CHAOS        => 0x10;
use constant NF_IPv6_PROTOCOL_UDP          => 0x11;
use constant NF_IPv6_PROTOCOL_MUX          => 0x12;
use constant NF_IPv6_PROTOCOL_DCNMEAS      => 0x13;
use constant NF_IPv6_PROTOCOL_HMP          => 0x14;
use constant NF_IPv6_PROTOCOL_PRM          => 0x15;
use constant NF_IPv6_PROTOCOL_IDP          => 0x16;
use constant NF_IPv6_PROTOCOL_TRUNK1       => 0x17;
use constant NF_IPv6_PROTOCOL_TRUNK2       => 0x18;
use constant NF_IPv6_PROTOCOL_LEAF1        => 0x19;
use constant NF_IPv6_PROTOCOL_LEAF2        => 0x20;
use constant NF_IPv6_PROTOCOL_DCCP         => 0x21;
use constant NF_IPv6_PROTOCOL_3PC          => 0x22;
use constant NF_IPv6_PROTOCOL_IDPR         => 0x23;
use constant NF_IPv6_PROTOCOL_XTP          => 0x24;
use constant NF_IPv6_PROTOCOL_DDP          => 0x25;
use constant NF_IPv6_PROTOCOL_IDPRCMTP     => 0x26;
use constant NF_IPv6_PROTOCOL_TPPLUSPLUS   => 0x27;
use constant NF_IPv6_PROTOCOL_IL           => 0x28;
use constant NF_IPv6_PROTOCOL_IPv6         => 0x29;
use constant NF_IPv6_PROTOCOL_SDRP         => 0x2a;
use constant NF_IPv6_PROTOCOL_IPv6ROUTING  => 0x2b;
use constant NF_IPv6_PROTOCOL_IPv6FRAGMENT => 0x2c;
use constant NF_IPv6_PROTOCOL_IDRP         => 0x2d;
use constant NF_IPv6_PROTOCOL_RSVP         => 0x2e;
use constant NF_IPv6_PROTOCOL_GRE          => 0x2f;
use constant NF_IPv6_PROTOCOL_ESP          => 0x32;
use constant NF_IPv6_PROTOCOL_AH           => 0x33;
use constant NF_IPv6_PROTOCOL_ICMPv6       => 0x3a;
use constant NF_IPv6_PROTOCOL_IPv6NONEXT   => 0x3b;
use constant NF_IPv6_PROTOCOL_IPv6DESTINATION => 0x3c;
use constant NF_IPv6_PROTOCOL_EIGRP           => 0x58;
use constant NF_IPv6_PROTOCOL_OSPF            => 0x59;
use constant NF_IPv6_PROTOCOL_ETHERIP         => 0x61;
use constant NF_IPv6_PROTOCOL_PIM             => 0x67;
use constant NF_IPv6_PROTOCOL_VRRP            => 0x70;
use constant NF_IPv6_PROTOCOL_STP             => 0x76;
use constant NF_IPv6_PROTOCOL_SCTP            => 0x84;
use constant NF_IPv6_PROTOCOL_IPv6MOBILITY    => 0x87;
use constant NF_IPv6_PROTOCOL_UDPLITE         => 0x88;

our @AS = qw(
   version
   trafficClass
   flowLabel
   nextHeader
   payloadLength
   hopLimit
   src
   dst
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

BEGIN {
   *protocol = \&nextHeader;
}

no strict 'vars';

use Bit::Vector;

sub new {
   shift->SUPER::new(
      version       => 6,
      trafficClass  => 0,
      flowLabel     => 0,
      nextHeader    => NF_IPv6_PROTOCOL_TCP,
      hopLimit      => 0xff,
      src           => '::1',
      dst           => '::1',
      payloadLength => 0,
      @_,
   );
}

sub getLength { NF_IPv6_HDR_LEN }

sub computeLengths {
   my $self = shift;
   my ($layers) = @_;

   my $len = 0;
   my $last;
   my $start;
   for my $l (@$layers) {
      if (! $start) {
         $start++ if $l->layer eq 'IPv6';
         next;
      }
      $len += $l->getLength;
      $last = $l;
   }
   if (defined($last->payload)) {
      $len += length($last->payload);
   }

   $self->payloadLength($len);

   return 1;
}

sub pack {
   my $self = shift;

   my $version      = Bit::Vector->new_Dec(4,  $self->[$__version]);
   my $trafficClass = Bit::Vector->new_Dec(8,  $self->[$__trafficClass]);
   my $flowLabel    = Bit::Vector->new_Dec(20, $self->[$__flowLabel]);
   my $v32          = $version->Concat_List($trafficClass, $flowLabel);

   $self->[$__raw] = $self->SUPER::pack('NnCCa*a*',
      $v32->to_Dec,
      $self->[$__payloadLength],
      $self->[$__nextHeader],
      $self->[$__hopLimit],
      inet6Aton($self->[$__src]),
      inet6Aton($self->[$__dst]),
   ) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($vTcFl, $pl, $nh, $hl, $sa, $da, $payload) =
      $self->SUPER::unpack('NnCCa16a16 a*', $self->[$__raw])
         or return undef;

   my $v32 = Bit::Vector->new_Dec(32,  $vTcFl);

   $self->[$__flowLabel]     = $v32->Chunk_Read(20,  0);
   $self->[$__trafficClass]  = $v32->Chunk_Read( 8, 20);
   $self->[$__version]       = $v32->Chunk_Read( 4, 28);
   $self->[$__payloadLength] = $pl;
   $self->[$__nextHeader]    = $nh;
   $self->[$__hopLimit]      = $hl;
   $self->[$__src]           = inet6Ntoa($sa);
   $self->[$__dst]           = inet6Ntoa($da);

   $self->[$__payload] = $payload;

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   my $types = {           
      NF_IPv6_PROTOCOL_ICMPv4()       => 'ICMPv4',
      NF_IPv6_PROTOCOL_IGMP()         => 'IGMP',
      NF_IPv6_PROTOCOL_IPIP()         => 'IPv4',
      NF_IPv6_PROTOCOL_TCP()          => 'TCP',
      NF_IPv6_PROTOCOL_EGP()          => 'EGP',
      NF_IPv6_PROTOCOL_IGRP()         => 'IGRP',
      NF_IPv6_PROTOCOL_CHAOS()        => 'CHAOS',
      NF_IPv6_PROTOCOL_UDP()          => 'UDP',
      NF_IPv6_PROTOCOL_IDP()          => 'IDP',
      NF_IPv6_PROTOCOL_DCCP()         => 'DCCP',
      NF_IPv6_PROTOCOL_IPv6()         => 'IPv6',
      NF_IPv6_PROTOCOL_IPv6ROUTING()  => 'IPv6::Routing',
      NF_IPv6_PROTOCOL_IPv6FRAGMENT() => 'IPv6::Fragment',
      NF_IPv6_PROTOCOL_IDRP()         => 'IDRP',
      NF_IPv6_PROTOCOL_RSVP()         => 'RSVP',
      NF_IPv6_PROTOCOL_GRE()          => 'GRE',
      NF_IPv6_PROTOCOL_ESP()          => 'ESP',
      NF_IPv6_PROTOCOL_AH()           => 'AH',
      NF_IPv6_PROTOCOL_ICMPv6()       => 'ICMPv6',
      NF_IPv6_PROTOCOL_EIGRP()        => 'EIGRP',
      NF_IPv6_PROTOCOL_OSPF()         => 'OSPF',
      NF_IPv6_PROTOCOL_ETHERIP()      => 'ETHERIP',
      NF_IPv6_PROTOCOL_PIM()          => 'PIM',
      NF_IPv6_PROTOCOL_VRRP()         => 'VRRP',
      NF_IPv6_PROTOCOL_STP()          => 'STP',
      NF_IPv6_PROTOCOL_SCTP()         => 'SCTP',
      NF_IPv6_PROTOCOL_UDPLITE()      => 'UDPLite',
      NF_IPv6_PROTOCOL_IPv6DESTINATION() => 'IPv6::Destination',
      NF_IPv6_PROTOCOL_IPv6MOBILITY()    => 'IPv6::Mobility',
      NF_IPv6_PROTOCOL_IPv6HOPBYHOP()    => 'IPv6::HopByHop',
      NF_IPv6_PROTOCOL_GGP()             => 'GGP',
      NF_IPv6_PROTOCOL_ST()              => 'ST',
      NF_IPv6_PROTOCOL_CBT()             => 'CBT',
      NF_IPv6_PROTOCOL_PUP()             => 'PUP',
      NF_IPv6_PROTOCOL_ARGUS()           => 'ARGUS',
      NF_IPv6_PROTOCOL_EMCON()           => 'EMCON',
      NF_IPv6_PROTOCOL_XNET()            => 'XNET',
      NF_IPv6_PROTOCOL_MUX()             => 'MUX',
      NF_IPv6_PROTOCOL_DCNMEAS()         => 'DCNMEAS',
      NF_IPv6_PROTOCOL_HMP()             => 'HMP',
      NF_IPv6_PROTOCOL_PRM()             => 'PRM',
      NF_IPv6_PROTOCOL_TRUNK1()          => 'TRUNK1',
      NF_IPv6_PROTOCOL_TRUNK2()          => 'TRUNK2',
      NF_IPv6_PROTOCOL_LEAF1()           => 'LEAF1',
      NF_IPv6_PROTOCOL_LEAF2()           => 'LEAF2',
      NF_IPv6_PROTOCOL_3PC()             => '3PC',
      NF_IPv6_PROTOCOL_IDPR()            => 'IDPR',
      NF_IPv6_PROTOCOL_XTP()             => 'XTP',
      NF_IPv6_PROTOCOL_DDP()             => 'DDP',
      NF_IPv6_PROTOCOL_IDPRCMTP()        => 'IDPRCMTP',
      NF_IPv6_PROTOCOL_TPPLUSPLUS()      => 'TPPlusPlus',
      NF_IPv6_PROTOCOL_IL()              => 'IL',
      NF_IPv6_PROTOCOL_SDRP()            => 'SDRP',
      NF_IPv6_PROTOCOL_IPv6NONEXT()      => 'IPv6::NoNext',
   };

   $types->{$self->[$__nextHeader]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;       

   my $l = $self->layer;    
   sprintf
      "$l: version:%d  trafficClass:0x%02x  flowLabel:0x%05x  ".
      "nextHeader:0x%02x\n".
      "$l: payloadLength:%d  hopLimit:%d\n".
      "$l: src:%s  dst:%s",
         $self->[$__version], $self->[$__trafficClass], $self->[$__flowLabel],
         $self->[$__nextHeader], $self->[$__payloadLength],
         $self->[$__hopLimit], $self->[$__src], $self->[$__dst];
}

1;

=head1 NAME

Net::Frame::Layer::IPv6 - Internet Protocol v6 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::IPv6 qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::IPv6->new(
      version       => 6,
      trafficClass  => 0,
      flowLabel     => 0,
      nextHeader    => NF_IPv6_PROTOCOL_TCP,
      hopLimit      => 0xff,
      src           => '::1',
      dst           => '::1',
      payloadLength => 0,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::IPv6->new(raw = $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv6 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2460.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version> - 4 bits

Version of Internet Protocol header.

=item B<trafficClass> - 8 bits

Traffic class field. Was Type of Service in IPv4.

=item B<flowLabel> - 20 bits

Flow label class field. Was IP ID in IPv4.

=item B<nextHeader> - 8 bits

The type of next header. Was protocol in IPv4.

=item B<protocol>

Is an alias for B<nextHeader>.

=item B<payloadLength> - 16 bits

Length in bytes of encapsulated layers (usually, that is layer 4 + layer 7).

=item B<hopLimit> - 8 bits

Was TTL field in IPv4.

=item B<src> - 32 bits

=item B<dst> - 32 bits

Source and destination addresses.

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

=item B<computeLengths> ({ payloadLength => VALUE })

In order to compute lengths attributes within IPv6 header, you need to pass via a hashref the number of bytes contained in IPv6 payload (that is, the sum of all layers after the IPv6 one).

=back

The following are inherited methods. Some of them may be overridden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::IPv6 qw(:consts);

=over 4

=item B<NF_IPv6_PROTOCOL_ICMPv4>

=item B<NF_IPv6_PROTOCOL_IGMP>

=item B<NF_IPv6_PROTOCOL_IPIP>

=item B<NF_IPv6_PROTOCOL_TCP>

=item B<NF_IPv6_PROTOCOL_EGP>

=item B<NF_IPv6_PROTOCOL_IGRP>

=item B<NF_IPv6_PROTOCOL_CHAOS>

=item B<NF_IPv6_PROTOCOL_UDP>

=item B<NF_IPv6_PROTOCOL_IDP>

=item B<NF_IPv6_PROTOCOL_DCCP>

=item B<NF_IPv6_PROTOCOL_IPv6>

=item B<NF_IPv6_PROTOCOL_IPv6ROUTING>

=item B<NF_IPv6_PROTOCOL_IPv6FRAGMENT>

=item B<NF_IPv6_PROTOCOL_IDRP>

=item B<NF_IPv6_PROTOCOL_RSVP>

=item B<NF_IPv6_PROTOCOL_GRE>

=item B<NF_IPv6_PROTOCOL_ESP>

=item B<NF_IPv6_PROTOCOL_AH>

=item B<NF_IPv6_PROTOCOL_ICMPv6>

=item B<NF_IPv6_PROTOCOL_EIGRP>

=item B<NF_IPv6_PROTOCOL_OSPF>

=item B<NF_IPv6_PROTOCOL_ETHERIP>

=item B<NF_IPv6_PROTOCOL_PIM>

=item B<NF_IPv6_PROTOCOL_VRRP>

=item B<NF_IPv6_PROTOCOL_STP>

=item B<NF_IPv6_PROTOCOL_SCTP>

=item B<NF_IPv6_PROTOCOL_UDPLITE>

=item B<NF_IPv6_PROTOCOL_IPv6HOPBYHOP>

=item B<NF_IPv6_PROTOCOL_GGP>

=item B<NF_IPv6_PROTOCOL_ST>

=item B<NF_IPv6_PROTOCOL_CBT>

=item B<NF_IPv6_PROTOCOL_PUP>

=item B<NF_IPv6_PROTOCOL_ARGUS>

=item B<NF_IPv6_PROTOCOL_EMCON>

=item B<NF_IPv6_PROTOCOL_XNET>

=item B<NF_IPv6_PROTOCOL_MUX>

=item B<NF_IPv6_PROTOCOL_DCNMEAS>

=item B<NF_IPv6_PROTOCOL_HMP>

=item B<NF_IPv6_PROTOCOL_PRM>

=item B<NF_IPv6_PROTOCOL_TRUNK1>

=item B<NF_IPv6_PROTOCOL_TRUNK2>

=item B<NF_IPv6_PROTOCOL_LEAF1>

=item B<NF_IPv6_PROTOCOL_LEAF2>

=item B<NF_IPv6_PROTOCOL_3PC>

=item B<NF_IPv6_PROTOCOL_IDPR>

=item B<NF_IPv6_PROTOCOL_XTP>

=item B<NF_IPv6_PROTOCOL_DDP>

=item B<NF_IPv6_PROTOCOL_IDPRCMTP>

=item B<NF_IPv6_PROTOCOL_TPPLUSPLUS>

=item B<NF_IPv6_PROTOCOL_IL>

=item B<NF_IPv6_PROTOCOL_SDRP>

=item B<NF_IPv6_PROTOCOL_IPv6NONEXT>

=item B<NF_IPv6_PROTOCOL_IPv6DESTINATION>

=item B<NF_IPv6_PROTOCOL_IPv6MOBILITY>

Constants for B<nextHeader> attribute.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
