#
# $Id: IGMPv4.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::IGMPv4;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

use Net::Packet::Consts qw(:igmpv4 :layer);
use Net::Packet::Utils qw(inetNtoa inetAton);
require Bit::Vector;

our @AS = qw(
   version
   type
   maxRespTime
   unused
   checksum
   groupAddress
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      version      => 2,
      type         => NP_IGMPv4_v2_TYPE_QUERY,
      maxRespTime  => 10,
      unused       => 0,
      checksum     => 0,
      groupAddress => NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS,
      @_,
   );
}

sub getLength { NP_IGMPv4_HDR_LEN }

sub pack {
   my $self = shift;

   if ($self->version == 1) {
      $self->raw($self->SUPER::pack('CCna4',
         $self->version, $self->type, $self->unused, $self->checksum,
         inetAton($self->groupAddress),
      )) or return undef;
   }
   else {
      $self->raw($self->SUPER::pack('CCna4',
         $self->type, $self->maxRespTime, $self->checksum,
         inetAton($self->groupAddress),
      )) or return undef;
   }

   1;
}

sub unpack {
   my $self = shift;

   my ($versionType, $unused, $checksum, $groupAddress, $payload) =
      $self->SUPER::unpack('CCna4 a*', $self->raw)
         or return undef;

   # It is a version 2 of the protocol spec
   if ($unused) {
      $self->version(2);
      $self->type($versionType);
      $self->maxRespTime($unused / 10);
   }
   # Or version 1
   else {
      my $v8 = Bit::Vector->new_Dec(8, $versionType);
      $self->version($v8->Chunk_Read(4, 0));
      $self->type($v8->Chunk_Read(4, 4));
      $self->unused($unused);
   }

   $self->checksum($checksum);
   $self->groupAddress(inetNtoa($groupAddress));

   $self->payload($payload);

   1;
}

sub encapsulate {
   my $types = {
      NP_LAYER_NONE() => NP_LAYER_NONE(),
   };

   $types->{NP_LAYER_NONE()} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   if ($self->version == 1) {
      sprintf "$l:+$i: version:%d  type:0x%01x  unused:0x%02x  ".
              "checksum:0x%04x\n".
              "$l: $i: groupAddress:%s",
                 $self->version, $self->type, $self->unused, $self->checksum,
                 $self->groupAddress;
   }
   else {
      sprintf "$l:+$i: version:%d  type:0x%02x  maxRespTime:%d  ".
              "checksum:0x%04x\n".
              "$l: $i: groupAddress:%s",
                 $self->version, $self->type, $self->maxRespTime,
                 $self->checksum, $self->groupAddress;
   }
}

1;

__END__

=head1 NAME

Net::Packet::IGMPv4 - Internet Group Management Protocol v4 layer 4 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:igmpv4);
   require Net::Packet::IGMPv4;

   # Build a layer
   my $layer = Net::Packet::IGMPv4->new(
      version      => 2,
      type         => NP_IGMPv4_v2_TYPE_QUERY,
      maxRespTime  => 10,
      checksum     => 0,
      groupAddress => NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::IGMPv4->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Internet Group Management Protocol v4 (version 1 and 2) layer.

RFC for version 1: ftp://ftp.rfc-editor.org/in-notes/rfc1112.txt

RFC for version 2: ftp://ftp.rfc-editor.org/in-notes/rfc2236.txt

See also B<Net::Packet::Layer> and B<Net::Packet::Layer4> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version> - 4 bits (or 0 for version 2)

=item B<type> - 4 bits (or 8 bits for version 2)

=item B<unused> - 8 bits (or 0 for version 2)

=item B<maxRespTime> - 8 bits (or 0 for version 1)

=item B<checksum> - 16 bits

=item B<groupAddress> - 32 bits

For version 1, you use the following attributes: version, type, unused, checksum, groupAddress.

For version 2, you use the following attributes: type, maxRespTime, checksum, groupAddress.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

version:      2

type:         NP_IGMPv4_v2_TYPE_QUERY

maxRespTime:  10

checksum:     0

groupAddress: NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:igmpv4);

=over 4

=item B<NP_IGMPv4_HDR_LEN>

IGMPv4 header length.

=item B<NP_IGMPv4_v1_TYPE_QUERY>

=item B<NP_IGMPv4_v1_TYPE_REPORT>

Various types supported by version 1 of the protocol.

=item B<NP_IGMPv4_v2_TYPE_QUERY>

=item B<NP_IGMPv4_v2_TYPE_QUERY_v1>

=item B<NP_IGMPv4_v2_TYPE_REPORT>

=item B<NP_IGMPv4_v2_TYPE_LEAVE_GROUP>

Various types supported by version 2 of the protocol.

=item B<NP_IGMPv4_GROUP_ADDRESS_NO_HOSTS>

=item B<NP_IGMPv4_GROUP_ADDRESS_ALL_HOSTS>

=item B<NP_IGMPv4_GROUP_ADDRESS_ALL_ROUTERS>

Various group addresses supported by all versions of the protocol.

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
