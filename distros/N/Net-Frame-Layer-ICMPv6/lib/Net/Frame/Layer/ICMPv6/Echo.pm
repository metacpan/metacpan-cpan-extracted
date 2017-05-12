#
# $Id: Echo.pm 45 2014-04-09 06:32:08Z gomor $
#
package Net::Frame::Layer::ICMPv6::Echo;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   identifier
   sequenceNumber
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      identifier     => getRandom16bitsInt(),
      sequenceNumber => getRandom16bitsInt(),
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nn',
      $self->identifier, $self->sequenceNumber,
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($identifier, $sequenceNumber, $payload) =
      $self->SUPER::unpack('nn a*', $self->raw)
         or return;

   $self->identifier($identifier);
   $self->sequenceNumber($sequenceNumber);
   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: identifier:%d  sequenceNumber:%d",
      $self->identifier, $self->sequenceNumber;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::Echo - ICMPv6 Echo type object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv6::Echo;

   my $layer = Net::Frame::Layer::ICMPv6::Echo->new(
      identifier     => getRandom16bitsInt(),
      sequenceNumber => getRandom16bitsInt(),
      payload        => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv6::Echo->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv6 Echo object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<identifier>

Identification number.

=item B<sequenceNumber>

Sequence number.

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

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer::ICMPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
