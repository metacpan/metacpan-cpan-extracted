#
# $Id: SNAP.pm 20 2015-01-13 18:34:19Z gomor $
#
package Net::Frame::Layer::LLC::SNAP;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   oui
   pid
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

use Net::Frame::Layer::LLC qw(:consts);
require Bit::Vector;

sub new {
   shift->SUPER::new(
      oui => NF_LLC_SNAP_OUI_CISCO,
      pid => NF_LLC_SNAP_PID_CDP,
      @_,
   );
}

sub getLength { NF_LLC_SNAP_HDR_LEN }

sub pack {
   my $self = shift;

   my $oui = Bit::Vector->new_Dec(24, $self->[$__oui]);

   $self->[$__raw] = $self->SUPER::pack('B24n',
      $oui->to_Bin,
      $self->[$__pid],
   ) or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($oui, $pid, $payload) = $self->SUPER::unpack('B24n a*', $self->[$__raw])
      or return undef;

   my $v24 = Bit::Vector->new_Bin(24, $oui);
   $self->[$__oui] = $v24->to_Dec;
   $self->[$__pid] = $pid;

   $self->[$__payload] = $payload;

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   my $types = {
      NF_LLC_SNAP_PID_CDP() => 'CDP',
      NF_LLC_SNAP_PID_STP() => 'STP',
      NF_LLC_SNAP_PID_IPX() => 'IPX',
   };

   $types->{$self->[$__pid]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: oui:0x%06x  pid:0x%04x",
      $self->[$__oui], $self->[$__pid];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLC::SNAP - LLC SNAP layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLC qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::LLC::SNAP->new(
      oui     => NF_LLC_OUI_CISCO,
      pid     => NF_LLC_PID_CDP,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLC::SNAP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LLC SNAP layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<oui> - 24 bits

=item B<pid> - 16 bits

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

See B<Net::Frame::Layer::LLC>.

=head1 SEE ALSO

L<Net::Frame::Layer::LLC>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
