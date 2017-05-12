#
# $Id: GRE.pm 23 2015-01-20 18:48:56Z gomor $
#
package Net::Frame::Layer::GRE;
use strict; use warnings;

our $VERSION = '1.05';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_GRE_HDR_LEN
      NF_GRE_TYPE_IPv4
      NF_GRE_TYPE_X25
      NF_GRE_TYPE_ARP
      NF_GRE_TYPE_CGMP
      NF_GRE_TYPE_80211
      NF_GRE_TYPE_PPPIPCP
      NF_GRE_TYPE_RARP
      NF_GRE_TYPE_DDP
      NF_GRE_TYPE_AARP
      NF_GRE_TYPE_PPPCCP
      NF_GRE_TYPE_WCP
      NF_GRE_TYPE_8021Q
      NF_GRE_TYPE_IPX
      NF_GRE_TYPE_STP
      NF_GRE_TYPE_IPv6
      NF_GRE_TYPE_WLCCP
      NF_GRE_TYPE_MPLS
      NF_GRE_TYPE_PPPoED
      NF_GRE_TYPE_PPPoES
      NF_GRE_TYPE_8021X
      NF_GRE_TYPE_AoE
      NF_GRE_TYPE_80211I
      NF_GRE_TYPE_LLDP
      NF_GRE_TYPE_LLTD
      NF_GRE_TYPE_LOOP
      NF_GRE_TYPE_VLAN
      NF_GRE_TYPE_PPPPAP
      NF_GRE_TYPE_PPPCHAP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_GRE_HDR_LEN   => 4;
use constant NF_GRE_TYPE_IPv4      => 0x0800;
use constant NF_GRE_TYPE_X25       => 0x0805;
use constant NF_GRE_TYPE_ARP       => 0x0806;
use constant NF_GRE_TYPE_CGMP      => 0x2001;
use constant NF_GRE_TYPE_80211     => 0x2452;
use constant NF_GRE_TYPE_PPPIPCP   => 0x8021;
use constant NF_GRE_TYPE_RARP      => 0x8035;
use constant NF_GRE_TYPE_DDP       => 0x809b;
use constant NF_GRE_TYPE_AARP      => 0x80f3;
use constant NF_GRE_TYPE_PPPCCP    => 0x80fd;
use constant NF_GRE_TYPE_WCP       => 0x80ff;
use constant NF_GRE_TYPE_8021Q     => 0x8100;
use constant NF_GRE_TYPE_IPX       => 0x8137;
use constant NF_GRE_TYPE_STP       => 0x8181;
use constant NF_GRE_TYPE_IPv6      => 0x86dd;
use constant NF_GRE_TYPE_WLCCP     => 0x872d;
use constant NF_GRE_TYPE_MPLS      => 0x8847;
use constant NF_GRE_TYPE_PPPoED    => 0x8863;
use constant NF_GRE_TYPE_PPPoES    => 0x8864;
use constant NF_GRE_TYPE_8021X     => 0x888e;
use constant NF_GRE_TYPE_AoE       => 0x88a2;
use constant NF_GRE_TYPE_80211I    => 0x88c7;
use constant NF_GRE_TYPE_LLDP      => 0x88cc;
use constant NF_GRE_TYPE_LLTD      => 0x88d9;
use constant NF_GRE_TYPE_LOOP      => 0x9000;
use constant NF_GRE_TYPE_VLAN      => 0x9100;
use constant NF_GRE_TYPE_PPPPAP    => 0xc023;
use constant NF_GRE_TYPE_PPPCHAP   => 0xc223;

our @AS = qw(
   flags
   protocol
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      flags    => 0,
      protocol => NF_GRE_TYPE_IPv4,
      @_,
   );
}

sub getLength { NF_GRE_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('nn',
      $self->[$__flags],
      $self->[$__protocol],
   ) or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($flags, $protocol, $payload) =
      $self->SUPER::unpack('nn a*', $self->[$__raw])
         or return undef;

   $self->[$__flags]    = $flags;
   $self->[$__protocol] = $protocol;
   $self->[$__payload]  = $payload;

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   my $types = {
      NF_GRE_TYPE_IPv4()    => 'IPv4',
      NF_GRE_TYPE_X25()     => 'X25',
      NF_GRE_TYPE_ARP()     => 'ARP',
      NF_GRE_TYPE_CGMP()    => 'CGMP',
      NF_GRE_TYPE_80211()   => '80211',
      NF_GRE_TYPE_PPPIPCP() => 'PPPIPCP',
      NF_GRE_TYPE_RARP()    => 'RARP',
      NF_GRE_TYPE_DDP ()    => 'DDP',
      NF_GRE_TYPE_AARP()    => 'AARP',
      NF_GRE_TYPE_PPPCCP()  => 'PPPCCP',
      NF_GRE_TYPE_WCP()     => 'WCP',
      NF_GRE_TYPE_8021Q()   => '8021Q',
      NF_GRE_TYPE_IPX()     => 'IPX',
      NF_GRE_TYPE_STP()     => 'STP',
      NF_GRE_TYPE_IPv6()    => 'IPv6',
      NF_GRE_TYPE_WLCCP()   => 'WLCCP',
      NF_GRE_TYPE_MPLS()    => 'MPLS',
      NF_GRE_TYPE_PPPoED()  => 'PPPoED',
      NF_GRE_TYPE_PPPoES()  => 'PPPoES',
      NF_GRE_TYPE_8021X()   => '8021X',
      NF_GRE_TYPE_AoE()     => 'AoE',
      NF_GRE_TYPE_80211I()  => '80211I',
      NF_GRE_TYPE_LLDP()    => 'LLDP',
      NF_GRE_TYPE_LLTD()    => 'LLTD',
      NF_GRE_TYPE_LOOP()    => 'LOOP',
      NF_GRE_TYPE_VLAN()    => 'VLAN',
      NF_GRE_TYPE_PPPPAP()  => 'PPPPAP',
      NF_GRE_TYPE_PPPCHAP() => 'PPPCHAP',
   };

   $types->{$self->[$__protocol]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: flags:0x%04x  protocol:0x%04x",
      $self->[$__flags], $self->[$__protocol];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::GRE - Generic Route Encapsulation layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::GRE qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::GRE->new(
      flags    => 0,
      protocol => NF_GRE_TYPE_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::GRE->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Generic Route Encapsulation layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<flags> - 16 bits

GRE header flags.

=item B<protocol> - 16 bits

Encapsulated protocol.

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

Load them: use Net::Frame::Layer::GRE qw(:consts);

=over 4

=item B<NF_GRE_TYPE_IPv4>

=item B<NF_GRE_TYPE_X25>

=item B<NF_GRE_TYPE_ARP>

=item B<NF_GRE_TYPE_CGMP>

=item B<NF_GRE_TYPE_80211>

=item B<NF_GRE_TYPE_PPPIPCP>

=item B<NF_GRE_TYPE_RARP>

=item B<NF_GRE_TYPE_DDP>

=item B<NF_GRE_TYPE_AARP>

=item B<NF_GRE_TYPE_PPPCCP>

=item B<NF_GRE_TYPE_WCP>

=item B<NF_GRE_TYPE_8021Q>

=item B<NF_GRE_TYPE_IPX>

=item B<NF_GRE_TYPE_STP>

=item B<NF_GRE_TYPE_IPv6>

=item B<NF_GRE_TYPE_WLCCP>

=item B<NF_GRE_TYPE_MPLS>

=item B<NF_GRE_TYPE_PPPoED>

=item B<NF_GRE_TYPE_PPPoES>

=item B<NF_GRE_TYPE_8021X>

=item B<NF_GRE_TYPE_AoE>

=item B<NF_GRE_TYPE_80211I>

=item B<NF_GRE_TYPE_LLDP>

=item B<NF_GRE_TYPE_LLTD>

=item B<NF_GRE_TYPE_LOOP>

=item B<NF_GRE_TYPE_VLAN>

=item B<NF_GRE_TYPE_PPPPAP>

=item B<NF_GRE_TYPE_PPPCHAP>

Various supported encapsulated layer types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
