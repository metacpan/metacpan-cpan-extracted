#
# $Id: NULL.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::NULL;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_NULL_HDR_LEN
      NF_NULL_TYPE_IPv4
      NF_NULL_TYPE_ARP
      NF_NULL_TYPE_CGMP
      NF_NULL_TYPE_80211
      NF_NULL_TYPE_DDP
      NF_NULL_TYPE_AARP
      NF_NULL_TYPE_WCP
      NF_NULL_TYPE_8021Q
      NF_NULL_TYPE_IPX
      NF_NULL_TYPE_STP
      NF_NULL_TYPE_IPv6
      NF_NULL_TYPE_WLCCP
      NF_NULL_TYPE_PPPoED
      NF_NULL_TYPE_PPPoES
      NF_NULL_TYPE_8021X
      NF_NULL_TYPE_AoE
      NF_NULL_TYPE_LLDP
      NF_NULL_TYPE_LOOP
      NF_NULL_TYPE_VLAN
      NF_NULL_TYPE_ETH
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_NULL_HDR_LEN      => 4;
use constant NF_NULL_TYPE_IPv4    => 0x02000000;
use constant NF_NULL_TYPE_ARP     => 0x06080000;
use constant NF_NULL_TYPE_CGMP    => 0x01200000;
use constant NF_NULL_TYPE_80211   => 0x52240000;
use constant NF_NULL_TYPE_DDP     => 0x9b800000;
use constant NF_NULL_TYPE_AARP    => 0xf3800000;
use constant NF_NULL_TYPE_WCP     => 0xff800000;
use constant NF_NULL_TYPE_8021Q   => 0x00810000;
use constant NF_NULL_TYPE_IPX     => 0x37810000;
use constant NF_NULL_TYPE_STP     => 0x81810000;
use constant NF_NULL_TYPE_IPv6    => 0x1c000000;
use constant NF_NULL_TYPE_WLCCP   => 0x2d870000;
use constant NF_NULL_TYPE_PPPoED  => 0x63880000;
use constant NF_NULL_TYPE_PPPoES  => 0x64880000;
use constant NF_NULL_TYPE_8021X   => 0x8e880000;
use constant NF_NULL_TYPE_AoE     => 0xa2880000;
use constant NF_NULL_TYPE_LLDP    => 0xcc880000;
use constant NF_NULL_TYPE_LOOP    => 0x00900000;
use constant NF_NULL_TYPE_VLAN    => 0x00910000;
use constant NF_NULL_TYPE_ETH     => 0x58650000;

our @AS = qw(
   type
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      type => NF_NULL_TYPE_IPv4,
      @_,
   );
}

sub getLength { NF_NULL_HDR_LEN }

sub pack {
   my $self = shift;
   $self->[$__raw] = $self->SUPER::pack('N', $self->[$__type])
      or return undef;
   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($type, $payload) = $self->SUPER::unpack('N a*', $self->[$__raw])
      or return undef;

   $self->[$__type]    = $type;
   $self->[$__payload] = $payload;

   $self;
}

our $Next = {
   NF_NULL_TYPE_IPv4()   => 'IPv4',
   NF_NULL_TYPE_ARP()    => 'ARP',
   NF_NULL_TYPE_CGMP()   => 'CGMP',
   NF_NULL_TYPE_80211()  => '80211',
   NF_NULL_TYPE_DDP()    => 'DDP',
   NF_NULL_TYPE_AARP()   => 'AARP',
   NF_NULL_TYPE_WCP()    => 'WCP',
   NF_NULL_TYPE_8021Q()  => '8021Q',
   NF_NULL_TYPE_IPX()    => 'IPX',
   NF_NULL_TYPE_STP()    => 'STP',
   NF_NULL_TYPE_IPv6()   => 'IPv6',
   NF_NULL_TYPE_WLCCP()  => 'WLCCP',
   NF_NULL_TYPE_PPPoED() => 'PPPoED',
   NF_NULL_TYPE_PPPoES() => 'PPPoES',
   NF_NULL_TYPE_8021X()  => '8021X',
   NF_NULL_TYPE_AoE()    => 'AoE',
   NF_NULL_TYPE_LLDP()   => 'LLDP',
   NF_NULL_TYPE_LOOP()   => 'LOOP',
   NF_NULL_TYPE_VLAN()   => 'VLAN',
   NF_NULL_TYPE_ETH()    => 'ETH',
};

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   return $Next->{$self->[$__type]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: type:0x%08x", $self->type;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::NULL - BSD loopback layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::NULL qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::NULL->new(
      type => NF_NULL_TYPE_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::NULL->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the BSD loopback layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

Stores the type of encapsulated layer.

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

Load them: use Net::Frame::Layer::NULL qw(:consts);

=over 4

=item B<NF_NULL_TYPE_IPv4>

=item B<NF_NULL_TYPE_ARP>

=item B<NF_NULL_TYPE_CGMP>

=item B<NF_NULL_TYPE_80211>

=item B<NF_NULL_TYPE_DDP>

=item B<NF_NULL_TYPE_AARP>

=item B<NF_NULL_TYPE_WCP>

=item B<NF_NULL_TYPE_8021Q>

=item B<NF_NULL_TYPE_IPX>

=item B<NF_NULL_TYPE_STP>

=item B<NF_NULL_TYPE_IPv6>

=item B<NF_NULL_TYPE_WLCCP>

=item B<NF_NULL_TYPE_PPPoED>

=item B<NF_NULL_TYPE_PPPoES>

=item B<NF_NULL_TYPE_8021X>

=item B<NF_NULL_TYPE_AoE>

=item B<NF_NULL_TYPE_LLDP>

=item B<NF_NULL_TYPE_LOOP>

=item B<NF_NULL_TYPE_VLAN>

=item B<NF_NULL_TYPE_ETH>

Various supported encapsulated layer types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
