#
# $Id: EmiteeDesc.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::EmiteeDesc;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   pause
   sourceAddress
   destinationAddress
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      type               => 0,
      pause              => 0,
      sourceAddress      => 'ff:ff:ff:ff:ff:ff',
      destinationAddress => 'ff:ff:ff:ff:ff:ff',
      @_,
   );
}

sub getLength { 14 }

sub pack {
   my $self = shift;

   (my $sourceAddress      = $self->sourceAddress)      =~ s/://g;
   (my $destinationAddress = $self->destinationAddress) =~ s/://g;

   $self->raw($self->SUPER::pack('CCH12H12',
      $self->type, $self->pause, $sourceAddress, $destinationAddress,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($type, $pause, $src, $dst, $payload) =
      $self->SUPER::unpack('CCH12H12 a*', $self->raw)
         or return undef;

   $self->type($type);
   $self->pause($pause);
   $self->sourceAddress(convertMac($src));
   $self->destinationAddress(convertMac($dst));

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf
      "$l: type:%02x  pause:%02x\n".
      "$l: sourceAddress:      %s\n".
      "$l: destinationAddress: %s",
         $self->type,
         $self->pause,
         $self->sourceAddress,
         $self->destinationAddress;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::EmiteeDesc - LLTD EmiteeDesc object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::EmiteeDesc;

   my $layer = Net::Frame::Layer::LLTD::EmiteeDesc->new(
      type               => 0,
      pause              => 0,
      sourceAddress      => 'ff:ff:ff:ff:ff:ff',
      destinationAddress => 'ff:ff:ff:ff:ff:ff',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::EmiteeDesc->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of LLTD EmiteeDescs.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>
=item B<pause>
=item B<sourceAddress>
=item B<destinationAddress>

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
