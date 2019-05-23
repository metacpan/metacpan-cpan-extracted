#
# $Id: ETH.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::ETH;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_ETH_HDR_LEN
      NF_ETH_ADDR_BROADCAST
      NF_ETH_TYPE_IPv4
      NF_ETH_TYPE_X25
      NF_ETH_TYPE_ARP
      NF_ETH_TYPE_CGMP
      NF_ETH_TYPE_80211
      NF_ETH_TYPE_PPPIPCP
      NF_ETH_TYPE_RARP
      NF_ETH_TYPE_DDP
      NF_ETH_TYPE_AARP
      NF_ETH_TYPE_PPPCCP
      NF_ETH_TYPE_WCP
      NF_ETH_TYPE_8021Q
      NF_ETH_TYPE_IPX
      NF_ETH_TYPE_STP
      NF_ETH_TYPE_IPv6
      NF_ETH_TYPE_WLCCP
      NF_ETH_TYPE_MPLS
      NF_ETH_TYPE_PPPoED
      NF_ETH_TYPE_PPPoES
      NF_ETH_TYPE_8021X
      NF_ETH_TYPE_AoE
      NF_ETH_TYPE_80211I
      NF_ETH_TYPE_LLDP
      NF_ETH_TYPE_LLTD
      NF_ETH_TYPE_LOOP
      NF_ETH_TYPE_VLAN
      NF_ETH_TYPE_PPPPAP
      NF_ETH_TYPE_PPPCHAP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_ETH_HDR_LEN        => 14;
use constant NF_ETH_ADDR_BROADCAST => 'ff:ff:ff:ff:ff:ff';
use constant NF_ETH_TYPE_IPv4      => 0x0800;
use constant NF_ETH_TYPE_X25       => 0x0805;
use constant NF_ETH_TYPE_ARP       => 0x0806;
use constant NF_ETH_TYPE_CGMP      => 0x2001;
use constant NF_ETH_TYPE_80211     => 0x2452;
use constant NF_ETH_TYPE_PPPIPCP   => 0x8021;
use constant NF_ETH_TYPE_RARP      => 0x8035;
use constant NF_ETH_TYPE_DDP       => 0x809b;
use constant NF_ETH_TYPE_AARP      => 0x80f3;
use constant NF_ETH_TYPE_PPPCCP    => 0x80fd;
use constant NF_ETH_TYPE_WCP       => 0x80ff;
use constant NF_ETH_TYPE_8021Q     => 0x8100;
use constant NF_ETH_TYPE_IPX       => 0x8137;
use constant NF_ETH_TYPE_STP       => 0x8181;
use constant NF_ETH_TYPE_IPv6      => 0x86dd;
use constant NF_ETH_TYPE_WLCCP     => 0x872d;
use constant NF_ETH_TYPE_MPLS      => 0x8847;
use constant NF_ETH_TYPE_PPPoED    => 0x8863;
use constant NF_ETH_TYPE_PPPoES    => 0x8864;
use constant NF_ETH_TYPE_8021X     => 0x888e;
use constant NF_ETH_TYPE_AoE       => 0x88a2;
use constant NF_ETH_TYPE_80211I    => 0x88c7;
use constant NF_ETH_TYPE_LLDP      => 0x88cc;
use constant NF_ETH_TYPE_LLTD      => 0x88d9;
use constant NF_ETH_TYPE_LOOP      => 0x9000;
use constant NF_ETH_TYPE_VLAN      => 0x9100;
use constant NF_ETH_TYPE_PPPPAP    => 0xc023;
use constant NF_ETH_TYPE_PPPCHAP   => 0xc223;

our @AS = qw(
   dst
   src
   type
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

BEGIN {
   *length = \&type;
}

no strict 'vars';

sub new {
   my $self = shift->SUPER::new(
      src  => '00:00:00:00:00:00',
      dst  => NF_ETH_ADDR_BROADCAST,
      type => NF_ETH_TYPE_IPv4,
      @_,
   );

   $self->[$__src] = lc($self->[$__src]) if $self->[$__src];
   $self->[$__dst] = lc($self->[$__dst]) if $self->[$__dst];

   $self;
}

sub getLength { NF_ETH_HDR_LEN }

sub pack {
   my $self = shift;

   (my $dst = $self->[$__dst]) =~ s/://g;
   (my $src = $self->[$__src]) =~ s/://g;

   $self->[$__raw] = $self->SUPER::pack('H12H12n', $dst, $src, $self->[$__type])
      or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($dst, $src, $type, $payload) =
      $self->SUPER::unpack('H12H12n a*', $self->[$__raw])
         or return undef;

   $self->[$__dst] = convertMac($dst);
   $self->[$__src] = convertMac($src);

   $self->[$__type]    = $type;
   $self->[$__payload] = $payload;

   $self;
}

sub computeLengths {
   my $self = shift;
   my ($layers) = @_;
   if ($self->[$__type] <= 1500) {
      my $len = 0;
      for my $l (@$layers) {
         next if $l->layer eq 'ETH';
         # We do not use getLength(), because the layer may 
         # have a fake length, due to fuzzing or stress
         # testing attempts from the user
         $len += CORE::length($l->pack),
      }
      $self->type($len);
   }
   return 1;
}

our $Next = {
   NF_ETH_TYPE_IPv4()    => 'IPv4',
   NF_ETH_TYPE_X25()     => 'X25',
   NF_ETH_TYPE_ARP()     => 'ARP',
   NF_ETH_TYPE_CGMP()    => 'CGMP',
   NF_ETH_TYPE_80211()   => '80211',
   NF_ETH_TYPE_PPPIPCP() => 'PPPIPCP',
   NF_ETH_TYPE_RARP()    => 'RARP',
   NF_ETH_TYPE_DDP ()    => 'DDP',
   NF_ETH_TYPE_AARP()    => 'AARP',
   NF_ETH_TYPE_PPPCCP()  => 'PPPCCP',
   NF_ETH_TYPE_WCP()     => 'WCP',
   NF_ETH_TYPE_8021Q()   => '8021Q',
   NF_ETH_TYPE_IPX()     => 'IPX',
   NF_ETH_TYPE_STP()     => 'STP',
   NF_ETH_TYPE_IPv6()    => 'IPv6',
   NF_ETH_TYPE_WLCCP()   => 'WLCCP',
   NF_ETH_TYPE_MPLS()    => 'MPLS',
   NF_ETH_TYPE_PPPoED()  => 'PPPoED',
   NF_ETH_TYPE_PPPoES()  => 'PPPoES',
   NF_ETH_TYPE_8021X()   => '8021X',
   NF_ETH_TYPE_AoE()     => 'AoE',
   NF_ETH_TYPE_80211I()  => '80211I',
   NF_ETH_TYPE_LLDP()    => 'LLDP',
   NF_ETH_TYPE_LLTD()    => 'LLTD',
   NF_ETH_TYPE_LOOP()    => 'LOOP',
   NF_ETH_TYPE_VLAN()    => 'VLAN',
   NF_ETH_TYPE_PPPPAP()  => 'PPPPAP',
   NF_ETH_TYPE_PPPCHAP() => 'PPPCHAP',
};

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   # Is this a 802.3 layer ?
   if ($self->[$__type] <= 1500 && $self->[$__payload]) {
      my $payload = CORE::unpack('H*', $self->[$__payload]);
      # We consider this is a LLC layer if the payload is more than 6 bytes long
      if (CORE::length($payload) > 6) {
         return 'LLC';
      }
      return NF_LAYER_UNKNOWN;
   }

   $Next->{$self->[$__type]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: dst:%s  src:%s  ", $self->[$__dst], $self->[$__src];

   if ($self->[$__type] <= 1500) {
      $buf .= sprintf "length:%d", $self->[$__type];
   }
   else {
      $buf .= sprintf "type:0x%04x", $self->[$__type];
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ETH - Ethernet/802.3 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::ETH qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::ETH->new(
      src  => '00:00:00:00:00:00',
      dst  => NF_ETH_ADDR_BROADCAST,
      type => NF_ETH_TYPE_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ETH->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Ethernet/802.3 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc894.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<src>

=item B<dst>

Source and destination MAC addresses, in classical format (00:11:22:33:44:55).

=item B<type>

The encapsulated layer type (IPv4, IPv6 ...) for Ethernet. Values for Ethernet types are greater than 1500. If it is less than 1500 the layer is considered a 802.3 one. See http://www.iana.org/assignments/ethernet-numbers .

=item B<length>

The length of the payload when this layer is a 802.3 one. This is the same attribute as B<type>, but you cannot use it when calling B<new> (you can only use it as an accessor after that).

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

Load them: use Net::Frame::Layer::ETH qw(:consts);

=over 4

=item B<NF_ETH_ADDR_BROADCAST>

Ethernet broadcast address.

=item B<NF_ETH_TYPE_IPv4>

=item B<NF_ETH_TYPE_X25>

=item B<NF_ETH_TYPE_ARP>

=item B<NF_ETH_TYPE_CGMP>

=item B<NF_ETH_TYPE_80211>

=item B<NF_ETH_TYPE_PPPIPCP>

=item B<NF_ETH_TYPE_RARP>

=item B<NF_ETH_TYPE_DDP>

=item B<NF_ETH_TYPE_AARP>

=item B<NF_ETH_TYPE_PPPCCP>

=item B<NF_ETH_TYPE_WCP>

=item B<NF_ETH_TYPE_8021Q>

=item B<NF_ETH_TYPE_IPX>

=item B<NF_ETH_TYPE_STP>

=item B<NF_ETH_TYPE_IPv6>

=item B<NF_ETH_TYPE_WLCCP>

=item B<NF_ETH_TYPE_MPLS>

=item B<NF_ETH_TYPE_PPPoED>

=item B<NF_ETH_TYPE_PPPoES>

=item B<NF_ETH_TYPE_8021X>

=item B<NF_ETH_TYPE_AoE>

=item B<NF_ETH_TYPE_80211I>

=item B<NF_ETH_TYPE_LLDP>

=item B<NF_ETH_TYPE_LLTD>

=item B<NF_ETH_TYPE_LOOP>

=item B<NF_ETH_TYPE_VLAN>

=item B<NF_ETH_TYPE_PPPPAP>

=item B<NF_ETH_TYPE_PPPCHAP>

Various supported Ethernet types.

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
