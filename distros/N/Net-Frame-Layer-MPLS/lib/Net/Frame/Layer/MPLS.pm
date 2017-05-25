#
# $Id: MPLS.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::MPLS;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_MPLS_S_NO
      NF_MPLS_S_YES
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_MPLS_S_NO  => 0;
use constant NF_MPLS_S_YES => 1;

our @AS = qw(
   label
   tc
   s
   ttl
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Bit::Vector;
use Net::Frame::Layer::MPLS::PWACH qw(:consts);
use Net::Frame::Layer::MPLS::PWMCW qw(:consts);

sub new {
   shift->SUPER::new(
      label => 0,
      tc    => 0,
      s     => NF_MPLS_S_YES,
      ttl   => 255,
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $label  = Bit::Vector->new_Dec(20, $self->label);
   my $tc     = Bit::Vector->new_Dec(3, $self->tc);
   my $s      = Bit::Vector->new_Dec(1, $self->s);
   my $ttl    = Bit::Vector->new_Dec(8, $self->ttl);
   my $bvlist = $label->Concat_List($tc, $s, $ttl);

   my $raw = $self->SUPER::pack('N',
      $bvlist->to_Dec
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $payload) =
      $self->SUPER::unpack('N a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(32, $bv);
   $self->label($bvlist->Chunk_Read(20,12));
   $self->tc   ($bvlist->Chunk_Read(3,9));
   $self->s    ($bvlist->Chunk_Read(1,8));
   $self->ttl  ($bvlist->Chunk_Read(8,0));

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if (!$self->s) {
      return 'MPLS';
   }
   if ($self->payload) {
      my $payload = CORE::unpack('H', $self->payload);
      if ($payload == NF_MPLS_PWNIBBLE_MCW) {
         return 'MPLS::PWMCW';
      } elsif ($payload == NF_MPLS_PWNIBBLE_ACH) {
         return 'MPLS::PWACH';
      } elsif ($payload == 4) {
         return 'IPv4';
      } elsif ($payload == 6) {
         return 'IPv6';
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: label:%d  tc:%d  s:%d  ttl:%d",
         $self->label, $self->tc, $self->s, $self->ttl;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::MPLS - Multiprotocol Label Switching layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::MPLS qw(:consts);

   my $layer = Net::Frame::Layer::MPLS->new(
      label => 0,
      tc    => 0,
      s     => NF_MPLS_S_YES,
      ttl   => 255,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::MPLS->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MPLS layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3031.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<label>

MPLS label.

=item B<tc>

MPLS traffic class.

=item B<s>

Bottom of stack.

=item B<ttl>

Time to live.

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

Load them: use Net::Frame::Layer::MPLS qw(:consts);

=over 4

=item B<NF_MPLS_S_NO>

=item B<NF_MPLS_S_YES>

Bottom of stack yes / no.

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
