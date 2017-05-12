#
# $Id: PPP.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::PPP;
use strict;
use warnings;

require Net::Packet::Layer2;
our @ISA = qw(Net::Packet::Layer2);

use Net::Packet::Consts qw(:ppp :layer);
require Bit::Vector;

our @AS = qw(
   address
   control
   protocol
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      address  => 0xff,
      control  => 0x03,
      protocol => NP_PPP_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NP_PPP_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('CCn', $self->[$__address],
      $self->[$__control], $self->[$__protocol])
         or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($address, $control, $protocol, $payload) =
      $self->SUPER::unpack('CCn a*', $self->[$__raw])
         or return undef;

   $self->[$__address]  = $address;
   $self->[$__control]  = $control;
   $self->[$__protocol] = $protocol;
   $self->[$__payload]  = $payload;

   1;
}

sub encapsulate {
   my $types = {
      NP_PPP_PROTOCOL_IPv4()   => NP_LAYER_IPv4(),
      NP_PPP_PROTOCOL_PPPLCP() => NP_LAYER_PPPLCP(),
   };

   $types->{shift->[$__protocol]} || NP_LAYER_UNKNOWN();
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $i = $self->is;
   sprintf "$l:+$i: address:0x%02x  control:0x%02x  protocol:0x%04x",
      $self->[$__address], $self->[$__control], $self->[$__protocol];
}

#
# Helpers
#

sub _isProtocol      { shift->[$__protocol] == shift()            }
sub isProtocolIpv4   { shift->_isProtocol(NP_PPP_PROTOCOL_IPv4)   }
sub isProtocolPpplcp { shift->_isProtocol(NP_PPP_PROTOCOL_PPPLCP) }

1;

__END__

=head1 NAME

Net::Packet::PPP - Point-to-Point Protocol layer 2 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:ppp);
   require Net::Packet::PPP;

   # Build a layer
   my $layer = Net::Packet::PPP->new(
      protocol => NP_PPP_PROTOCOL_IPv4,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::PPP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Point-to-Point Protocol layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer2> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<protocol> - 16 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

protocol: NP_PPP_PROTOCOL_IPv4

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<isProtocolIpv4>

=item B<isProtocolPpplcp>

Return 1 when encpasulated layer is of respective type. 0 otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:ppp);

=over 4

=item B<NP_PPP_HDR_LEN>

PPP header length.

=item B<NP_PPP_PROTOCOL_IPv4>

=item B<NP_PPP_PROTOCOL_PPPLCP>

Various supported encapsulated layer types.

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
