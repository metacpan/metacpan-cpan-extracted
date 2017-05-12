#
# $Id: VLAN.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::VLAN;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Net::Packet::Env qw($Env);
use Net::Packet::Consts qw(:vlan :layer);
require Net::Packet::Frame;
require Bit::Vector;

our @AS = qw(
   priority
   cfi
   id
   type
   frame
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      priority => 0,
      cfi      => 0,
      id       => 0,
      type     => NP_VLAN_TYPE_IPv4,
      @_,
   );
}

sub getLength {
   my $self = shift;
   # Keep old behaviour for backward compat
   if (! $Env->doFrameReturnList) {
      my $frame = $self->[$__frame];
      return(length($frame->raw) + NP_VLAN_HDR_LEN) if $frame;
   }
   NP_VLAN_HDR_LEN;
}

sub pack {
   my $self = shift;

   my $v3  = Bit::Vector->new_Dec(3,  $self->[$__priority]);
   my $v1  = Bit::Vector->new_Dec(1,  $self->[$__cfi]);
   my $v12 = Bit::Vector->new_Dec(12, $self->[$__id]);
   my $v16 = $v3->Concat_List($v1, $v12);

   $self->[$__raw] = $self->SUPER::pack('nn',
      $v16->to_Dec,
      $self->[$__type],
   ) or return undef;

   # Keep old behaviour for backward compat
   if (! $Env->doFrameReturnList) {
      if ($self->[$__frame] && $self->[$__frame]->raw) {
         $self->[$_raw] .= $self->SUPER::pack('a*',
            $self->[$__frame]->raw,
         );
      }
   }

   1;
}

sub unpack {
   my $self = shift;

   my ($pCfiId, $type, $payload) =
      $self->SUPER::unpack('nn a*', $self->[$__raw])
         or return undef;

   my $v16 = Bit::Vector->new_Dec(16, $pCfiId);

   $self->[$__priority] = $v16->Chunk_Read(3, 13);
   $self->[$__cfi]      = $v16->Chunk_Read(1, 12);
   $self->[$__id]       = $v16->Chunk_Read(12, 0);
   $self->[$__type]     = $type;

   # Keep old behaviour for backward compat
   if (! $Env->doFrameReturnList) {
      $self->[$__frame] = Net::Packet::Frame->new(
         raw         => $payload,
         encapsulate => $self->encapsulate,
      );
   }
   else {
      $self->[$__payload] = $payload;
   }

   1;
}

sub encapsulate {
   my $self = shift;

   my $types = {
      NP_VLAN_TYPE_IPv4() => NP_LAYER_IPv4(),
      NP_VLAN_TYPE_IPv6() => NP_LAYER_IPv6(),
      NP_VLAN_TYPE_ARP()  => NP_LAYER_ARP(),
      NP_VLAN_TYPE_VLAN() => NP_LAYER_VLAN(),
   };

   if ($self->[$__type] <= 1500 && $self->[$__payload]) {
      my $payload = CORE::unpack('H*', $self->[$__payload]);
      if ($payload =~ /^aaaa/) {
         return NP_LAYER_LLC();
      }
      return NP_LAYER_UNKNOWN();
   }
   else {
      $types->{$self->type} || NP_LAYER_UNKNOWN();
   }
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: priority:0x%01x  cfi:0x%01x  id:0x%02x  type:0x%02x",
      $self->[$__priority], $self->[$__cfi], $self->[$__id], $self->[$__type];
}

#
# Helpers
#

sub _isType    { shift->[$__type] == shift()                      }
sub isTypeArp  { shift->_isType(NP_VLAN_TYPE_ARP)                 }
sub isTypeVlan { shift->_isType(NP_VLAN_TYPE_VLAN)                }
sub isTypeIpv4 { shift->_isType(NP_VLAN_TYPE_IPv4)                }
sub isTypeIpv6 { shift->_isType(NP_VLAN_TYPE_IPv6)                }
sub isTypeIp   { my $self = shift; $self->isIpv4 || $self->isIpv6 }

1;

__END__

=head1 NAME

Net::Packet::VLAN - 802.1Q layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:vlan);
   require Net::Packet::VLAN;

   # Build a layer
   my $layer = Net::Packet::VLAN->new(
      priority => 0,
      cfi      => 0,
      id       => 0,
      type     => NP_VLAN_TYPE_IPv4,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::VLAN->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Virtual LAN/802.1Q layer.

Details: http://standards.ieee.org/getieee802/802.1.html

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<priority>

The priority field.

=item B<cfi>

The cfi field. It is only one bit long, so set it to 0 or 1.

=item B<id>

VLAN tag id. You'll love it.

=item B<type>

Which type the next encapsulated layer is.

=item B<frame>

This is a B<Net::Packet::Frame> object, built it like any other such frame. Just to mention that you should use B<dnoFexLien> attribute if you put in a B<Net::Packet::IPv4> layer.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

priority: 0

cfi:      0

id:       0

type:     NP_VLAN_TYPE_IPv4

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<isTypeArp>

=item B<isTypeIpv4>

=item B<isTypeIpv6>

=item B<isTypeIp> - is type IPv4 or IPv6

=item B<isTypeVlan>

Helper methods. Return true is the encapsulated layer is of specified type, false otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:vlan);

=over 4

=item B<NP_VLAN_TYPE_ARP>

=item B<NP_VLAN_TYPE_IPv4>

=item B<NP_VLAN_TYPE_IPv6>

=item B<NP_VLAN_TYPE_VLAN>

Various supported encapsulated frame types.

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
