#
# $Id: Address.pm 1640 2009-11-09 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::Address;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_CDP_ADDRESS_PROTOCOL_TYPE_NLPID
      NF_CDP_ADDRESS_PROTOCOL_TYPE_8022
      NF_CDP_ADDRESS_PROTOCOL_IP
      NF_CDP_ADDRESS_PROTOCOL_IPv6
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_CDP_ADDRESS_PROTOCOL_TYPE_NLPID => 1;
use constant NF_CDP_ADDRESS_PROTOCOL_TYPE_8022  => 2;
use constant NF_CDP_ADDRESS_PROTOCOL_IP   => CORE::pack 'H*', 'cc';
use constant NF_CDP_ADDRESS_PROTOCOL_IPv6 => CORE::pack 'H*', 'aaaa0300000086dd';

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
      protocolType   => NF_CDP_ADDRESS_PROTOCOL_TYPE_NLPID,
      protocolLength => 1,
      protocol       => NF_CDP_ADDRESS_PROTOCOL_IP,
      addressLength  => 4,
      address        => '127.0.0.1',
      @_,
   );
}

sub ipv4Address { 
   return new(@_)
}

sub ipv6Address {
   shift->SUPER::new(
      protocolType   => NF_CDP_ADDRESS_PROTOCOL_TYPE_8022,
      protocolLength => 8,
      protocol       => NF_CDP_ADDRESS_PROTOCOL_IPv6,
      addressLength  => 16,
      address        => '::1',
      @_,
   );
}

sub getLength {
   my $self = shift;

   my $length = 4;
   $length += length($self->protocol);
   $length += $self->addressLength;

   return $length
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CC',
      $self->protocolType,
      $self->protocolLength
   ) or return;

   my $protocolLength = $self->protocolLength;
   $raw .= $self->SUPER::pack("a$protocolLength n",
      $self->protocol,
      $self->addressLength
   ) or return;

   my $addressLength = $self->addressLength;
   if ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IP) {
      $raw .= $self->SUPER::pack('a4',
         inetAton($self->address)
      ) or return;
   } elsif ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IPv6) {
      $raw .= $self->SUPER::pack('a16',
         inet6Aton($self->address)
      ) or return;
   } else { 
      $raw .= $self->SUPER::pack("a$addressLength",
         $self->address
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($protocolType, $protocolLength, $tail) =
      $self->SUPER::unpack('CC a*', $self->raw)
         or return;

   $self->protocolType($protocolType);
   $self->protocolLength($protocolLength);

   my ($protocol, $addressLength);
   ($protocol, $addressLength, $tail) = 
      $self->SUPER::unpack("a$protocolLength n a*", $tail)
         or return;

   $self->protocol($protocol);
   $self->addressLength($addressLength);

   my ($address, $payload);
   if ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IP) {
      ($address, $payload) = 
         $self->SUPER::unpack('a4 a*', $tail)
            or return;
      $self->address(inetNtoa($address));
   } elsif ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IPv6) {
      ($address, $payload) = 
         $self->SUPER::unpack('a16 a*', $tail)
            or return;
      $self->address(inet6Ntoa($address));
   } else { 
      ($address, $payload) = 
         $self->SUPER::unpack("a$addressLength a*", $tail)
            or return;
      $self->address($address);
   }

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   $self->protocolLength(length($self->protocol));

   if ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IP) {
      $self->addressLength(4)
   } elsif ($self->protocol eq NF_CDP_ADDRESS_PROTOCOL_IPv6) {
      $self->addressLength(16)
   }else {
      return;
   }

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: protocolType:%d  protocolLength:%d  protocol:0x%s\n".
      "$l: addressLength:%d  address:%s",
         $self->protocolType, $self->protocolLength, (CORE::unpack 'H*', $self->protocol),
         $self->addressLength, $self->address;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::Address - Address encoding for CDP addresses TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::Address->new(
      protocolType   => NF_CDP_ADDRESS_PROTOCOL_TYPE_NLPID,
      protocolLength => 1,
      protocol       => NF_CDP_ADDRESS_PROTOCOL_IP,
      addressLength  => 4,
      address        => '127.0.0.1',
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding addresses for the Addresses and ManagementAddresses CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<protocolType>

Protocol type.  See B<CONSTANTS> for values.

=item B<protocolLength>

Length of protocol value.

=item B<protocol>

Protocol value.  This is a C<pack('H*', $string)> where B<$string> represents the protocol.  See B<CONSTANTS> for values.

=item B<addressLength>

Length of address.

=item B<address>

Address.

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

=item B<ipv4Address>

=item B<ipv4Address> (hash)

Alias to B<new>.

=item B<ipv6Address>

=item B<ipv6Address> (hash)

Alias to B<new>.

Object constructor for IPv6 specific address.

      protocolType   => NF_CDP_ADDRESS_PROTOCOL_TYPE_8022,
      protocolLength => 8,
      protocol       => NF_CDP_ADDRESS_PROTOCOL_IPv6,
      addressLength  => 16,
      address        => '::1',

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

=over 4

=item B<NF_CDP_ADDRESS_PROTOCOL_TYPE_NLPID>

=item B<NF_CDP_ADDRESS_PROTOCOL_TYPE_8022>

Protocol types.

=item B<NF_CDP_ADDRESS_PROTOCOL_IP>

=item B<NF_CDP_ADDRESS_PROTOCOL_IPv6>

Protocols.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::CDP::Addresses>, L<Net::Frame::Layer::CDP::ManagementAddresses>, L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
