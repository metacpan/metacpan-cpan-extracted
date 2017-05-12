#
# $Id: Discover.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::Discover;
use strict; use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   generationNumber
   numberOfStations
);
our @AA = qw(
   stationList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer qw(:subs);

sub new {
   shift->SUPER::new(
      generationNumber => 0,
      numberOfStations => 0,
      stationList      => [],
      @_,
   );
}

sub getStationListLength {
   my $self = shift;
   my $len = 0;
   for ($self->stationList) {
      $len += 6;
   }
   $len;
}

sub getLength { 4 + shift->getStationListLength }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nn',
      $self->generationNumber,
      $self->numberOfStations,
   ) or return undef;

   for ($self->stationList) {
      s/://g;
      $raw .= $self->SUPER::pack('H12', $_) or return undef;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($generationNumber, $numberOfStations, $tail) =
      $self->SUPER::unpack('nn a*', $self->raw)
         or return undef;

   $self->generationNumber($generationNumber);
   $self->numberOfStations($numberOfStations);

   my @stationList = ();
   if ($self->numberOfStations && $self->numberOfStations > 0) {
      for (1..$self->numberOfStations) {
         my $mac;
         ($mac, $tail) = $self->SUPER::unpack('H12 a*', $tail)
            or return undef;
         push @stationList, convertMac($mac);
      }
   }

   $self->stationList(\@stationList);
   $self->payload($tail);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf .= sprintf "$l: generationNumber:%d  numberOfStations:%d",
      $self->generationNumber,
      $self->numberOfStations;

   for my $s ($self->stationList) {
      $buf .= sprintf "\n$l: station: %s", $s;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::Discover - LLTD Discover upper layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::Discover;

   # Build a layer
   my $layer = Net::Frame::Layer::LLTD::Discover->new(
      generationNumber => 0,
      numberOfStations => 0,
      stationList      => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::Discover->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LLTD Discover layer.

Protocol specifications: http://www.microsoft.com/whdc/Rally/LLTD-spec.mspx .

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<generationNumber>

=item B<numberOfStations>

=item B<stationList> ( [ MACAddress, ... ] )

This last attribute takes an array ref of MAC addresses.

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

=item B<getStationListLength>

This method will compute the length of all included station list (see B<stationList> attribute).

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
