#
# $Id: Fragment.pm,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
package Net::Frame::Layer::IPv6::Fragment;
use strict; use warnings;

our $VERSION = '1.08';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   nextHeader
   reserved
   fragmentOffset
   res
   mFlag
   identification
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::IPv6 qw(:consts);

sub new {
   shift->SUPER::new(
      nextHeader     => NF_IPv6_PROTOCOL_TCP,
      reserved       => 0,
      fragmentOffset => 0,
      res            => 0,
      mFlag          => 0,
      identification => 0,
      @_,
   );
}

sub getLength { 8 }

sub pack {
   my $self = shift;

   my $fragmentOffset = Bit::Vector->new_Dec(13, $self->fragmentOffset);
   my $res            = Bit::Vector->new_Dec( 2, $self->res);
   my $mFlag          = Bit::Vector->new_Dec( 1, $self->mFlag);
   my $v16            = $fragmentOffset->Concat_List($res, $mFlag);

   my $raw = $self->SUPER::pack('CCnN',
      $self->nextHeader, $self->reserved, $v16->to_Dec, $self->identification
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($nextHeader, $reserved, $fragflags, $identification, $payload) =
      $self->SUPER::unpack('CCnN a*', $self->raw)
         or return;

   $self->nextHeader($nextHeader);
   $self->reserved($reserved);

   my $v16 = Bit::Vector->new_Dec(16, $fragflags);

   $self->fragmentOffset($v16->Chunk_Read(13, 3));
   $self->res           ($v16->Chunk_Read( 2, 1));
   $self->mFlag         ($v16->Chunk_Read( 1, 0));

   $self->identification($identification);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      my $next = $self->nextHeader;
      return Net::Frame::Layer::IPv6->new(nextHeader => $self->nextHeader)->encapsulate;
   }

   return NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: nextHeader:0x%02x  reserved:%d  fragmentOffset:0x%04x\n".
      "$l: res:%d  mFlag:%d  identification:%d",
         $self->nextHeader, $self->reserved, $self->fragmentOffset,
         $self->res, $self->mFlag, $self->identification;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::IPv6::Fragment - Internet Protocol v6 Fragment Extension Header layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::IPv6::Fragment;

   my $icmp = Net::Frame::Layer::IPv6::Fragment->new(
      nextHeader     => NF_IPv6_PROTOCOL_TCP,
      reserved       => 0,
      fragmentOffset => 0,
      res            => 0,
      mFlag          => 0,
      identification => 0
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::IPv6::Fragment->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IPv6 Fragment Extension Header layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2460.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<nextHeader>

Protocol number of the next header after the Fragment header.

=item B<reserved>

Not used; set to zeroes.

=item B<fragmentOffset>

Specifies the offset, or position, in the overall message where the data in this fragment goes. It is specified in units of 8 bytes (64 bits) and used in a manner very similar to the field of the same name in the IPv4 header.

=item B<res>

Not used; set to zeroes.

=item B<mFlag>

Same as the flag of the same name in the IPv4 header - when set to 0, indicates the last fragment in a message; when set to 1, indicates that more fragments are yet to come in the fragmented message.

=item B<identification>

Same as the field of the same name in the IPv4 header, but expanded to 32 bits. It contains a specific value that is common to each of the fragments belonging to a particular message, to ensure that pieces from different fragmented messages are not mixed together.

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
