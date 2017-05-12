#
# $Id: Destination.pm,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
package Net::Frame::Layer::IPv6::Destination;
use strict; use warnings;

our $VERSION = '1.08';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   nextHeader
   hdrExtLen
);
our @AA = qw(
   options
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::IPv6::Option;

sub new {
   shift->SUPER::new(
      nextHeader => NF_IPv6_PROTOCOL_TCP,
      hdrExtLen  => 0,
      options    => [],
      @_,
   );
}

sub getOptionsLength {
   my $self = shift;
   my $len = 0;
   $len += $_->getLength for $self->options;
   return $len;
}

sub getLength {
   my $self = shift;
   return 2 + $self->getOptionsLength;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CC',
      $self->nextHeader, $self->hdrExtLen
   ) or return;

   for ($self->options) {
      $raw .= $_->pack;
   }

   return $self->raw($raw);
}

sub _unpackOptions {
   my $self = shift;
   my ($payload) = @_;

   my @options = ();
   while (defined($payload) && length($payload)) {
      my $opt = Net::Frame::Layer::IPv6::Option->new(raw => $payload)->unpack;
      push @options, $opt;
      $payload = $opt->payload;
      $opt->payload(undef);
   }
   $self->options(\@options);

   return $payload;
}

sub unpack {
   my $self = shift;

   my ($nextHeader, $hdrExtLen, $payload) =
      $self->SUPER::unpack('CC a*', $self->raw)
         or return;

   $self->nextHeader($nextHeader);
   $self->hdrExtLen($hdrExtLen);

   my $options;
   my $optionsLen = $hdrExtLen*8 + 6; # 8 - 2 bytes offset
   ($options, $payload) = $self->SUPER::unpack("a$optionsLen a*", $payload)
      or return;

   if (defined($options) && length($options)) {
      $self->_unpackOptions($options);
   }

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $hdrExtLen = int($self->getLength/8) - 1;
   if ($hdrExtLen < 0) {
      $hdrExtLen = 0;
   }
   $self->hdrExtLen($hdrExtLen);

   for my $option ($self->options) {
      $option->computeLengths;
   }

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      my $next = $self->nextHeader;
      return Net::Frame::Layer::IPv6->new(nextHeader => $next)->encapsulate;
   }

   return NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: nextHeader:0x%02x  hdrExtLen:%d",
         $self->nextHeader, $self->hdrExtLen;

   for ($self->options) {
      $buf .= "\n" . $_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::IPv6::Destination - Internet Protocol v6 Destination Extension Header layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::IPv6::Destination;

   my $ipv6eh = Net::Frame::Layer::IPv6::Destination->new(
      nextHeader => NF_IPv6_PROTOCOL_TCP,
      hdrExtLen  => 2,
      options    => []
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::IPv6::Destination->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv6 Destination options Extension Header layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2460.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<nextHeader>

Protocol number of the next header after the Destination header.

=item B<hdrExtLen>

The length of the Destination Options header in 8-byte units, not including the first 8 bytes of the header.

=item B<options>

A number of B<Net::Frame::Layer::IPv6::Option> objects.

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

=item B<getOptionsLength>

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
