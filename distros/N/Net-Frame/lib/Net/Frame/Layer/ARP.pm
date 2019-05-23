#
# $Id: ARP.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::ARP;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_ARP_HDR_LEN
      NF_ARP_HTYPE_ETH
      NF_ARP_PTYPE_IPv4
      NF_ARP_PTYPE_IPv6     
      NF_ARP_HSIZE_ETH
      NF_ARP_PSIZE_IPv4
      NF_ARP_PSIZE_IPv6
      NF_ARP_OPCODE_REQUEST
      NF_ARP_OPCODE_REPLY
      NF_ARP_ADDR_BROADCAST
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_ARP_HDR_LEN        => 28;
use constant NF_ARP_HTYPE_ETH      => 0x0001;
use constant NF_ARP_PTYPE_IPv4     => 0x0800;
use constant NF_ARP_PTYPE_IPv6     => 0x86dd;
use constant NF_ARP_HSIZE_ETH      => 0x06;
use constant NF_ARP_PSIZE_IPv4     => 0x04;
use constant NF_ARP_PSIZE_IPv6     => 0x16;
use constant NF_ARP_OPCODE_REQUEST => 0x0001;
use constant NF_ARP_OPCODE_REPLY   => 0x0002;
use constant NF_ARP_ADDR_BROADCAST => '00:00:00:00:00:00';

our @AS = qw(
   hType
   pType
   hSize
   pSize
   opCode
   src
   srcIp
   dst
   dstIp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   my $self = shift->SUPER::new(
      hType   => NF_ARP_HTYPE_ETH,
      pType   => NF_ARP_PTYPE_IPv4,
      hSize   => NF_ARP_HSIZE_ETH,
      pSize   => NF_ARP_PSIZE_IPv4,
      opCode  => NF_ARP_OPCODE_REQUEST,
      src     => '00:00:00:00:00:00',
      dst     => NF_ARP_ADDR_BROADCAST,
      srcIp   => '127.0.0.1',
      dstIp   => '127.0.0.1',
      @_,
   );

   $self->[$__src] = lc($self->[$__src]) if $self->[$__src];
   $self->[$__dst] = lc($self->[$__dst]) if $self->[$__dst];

   return $self;
}

sub getLength {
   my $self = shift;
   my $len = NF_ARP_HDR_LEN;
   $len += 24 if $self->[$__pType] == NF_ARP_PTYPE_IPv6;
   return $len;
}

sub pack {
   my $self = shift;

   (my $srcMac = $self->[$__src]) =~ s/://g;
   (my $dstMac = $self->[$__dst]) =~ s/://g;

   # IPv4 packing
   if ($self->[$__pType] == NF_ARP_PTYPE_IPv4) {
      $self->[$__raw] = $self->SUPER::pack('nnCCnH12a4H12a4',
         $self->[$__hType],
         $self->[$__pType],
         $self->[$__hSize],
         $self->[$__pSize],
         $self->[$__opCode],
         $srcMac,
         inetAton($self->[$__srcIp]),
         $dstMac,
         inetAton($self->[$__dstIp]),
      ) or return;
   }
   # IPv6 packing
   else {
      $self->[$__raw] = $self->SUPER::pack('nnCCnH12a*H12a*',
         $self->[$__hType],
         $self->[$__pType],
         $self->[$__hSize],
         $self->[$__pSize],
         $self->[$__opCode],
         $srcMac,
         inet6Aton($self->[$__srcIp]),
         $dstMac,
         inet6Aton($self->[$__dstIp]),
      ) or return;
   }

   return $self->[$__raw];
}

sub unpack {
   my $self = shift;

   my ($hType, $pType, $tail) = $self->SUPER::unpack('nn a*',
      $self->[$__raw])
         or return;

   my ($hSize, $pSize, $opCode, $srcMac, $srcIp, $dstMac, $dstIp,
       $payload);

   # IPv4 unpacking
   if ($pType == NF_ARP_PTYPE_IPv4) {
      ($hSize, $pSize, $opCode, $srcMac, $srcIp, $dstMac, $dstIp,
       $payload) = $self->SUPER::unpack('CCnH12a4H12a4 a*', $tail)
         or return;
      $self->[$__srcIp] = inetNtoa($srcIp);
      $self->[$__dstIp] = inetNtoa($dstIp);
   }
   # IPv6 unpacking
   else {
      ($hSize, $pSize, $opCode, $srcMac, $srcIp, $dstMac, $dstIp,
       $payload) = $self->SUPER::unpack('CCnH12a16H12a16 a*', $tail)
         or return;
      $self->[$__srcIp] = inet6Ntoa($srcIp);
      $self->[$__dstIp] = inet6Ntoa($dstIp);
   }

   $self->[$__hType]  = $hType;
   $self->[$__pType]  = $pType;
   $self->[$__hSize]  = $hSize;
   $self->[$__pSize]  = $pSize;
   $self->[$__opCode] = $opCode;
   $self->[$__src]    = convertMac($srcMac);
   $self->[$__dst]    = convertMac($dstMac);

   $self->[$__payload] = $payload;

   return $self;
}

sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

sub match {
   my $self = shift;
   my ($with) = @_;
      ($self->[$__opCode] == NF_ARP_OPCODE_REQUEST)
   && ($with->[$__opCode] == NF_ARP_OPCODE_REPLY)
   && ($with->[$__dst]    eq $self->[$__src])
   && ($with->[$__srcIp]  eq $self->[$__dstIp])
   && ($with->[$__dstIp]  eq $self->[$__srcIp]);
}

sub encapsulate {
   my $self = shift;
   return $self->[$__nextLayer];
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf
      "$l: hType:0x%04x  pType:0x%04x  hSize:0x%02x  pSize:0x%02x".
      "  opCode:0x%04x\n".
      "$l: src:%s  srcIp:%s\n".
      "$l: dst:%s  dstIp:%s",
         $self->[$__hType], $self->[$__pType], $self->[$__hSize],
         $self->[$__pSize], $self->[$__opCode], $self->[$__src],
         $self->[$__srcIp], $self->[$__dst],  $self->[$__dstIp];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ARP - Address Resolution Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::ARP qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::ARP->new(
      hType   => NF_ARP_HTYPE_ETH,
      pType   => NF_ARP_PTYPE_IPv4,
      hSize   => NF_ARP_HSIZE_ETH,
      pSize   => NF_ARP_PSIZE_IPv4,
      opCode  => NF_ARP_OPCODE_REQUEST,
      src     => '00:00:00:00:00:00',
      dst     => NF_ARP_ADDR_BROADCAST,
      srcIp   => '127.0.0.1',
      dstIp   => '127.0.0.1',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ARP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ARP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc826.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<hType>

=item B<pType>

Hardware and protocol address types.

=item B<hSize>

=item B<pSize>

Hardware and protocol address sizes in bytes.

=item B<opCode>

The operation code number to perform.

=item B<src>

=item B<dst>

Source and destination hardware addresses.

=item B<srcIp>

=item B<dstIp>

Source and destination IP addresses.

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

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::ARP object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::ARP> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::ARP qw(:consts);

=over 4

=item B<NF_ARP_HTYPE_ETH>

Hardware address types.

=item B<NF_ARP_PTYPE_IPv4>

=item B<NF_ARP_PTYPE_IPv6>

Protocol address types.

=item B<NF_ARP_HSIZE_ETH>

Hardware address sizes.

=item B<NF_ARP_PSIZE_IPv4>

=item B<NF_ARP_PSIZE_IPv6>

Protocol address sizes.

=item B<NF_ARP_OPCODE_REQUEST>

=item B<NF_ARP_OPCODE_REPLY>

Operation code numbers.

=item B<NF_ARP_ADDR_BROADCAST>

Broadcast address for B<src> or B<dst> attributes.

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
