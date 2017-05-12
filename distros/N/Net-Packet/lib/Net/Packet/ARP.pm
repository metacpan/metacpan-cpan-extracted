#
# $Id: ARP.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::ARP;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

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

use Net::Packet::Env qw($Env);
use Net::Packet::Utils qw(convertMac inetAton inetNtoa);
use Net::Packet::Consts qw(:arp :layer);

sub new {
   my $self = shift->SUPER::new(
      hType   => NP_ARP_HTYPE_ETH,
      pType   => NP_ARP_PTYPE_IPv4,
      hSize   => NP_ARP_HSIZE_ETH,
      pSize   => NP_ARP_PSIZE_IPv4,
      opCode  => NP_ARP_OPCODE_REQUEST,
      src     => $Env->mac,
      dst     => NP_ARP_ADDR_BROADCAST,
      srcIp   => $Env->ip,
      dstIp   => "127.0.0.1",
      @_,
   );

   $self->[$__src] = lc($self->[$__src]) if $self->[$__src];
   $self->[$__dst] = lc($self->[$__dst]) if $self->[$__dst];

   $self;
}

sub getLength { NP_ARP_HDR_LEN }

sub pack {
   my $self = shift;

   (my $srcMac = $self->[$__src]) =~ s/://g;
   (my $dstMac = $self->[$__dst]) =~ s/://g;

   $self->[$__raw] = $self->SUPER::pack('nnUUnH12a4H12a4',
      $self->[$__hType],
      $self->[$__pType],
      $self->[$__hSize],
      $self->[$__pSize],
      $self->[$__opCode],
      $srcMac,
      inetAton($self->[$__srcIp]),
      $dstMac,
      inetAton($self->[$__dstIp]),
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($hType, $pType, $hSize, $pSize, $opCode, $srcMac, $srcIp, $dstMac,
      $dstIp) = $self->SUPER::unpack('nnUUnH12a4H12a4', $self->[$__raw])
         or return undef;

   $self->[$__hType]  = $hType;
   $self->[$__pType]  = $pType;
   $self->[$__hSize]  = $hSize;
   $self->[$__pSize]  = $pSize;
   $self->[$__opCode] = $opCode;
   $self->[$__src]    = convertMac($srcMac);
   $self->[$__srcIp]  = inetNtoa($srcIp);
   $self->[$__dst]    = convertMac($dstMac);
   $self->[$__dstIp]  = inetNtoa($dstIp);

   1;
}

sub recv {
   my $self = shift;
   my ($frame) = @_;

   my $src    = $self->[$__src];
   my $srcIp  = $self->[$__srcIp];
   my $dstIp  = $self->[$__dstIp];
   my $opCode = $self->[$__opCode];

   for ($frame->env->dump->framesFor($frame)) {
      if ($opCode == NP_ARP_OPCODE_REQUEST) {
         if ($_->l3->opCode == NP_ARP_OPCODE_REPLY
         &&  $_->l3->dst    eq $src
         &&  $_->l3->srcIp  eq $dstIp
         &&  $_->l3->dstIp  eq $srcIp) {
            return $_ if $_->timestamp ge $frame->timestamp;
         }
      }
   }

   undef;
}

sub encapsulate { NP_LAYER_NONE }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf
      "$l:+$i: hType:0x%04x  pType:0x%04x  hSize:0x%02x  pSize:0x%02x".
      "  opCode:0x%04x\n".
      "$l: $i: src:%s  srcIp:%s\n".
      "$l: $i: dst:%s  dstIp:%s",
         $self->[$__hType], $self->[$__pType], $self->[$__hSize],
         $self->[$__pSize], $self->[$__opCode], $self->[$__src],
         $self->[$__srcIp], $self->[$__dst],  $self->[$__dstIp];
}

#
# Helpers
#

sub _isOpCode { shift->[$__opCode] == shift             }
sub isRequest { shift->_isOpCode(NP_ARP_OPCODE_REQUEST) }
sub isReply   { shift->_isOpCode(NP_ARP_OPCODE_REPLY)   }

1;

__END__

=head1 NAME

Net::Packet::ARP - Address Resolution Protocol layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:arp);
   require Net::Packet::ARP;

   # Build a layer
   my $layer = Net::Packet::ARP->new(
      dstIp => "192.168.0.1",
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::ARP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ARP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc826.txt

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

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

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

hType:  NP_ARP_HTYPE_ETH

pType:  NP_ARP_PTYPE_IPv4

hSize:  NP_ARP_HSIZE_ETH

pSize:  NP_ARP_PSIZE_IPv4

opCode: NP_ARP_OPCODE_REQUEST

src:    $Env->mac

dst:    NP_ARP_ADDR_BROADCAST

srcIp:  $Env->ip

dstIp:  127.0.0.1

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<recv>

Will search for a matching replies in B<framesSorted> or B<frames> from a B<Net::Packet::Dump> object.

=item B<isRequest>

=item B<isReply>

Returns 1 if the B<opCode> attribute is of specified type.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:arp);

=over 4

=item B<NP_ARP_HTYPE_ETH>

=item B<NP_ARP_PTYPE_IPv4>

Hardware and protocol address types.

=item B<NP_ARP_HSIZE_ETH>

=item B<NP_ARP_PSIZE_IPv4>

Hardware and protocol address sizes.

=item B<NP_ARP_OPCODE_REQUEST>

=item B<NP_ARP_OPCODE_REPLY>

Operation code numbers.

=item B<NP_ARP_ADDR_BROADCAST>

Broadcast address for B<src> or B<dst> attributes.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
