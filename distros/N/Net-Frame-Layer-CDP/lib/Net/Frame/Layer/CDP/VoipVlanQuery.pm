#
# $Id: VoipVlanQuery.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::VoipVlanQuery;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   data
   voipVlan
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Net::Frame::Layer::CDP::Constants qw(:consts);

sub new {
   shift->SUPER::new(
      type     => NF_CDP_TYPE_VOIP_VLAN_QUERY,
      length   => 5,
      data     => 1,
      voipVlan => '',
      @_,
   );
}

sub getLength {
   my $self = shift;

   my $length = 4;
   if (defined($self->data) && ($self->data ne '')) {
      $length += 1;
   }
   if (defined($self->voipVlan) && ($self->voipVlan ne '')) {
      $length += 2;
   }

   return $length;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nn',
      $self->type,
      $self->length,
   ) or return;

   if (defined($self->data) && ($self->data ne '')) {
      $raw .= $self->SUPER::pack('C',
         $self->data
      ) or return;
   }

   if (defined($self->voipVlan) && ($self->voipVlan ne '')) {
      $raw .= $self->SUPER::pack('n',
         $self->voipVlan
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $length, $payload) = 
      $self->SUPER::unpack('nn a*', $self->raw)
         or return;

   $self->type($type);
   $self->length($length);

   my $data;
   if ($length >= 5) {
      ($data, $payload) = 
         $self->SUPER::unpack('C a*', $payload)
            or return;
      $self->data($data);
      my $voipVlan;
      if ($length >= 7) {
         ($voipVlan, $payload) = 
            $self->SUPER::unpack('n a*', $payload)
               or return;
         $self->voipVlan($voipVlan);
      } else {
         $self->voipVlan('');
      }
   } else {
      $self->data('');
      $self->voipVlan('');
   }

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $length = 4;
   if (defined($self->data) && ($self->data ne '')) {
      $length += 1;
   }
   if (defined($self->voipVlan) && ($self->voipVlan ne '')) {
      $length += 2;
   }

   $self->length($length);

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%04x  length:%d  data:%s  voipVlan:%s",
         $self->type, $self->length, $self->data, $self->voipVlan;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::VoipVlanQuery - CDP VoipVlanQuery TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::VoipVlanQuery->new(
      type     => NF_CDP_TYPE_VOIP_VLAN_QUERY,
      length   => 5,
      data     => 1,
      voipVlan => '',
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the VoipVlanQuery CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<type>

Type.

=item B<length>

Length of TLV option.

=item B<data>

Data.

=item B<voipVlan>

VoIP VLAN.

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
