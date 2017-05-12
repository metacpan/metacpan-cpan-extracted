#
# $Id: PPPoE.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::PPPoE;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Net::Packet::Consts qw(:pppoe :layer);
require Bit::Vector;

our @AS = qw(
   version
   type
   code
   sessionId
   payloadLength
   pppProtocol
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      version       => 1,
      type          => 1,
      code          => 0,
      sessionId     => 1,
      payloadLength => 0,
      pppProtocol   => NP_PPPoE_PPP_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NP_PPPoE_HDR_LEN }

sub getPayloadLength { shift->[$__payloadLength] }

sub pack {
   my $self = shift;

   my $version = Bit::Vector->new_Dec(4, $self->[$__version]);
   my $type    = Bit::Vector->new_Dec(4, $self->[$__type]);
   my $v8      = $version->Concat_List($type);

   $self->[$__raw] = $self->SUPER::pack('CCnnn',
      $v8->to_Dec,
      $self->[$__code],
      $self->[$__sessionId],
      $self->[$__payloadLength],
      $self->[$__pppProtocol],
   ) or return undef;

   if (length($self->[$__payload])) {
      $self->[$__raw] .= $self->SUPER::pack('a*', $self->[$__payload])
         or return undef;
   }

   1;
}

sub unpack {
   my $self = shift;

   my ($versionType, $code, $sessionId, $payloadLength, $pppProtocol,
      $payload) = $self->SUPER::unpack('CCnnn a*', $self->[$__raw])
         or return undef;

   my $v8 = Bit::Vector->new_Dec(8, $versionType);
   $self->version($v8->Chunk_Read(4, 0));
   $self->type($v8->Chunk_Read(4, 4));

   $self->[$__code]          = $code;
   $self->[$__sessionId]     = $sessionId;
   $self->[$__payloadLength] = $payloadLength;
   $self->[$__pppProtocol]   = $pppProtocol;
   $self->[$__payload]       = $payload;

   1;
}

sub encapsulate {
   my $types = {
      NP_PPPoE_PPP_PROTOCOL_IPv4()   => NP_LAYER_IPv4(),
      NP_PPPoE_PPP_PROTOCOL_PPPLCP() => NP_LAYER_PPPLCP(),
   };

   $types->{shift->[$__pppProtocol]} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: version:%d  type:%d  code:0x%02x  sessionId:0x%04x\n".
           "$l: $i: payloadLength:%d  pppProtocol:0x%04x",
      $self->[$__version], $self->[$__type], $self->[$__code],
      $self->[$__sessionId], $self->[$__payloadLength], $self->[$__pppProtocol];
}

1;

__END__

=head1 NAME

Net::Packet::PPPoE - PPP-over-Ethernet layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:pppoe);
   require Net::Packet::PPPoE;

   # Build a layer
   my $layer = Net::Packet::PPPoE->new(
      version       => 1,
      type          => 1,
      code          => 0,
      sessionId     => 1,
      payloadLength => 0,
      pppProtocol   => NP_PPPoE_PPP_PROTOCOL_IPv4,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::PPPoE->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the PPP-over-Ethernet layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version> - 4 bits

=item B<code> - 4 bits

=item B<type> - 8 bits

=item B<sessionId> - 16 bits

=item B<payloadLength> - 16 bits

=item B<pppProtocol> - 16 bits

For this last attribute, we can note that it is included in the computation of payloadLength.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

version:       1

type:          1

code:          0

sessionId:     1

payloadLength: 0

pppProtocol:   NP_PPPoE_PPP_PROTOCOL_IPv4

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:pppoe);

=over 4

=item B<NP_PPPoE_HDR_LEN>

PPPoE header length.

=item B<NP_PPPoE_PPP_PROTOCOL_IPv4>

=item B<NP_PPPoE_PPP_PROTOCOL_PPPLCP>

Various supported encapsulated PPP protocols.

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
