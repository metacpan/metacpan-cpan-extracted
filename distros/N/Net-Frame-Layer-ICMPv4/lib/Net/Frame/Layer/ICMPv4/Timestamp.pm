#
# $Id: Timestamp.pm 56 2015-01-20 18:55:33Z gomor $
#
package Net::Frame::Layer::ICMPv4::Timestamp;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   identifier
   sequenceNumber
   originateTimestamp
   receiveTimestamp
   transmitTimestamp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      identifier         => getRandom16bitsInt(),
      sequenceNumber     => getRandom16bitsInt(),
      originateTimestamp => time(),
      receiveTimestamp   => 0,
      transmitTimestamp  => 0,
      @_,
   );
}

sub getLength { 16 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nnNNN',
      $self->identifier, $self->sequenceNumber, $self->originateTimestamp,
      $self->receiveTimestamp, $self->transmitTimestamp,
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($identifier, $sequenceNumber, $originateTimestamp, $receiveTimestamp,
      $transmitTimestamp, $payload)
         = $self->SUPER::unpack('nnNNN a*', $self->raw)
            or return;

   $self->identifier($identifier);
   $self->sequenceNumber($sequenceNumber);
   $self->originateTimestamp($originateTimestamp);
   $self->receiveTimestamp($receiveTimestamp);
   $self->transmitTimestamp($transmitTimestamp);
   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf
      "$l: identifier:%d  sequenceNumber:%d\n".
      "$l: originateTimestamp:%d  receiveTimestamp:%d  transmitTimestamp:%d",
         $self->identifier, $self->sequenceNumber, $self->originateTimestamp,
         $self->receiveTimestamp, $self->transmitTimestamp;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv4::Timestamp - ICMPv4 Timestamp type object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv4::Timestamp;

   my $layer = Net::Frame::Layer::ICMPv4::Timestamp->new(
      identifier         => getRandom16bitsInt(),
      sequenceNumber     => getRandom16bitsInt(),
      originateTimestamp => time(),
      receiveTimestamp   => 0,
      transmitTimestamp  => 0,
      payload            => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv4::Timestamp->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv4 Timestamp object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<identifier>

Identification number.

=item B<sequenceNumber>

Sequence number.

=item B<originateTimestamp>

=item B<receiveTimestamp>

=item B<transmitTimestamp>

The three timestamps used in this message type.

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

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer::ICMPv4>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
