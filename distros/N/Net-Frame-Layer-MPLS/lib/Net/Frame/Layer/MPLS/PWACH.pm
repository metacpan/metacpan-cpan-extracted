#
# $Id: PWACH.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::MPLS::PWACH;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_MPLS_PWNIBBLE_ACH
      NF_MPLS_PWACHTYPE_RESERVED
      NF_MPLS_PWACHTYPE_MCC
      NF_MPLS_PWACHTYPE_SCC
      NF_MPLS_PWACHTYPE_BFD
      NF_MPLS_PWACHTYPE_SBFD
      NF_MPLS_PWACHTYPE_DLM
      NF_MPLS_PWACHTYPE_ILM
      NF_MPLS_PWACHTYPE_DM
      NF_MPLS_PWACHTYPE_DLMDM
      NF_MPLS_PWACHTYPE_ILMDM
      NF_MPLS_PWACHTYPE_IPv4
      NF_MPLS_PWACHTYPE_TPCC
      NF_MPLS_PWACHTYPE_TPCV
      NF_MPLS_PWACHTYPE_PSCCT
      NF_MPLS_PWACHTYPE_ODCV
      NF_MPLS_PWACHTYPE_LI
      NF_MPLS_PWACHTYPE_OAM
      NF_MPLS_PWACHTYPE_MACOAM
      NF_MPLS_PWACHTYPE_IPv6
      NF_MPLS_PWACHTYPE_FAULTOAM
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_MPLS_PWNIBBLE_ACH => 1;

use constant NF_MPLS_PWACHTYPE_RESERVED => 0x0000;
use constant NF_MPLS_PWACHTYPE_MCC      => 0x0001;
use constant NF_MPLS_PWACHTYPE_SCC      => 0x0002;
use constant NF_MPLS_PWACHTYPE_BFD      => 0x0007;
use constant NF_MPLS_PWACHTYPE_SBFD     => 0x0008;
use constant NF_MPLS_PWACHTYPE_DLM      => 0x000a;
use constant NF_MPLS_PWACHTYPE_ILM      => 0x000b;
use constant NF_MPLS_PWACHTYPE_DM       => 0x000c;
use constant NF_MPLS_PWACHTYPE_DLMDM    => 0x000d;
use constant NF_MPLS_PWACHTYPE_ILMDM    => 0x000e;
use constant NF_MPLS_PWACHTYPE_IPv4     => 0x0021;
use constant NF_MPLS_PWACHTYPE_TPCC     => 0x0022;
use constant NF_MPLS_PWACHTYPE_TPCV     => 0x0023;
use constant NF_MPLS_PWACHTYPE_PSCCT    => 0x0024;
use constant NF_MPLS_PWACHTYPE_ODCV     => 0x0025;
use constant NF_MPLS_PWACHTYPE_LI       => 0x0026;
use constant NF_MPLS_PWACHTYPE_OAM      => 0x0027;
use constant NF_MPLS_PWACHTYPE_MACOAM   => 0x0028;
use constant NF_MPLS_PWACHTYPE_IPv6     => 0x0057;
use constant NF_MPLS_PWACHTYPE_FAULTOAM => 0x0058;

our @AS = qw(
   pwNibble
   version
   reserved
   channelType
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Bit::Vector;

sub new {
   shift->SUPER::new(
      pwNibble    => NF_MPLS_PWNIBBLE_ACH,
      version     => 0,
      reserved    => 0,
      channelType => NF_MPLS_PWACHTYPE_IPv4,
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $pwNibble = Bit::Vector->new_Dec(4, $self->pwNibble);
   my $version  = Bit::Vector->new_Dec(4, $self->version);
   my $bvlist   = $pwNibble->Concat_List($version);

   my $raw = $self->SUPER::pack('CCn',
      $bvlist->to_Dec,
      $self->reserved,
      $self->channelType
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $reserved, $channelType, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(8, $bv);
   $self->pwNibble($bvlist->Chunk_Read(4,4));
   $self->version ($bvlist->Chunk_Read(4,0));

   $self->reserved($reserved);
   $self->channelType($channelType);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->channelType == NF_MPLS_PWACHTYPE_IPv4) {
      return 'IPv4';
   } elsif ($self->channelType == NF_MPLS_PWACHTYPE_IPv6) {
      return 'IPv6';
   }

   if ($self->payload) {
      my $payload = CORE::unpack('H', $self->payload);
      if ($payload == 0) {
         return 'PWACH::PWMCW';
      } elsif ($payload == NF_MPLS_PWNIBBLE_ACH) {
         return 'PWACH::PWACH';
      } elsif ($payload == 4) {
         return 'IPv4';
      } elsif ($payload == 6) {
         return 'IPv6';
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: pwNibble:%d  version:%d  reserved:%d  channelType:0x%04x",
         $self->pwNibble, $self->version, $self->reserved, $self->channelType;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::MPLS::PWACH - MPLS Pseudowire Associated Channel Header layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::MPLS::PWACH qw(:consts);

   my $layer = Net::Frame::Layer::MPLS::PWACH->new(
      pwNibble    => NF_MPLS_PWNIBBLE_ACH,
      version     => 0,
      reserved    => 0,
      channelType => NF_MPLS_PWACHTYPE_IPv4,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::MPLS::PWACH->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MPLS Pseudowire Associated Channel Header layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc4385.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<pwNibble>

PWACH first nibble - default 1.

=item B<version>

PWACH version - default 0.

=item B<reserved>

Reserved - default 0.

=item B<channelType>

PWACH channel type.

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

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::MPLS::PWACH qw(:consts);

=over 4

=item B<NF_MPLS_PWNIBBLE_ACH>

Pseudowire first nibble.

=item B<NF_MPLS_PWACHTYPE_RESERVED>

=item B<NF_MPLS_PWACHTYPE_MCC>

=item B<NF_MPLS_PWACHTYPE_SCC>

=item B<NF_MPLS_PWACHTYPE_BFD>

=item B<NF_MPLS_PWACHTYPE_SBFD>

=item B<NF_MPLS_PWACHTYPE_DLM>

=item B<NF_MPLS_PWACHTYPE_ILM>

=item B<NF_MPLS_PWACHTYPE_DM>

=item B<NF_MPLS_PWACHTYPE_DLMDM>

=item B<NF_MPLS_PWACHTYPE_ILMDM>

=item B<NF_MPLS_PWACHTYPE_IPv4>

=item B<NF_MPLS_PWACHTYPE_TPCC>

=item B<NF_MPLS_PWACHTYPE_TPCV>

=item B<NF_MPLS_PWACHTYPE_PSCCT>

=item B<NF_MPLS_PWACHTYPE_ODCV>

=item B<NF_MPLS_PWACHTYPE_LI>

=item B<NF_MPLS_PWACHTYPE_OAM>

=item B<NF_MPLS_PWACHTYPE_MACOAM>

=item B<NF_MPLS_PWACHTYPE_IPv6>

=item B<NF_MPLS_PWACHTYPE_FAULTOAM>

Pseudowire Associated Channel types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
