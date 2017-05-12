#
# $Id: Address.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::CDP::Address;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

use Net::Packet::Consts qw(:cdp);
use Net::Packet::Utils qw(inetAton inetNtoa);

our @AS = qw(
   protocolType
   protocolLength
   protocol
   addressLength
   address
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      protocolType   => NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID,
      protocolLength => NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID,
      protocol       => NP_CDP_ADDRESS_PROTOCOL_IP,
      addressLength  => NP_CDP_ADDRESS_ADDRESS_LENGTH_IP,
      address        => '127.0.0.1',
      @_,
   );
}

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('CCCna4',
      $self->protocolType,
      $self->protocolLength,
      $self->protocol,
      $self->addressLength,
      inetAton($self->address),
   )) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($protocolType, $protocolLength, $protocol, $addressLength, $tail) =
      $self->SUPER::unpack('CCCn a*', $self->raw)
         or return undef;

   $self->protocolType($protocolType);
   $self->protocolLength($protocolLength);
   $self->protocol($protocol);
   $self->addressLength($addressLength);

   my $payload;
   if ($protocol eq NP_CDP_ADDRESS_PROTOCOL_IP) {
      my ($address, $lPayload) = $self->SUPER::unpack('a4 a*', $tail)
         or return undef;
      $self->address(inetNtoa($address));
      $payload = $lPayload;
   }
   else {
      # Unknown
   }

   $self->payload($payload);

   1;
}

sub print {
   my $self = shift;

   my $i = $self->is;
   my $l = $self->layer;
   sprintf "$l: $i: protocolType:0x%02x  protocolLength:%d  protocol:0x%02x\n".
           "$l: $i: addressLength:%d  address:%s",
      $self->protocolType, $self->protocolLength, $self->protocol,
      $self->addressLength, $self->address;
}

1;

__END__

=head1 NAME

Net::Packet::CDP::Address - Cisco Discovery Protocol Address format

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:cdp);
   require Net::Packet::CDP::Address;

   # Build a layer
   my $layer = Net::Packet::CDP::Address->new(
      protocolType   => NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID,
      protocolLength => NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID,
      protocol       => NP_CDP_ADDRESS_PROTOCOL_IP,
      addressLength  => NP_CDP_ADDRESS_ADDRESS_LENGTH_IP,
      address        => '127.0.0.1',
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::CDP::Address->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Cisco Discovery Protocol Address format.

=head1 ATTRIBUTES

=over 4

=item B<protocolType> - 8 bits

=item B<protocolLength> - 8 bits

=item B<protocol> - 8 bits

=item B<addressLength> - 16 bits

=item B<address> - 32 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

protocolType:   NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID

protocolLength: NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID

protocol:       NP_CDP_ADDRESS_PROTOCOL_IP

addressLength:  NP_CDP_ADDRESS_ADDRESS_LENGTH_IP

address:        '127.0.0.1'

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

=over 4

=item B<NP_CDP_ADDRESS_PROTOCOL_TYPE_NLPID>

=item B<NP_CDP_ADDRESS_PROTOCOL_LENGTH_NLPID>

=item B<NP_CDP_ADDRESS_PROTOCOL_IP>

=item B<NP_CDP_ADDRESS_ADDRESS_LENGTH_IP>

See also B<Net::Packet::CDP> for other CONSTANTS.

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
