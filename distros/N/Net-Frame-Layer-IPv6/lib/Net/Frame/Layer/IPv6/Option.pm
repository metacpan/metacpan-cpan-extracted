#
# $Id: Option.pm,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
package Net::Frame::Layer::IPv6::Option;
use strict;
use warnings;

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
      type   => 1,
      length => 0,
      value  => '',
      @_,
   );
}

sub getLength { 
   my $self = shift;

   if ($self->type == 0) {  # Pad1, only type is used
      return 1;
   }

   return length($self->value) + 2;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('C', $self->type)
      or return;

   if ($self->type != 0) {  # Not a Pad1 option
      $raw .= $self->SUPER::pack('Ca*', $self->length, $self->value)
         or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $payload) = $self->SUPER::unpack('C a*', $self->raw)
      or return;
   $self->type($type);

   if ($self->type != 0) {  # Not a Pad1 option
      my ($length, $tail) = $self->SUPER::unpack('C a*', $payload)
         or return;

      my $value = '';
      ($value, $payload) = $self->SUPER::unpack("a$length a*", $tail)
         or return;

      $self->length($length);
      $self->value($value);
   }

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $length = 0;
   if ($self->type != 0) { #  Not a Pad1 option
      $length = length($self->value);
   }
   $self->length($length);

   return 1;
}

sub print {
   my $self = shift;

   my $buf = '';
   my $l   = $self->layer;
   if ($self->type == 0x00) {  # Pad1 specific type
      $buf .= sprintf "$l: type:0x%02x", $self->type;
   }
   else {
      $buf .= sprintf "$l: type:0x%02x  length:%d  value:%s",
         $self->type, $self->length, CORE::unpack('H*', $self->value);
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::IPv6::Option - IPv6 Option object

=head1 SYNOPSIS

   use Net::Frame::Layer::IPv6::Option;

   my $layer = Net::Frame::Layer::IPv6::Option->new(
      type   => 1,
      length => 0,
      value  => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::IPv6::Option->new(
      raw => $raw,
   );

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of IPv6 Options.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

The type of IPv6 option.

=item B<length>

The length of IPv6 option (a number of bytes), including B<type> and B<length> fields.

=item B<value>

The value.

=back

The default B<type>, B<length> and B<value> create the PadN option padding, where N=2.

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

L<Net::Frame::Layer::IPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
