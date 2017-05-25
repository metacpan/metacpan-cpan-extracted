#
# $Id: PWMCW.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::MPLS::PWMCW;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_MPLS_PWNIBBLE_MCW
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_MPLS_PWNIBBLE_MCW => 0;

our @AS = qw(
   pwNibble
   flags
   frg
   length
   sequenceNumber
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Bit::Vector;

sub new {
   shift->SUPER::new(
      pwNibble       => NF_MPLS_PWNIBBLE_MCW,
      flags          => 0,
      frg            => 0,
      length         => 0,
      sequenceNumber => 0,
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $pwNibble = Bit::Vector->new_Dec(4, $self->pwNibble);
   my $flags    = Bit::Vector->new_Dec(4, $self->flags);
   my $bvlist1  = $pwNibble->Concat_List($flags);

   my $frg     = Bit::Vector->new_Dec(2, $self->frg);
   my $length  = Bit::Vector->new_Dec(6, $self->length);
   my $bvlist2 = $frg->Concat_List($length);

   my $raw = $self->SUPER::pack('CCn',
      $bvlist1->to_Dec,
      $bvlist2->to_Dec,
      $self->sequenceNumber
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv1, $bv2, $sequenceNumber, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   my $bvlist1 = Bit::Vector->new_Dec(8, $bv1);
   $self->pwNibble($bvlist1->Chunk_Read(4,4));
   $self->flags   ($bvlist1->Chunk_Read(4,0));

   my $bvlist2 = Bit::Vector->new_Dec(8, $bv2);
   $self->frg   ($bvlist2->Chunk_Read(2,6));
   $self->length($bvlist2->Chunk_Read(6,0));

   $self->sequenceNumber($sequenceNumber);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      my $payload = CORE::unpack('H', $self->payload);
      if ($payload == NF_MPLS_PWNIBBLE_MCW) {
         return 'PWMCW::PWMCW';
      } elsif ($payload == 1) {
         return 'PWMCW::PWMCW';
      } elsif ($payload == 4) {
         return 'IPv4';
      } elsif ($payload == 6) {
         return 'IPv6';
      } else {
         return 'ETH';
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: pwNibble:%d  flags:%d  frg:%d  length:%d  sequenceNumber:0x%04x",
         $self->pwNibble, $self->flags, $self->frg, 
         $self->length, $self->sequenceNumber;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::MPLS::PWMCW - MPLS Pseudowire MPLS Control Word layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::MPLS::PWMCW qw(:consts);

   my $layer = Net::Frame::Layer::MPLS::PWMCW->new(
      pwNibble       => NF_MPLS_PWNIBBLE_MCW,
      flags          => 0,
      frg            => 0,
      length         => 0,
      sequenceNumber => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::MPLS::PWMCW->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MPLS Pseudowire MPLS Control Word layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc4385.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<pwNibble>

PWMCW first nibble - default 0.

=item B<flags>

PWMCW flags.

=item B<frg>

PWMCW fragmentation.

=item B<length>

PWMCW length.

=item B<sequenceNumber>

PWMCW sequence number.

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

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::MPLS::PWMCW qw(:consts);

=over 4

=item B<NF_MPLS_PWNIBBLE_MCW>

Pseudowire first nibble.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
