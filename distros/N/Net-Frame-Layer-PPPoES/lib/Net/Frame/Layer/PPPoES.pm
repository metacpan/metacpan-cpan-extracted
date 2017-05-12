#
# $Id: PPPoES.pm 8 2015-01-14 06:51:28Z gomor $
#
package Net::Frame::Layer::PPPoES;
use strict;
use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_PPPoE_HDR_LEN
      NF_PPPoE_PPP_PROTOCOL_IPv4
      NF_PPPoE_PPP_PROTOCOL_PPPLCP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_PPPoE_HDR_LEN => 8;
use constant NF_PPPoE_PPP_PROTOCOL_IPv4   => 0x0021;
use constant NF_PPPoE_PPP_PROTOCOL_PPPLCP => 0xc021;

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

require Bit::Vector;

sub new {
   shift->SUPER::new(
      version       => 1,
      type          => 1,
      code          => 0,
      sessionId     => 1,
      payloadLength => 0,
      pppProtocol   => NF_PPPoE_PPP_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NF_PPPoE_HDR_LEN }

sub getPayloadLength { shift->payloadLength }

sub pack {
   my $self = shift;

   my $version = Bit::Vector->new_Dec(4, $self->version);
   my $type    = Bit::Vector->new_Dec(4, $self->type);
   my $v8      = $version->Concat_List($type);

   $self->raw($self->SUPER::pack('CCnnn',
      $v8->to_Dec,
      $self->code,
      $self->sessionId,
      $self->payloadLength,
      $self->pppProtocol,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($versionType, $code, $sessionId, $payloadLength, $pppProtocol, $payload)
      = $self->SUPER::unpack('CCnnn a*', $self->raw)
         or return undef;

   my $v8 = Bit::Vector->new_Dec(8, $versionType);
   $self->version($v8->Chunk_Read(4, 0));
   $self->type($v8->Chunk_Read(4, 4));

   $self->code($code);
   $self->sessionId($sessionId);
   $self->payloadLength($payloadLength);
   $self->pppProtocol($pppProtocol);

   $self->payload($payload);

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   my $types = {
      NF_PPPoE_PPP_PROTOCOL_IPv4()   => 'IPv4',
      NF_PPPoE_PPP_PROTOCOL_PPPLCP() => 'PPPLCP',
   };

   $types->{$self->pppProtocol} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: version:%d  type:%d  code:0x%02x  sessionId:0x%04x\n".
           "$l: payloadLength:%d  pppProtocol:0x%04x",
      $self->version,
      $self->type,
      $self->code,
      $self->sessionId,
      $self->payloadLength,
      $self->pppProtocol,
   ;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::PPPoES - PPP-over-Ethernet layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::PPPoES qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::PPPoES->new(
      version       => 1,
      type          => 1,
      code          => 0,
      sessionId     => 1,
      payloadLength => 0,
      pppProtocol   => NF_PPPoE_PPP_PROTOCOL_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::PPPoES->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the PPPoES layer.

See also B<Net::Frame::Layer> for other attributes and methods.

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

Load them: use Net::Frame::Layer::PPPoES qw(:consts);

=over 4

=item B<NF_PPPoE_HDR_LEN>

=item B<NF_PPPoE_PPP_PROTOCOL_IPv4>

=item B<NF_PPPoE_PPP_PROTOCOL_PPPLCP>

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
