#
# $Id: Emit.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::Emit;
use strict; use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   numDescs
);
our @AA = qw(
   emiteeDescList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::LLTD::EmiteeDesc;

sub new {
   shift->SUPER::new(
      numDescs       => 0,
      emiteeDescList => [],
      @_,
   );
}

sub getEmiteeDescLength {
   my $self = shift;
   my $len = 0;
   for ($self->emiteeDescList) {
      $len += $_->getLength;
   }
   $len;
}

sub getLength {
   my $self = shift;
   my $len = 2;
   $len += $self->getEmiteeDescLength if $self->emiteeDescList;
   $len;
}

sub pack {
   my $self = shift;

   $self->raw(
      $self->SUPER::pack('n',
         $self->numDescs,
      )
   ) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($numDescs, $payload) =
      $self->SUPER::unpack('n a*', $self->raw)
         or return undef;

   $self->numDescs($numDescs);

   my @emiteeDescList = ();
   if ($self->numDescs && $self->numDescs > 0) {
      for (1..$self->numDescs) {
         my $emitee = Net::Frame::Layer::LLTD::EmiteeDesc->new(raw => $payload);
         $emitee->unpack;
         push @emiteeDescList, $emitee;
         $payload = $emitee->payload;
      }
   }

   $self->emiteeDescList(\@emiteeDescList);
   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: numDescs:%d", $self->numDescs;

   for ($self->emiteeDescList) {
      $buf .= "\n".$_->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::Emit - LLTD Emit upper layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::Emit;

   # Build a layer
   my $layer = Net::Frame::Layer::LLTD::Emit->new(
      numDescs       => 0,
      emiteeDescList => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::Emit->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LLTD Emit layer.

Protocol specifications: http://www.microsoft.com/whdc/Rally/LLTD-spec.mspx .

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<numDescs>

=item B<emiteeDescList> ( [ B<Net::Frame::Layer::LLTD::EmiteeDesc>, ... ] )

This last attribute will store an array ref of B<Net::Frame::Layer::LLTD::EmiteeDesc> objects.

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

=item B<getEmiteeDescLength>

This method will compute the length of all EmiteeDesc objects.

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
