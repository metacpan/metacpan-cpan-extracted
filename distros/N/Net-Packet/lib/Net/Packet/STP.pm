#
# $Id: STP.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::STP;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

use Net::Packet::Consts qw(:stp :layer);
use Net::Packet::Utils qw(convertMac);

our @AS = qw(
   protocolIdentifier
   protocolVersionIdentifier
   bpduType
   bpduFlags
   rootIdentifier
   rootPathCost
   bridgeIdentifier
   portIdentifier
   messageAge
   maxAge
   helloTime
   forwardDelay
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      protocolIdentifier        => NP_STP_PROTOCOL_IDENTIFIER_STP,
      protocolVersionIdentifier => 0,
      bpduType                  => 0x00,
      bpduFlags                 => 0x00,
      rootIdentifier            => '1/00:11:22:33:44:55',
      rootPathCost              => 1,
      bridgeIdentifier          => '2/11:22:33:44:55:66',
      portIdentifier            => 0x0001,
      messageAge                => 1,
      maxAge                    => 10,
      helloTime                 => 1,
      forwardDelay              => 10,
      @_,
   );
}

sub getLength { NP_STP_HDR_LEN }

sub pack {
   my $self = shift;

   my ($root, $id1)   = split('\s*/\s*', $self->rootIdentifier);
   my ($bridge, $id2) = split('\s*/\s*', $self->bridgeIdentifier);

   $id1 =~ s/://g;
   $id2 =~ s/://g;

   $self->raw($self->SUPER::pack('nCCCnH12NnH12nvvvv',
      $self->protocolIdentifier, $self->protocolVersionIdentifier,
      $self->bpduType, $self->bpduFlags, $root, $id1, $self->rootPathCost,
      $bridge, $id2, $self->portIdentifier, $self->messageAge, $self->maxAge,
      $self->helloTime, $self->forwardDelay)
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($protocolIdentifier, $protocolVersionIdentifier, $bpduType, $bpduFlags,
      $root, $identifier1, $rootPathCost, $bridge, $identifier2,
      $portIdentifier, $messageAge, $maxAge, $helloTime, $forwardDelay,
      $payload) = $self->SUPER::unpack('nCCCnH12NnH12nvvvv a*', $self->raw)
         or return undef;

   my $id1 = $root.'/'.convertMac($identifier1);
   my $id2 = $bridge.'/'.convertMac($identifier2);
   $self->rootIdentifier($id1);
   $self->bridgeIdentifier($id2);

   $self->protocolIdentifier($protocolIdentifier);
   $self->protocolVersionIdentifier($protocolVersionIdentifier);
   $self->bpduType($bpduType);
   $self->bpduFlags($bpduFlags);
   $self->rootPathCost($rootPathCost);
   $self->portIdentifier($portIdentifier);
   $self->messageAge($messageAge);
   $self->maxAge($maxAge);
   $self->helloTime($helloTime);
   $self->forwardDelay($forwardDelay);

   $self->payload($payload);

   1;
}

sub encapsulate {
   my $types = {
      NP_LAYER_NONE() => NP_LAYER_NONE(),
   };

   $types->{NP_LAYER_NONE()} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: protocolIdentifier:0x%04x  protocolVersionIdentifier:%d\n".
           "$l: $i: bpduType:0x%02x  bpduFlags:0x%02x\n".
           "$l: $i: rootIdentifier:%s  rootPathCost:%d\n".
           "$l: $i: bridgeIdentifier:%s  portIdentifier:0x%04x\n".
           "$l: $i: messageAge:%d  maxAge:%d  helloTime:%d  forwardDelay:%d",
              $self->protocolIdentifier, $self->protocolVersionIdentifier,
              $self->bpduType, $self->bpduFlags, $self->rootIdentifier,
              $self->rootPathCost, $self->bridgeIdentifier,
              $self->portIdentifier, $self->messageAge, $self->maxAge,
              $self->helloTime, $self->forwardDelay;
}

1;

__END__

=head1 NAME

Net::Packet::STP - Spanning Tree Protocol layer 4 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:stp);
   require Net::Packet::STP;

   # Build a layer
   my $layer = Net::Packet::STP->new(
      protocolIdentifier        => NP_STP_PROTOCOL_IDENTIFIER_STP,
      protocolVersionIdentifier => 0,
      bpduType                  => 0x00,
      bpduFlags                 => 0x00,
      rootIdentifier            => '1/00:11:22:33:44:55',
      rootPathCost              => 1,
      bridgeIdentifier          => '2/11:22:33:44:55:66',
      portIdentifier            => 0x0001,
      messageAge                => 1,
      maxAge                    => 10,
      helloTime                 => 1,
      forwardDelay              => 10,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::STP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Spanning Tree Protocol layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer4> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<protocolIdentifier> - 16 bits

=item B<protocolVersionIdentifier> - 8 bits

=item B<bpduType> - 8 bits

=item B<bpduFlags> - 8 bits

=item B<rootIdentifier> - 64 bits (16 + 56)

=item B<rootPathCost> - 32 bits

=item B<bridgeIdentifier> - 64 bits (16 + 56)

=item B<portIdentifier> - 16 bits

=item B<messageAge> - 16 bits

=item B<maxAge> - 16 bits

=item B<helloTime> - 16 bits

=item B<forwardDelay> - 16 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

protocolIdentifier:        NP_STP_PROTOCOL_IDENTIFIER_STP

protocolVersionIdentifier: 0

bpduType:                  0x00

bpduFlags:                 0x00

rootIdentifier:            '1/00:11:22:33:44:55'

rootPathCost:              1

bridgeIdentifier:          '2/11:22:33:44:55:66'

portIdentifier:            0x0001

messageAge:                1

maxAge:                    10

helloTime:                 1

forwardDelay:              10

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:stp);

=over 4

=item B<NP_STP_HDR_LEN>

STP header length.

=item B<NP_STP_PROTOCOL_IDENTIFIER_STP>

Various supported STP protocol identifiers.

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
