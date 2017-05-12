#
# $Id: IPv6.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::IPv6;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Net::Packet::Env qw($Env);
use Net::Packet::Utils qw(unpackIntFromNet packIntToNet
   inet6Aton inet6Ntoa);
use Net::Packet::Consts qw(:ipv6 :layer);

BEGIN {
   *protocol = \&nextHeader;
}

our @AS = qw(
   version
   trafficClass
   flowLabel
   nextHeader
   payloadLength
   hopLimit
   src
   dst
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

require Bit::Vector;

sub new {
   shift->SUPER::new(
      version       => 6,
      trafficClass  => 0,
      flowLabel     => 0,
      nextHeader    => NP_IPv6_PROTOCOL_TCP,
      hopLimit      => 0xff,
      src           => $Env->ip6,
      dst           => '::1',
      payloadLength => 0,
      @_,
   );
}

sub getLength        { NP_IPv6_HDR_LEN           }
sub getPayloadLength { shift->[$__payloadLength] }

sub _computePayloadLength {
   my $self = shift;
   my ($l4, $l7) = @_;

   my $len = 0;
   $len += $l4->getLength if $l4;
   $len += $l7->getLength if $l7;
   $self->[$__payloadLength] = $len;
}

sub computeLengths {
   my $self = shift;
   my ($env, $l2, $l3, $l4, $l7) = @_;

   $l4 && ($l4->computeLengths($env, $l2, $l3, $l4, $l7) or return undef);
   $self->_computePayloadLength($l4, $l7);
   1;
}

sub pack {
   my $self = shift;

   my $version      = Bit::Vector->new_Dec(4,  $self->[$__version]);
   my $trafficClass = Bit::Vector->new_Dec(8,  $self->[$__trafficClass]);
   my $flowLabel    = Bit::Vector->new_Dec(20, $self->[$__flowLabel]);
   my $v32          = $version->Concat_List($trafficClass, $flowLabel);

   $self->[$__raw] = $self->SUPER::pack('NnCCa*a*',
      $v32->to_Dec,
      $self->[$__payloadLength],
      $self->[$__nextHeader],
      $self->[$__hopLimit],
      inet6Aton($self->[$__src]),
      inet6Aton($self->[$__dst]),
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($vTcFl, $pl, $nh, $hl, $sa, $da, $payload) =
      $self->SUPER::unpack('NnCCa16a16 a*', $self->[$__raw])
         or return undef;

   my $v32 = Bit::Vector->new_Dec(32,  $vTcFl);

   $self->[$__flowLabel]     = $v32->Chunk_Read(20,  0);
   $self->[$__trafficClass]  = $v32->Chunk_Read( 8, 20);
   $self->[$__version]       = $v32->Chunk_Read( 4, 28);
   $self->[$__payloadLength] = $pl;
   $self->[$__nextHeader]    = $nh;
   $self->[$__hopLimit]      = $hl;
   $self->[$__src]           = inet6Ntoa($sa);
   $self->[$__dst]           = inet6Ntoa($da);

   $self->[$__payload] = $payload;

   1;
}

sub encapsulate {
   my $types = {           
      NP_IPv6_PROTOCOL_TCP()    => NP_LAYER_TCP(),
      NP_IPv6_PROTOCOL_UDP()    => NP_LAYER_UDP(),
      #NP_IPv4_PROTOCOL_ICMPv6() => NP_LAYER_ICMPv6(),
   };

   $types->{shift->[$__nextHeader]} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;       

   my $i = $self->is;       
   my $l = $self->layer;    
   sprintf
      "$l:+$i: version:%d  trafficClass:0x%02x  flowLabel:0x%05x  ".
      "nextHeader:0x%02x\n".
      "$l: $i: payloadLength:%d  hopLimit:%d\n".
      "$l: $i: src:%s  dst:%s",
         $self->[$__version], $self->[$__trafficClass], $self->[$__flowLabel],
         $self->[$__nextHeader], $self->[$__payloadLength],
         $self->[$__hopLimit], $self->[$__src], $self->[$__dst];
}

1;

=head1 NAME

Net::Packet::IPv6 - Internet Protocol v6 layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:ipv6);
   require Net::Packet::IPv6;

   # Build a layer
   my $layer = Net::Packet::IPv6->new(
      dst => $hostname6,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::IPv6->new(raw = $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv6 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2460.txt

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

Version of Internet Protocol header.

=item B<trafficClass>

Traffic class field. Was Type of Service in IPv4.

=item B<flowLabel>

Flow label class field. Was IP ID in IPv4.

=item B<nextHeader>

The type of next header. Was protocol in IPv4.

=item B<protocol>

Is an alias for B<nextHeader>

=item B<payloadLength>

Length in bytes of encapsulated layers (that is, layer 4 + layer 7).

=item B<hopLimit>

Was TTL field in IPv4.

=item B<src>

=item B<dst>

Source and destination addresses.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

version:      6

trafficClass: 0

flowLabel:    0

nextHeader:   NP_IPv6_PROTOCOL_TCP

hopLimit:     0xff

src:          $Env->ip6

dst:          '::1'

=item B<getPayloadLength>

Returns the length in bytes of encapsulated layers (that is layer 4 + layer 7).

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:ipv6);

=over 4

=item B<NP_IPv6_PROTOCOL_TCP>

=item B<NP_IPv6_PROTOCOL_UDP>

Constants for B<nextHeader> attribute.

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
