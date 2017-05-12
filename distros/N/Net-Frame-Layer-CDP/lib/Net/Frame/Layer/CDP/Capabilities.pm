#
# $Id: Capabilities.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::Capabilities;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_CDP_TYPE_CAPABILITIES_ROUTER
      NF_CDP_TYPE_CAPABILITIES_TRANSBRIDGE
      NF_CDP_TYPE_CAPABILITIES_SRCRTBRIDGE
      NF_CDP_TYPE_CAPABILITIES_SWITCH
      NF_CDP_TYPE_CAPABILITIES_HOST
      NF_CDP_TYPE_CAPABILITIES_IGMP
      NF_CDP_TYPE_CAPABILITIES_REPEATER
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_CDP_TYPE_CAPABILITIES_ROUTER      =>  1;
use constant NF_CDP_TYPE_CAPABILITIES_TRANSBRIDGE =>  2;
use constant NF_CDP_TYPE_CAPABILITIES_SRCRTBRIDGE =>  4;
use constant NF_CDP_TYPE_CAPABILITIES_SWITCH      =>  8;
use constant NF_CDP_TYPE_CAPABILITIES_HOST        => 16;
use constant NF_CDP_TYPE_CAPABILITIES_IGMP        => 32;
use constant NF_CDP_TYPE_CAPABILITIES_REPEATER    => 64;

our @AS = qw(
   type
   length
   capabilities
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Net::Frame::Layer::CDP::Constants qw(:consts);

sub new {
   shift->SUPER::new(
      type         => NF_CDP_TYPE_CAPABILITIES,
      length       => 8,
      capabilities => 0x00000000,
      @_,
   );
}

sub getLength { 8 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nnN',
      $self->type,
      $self->length,
      $self->capabilities,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $length, $capabilities, $payload) = 
      $self->SUPER::unpack('nnN a*', $self->raw)
         or return;

   $self->type($type);
   $self->length($length);
   $self->capabilities($capabilities);

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   $self->length(8);

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%04x  length:%d  capabilities:0x%08x",
         $self->type, $self->length, $self->capabilities;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::Capabilities - CDP Capabilities TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::Capabilities->new(
      type         => NF_CDP_TYPE_CAPABILITIES
      length       => 8,
      capabilities => 0x00000000,
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Capabilities CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<type>

Type.

=item B<length>

Length of TLV option.

=item B<capabilities>

None or more capabilities logically OR together.  See B<CONSTANTS> for values.

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

=over 4

=item B<NF_CDP_TYPE_CAPABILITIES_ROUTER>

=item B<NF_CDP_TYPE_CAPABILITIES_TRANSBRIDGE>

=item B<NF_CDP_TYPE_CAPABILITIES_SRCRTBRIDGE>

=item B<NF_CDP_TYPE_CAPABILITIES_SWITCH>

=item B<NF_CDP_TYPE_CAPABILITIES_HOST>

=item B<NF_CDP_TYPE_CAPABILITIES_IGMP>

=item B<NF_CDP_TYPE_CAPABILITIES_REPEATER>

Capabilities.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
