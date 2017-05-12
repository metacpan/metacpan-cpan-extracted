#
# $Id: Tlv.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::Tlv;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   value
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      type   => 0,
      length => 0,
      value  => '',
      @_,
   );
}

sub getLength { 2 + shift->length }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('CCa*',
      $self->type, $self->length, $self->value,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($type, $length, $tail) = $self->SUPER::unpack('CC a*', $self->raw)
      or return undef;

   my $bLen = $length;
   my ($value, $payload) = $self->SUPER::unpack("a$bLen a*", $tail)
      or return undef;

   $self->type($type);
   $self->length($length);
   $self->value($value);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: type:%02x  length:%02x  value:%s",
      $self->type, $self->length, CORE::unpack('H*', $self->value);
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::Tlv - LLTD Tlv object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::Tlv;

   my $layer = Net::Frame::Layer::LLTD::Tlv->new(
      type   => 0,
      length => 0,
      value  => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::Tlv->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of LLTD Tlv.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

The type of LLTD option.

=item B<length>

The length of LLTD option (a number of bytes), including B<type> and B<length> fields.

=item B<value>

The value.

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
