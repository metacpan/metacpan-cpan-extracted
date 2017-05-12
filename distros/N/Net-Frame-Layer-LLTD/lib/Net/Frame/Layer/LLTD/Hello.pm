#
# $Id: Hello.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::Hello;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   generationNumber
   currentMapperAddress
   apparentMapperAddress
);
our @AA = qw(
   tlvList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::LLTD::Tlv;

sub new {
   shift->SUPER::new(
      generationNumber      => 0,
      currentMapperAddress  => 'ff:ff:ff:ff:ff:ff',
      apparentMapperAddress => 'ff:ff:ff:ff:ff:ff',
      tlvList               => [],
      @_,
   );
}

sub getTlvListLength {
   my $self = shift;
   my $len = 0;
   for ($self->tlvList) {
      $len += $_->getLength;
   }
   $len;
}

sub getLength {
   my $self = shift;
   my $len = 14;
   $len += $self->getTlvListLength if $self->tlvList;
   $len;
}

sub pack {
   my $self = shift;

   (my $mac1 = $self->currentMapperAddress)  =~ s/://g;
   (my $mac2 = $self->apparentMapperAddress) =~ s/://g;

   my $raw = $self->SUPER::pack('nH12H12',
      $self->generationNumber,
      $mac1,
      $mac2,
   ) or return undef;

   for ($self->tlvList) {
      $raw .= $_->pack;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($generationNumber, $mac1, $mac2, $payload) =
      $self->SUPER::unpack('nH12H12 a*', $self->raw)
         or return undef;

   $self->generationNumber($generationNumber);
   $self->currentMapperAddress(convertMac($mac1));
   $self->apparentMapperAddress(convertMac($mac2));

   my @tlvList = ();
   while ($payload && length($payload) > 2) {
      my $tlv = Net::Frame::Layer::LLTD::Tlv->new(raw => $payload);
      $tlv->unpack;
      push @tlvList, $tlv;
      $payload = $tlv->payload;
   }

   $self->tlvList(\@tlvList);
   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: generationNumber:%d\n".
      "$l: currentMapperAddress:  %s\n".
      "$l: apparentMapperAddress: %s",
         $self->generationNumber,
         $self->currentMapperAddress,
         $self->apparentMapperAddress;

   for ($self->tlvList) {
      $buf .= "\n".$_->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::Hello - LLTD Hello upper layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::Hello;

   # Build a layer
   my $layer = Net::Frame::Layer::LLTD::Hello->new(
      generationNumber      => 0,
      currentMapperAddress  => 'ff:ff:ff:ff:ff:ff',
      apparentMapperAddress => 'ff:ff:ff:ff:ff:ff',
      tlvList               => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::Hello->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LLTD Hello layer.

Protocol specifications: http://www.microsoft.com/whdc/Rally/LLTD-spec.mspx .

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<generationNumber>

=item B<currentMapperAddress>

=item B<apparentMapperAddress>

=item B<tlvList> ( [ B<Net::Frame::Layer::LLTD::Tlv>, ... ] )

This last attribute will store an array ref of B<Net::Frame::Layer::LLTD::Tlv> objects.

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

=item B<getTlvListLength>

This method will compute the length of all tlv objects contained in B<tlvList> attribute.

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

See L<Net::Frame::Layer::LLTD>.

=head1 SEE ALSO

L<Net::Frame::Layer::LLTD>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
