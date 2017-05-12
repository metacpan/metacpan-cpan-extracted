#
# $Id: NativeVlan.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::NativeVlan;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   nativeVlan
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Net::Frame::Layer::CDP::Constants qw(:consts);

sub new {
   shift->SUPER::new(
      type       => NF_CDP_TYPE_NATIVE_VLAN,
      length     => 6,
      nativeVlan => 1,
      @_,
   );
}

sub getLength { 6 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nnn',
      $self->type,
      $self->length,
      $self->nativeVlan,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $length, $nativeVlan, $payload) = 
      $self->SUPER::unpack('nnn a*', $self->raw)
         or return;

   $self->type($type);
   $self->length($length);
   $self->nativeVlan($nativeVlan);

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   $self->length(6);

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%04x  length:%d  nativeVlan:%d",
         $self->type, $self->length, $self->nativeVlan;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::NativeVlan - CDP NativeVlan TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::NativeVlan->new(
      type       => NF_CDP_TYPE_NATIVE_VLAN
      length     => 6,
      nativeVlan => 1,
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the NativeVlan CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<type>

Type.

=item B<length>

Length of TLV option.

=item B<nativeVlan>

Native VLAN.

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

L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
