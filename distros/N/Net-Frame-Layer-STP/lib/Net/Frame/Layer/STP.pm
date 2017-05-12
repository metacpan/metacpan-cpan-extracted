#
# $Id: STP.pm 8 2015-01-14 06:55:14Z gomor $
#
package Net::Frame::Layer::STP;
use strict; use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_STP_HDR_LEN
      NF_STP_PROTOCOL_IDENTIFIER_STP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_STP_HDR_LEN                 => 42;
use constant NF_STP_PROTOCOL_IDENTIFIER_STP => 0x0000;

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

use Net::Frame::Layer qw(:subs);

sub new {
   shift->SUPER::new(
      protocolIdentifier        => NF_STP_PROTOCOL_IDENTIFIER_STP,
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

sub getLength { NF_STP_HDR_LEN }

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

   $self->raw;
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

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: protocolIdentifier:0x%04x  protocolVersionIdentifier:%d\n".
           "$l: bpduType:0x%02x  bpduFlags:0x%02x\n".
           "$l: rootIdentifier:%s  rootPathCost:%d\n".
           "$l: bridgeIdentifier:%s  portIdentifier:0x%04x\n".
           "$l: messageAge:%d  maxAge:%d  helloTime:%d  forwardDelay:%d",
              $self->protocolIdentifier, $self->protocolVersionIdentifier,
              $self->bpduType, $self->bpduFlags, $self->rootIdentifier,
              $self->rootPathCost, $self->bridgeIdentifier,
              $self->portIdentifier, $self->messageAge, $self->maxAge,
              $self->helloTime, $self->forwardDelay;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::STP - Spanning Tree Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::STP qw(:consts);

   # Build a layer
   my $layer = Net::Packet::STP->new(
      protocolIdentifier        => NF_STP_PROTOCOL_IDENTIFIER_STP,
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

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::STP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Spanning Tree Protocol layer.

See also B<Net::Frame::Layer> for other attributes and methods.

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

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

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

Load them: use Net::Frame::Layer::STP qw(:consts);

=over 4

=item B<NF_STP_HDR_LEN>

STP header length.

=item B<NF_STP_PROTOCOL_IDENTIFIER_STP>

Various supported STP protocol identifiers.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
