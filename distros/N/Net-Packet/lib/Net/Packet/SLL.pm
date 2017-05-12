#
# $Id: SLL.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::SLL;
use strict;
use warnings;

require Net::Packet::Layer2;
our @ISA = qw(Net::Packet::Layer2);

use Net::Packet::Consts qw(:sll :layer);

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
      packetType    => NP_SLL_PACKET_TYPE_SENT_BY_US,
      addressType   => NP_SLL_ADDRESS_TYPE_512,
      addressLength => 0,
      source        => 0,
      protocol      => NP_SLL_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NP_SLL_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('nnnH16n',
      $self->[$__packetType],
      $self->[$__addressType],
      $self->[$__addressLength],
      $self->[$__source],
      $self->[$__protocol],
   ) or return undef;

   1;
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

   1;
}

sub encapsulate {
   my $types = {
      NP_SLL_PROTOCOL_IPv4() => NP_LAYER_IPv4(),
      NP_SLL_PROTOCOL_IPv6() => NP_LAYER_IPv6(),
      NP_SLL_PROTOCOL_ARP()  => NP_LAYER_ARP(),
      NP_SLL_PROTOCOL_VLAN() => NP_LAYER_VLAN(),
   };

   $types->{shift->[$__protocol]} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: packetType:0x%04x  addressType:0x%04x  ".
           "addressLength:0x%04x\n".
           "$l: $i: source:%d  protocol:0x%04x",
      $self->[$__packetType], $self->[$__addressType],
      $self->[$__addressLength], $self->[$__source], $self->[$__protocol];
}

#
# Helpers
#

sub _isProtocol    { shift->[$__protocol] == shift()          }
sub isProtocolIpv4 { shift->_isProtocol(NP_SLL_PROTOCOL_IPv4) }
sub isProtocolIpv6 { shift->_isProtocol(NP_SLL_PROTOCOL_IPv6) }
sub isProtocolIp   {
   my $self = shift; $self->isProtocolIpv4 || $self->isProtocolIpv6;
}

1;

__END__

=head1 NAME

Net::Packet::SLL - Linux cooked capture layer 2 object

=head1 SYNOPSIS

   #
   # Usually, you do not use this module directly
   #
   use Net::Packet::Consts qw(:sll);
   require Net::Packet::SLL;

   # Build a layer
   my $layer = Net::Packet::SLL->new;
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::SLL->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Linux cooked capture layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer2> for other attributes and methods.

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

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

packetType:    NP_SLL_PACKET_TYPE_SENT_BY_US

addressType:   NP_SLL_ADDRESS_TYPE_512

addressLength: 0

source:        0

protocol:      NP_SLL_PROTOCOL_IPv4

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<isProtocolIpv4>

=item B<isProtocolIpv6>

=item B<isProtocolIp> - is type IPv4 or IPv6

Helper methods. Return true is the encapsulated layer is of specified type, false otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:sll);

=over 4

=item B<NP_SLL_PACKET_TYPE_SENT_BY_US>

=item B<NP_SLL_PACKET_TYPE_UNICAST_TO_US>

Various possible packet types.

=item B<NP_SLL_PROTOCOL_IPv4>

=item B<NP_SLL_PROTOCOL_IPv6>

=item B<NP_SLL_PROTOCOL_ARP>

=item B<NP_SLL_PROTOCOL_VLAN>

Various supported encapsulated layer types.

=item B<NP_SLL_HDR_LEN>

=item B<NP_SLL_ADDRESS_TYPE_512>

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
