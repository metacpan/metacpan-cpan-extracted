#
# $Id: PPPLCP.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::PPPLCP;
use strict;
use warnings;

require Net::Packet::Layer3;
our @ISA = qw(Net::Packet::Layer3);

use Net::Packet::Consts qw(:ppplcp :layer);

our @AS = qw(
   code
   identifier
   length
   magicNumber
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      code        => NP_PPPLCP_CODE_ECHO_REQUEST,
      identifier  => 1,
      length      => NP_PPPLCP_HDR_LEN,
      magicNumber => 0xffffffff,
      @_,
   );
}

sub getLength { shift->[$__length] }

sub getPayloadLength { shift->[$__length] - NP_PPPLCP_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('CCnN',
      $self->[$__code],
      $self->[$__identifier],
      $self->[$__length],
      $self->[$__magicNumber],
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($code, $identifier, $length, $magicNumber, $payload) =
      $self->SUPER::unpack('CCnN a*', $self->[$__raw])
         or return undef;

   $self->[$__code]        = $code;
   $self->[$__identifier]  = $identifier;
   $self->[$__length]      = $length;
   $self->[$__magicNumber] = $magicNumber;
   $self->[$__payload]     = $payload;

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
   sprintf "$l:+$i: code:0x%02x  identifier:0x%02x  length:%d  ".
           "magicNumber:0x%04x",
      $self->[$__code], $self->[$__identifier], $self->[$__length],
      $self->[$__magicNumber];
}

1;

__END__

=head1 NAME

Net::Packet::PPPLCP - PPP Link Control Protocol layer 3 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:ppplcp);
   require Net::Packet::PPPLCP;

   # Build a layer
   my $layer = Net::Packet::PPPLCP->new(
      code        => NP_PPPLCP_CODE_ECHO_REQUEST,
      identifier  => 1,
      length      => NP_PPPLCP_HDR_LEN,
      magicNumber => 0xffffffff,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::PPPLCP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the PPP Link Control Protocol layer.

See also B<Net::Packet::Layer> and B<Net::Packet::Layer3> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<code> - 8 bits

=item B<identifier> - 8 bits

=item B<length> - 16 bits

=item B<magicNumber> - 32 bits

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

code:        NP_PPPLCP_CODE_ECHO_REQUEST

identifier:  1

length:      NP_PPPLCP_HDR_LEN

magicNumber: 0xffffffff

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

Load them: use Net::Packet::Consts qw(:ppplcp);

=over 4

=item B<NP_PPPLCP_HDR_LEN>

PPP LCP header length.

=item B<NP_PPPLCP_CODE_ECHO_REQUEST>

=item B<NP_PPPLCP_CODE_ECHO_REPLY>

Various supported PPP LCP codes.

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
