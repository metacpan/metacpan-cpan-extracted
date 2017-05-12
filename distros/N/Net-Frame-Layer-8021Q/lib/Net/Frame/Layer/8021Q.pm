#
# $Id: 8021Q.pm 10 2015-01-20 18:42:55Z gomor $
#
package Net::Frame::Layer::8021Q;
use strict; use warnings;

our $VERSION = '1.03';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_8021Q_HDR_LEN
      NF_8021Q_TYPE_IPv4
      NF_8021Q_TYPE_X25
      NF_8021Q_TYPE_ARP
      NF_8021Q_TYPE_CGMP
      NF_8021Q_TYPE_80211
      NF_8021Q_TYPE_PPPIPCP
      NF_8021Q_TYPE_RARP
      NF_8021Q_TYPE_DDP
      NF_8021Q_TYPE_AARP
      NF_8021Q_TYPE_PPPCCP
      NF_8021Q_TYPE_WCP
      NF_8021Q_TYPE_8021Q
      NF_8021Q_TYPE_IPX
      NF_8021Q_TYPE_STP
      NF_8021Q_TYPE_IPv6
      NF_8021Q_TYPE_WLCCP
      NF_8021Q_TYPE_MPLS
      NF_8021Q_TYPE_PPPoED
      NF_8021Q_TYPE_PPPoES
      NF_8021Q_TYPE_8021X
      NF_8021Q_TYPE_AoE
      NF_8021Q_TYPE_80211I
      NF_8021Q_TYPE_LLDP
      NF_8021Q_TYPE_LLTD
      NF_8021Q_TYPE_LOOP
      NF_8021Q_TYPE_VLAN
      NF_8021Q_TYPE_PPPPAP
      NF_8021Q_TYPE_PPPCHAP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_8021Q_HDR_LEN        => 4;
use constant NF_8021Q_TYPE_IPv4      => 0x0800;
use constant NF_8021Q_TYPE_X25       => 0x0805;
use constant NF_8021Q_TYPE_ARP       => 0x0806;
use constant NF_8021Q_TYPE_CGMP      => 0x2001;
use constant NF_8021Q_TYPE_80211     => 0x2452;
use constant NF_8021Q_TYPE_PPPIPCP   => 0x8021;
use constant NF_8021Q_TYPE_RARP      => 0x8035;
use constant NF_8021Q_TYPE_DDP       => 0x809b;
use constant NF_8021Q_TYPE_AARP      => 0x80f3;
use constant NF_8021Q_TYPE_PPPCCP    => 0x80fd;
use constant NF_8021Q_TYPE_WCP       => 0x80ff;
use constant NF_8021Q_TYPE_8021Q     => 0x8100;
use constant NF_8021Q_TYPE_IPX       => 0x8137;
use constant NF_8021Q_TYPE_STP       => 0x8181;
use constant NF_8021Q_TYPE_IPv6      => 0x86dd;
use constant NF_8021Q_TYPE_WLCCP     => 0x872d;
use constant NF_8021Q_TYPE_MPLS      => 0x8847;
use constant NF_8021Q_TYPE_PPPoED    => 0x8863;
use constant NF_8021Q_TYPE_PPPoES    => 0x8864;
use constant NF_8021Q_TYPE_8021X     => 0x888e;
use constant NF_8021Q_TYPE_AoE       => 0x88a2;
use constant NF_8021Q_TYPE_80211I    => 0x88c7;
use constant NF_8021Q_TYPE_LLDP      => 0x88cc;
use constant NF_8021Q_TYPE_LLTD      => 0x88d9;
use constant NF_8021Q_TYPE_LOOP      => 0x9000;
use constant NF_8021Q_TYPE_VLAN      => 0x9100;
use constant NF_8021Q_TYPE_PPPPAP    => 0xc023;
use constant NF_8021Q_TYPE_PPPCHAP   => 0xc223;

our @AS = qw(
   priority
   cfi
   id
   type
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

require Bit::Vector;

sub new {
   shift->SUPER::new(
      priority => 0,
      cfi      => 0,
      id       => 0,
      type     => NF_8021Q_TYPE_IPv4,
      @_,
   );
}

sub getLength { NF_8021Q_HDR_LEN }

sub pack {
   my $self = shift;

   my $v3  = Bit::Vector->new_Dec( 3, $self->[$__priority]);
   my $v1  = Bit::Vector->new_Dec( 1, $self->[$__cfi]);
   my $v12 = Bit::Vector->new_Dec(12, $self->[$__id]);
   my $v16 = $v3->Concat_List($v1, $v12);

   $self->[$__raw] = $self->SUPER::pack('nn',
      $v16->to_Dec,
      $self->[$__type],
   ) or return undef;

   $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($pCfiId, $type, $payload) =
      $self->SUPER::unpack('nn a*', $self->[$__raw])
         or return undef;

   my $v16 = Bit::Vector->new_Dec(16, $pCfiId);

   $self->[$__priority] = $v16->Chunk_Read( 3, 13);
   $self->[$__cfi]      = $v16->Chunk_Read( 1, 12);
   $self->[$__id]       = $v16->Chunk_Read(12,  0);
   $self->[$__type]     = $type;
   $self->[$__payload]  = $payload;

   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   my $types = {
      NF_8021Q_TYPE_IPv4()    => 'IPv4',
      NF_8021Q_TYPE_X25()     => 'X25',
      NF_8021Q_TYPE_ARP()     => 'ARP',
      NF_8021Q_TYPE_CGMP()    => 'CGMP',
      NF_8021Q_TYPE_80211()   => '80211',
      NF_8021Q_TYPE_PPPIPCP() => 'PPPIPCP',
      NF_8021Q_TYPE_RARP()    => 'RARP',
      NF_8021Q_TYPE_DDP()     => 'DDP',
      NF_8021Q_TYPE_AARP()    => 'AARP',
      NF_8021Q_TYPE_PPPCCP()  => 'PPPCCP',
      NF_8021Q_TYPE_WCP()     => 'WCP',
      NF_8021Q_TYPE_8021Q()   => '8021Q',
      NF_8021Q_TYPE_IPX()     => 'IPX',
      NF_8021Q_TYPE_STP()     => 'STP',
      NF_8021Q_TYPE_IPv6()    => 'IPv6',
      NF_8021Q_TYPE_WLCCP()   => 'WLCCP',
      NF_8021Q_TYPE_MPLS()    => 'MPLS',
      NF_8021Q_TYPE_PPPoED()  => 'PPPoED',
      NF_8021Q_TYPE_PPPoES()  => 'PPPoES',
      NF_8021Q_TYPE_8021X()   => '8021X',
      NF_8021Q_TYPE_AoE()     => 'AoE',
      NF_8021Q_TYPE_80211I()  => '80211I',
      NF_8021Q_TYPE_LLDP()    => 'LLDP',
      NF_8021Q_TYPE_LLTD()    => 'LLTD',
      NF_8021Q_TYPE_LOOP()    => 'LOOP',
      NF_8021Q_TYPE_VLAN()    => 'VLAN',
      NF_8021Q_TYPE_PPPPAP()  => 'PPPPAP',
      NF_8021Q_TYPE_PPPCHAP() => 'PPPCHAP',
   };

   if ($self->[$__type] <= 1500 && $self->[$__payload]) {
      my $payload = CORE::unpack('H*', $self->[$__payload]);
      if ($payload =~ /^aaaa/) {
         return 'LLC';
      }
      return NF_LAYER_UNKNOWN;
   }

   $types->{$self->type} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: priority:0x%01x  cfi:0x%01x  id:%d  type:0x%02x",
      $self->[$__priority], $self->[$__cfi], $self->[$__id], $self->[$__type];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::8021Q - 802.1Q layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::8021Q qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::8021Q->new(
      priority => 0,
      cfi      => 0,
      id       => 0,
      type     => NF_8021Q_TYPE_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::8021Q->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the 802.1Q layer.

Details: http://standards.ieee.org/getieee802/802.1.html

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<priority>

The priority field.

=item B<cfi>

The cfi field. It is only one bit long, so set it to 0 or 1.

=item B<id>

8021Q tag id. You'll love it.

=item B<type>

Which type the next encapsulated layer is.

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

Load them: use Net::Frame::Layer::8021Q qw(:consts);

=over 4

=item B<NF_8021Q_TYPE_IPv4>

=item B<NF_8021Q_TYPE_X25>

=item B<NF_8021Q_TYPE_ARP>

=item B<NF_8021Q_TYPE_CGMP>

=item B<NF_8021Q_TYPE_80211>

=item B<NF_8021Q_TYPE_PPPIPCP>

=item B<NF_8021Q_TYPE_RARP>

=item B<NF_8021Q_TYPE_DDP>

=item B<NF_8021Q_TYPE_AARP>

=item B<NF_8021Q_TYPE_PPPCCP>

=item B<NF_8021Q_TYPE_WCP>

=item B<NF_8021Q_TYPE_8021Q>

=item B<NF_8021Q_TYPE_IPX>

=item B<NF_8021Q_TYPE_STP>

=item B<NF_8021Q_TYPE_IPv6>

=item B<NF_8021Q_TYPE_WLCCP>

=item B<NF_8021Q_TYPE_MPLS>

=item B<NF_8021Q_TYPE_PPPoED>

=item B<NF_8021Q_TYPE_PPPoES>

=item B<NF_8021Q_TYPE_8021X>

=item B<NF_8021Q_TYPE_AoE>

=item B<NF_8021Q_TYPE_80211I>

=item B<NF_8021Q_TYPE_LLDP>

=item B<NF_8021Q_TYPE_LLTD>

=item B<NF_8021Q_TYPE_LOOP>

=item B<NF_8021Q_TYPE_VLAN>

=item B<NF_8021Q_TYPE_PPPPAP>

=item B<NF_8021Q_TYPE_PPPCHAP>

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
