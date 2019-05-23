#
# $Id: PPP.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::PPP;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_PPP_HDR_LEN
      NF_PPP_PROTOCOL_IPv4
      NF_PPP_PROTOCOL_DDP
      NF_PPP_PROTOCOL_IPX
      NF_PPP_PROTOCOL_IPv6
      NF_PPP_PROTOCOL_CDP
      NF_PPP_PROTOCOL_PPPLCP
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_PPP_HDR_LEN         => 4;
use constant NF_PPP_PROTOCOL_IPv4   => 0x0021;
use constant NF_PPP_PROTOCOL_DDP    => 0x0029;
use constant NF_PPP_PROTOCOL_IPX    => 0x002b;
use constant NF_PPP_PROTOCOL_IPv6   => 0x0057;
use constant NF_PPP_PROTOCOL_CDP    => 0x0207;
use constant NF_PPP_PROTOCOL_PPPLCP => 0xc021;

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
      protocol => NF_PPP_PROTOCOL_IPv4,
      @_,
   );
}

sub getLength { NF_PPP_HDR_LEN }

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('CCn', $self->[$__address],
      $self->[$__control], $self->[$__protocol])
         or return undef;

   $self->[$__raw];
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

   $self;
}

our $Next = {
   NF_PPP_PROTOCOL_IPv4()   => 'IPv4',
   NF_PPP_PROTOCOL_DDP()    => 'DDP',
   NF_PPP_PROTOCOL_IPX()    => 'IPX',
   NF_PPP_PROTOCOL_IPv6()   => 'IPv6',
   NF_PPP_PROTOCOL_CDP()    => 'CDP',
   NF_PPP_PROTOCOL_PPPLCP() => 'PPPLCP',
};

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   return $Next->{$self->[$__protocol]} || NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: address:0x%02x  control:0x%02x  protocol:0x%04x",
      $self->[$__address], $self->[$__control], $self->[$__protocol];
}

1;

__END__

=head1 NAME

Net::Frame::Layer::PPP - Point-to-Point Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::PPP qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::PPP->new(
      address  => 0xff,
      control  => 0x03,
      protocol => NF_PPP_PROTOCOL_IPv4,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::PPP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Point-to-Point Protocol layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<address> - 8 bits

=item B<control> - 8 bits

=item B<protocol> - 16 bits

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

Load them: use Net::Frame::Layer::PPP qw(:consts);

=over 4

=item B<NF_PPP_PROTOCOL_IPv4>

=item B<NF_PPP_PROTOCOL_DDP>

=item B<NF_PPP_PROTOCOL_IPX>

=item B<NF_PPP_PROTOCOL_IPv6>

=item B<NF_PPP_PROTOCOL_CDP>

=item B<NF_PPP_PROTOCOL_PPPLCP>

Various supported encapsulated layer types.

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
