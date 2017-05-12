#
# $Id: LLTD.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_LLTD_TOS_TOPOLOGY_DISCOVERY
      NF_LLTD_TOS_QUICK_DISCOVERY
      NF_LLTD_TOS_QOS_DIAGNOSTICS
      NF_LLTD_FUNCTION_DISCOVER
      NF_LLTD_FUNCTION_HELLO
      NF_LLTD_FUNCTION_EMIT
      NF_LLTD_FUNCTION_TRAIN
      NF_LLTD_FUNCTION_PROBE
      NF_LLTD_FUNCTION_ACK
      NF_LLTD_FUNCTION_QUERY
      NF_LLTD_FUNCTION_QUERY_RESP
      NF_LLTD_FUNCTION_RESET
      NF_LLTD_FUNCTION_CHARGE
      NF_LLTD_FUNCTION_FLAT
      NF_LLTD_FUNCTION_QUERY_LARGE_TLV
      NF_LLTD_FUNCTION_QUERY_LARGE_TLV_RESP
      NF_LLTD_TLV_TYPE_EOP
      NF_LLTD_TLV_TYPE_HOSTID
      NF_LLTD_TLV_TYPE_CHARACTERISTICS
      NF_LLTD_TLV_TYPE_PHYSICALMEDIUM
      NF_LLTD_TLV_TYPE_WIRELESSMODE
      NF_LLTD_TLV_TYPE_BSSID
      NF_LLTD_TLV_TYPE_SSID
      NF_LLTD_TLV_TYPE_IPv4ADDRESS
      NF_LLTD_TLV_TYPE_IPv6ADDRESS
      NF_LLTD_TLV_TYPE_MAXOPRATE
      NF_LLTD_TLV_TYPE_PERFCOUNTER
      NF_LLTD_TLV_TYPE_LINKSPEED
      NF_LLTD_TLV_TYPE_RSSI
      NF_LLTD_TLV_TYPE_ICONIMAGE
      NF_LLTD_TLV_TYPE_MACHINENAME
      NF_LLTD_TLV_TYPE_SUPPORTINFO
      NF_LLTD_TLV_TYPE_FRIENDLYNAME
      NF_LLTD_TLV_TYPE_UUID
      NF_LLTD_TLV_TYPE_HARDWAREID
      NF_LLTD_TLV_TYPE_QOSCHARACTERISTICS
      NF_LLTD_TLV_TYPE_WIRELESSPHYSICALMEDIUM
      NF_LLTD_TLV_TYPE_APTABLE
      NF_LLTD_TLV_TYPE_DETAILEDICONIMAGE
      NF_LLTD_TLV_TYPE_SEESLISTCOUNT
      NF_LLTD_TLV_TYPE_COMPONENTTABLE
      NF_LLTD_TLV_TYPE_REPEATERAP
      NF_LLTD_TLV_TYPE_REPEATERAPTABLE
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_LLTD_TOS_TOPOLOGY_DISCOVERY => 0x00;
use constant NF_LLTD_TOS_QUICK_DISCOVERY    => 0x01;
use constant NF_LLTD_TOS_QOS_DIAGNOSTICS    => 0x02;

use constant NF_LLTD_FUNCTION_DISCOVER             => 0x00;
use constant NF_LLTD_FUNCTION_HELLO                => 0x01;
use constant NF_LLTD_FUNCTION_EMIT                 => 0x02;
use constant NF_LLTD_FUNCTION_TRAIN                => 0x03; # No upper
use constant NF_LLTD_FUNCTION_PROBE                => 0x04; # No upper
use constant NF_LLTD_FUNCTION_ACK                  => 0x05; # No upper
use constant NF_LLTD_FUNCTION_QUERY                => 0x06; # No upper
use constant NF_LLTD_FUNCTION_QUERY_RESP           => 0x07;
use constant NF_LLTD_FUNCTION_RESET                => 0x08; # No upper
use constant NF_LLTD_FUNCTION_CHARGE               => 0x09; # No upper
use constant NF_LLTD_FUNCTION_FLAT                 => 0x0a; # XXX: TODO
use constant NF_LLTD_FUNCTION_QUERY_LARGE_TLV      => 0x0b; # XXX: TODO
use constant NF_LLTD_FUNCTION_QUERY_LARGE_TLV_RESP => 0x0c; # XXX: TODO

use constant NF_LLTD_TLV_TYPE_EOP                    => 0x00;
use constant NF_LLTD_TLV_TYPE_HOSTID                 => 0x01;
use constant NF_LLTD_TLV_TYPE_CHARACTERISTICS        => 0x02;
use constant NF_LLTD_TLV_TYPE_PHYSICALMEDIUM         => 0x03;
use constant NF_LLTD_TLV_TYPE_WIRELESSMODE           => 0x04;
use constant NF_LLTD_TLV_TYPE_BSSID                  => 0x05;
use constant NF_LLTD_TLV_TYPE_SSID                   => 0x06;
use constant NF_LLTD_TLV_TYPE_IPv4ADDRESS            => 0x07;
use constant NF_LLTD_TLV_TYPE_IPv6ADDRESS            => 0x08;
use constant NF_LLTD_TLV_TYPE_MAXOPRATE              => 0x09;
use constant NF_LLTD_TLV_TYPE_PERFCOUNTER            => 0x0a;
use constant NF_LLTD_TLV_TYPE_LINKSPEED              => 0x0c;
use constant NF_LLTD_TLV_TYPE_RSSI                   => 0x0d;
use constant NF_LLTD_TLV_TYPE_ICONIMAGE              => 0x0e;
use constant NF_LLTD_TLV_TYPE_MACHINENAME            => 0x0f;
use constant NF_LLTD_TLV_TYPE_SUPPORTINFO            => 0x10;
use constant NF_LLTD_TLV_TYPE_FRIENDLYNAME           => 0x11;
use constant NF_LLTD_TLV_TYPE_UUID                   => 0x12;
use constant NF_LLTD_TLV_TYPE_HARDWAREID             => 0x13;
use constant NF_LLTD_TLV_TYPE_QOSCHARACTERISTICS     => 0x14;
use constant NF_LLTD_TLV_TYPE_WIRELESSPHYSICALMEDIUM => 0x15;
use constant NF_LLTD_TLV_TYPE_APTABLE                => 0x16;
use constant NF_LLTD_TLV_TYPE_DETAILEDICONIMAGE      => 0x18;
use constant NF_LLTD_TLV_TYPE_SEESLISTCOUNT          => 0x19;
use constant NF_LLTD_TLV_TYPE_COMPONENTTABLE         => 0x1a;
use constant NF_LLTD_TLV_TYPE_REPEATERAP             => 0x1b;
use constant NF_LLTD_TLV_TYPE_REPEATERAPTABLE        => 0x1c;

#The following functions are valid for service type 0x02:
#0x00 = QosInitializeSink
#0x01 = QosReady
#0x02 = QosProbe
#0x03 = QosQuery
#0x04 = QosQueryResp
#0x05 = QosReset
#0x06 = QosError
#0x07 = QosAck
#0x08 = QosCounterSnapshot
#0x09 = QosCounterResult
#0x0A = QosCounterLease

our @AS = qw(
   version
   tos
   reserved
   function
   networkAddress1
   networkAddress2
   identifier
   upperLayer
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::LLTD::Discover;
use Net::Frame::Layer::LLTD::Hello;
use Net::Frame::Layer::LLTD::Emit;
use Net::Frame::Layer::LLTD::QueryResp;

sub new {
   shift->SUPER::new(
      version         => 1,
      tos             => NF_LLTD_TOS_TOPOLOGY_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_DISCOVER,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => 'ff:ff:ff:ff:ff:ff',
      identifier      => getRandom16bitsInt(),
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 18;
   $len += $self->upperLayer->getLength if $self->upperLayer;
   $len;
}

sub pack {
   my $self = shift;

   (my $dst = $self->networkAddress1) =~ s/://g;
   (my $src = $self->networkAddress2) =~ s/://g;

   my $raw = $self->SUPER::pack('CCCCH12H12n',
      $self->version,
      $self->tos,
      $self->reserved,
      $self->function,
      $dst,
      $src,
      $self->identifier,
   ) or return undef;

   $raw .= $self->upperLayer->pack if $self->upperLayer;

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($version, $tos, $reserved, $function, $dst, $src, $identifier,
       $payload) = $self->SUPER::unpack('CCCCH12H12n a*', $self->raw)
         or return undef;

   $self->version($version);
   $self->tos($tos);
   $self->reserved($reserved);
   $self->function($function);
   $self->networkAddress1(convertMac($dst));
   $self->networkAddress2(convertMac($src));
   $self->identifier($identifier);

   my $upperLayer;
   if ($self->tos == NF_LLTD_TOS_QUICK_DISCOVERY
   ||  $self->tos == NF_LLTD_TOS_TOPOLOGY_DISCOVERY) {
      if ($self->function == NF_LLTD_FUNCTION_DISCOVER) {
         $upperLayer = Net::Frame::Layer::LLTD::Discover->new(raw => $payload);
      }
      elsif ($self->function == NF_LLTD_FUNCTION_HELLO) {
         $upperLayer = Net::Frame::Layer::LLTD::Hello->new(raw => $payload);
      }
      elsif ($self->function == NF_LLTD_FUNCTION_EMIT) {
         $upperLayer = Net::Frame::Layer::LLTD::Emit->new(raw => $payload);
      }
      elsif ($self->function == NF_LLTD_FUNCTION_QUERY_RESP) {
         $upperLayer = Net::Frame::Layer::LLTD::QueryResp->new(raw => $payload);
      }
   }

   if ($upperLayer) {
      $upperLayer->unpack;
      $self->upperLayer($upperLayer);
      $self->payload($upperLayer->payload);
      $upperLayer->payload(undef);
   }
   else {
      $self->payload($payload);
   }

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  tos:0x%02x  reserved:%d  function:0x%02x\n".
      "$l: networkAddress1: %s  networkAddress2: %s\n".
      "$l: identifier:%d",
         $self->version,
         $self->tos,
         $self->reserved,
         $self->function,
         $self->networkAddress1,
         $self->networkAddress2,
         $self->identifier;

   $buf .= "\n".$self->upperLayer->print if $self->upperLayer;

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD - Link Layer Topology Discovery layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::LLTD->new(
      version         => 1,
      tos             => NF_LLTD_TOS_TOPOLOGY_DISCOVERY,
      reserved        => 0,
      function        => NF_LLTD_FUNCTION_DISCOVER,
      networkAddress1 => 'ff:ff:ff:ff:ff:ff',
      networkAddress2 => 'ff:ff:ff:ff:ff:ff',
      identifier      => getRandom16bitsInt(),
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Link Layer Topology Discovery layer.

Protocol specifications: http://www.microsoft.com/whdc/Rally/LLTD-spec.mspx .

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

=item B<tos>

=item B<reserved>

=item B<function>

=item B<networkAddress1>

=item B<networkAddress2>

=item B<identifier>

=item B<upperLayer>

This last attribute will store the upper layer object.

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

Load them: use Net::Frame::Layer::LLTD qw(:consts);

=over 4

=item B<NF_LLTD_TOS_TOPOLOGY_DISCOVERY>

=item B<NF_LLTD_TOS_QUICK_DISCOVERY>

=item B<NF_LLTD_TOS_QOS_DIAGNOSTICS>

Constants for LLTD tos attribute.

=item B<NF_LLTD_FUNCTION_DISCOVER>

=item B<NF_LLTD_FUNCTION_HELLO>

=item B<NF_LLTD_FUNCTION_EMIT>

=item B<NF_LLTD_FUNCTION_TRAIN>

=item B<NF_LLTD_FUNCTION_PROBE>

=item B<NF_LLTD_FUNCTION_ACK>

=item B<NF_LLTD_FUNCTION_QUERY>

=item B<NF_LLTD_FUNCTION_QUERY_RESP>

=item B<NF_LLTD_FUNCTION_RESET>

=item B<NF_LLTD_FUNCTION_CHARGE>

=item B<NF_LLTD_FUNCTION_FLAT>

=item B<NF_LLTD_FUNCTION_QUERY_LARGE_TLV>

=item B<NF_LLTD_FUNCTION_QUERY_LARGE_TLV_RESP>

Constants for LLTD function attribute.

=item B<NF_LLTD_TLV_TYPE_EOP>

=item B<NF_LLTD_TLV_TYPE_HOSTID>

=item B<NF_LLTD_TLV_TYPE_CHARACTERISTICS>

=item B<NF_LLTD_TLV_TYPE_PHYSICALMEDIUM>

=item B<NF_LLTD_TLV_TYPE_WIRELESSMODE>

=item B<NF_LLTD_TLV_TYPE_BSSID>

=item B<NF_LLTD_TLV_TYPE_SSID>

=item B<NF_LLTD_TLV_TYPE_IPv4ADDRESS>

=item B<NF_LLTD_TLV_TYPE_IPv6ADDRESS>

=item B<NF_LLTD_TLV_TYPE_MAXOPRATE>

=item B<NF_LLTD_TLV_TYPE_PERFCOUNTER>

=item B<NF_LLTD_TLV_TYPE_LINKSPEED>

=item B<NF_LLTD_TLV_TYPE_RSSI>

=item B<NF_LLTD_TLV_TYPE_ICONIMAGE>

=item B<NF_LLTD_TLV_TYPE_MACHINENAME>

=item B<NF_LLTD_TLV_TYPE_SUPPORTINFO>

=item B<NF_LLTD_TLV_TYPE_FRIENDLYNAME>

=item B<NF_LLTD_TLV_TYPE_UUID>

=item B<NF_LLTD_TLV_TYPE_HARDWAREID>

=item B<NF_LLTD_TLV_TYPE_QOSCHARACTERISTICS>

=item B<NF_LLTD_TLV_TYPE_WIRELESSPHYSICALMEDIUM>

=item B<NF_LLTD_TLV_TYPE_APTABLE>

=item B<NF_LLTD_TLV_TYPE_DETAILEDICONIMAGE>

=item B<NF_LLTD_TLV_TYPE_SEESLISTCOUNT>

=item B<NF_LLTD_TLV_TYPE_COMPONENTTABLE>

=item B<NF_LLTD_TLV_TYPE_REPEATERAP>

=item B<NF_LLTD_TLV_TYPE_REPEATERAPTABLE>

Constants for LLTD Tlv type attribute.

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
