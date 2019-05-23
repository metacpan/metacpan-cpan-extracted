#
# $Id: SLL.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::SLL;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_SLL_HDR_LEN
      NF_SLL_PACKET_TYPE_SENT_BY_US
      NF_SLL_PACKET_TYPE_UNICAST_TO_US
      NF_SLL_ADDRESS_TYPE_512
      NF_SLL_PROTOCOL_IPv4
      NF_SLL_PROTOCOL_X25
      NF_SLL_PROTOCOL_ARP
      NF_SLL_PROTOCOL_CGMP
      NF_SLL_PROTOCOL_80211
      NF_SLL_PROTOCOL_PPPIPCP
      NF_SLL_PROTOCOL_RARP
      NF_SLL_PROTOCOL_DDP
      NF_SLL_PROTOCOL_AARP
      NF_SLL_PROTOCOL_PPPCCP
      NF_SLL_PROTOCOL_WCP
      NF_SLL_PROTOCOL_8021Q
      NF_SLL_PROTOCOL_IPX
      NF_SLL_PROTOCOL_STP
      NF_SLL_PROTOCOL_IPv6
      NF_SLL_PROTOCOL_WLCCP
      NF_SLL_PROTOCOL_MPLS
      NF_SLL_PROTOCOL_PPPoED
      NF_SLL_PROTOCOL_PPPoES
      NF_SLL_PROTOCOL_8021X
      NF_SLL_PROTOCOL_AoE
      NF_SLL_PROTOCOL_80211I
      NF_SLL_PROTOCOL_LLDP
      NF_SLL_PROTOCOL_LLTD
      NF_SLL_PROTOCOL_LOOP
      NF_SLL_PROTOCOL_VLAN
      NF_SLL_PROTOCOL_PPPPAP
      NF_SLL_PROTOCOL_PPPCHAP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_SLL_HDR_LEN                   => 16;
use constant NF_SLL_PACKET_TYPE_SENT_BY_US    => 4;
use constant NF_SLL_PACKET_TYPE_UNICAST_TO_US => 0;
use constant NF_SLL_ADDRESS_TYPE_512          => 512;
use constant NF_SLL_PROTOCOL_IPv4      => 0x0800;
use constant NF_SLL_PROTOCOL_X25       => 0x0805;
use constant NF_SLL_PROTOCOL_ARP       => 0x0806;
use constant NF_SLL_PROTOCOL_CGMP      => 0x2001;
use constant NF_SLL_PROTOCOL_80211     => 0x2452;
use constant NF_SLL_PROTOCOL_PPPIPCP   => 0x8021;
use constant NF_SLL_PROTOCOL_RARP      => 0x8035;
use constant NF_SLL_PROTOCOL_DDP       => 0x809b;
use constant NF_SLL_PROTOCOL_AARP      => 0x80f3;
use constant NF_SLL_PROTOCOL_PPPCCP    => 0x80fd;
use constant NF_SLL_PROTOCOL_WCP       => 0x80ff;
use constant NF_SLL_PROTOCOL_8021Q     => 0x8100;
use constant NF_SLL_PROTOCOL_IPX       => 0x8137;
use constant NF_SLL_PROTOCOL_STP       => 0x8181;
use constant NF_SLL_PROTOCOL_IPv6      => 0x86dd;
use constant NF_SLL_PROTOCOL_WLCCP     => 0x872d;
use constant NF_SLL_PROTOCOL_MPLS      => 0x8847;
use constant NF_SLL_PROTOCOL_PPPoED    => 0x8863;
use constant NF_SLL_PROTOCOL_PPPoES    => 0x8864;
use constant NF_SLL_PROTOCOL_8021X     => 0x888e;
use constant NF_SLL_PROTOCOL_AoE       => 0x88a2;
use constant NF_SLL_PROTOCOL_80211I    => 0x88c7;
use constant NF_SLL_PROTOCOL_LLDP      => 0x88cc;
use constant NF_SLL_PROTOCOL_LLTD      => 0x88d9;
use constant NF_SLL_PROTOCOL_LOOP      => 0x9000;
use constant NF_SLL_PROTOCOL_VLAN      => 0x9100;
use constant NF_SLL_PROTOCOL_PPPPAP    => 0xc023;
use constant NF_SLL_PROTOCOL_PPPCHAP   => 0xc223;

our @AS = qw(
   packetType
   addressType
   addressLength
   source
   protocol
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      packetType    => NF_SLL_PACKET_TYPE_SENT_BY_US,
      addressType   => NF_SLL_ADDRESS_TYPE_512,
      addressLength => 0,
      source        => 0,
      protocol      => NF_SLL_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NF_SLL_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('nnnH16n',
      $self->[$__packetType],
      $self->[$__addressType],
      $self->[$__addressLength],
      $self->[$__source],
      $self->[$__protocol],
   ) or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($pt, $at, $al, $s, $p, $payload) =
      $self->SUPER::unpack('nnnH16n a*', $self->[$__raw])
         or return undef;

   $self->[$__packetType]    = $pt;
   $self->[$__addressType]   = $at;
   $self->[$__addressLength] = $al;
   $self->[$__source]        = $s;
   $self->[$__protocol]      = $p;
   $self->[$__payload]       = $payload;

   $self;
}

our $Next = {
   NF_SLL_PROTOCOL_IPv4()    => 'IPv4',
   NF_SLL_PROTOCOL_X25()     => 'X25',
   NF_SLL_PROTOCOL_ARP()     => 'ARP',
   NF_SLL_PROTOCOL_CGMP()    => 'CGMP',
   NF_SLL_PROTOCOL_80211()   => '80211',
   NF_SLL_PROTOCOL_PPPIPCP() => 'PPPIPCP',
   NF_SLL_PROTOCOL_RARP()    => 'RARP',
   NF_SLL_PROTOCOL_DDP ()    => 'DDP',
   NF_SLL_PROTOCOL_AARP()    => 'AARP',
   NF_SLL_PROTOCOL_PPPCCP()  => 'PPPCCP',
   NF_SLL_PROTOCOL_WCP()     => 'WCP',
   NF_SLL_PROTOCOL_8021Q()   => '8021Q',
   NF_SLL_PROTOCOL_IPX()     => 'IPX',
   NF_SLL_PROTOCOL_STP()     => 'STP',
   NF_SLL_PROTOCOL_IPv6()    => 'IPv6',
   NF_SLL_PROTOCOL_WLCCP()   => 'WLCCP',
   NF_SLL_PROTOCOL_MPLS()    => 'MPLS',
   NF_SLL_PROTOCOL_PPPoED()  => 'PPPoED',
   NF_SLL_PROTOCOL_PPPoES()  => 'PPPoES',
   NF_SLL_PROTOCOL_8021X()   => '8021X',
   NF_SLL_PROTOCOL_AoE()     => 'AoE',
   NF_SLL_PROTOCOL_80211I()  => '80211I',
   NF_SLL_PROTOCOL_LLDP()    => 'LLDP',
   NF_SLL_PROTOCOL_LLTD()    => 'LLTD',
   NF_SLL_PROTOCOL_LOOP()    => 'LOOP',
   NF_SLL_PROTOCOL_VLAN()    => 'VLAN',
   NF_SLL_PROTOCOL_PPPPAP()  => 'PPPPAP',
   NF_SLL_PROTOCOL_PPPCHAP() => 'PPPCHAP',
};

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   return $Next->{$self->[$__protocol]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: packetType:0x%04x  addressType:0x%04x  ".
           "addressLength:0x%04x\n".
           "$l: source:%d  protocol:0x%04x",
      $self->[$__packetType], $self->[$__addressType],
      $self->[$__addressLength], $self->[$__source], $self->[$__protocol];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::SLL - Linux cooked capture layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::SLL qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::SLL->new(
      packetType    => NF_SLL_PACKET_TYPE_SENT_BY_US,
      addressType   => NF_SLL_ADDRESS_TYPE_512,
      addressLength => 0,
      source        => 0,
      protocol      => NF_SLL_PROTOCOL_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::SLL->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Linux cooked capture layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<packetType>

Stores the packet type (unicast to us, sent by us ...).

=item B<addressType>

The address type.

=item B<addressLength>

The length of the previously specified address.

=item B<source>

Source address.

=item B<protocol>

Encapsulated protocol.

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

Load them: use Net::Frame::Layer::SLL qw(:consts);

=over 4

=item B<NF_SLL_PACKET_TYPE_SENT_BY_US>

=item B<NF_SLL_PACKET_TYPE_UNICAST_TO_US>

Various possible packet types.

=item B<NF_SLL_PROTOCOL_IPv4>

=item B<NF_SLL_PROTOCOL_X25>

=item B<NF_SLL_PROTOCOL_ARP>

=item B<NF_SLL_PROTOCOL_CGMP>

=item B<NF_SLL_PROTOCOL_80211>

=item B<NF_SLL_PROTOCOL_PPPIPCP>

=item B<NF_SLL_PROTOCOL_RARP>

=item B<NF_SLL_PROTOCOL_DDP>

=item B<NF_SLL_PROTOCOL_AARP>

=item B<NF_SLL_PROTOCOL_PPPCCP>

=item B<NF_SLL_PROTOCOL_WCP>

=item B<NF_SLL_PROTOCOL_8021Q>

=item B<NF_SLL_PROTOCOL_IPX>

=item B<NF_SLL_PROTOCOL_STP>

=item B<NF_SLL_PROTOCOL_IPv6>

=item B<NF_SLL_PROTOCOL_WLCCP>

=item B<NF_SLL_PROTOCOL_MPLS>

=item B<NF_SLL_PROTOCOL_PPPoED>

=item B<NF_SLL_PROTOCOL_PPPoES>

=item B<NF_SLL_PROTOCOL_8021X>

=item B<NF_SLL_PROTOCOL_AoE>

=item B<NF_SLL_PROTOCOL_80211I>

=item B<NF_SLL_PROTOCOL_LLDP>

=item B<NF_SLL_PROTOCOL_LLTD>

=item B<NF_SLL_PROTOCOL_LOOP>

=item B<NF_SLL_PROTOCOL_VLAN>

=item B<NF_SLL_PROTOCOL_PPPPAP>

=item B<NF_SLL_PROTOCOL_PPPCHAP>

Various supported encapsulated layer types.

=item B<NF_SLL_ADDRESS_TYPE_512>

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
