#
# $Id: OSPF.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::OSPF;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

use Net::Packet::Consts qw(:ospf :layer);
use Net::Packet::Utils qw(inetAton inetNtoa);

our @AS = qw(
   version
   messageType
   length
   sourceOspfRouter
   areaId
   checksum
   authType
   authData
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      version          => 2,
      messageType      => 0,
      length           => NP_OSPF_HDR_LEN,
      sourceOspfRouter => '127.0.0.1',
      areaId           => '127.0.0.1',
      checksum         => 0,
      authType         => NP_OSPF_AUTH_TYPE_NULL,
      authData         => '',
      @_,
   );
}

sub getLength { shift->length }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('CCna4a4nnH16',
      $self->version, $self->messageType, $self->length,
      inetAton($self->sourceOspfRouter), inetAton($self->areaId),
      $self->checksum, $self->authType, $self->authData,
   )) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($version, $messageType, $length, $sourceOspfRouter, $areaId, $checksum,
      $authType, $authData, $payload) =
         $self->SUPER::unpack('CCna4a4nnH16 a*', $self->raw)
            or return undef;

   $self->version($version);
   $self->messageType($messageType);
   $self->length($length);
   $self->sourceOspfRouter(inetNtoa($sourceOspfRouter));
   $self->areaId(inetNtoa($areaId));
   $self->checksum($checksum);
   $self->authType($authType);
   $self->authData($authData);

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
   sprintf "$l:+$i: version:%d  messageType:0x%02x length:%d\n".
           "$l: $i: sourceOspfRouter:%s  areaId:%s\n".
           "$l: $i: checksum:0x%04x  authType:0x%04x\n".
           "$l: $i: authData:%s",
              $self->version, $self->messageType, $self->length,
              $self->sourceOspfRouter, $self->areaId, $self->checksum,
              $self->authType, $self->authData;
}

1;

__END__

=head1 NAME

Net::Packet::OSPF - Open Shortest Path First layer 4 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:ospf);
   require Net::Packet::OSPF;

   # Build a layer
   my $layer = Net::Packet::OSPF->new(
      version          => 2,
      messageType      => 0,
      length           => NP_OSPF_HDR_LEN,
      sourceOspfRouter => '127.0.0.1',
      areaId           => '127.0.0.1',
      checksum         => 0,
      authType         => NP_OSPF_AUTH_TYPE_NULL,
      authData         => '',
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::OSPF->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Open Shortest Path First layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer4> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version> - 8 bits

=item B<messageType> - 8 bits

=item B<length> - 16 bits

=item B<sourceOspfRouter> - 32 bits

=item B<areaId> - 32 bits

=item B<checksum> - 16 bits

=item B<authType> - 16 bits

=item B<authData> - 64 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

version:          2

messageType:      0

length:           NP_OSPF_HDR_LEN

sourceOspfRouter: '127.0.0.1'

areaId:           '127.0.0.1'

checksum:         0

authType:         NP_OSPF_AUTH_TYPE_NULL

authData:         ''

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:ospf);

=over 4

=item B<NP_OSPF_HDR_LEN>

OSPF header length.

=item B<NP_OSPF_AUTH_TYPE_NULL>

Various supported OSPF authentication types.

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
