#
# $Id: Tlv.pm 9 2012-11-22 19:13:54Z gomor $
#
package Net::Frame::Layer::SinFP3::Tlv;
use strict;
use warnings;

use base qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   value
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer qw(:consts :subs);

sub new {
   my $self = shift->SUPER::new(
      type   => 0,
      length => 0,
      value  => '',
      @_,
   );

   return $self;
}

sub getLength {
   my $self = shift;

   return 2 + $self->length;
}

sub computeLengths {
   my $self = shift;

   my $len = length($self->value);

   return $self->length($len);
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCa*',
   #my $raw = $self->SUPER::pack('CCC',
      $self->type,
      $self->length,
      #CORE::pack('C', $self->value),
      $self->value,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $length, $tail) = $self->SUPER::unpack("CC a*", $self->raw)
      or return;

   my $bLen = $length;
   my ($value, $payload) = $self->SUPER::unpack("a$bLen a*", $tail)
      or return;

   $self->type($type);
   $self->length($length);
   $self->value($value);

   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf("$l: type:0x%02x  length:%d  value:%s",
      $self->type,
      $self->length,
      CORE::unpack("H*", $self->value),
   );

   my $type = $self->type;
   if ($type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_SYSTEMCLASS
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_VENDOR
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_OS
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_OSVERSION
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_MATCHTYPE
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_MATCHMASK
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_P1SIG
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_P2SIG
   ||  $type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_P2SIG) {
      $buf .= " [".CORE::unpack("a*", $self->value)."]";
   }
   elsif ($type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_TRUSTED) {
      $buf .= " [trusted]";
   }
   elsif ($type == &Net::Frame::Layer::SinFP3::NF_SINFP3_TLV_TYPE_MATCHSCORE) {
      $buf .= " [".CORE::unpack("C", $self->value).'%]';
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::SinFP3::Tlv - SinFP3 Tlv object

=head1 SYNOPSIS

   use Net::Frame::Layer::SinFP3::Tlv;

   my $layer = Net::Frame::Layer::SinFP3::Tlv->new(
      type   => 0,
      length => 0,
      value  => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::SinFP3::Tlv->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of SinFP3 Tlv.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

The type of SinFP3 option.

=item B<length>

The length of SinFP3 option (a number of bytes), only counting length of B<value>.

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

See L<Net::Frame::Layer::SinFP3>.

=head1 SEE ALSO

L<Net::Frame::Layer::SinFP3>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
