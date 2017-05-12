#
# $Id: CDP.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

use Net::Frame::Layer::CDP::Constants qw(:consts);
use Net::Frame::Layer::CDP::DeviceId;
use Net::Frame::Layer::CDP::Addresses;
use Net::Frame::Layer::CDP::Address qw(:consts);
use Net::Frame::Layer::CDP::PortId;
use Net::Frame::Layer::CDP::Capabilities qw(:consts);
use Net::Frame::Layer::CDP::SoftwareVersion;
use Net::Frame::Layer::CDP::Platform;
use Net::Frame::Layer::CDP::IPNetPrefix;
use Net::Frame::Layer::CDP::VTPDomain;
use Net::Frame::Layer::CDP::NativeVlan;
use Net::Frame::Layer::CDP::Duplex qw(:consts);
use Net::Frame::Layer::CDP::VoipVlanReply;
use Net::Frame::Layer::CDP::VoipVlanQuery;
use Net::Frame::Layer::CDP::Power;
use Net::Frame::Layer::CDP::MTU;
use Net::Frame::Layer::CDP::TrustBitmap qw(:consts);
use Net::Frame::Layer::CDP::UntrustedCos;
use Net::Frame::Layer::CDP::ManagementAddresses;
use Net::Frame::Layer::CDP::Unknown;

my @consts;
for my $c (sort(keys(%constant::declared))) {
    if ($c =~ /^Net::Frame::Layer::CDP::Constants::/) {
        $c =~ s/^Net::Frame::Layer::CDP::Constants:://;
        push @consts, $c
    }
    if ($c =~ /^Net::Frame::Layer::CDP::Address::/) {
        $c =~ s/^Net::Frame::Layer::CDP::Address:://;
        push @consts, $c
    }
    if ($c =~ /^Net::Frame::Layer::CDP::Capabilities::/) {
        $c =~ s/^Net::Frame::Layer::CDP::Capabilities:://;
        push @consts, $c
    }
    if ($c =~ /^Net::Frame::Layer::CDP::Duplex::/) {
        $c =~ s/^Net::Frame::Layer::CDP::Duplex:://;
        push @consts, $c
    }
    if ($c =~ /^Net::Frame::Layer::CDP::TrustBitmap::/) {
        $c =~ s/^Net::Frame::Layer::CDP::TrustBitmap:://;
        push @consts, $c
    }
}
our %EXPORT_TAGS = (
   consts => [qw(
      NF_CDP_MAC
      NF_CDP_VERSION_1
      NF_CDP_VERSION_2
   ), @consts],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_CDP_MAC => '01:00:0c:cc:cc:cc';
use constant NF_CDP_VERSION_1 => 1;
use constant NF_CDP_VERSION_2 => 2;

our @AS = qw(
   version
   ttl
   checksum
);
# Needed because subsequent NFL::CDP::Layers are stacked and can't 
# return to NFL::CDP for dispatch.  This isn't exposed for user 
# configuration, only for storing values in unpack() for later display.
our @AA = qw(
   tlvs
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

no strict 'vars';

sub new {
   shift->SUPER::new(
      version  => NF_CDP_VERSION_2,
      ttl      => 180,
      checksum => 0,
      tlvs     => [],
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCn',
      $self->version,
      $self->ttl,
      $self->checksum
   ) or return;

   return $self->raw($raw);
}

sub _unpackOptions {
   my $self = shift;
   my ($payload) = @_;

   my @tlvs = ();
   while (defined($payload) && (length($payload) > 0)) {
      my $tlv;
      # don't unpack $type from $payload as the entire $payload
      # including $type must get dispatched in if/then below
      my $type = substr $payload, 0, 2;
      $type = CORE::unpack('n', $type);
      if      ($type == NF_CDP_TYPE_DEVICE_ID) {
         $tlv = Net::Frame::Layer::CDP::DeviceId->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_ADDRESSES) {
         $tlv = Net::Frame::Layer::CDP::Addresses->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_PORT_ID) {
         $tlv = Net::Frame::Layer::CDP::PortId->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_CAPABILITIES) {
         $tlv = Net::Frame::Layer::CDP::Capabilities->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_SOFTWARE_VERSION) {
         $tlv = Net::Frame::Layer::CDP::SoftwareVersion->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_PLATFORM) {
         $tlv = Net::Frame::Layer::CDP::Platform->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_IPNET_PREFIX) {
         $tlv = Net::Frame::Layer::CDP::IPNetPrefix->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_VTP_DOMAIN) {
         $tlv = Net::Frame::Layer::CDP::VTPDomain->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_NATIVE_VLAN) {
         $tlv = Net::Frame::Layer::CDP::NativeVlan->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_DUPLEX) {
         $tlv = Net::Frame::Layer::CDP::Duplex->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_VOIP_VLAN_REPLY) {
         $tlv = Net::Frame::Layer::CDP::VoipVlanReply->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_VOIP_VLAN_QUERY) {
         $tlv = Net::Frame::Layer::CDP::VoipVlanQuery->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_POWER) {
         $tlv = Net::Frame::Layer::CDP::Power->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_MTU) {
         $tlv = Net::Frame::Layer::CDP::MTU->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_TRUST_BITMAP) {
         $tlv = Net::Frame::Layer::CDP::TrustBitmap->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_UNTRUSTED_COS) {
         $tlv = Net::Frame::Layer::CDP::UntrustedCos->new(raw => $payload)->unpack;
      } elsif ($type == NF_CDP_TYPE_MANAGEMENT_ADDR) {
         $tlv = Net::Frame::Layer::CDP::ManagementAddresses->new(raw => $payload)->unpack;
      } else {
         $tlv = Net::Frame::Layer::CDP::Unknown->new(raw => $payload)->unpack;
      }
      push @tlvs, $tlv;
      $payload = $tlv->payload;
      $tlv->payload(undef);
   }
   $self->tlvs(\@tlvs);

   return $payload;
}

sub unpack {
   my $self = shift;

   my ($version, $ttl, $checksum, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   $self->version($version);
   $self->ttl($ttl);
   $self->checksum($checksum);

   if (defined($payload) && length($payload)) {
      $payload = $self->_unpackOptions($payload);
   }

   $self->payload($payload);

   return $self;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $phpkt = $self->SUPER::pack('CCn',
         $self->version, $self->ttl, 0)
            or return;

   my $start   = 0;
   my $last    = $self;
   my $payload = '';
   for my $l (@$layers) {
      $last = $l;
      if (! $start) {
         $start++ if $l->layer eq 'CDP';
         next;
      }
      $payload .= $l->pack;
   }

   if (defined($last->payload) && length($last->payload)) {
      $payload .= $last->payload;
   }

   # From wireshark: packet-cdp.c
   # http://fossies.org/dox/wireshark-1.9.1/packet-cdp_8c_source.html
   # /* CDP doesn't adhere to RFC 1071 section 2. (B). It incorrectly assumes
   # * checksums are calculated on a big endian platform, therefore i.s.o.
   # * padding odd sized data with a zero byte _at the end_ it sets the last
   # * big endian _word_ to contain the last network _octet_. This byteswap
   # * has to be done on the last octet of network data before feeding it to
   # * the Internet checksum routine.
   # * CDP checksumming code has a bug in the addition of this last _word_
   # * as a signed number into the long word intermediate checksum. When
   # * reducing this long to word size checksum an off-by-one error can be
   # * made. This off-by-one error is compensated for in the last _word_ of
   # * the network data.
   # */
   # See:  http://www.perlmonks.org/?node_id=1026156   
###DEBUG: printf "BEFORE = %s\n", (CORE::unpack "H*", $payload);
   if (length( $payload )%2) {
      if (substr($payload, -1) ge "\x80") {
         substr $payload, -1, 1, chr(ord(substr $payload, -1) - 1);
         substr $payload, -1, 0, "\xff";
      } else {
         substr $payload, -1, 0, "\0";
      }
   }
###DEBUG: printf "AFTER  = %s\n", (CORE::unpack "H*", $payload);

   if (length($payload)) {
      $phpkt .= $self->SUPER::pack('a*', $payload)
         or return;
   }

   $self->checksum(inetChecksum($phpkt));

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   # if ($self->payload) {
      # return 'CDP';
   # }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  ttl:%d  checksum:0x%04x",
         $self->version, $self->ttl, $self->checksum;

   for ($self->tlvs) {
      $buf .= "\n" . $_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP - Cisco Discovery Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP->new(
      version  => NF_CDP_VERSION_2,
      ttl      => 180,
      checksum => 0,
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the CDP layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

CDP version.

=item B<ttl>

Amount of time, in seconds, that a receiver should retain the information.

=item B<checksum>

CDP checksum.

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

=item B<computeChecksums>

Computes the CDP checksum.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getOptionsLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::CDP qw(:consts);

=over 4

=item B<NF_CDP_MAC>

Default Layer 2 destination address.

=item B<NF_CDP_VERSION_1>

=item B<NF_CDP_VERSION_2>

CDP version.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 ACKNOWLEDGEMENTS

Ported from the L<Net::Packet::CDP> modules by Patrice E<lt>GomoRE<gt> Auffret.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
