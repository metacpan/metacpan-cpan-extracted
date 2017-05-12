#
# $Id: Routing.pm,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
package Net::Frame::Layer::IPv6::Routing;
use strict; use warnings;

our $VERSION = '1.08';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   nextHeader
   hdrExtLen
   routingType
   segmentsLeft
   reserved
);
our @AA = qw(
   addresses
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

use Net::Frame::Layer::IPv6 qw(:consts);
my $IPv6RoutingComputeSegmentsLeft = 1;

sub new {
   shift->SUPER::new(
      nextHeader   => NF_IPv6_PROTOCOL_TCP,
      hdrExtLen    => 2,
      routingType  => 0,
      segmentsLeft => 1,
      reserved     => 0,
      addresses    => ['::1'],
      @_,
   );
}

sub _getAddressesLength {
   my $self = shift;
   my $len = 0;
   $len += 16 for $self->addresses;
   return $len;
}

sub getLength {
   my $self = shift;
   return 8 + $self->_getAddressesLength;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCCCN',
      $self->nextHeader, $self->hdrExtLen, $self->routingType,
      $self->segmentsLeft, $self->reserved
   ) or return;

   for ($self->addresses) {
      $raw .= $self->SUPER::pack('a16',
         inet6Aton($_)
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($nextHeader, $hdrExtLen, $routingType, $segmentsLeft, $reserved, $rest) =
      $self->SUPER::unpack('CCCCN a*', $self->raw)
         or return;

   $self->nextHeader($nextHeader);
   $self->hdrExtLen($hdrExtLen);
   $self->routingType($routingType);
   $self->segmentsLeft($segmentsLeft);
   $self->reserved($reserved);

   my @addresses = ();
   for (1..$hdrExtLen/2) {
      my ($address) =
         $self->SUPER::unpack('a16', substr $rest, 16*($_-1))
            or return;
      push @addresses, inet6Ntoa($address)
   }

   $self->addresses(\@addresses);

   $self->payload(substr $rest, 16*$hdrExtLen/2);

   return $self;
}

sub computeSegmentsLeft {
   my ($self, $arg) = @_;

   if (defined($arg)) {
      if (($arg =~ /^\d$/) && ($arg == 0)) {
         $IPv6RoutingComputeSegmentsLeft = 0
      } else {
         $IPv6RoutingComputeSegmentsLeft = 1
      }
   }
   return $IPv6RoutingComputeSegmentsLeft
}

sub computeLengths {
   my $self = shift;

   my $hdrExtLen = 0;
   $hdrExtLen += 2 for $self->addresses;
   $self->hdrExtLen($hdrExtLen);

   if ($IPv6RoutingComputeSegmentsLeft) {
      my $segmentsLeft = 0;
      $segmentsLeft += 1 for $self->addresses;
      $self->segmentsLeft($segmentsLeft);
   }

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      my $next = $self->nextHeader;
      return Net::Frame::Layer::IPv6->new(nextHeader=>$self->nextHeader)->encapsulate
   }

   return NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: nextHeader:0x%02x  hdrExtLen:%d  routingType:%d\n".
      "$l: segmentsLeft:%d  reserved:%d",
         $self->nextHeader, $self->hdrExtLen, $self->routingType,
         $self->segmentsLeft, $self->reserved;

   for ($self->addresses) {
      $buf .= sprintf
         "\n$l: address:%s",
            $_
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::IPv6::Routing - Internet Protocol v6 Routing Extension Header layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::IPv6::Routing;

   my $icmp = Net::Frame::Layer::IPv6::Routing->new(
      nextHeader   => NF_IPv6_PROTOCOL_TCP
      hdrExtLen    => 2
      routingType  => 0,
      segmentsLeft => 1,
      reserved     => 0,
      addresses    => ['::1']
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::IPv6::Routing->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv6 Routing Extension Header layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2460.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<nextHeader>

Protocol number of the next header after the Routing header.

=item B<hdrExtLen>

The length of the Routing header in 8-byte units, not including the first 8 bytes of the header. For a Routing Type of 0, this value is thus two times the number addresses embedded in the header.

=item B<routingType>

This field allows multiple routing types to be defined; at present, the only value used is 0.

=item B<segmentsLeft>

Specifies the number of explicitly-named nodes remaining in the route until the destination.

=item B<reserved>

Not used; set to zeroes.

=item B<addresses>

A set of IPv6 addresses that specify the route to be used.

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

=item B<computeLengths>

Computes B<hdrExtLen> and B<segmentsLeft> based on number of B<addresses>.

=item B<computeSegmentsLeft> (0 | 1)

Disable (0) or enable (1) automatic computing of B<segmentsLeft> by the B<computeLengths> method.  Default is enabled.

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

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
