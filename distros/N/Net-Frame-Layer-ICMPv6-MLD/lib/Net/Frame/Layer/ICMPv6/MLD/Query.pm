#
# $Id: Query.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::ICMPv6::MLD::Query;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   resv
   sFlag
   qrv
   qqic
   numSources
);
our @AA = qw(
   sourceAddress
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

#no strict 'vars';

use Bit::Vector;

sub new {
   shift->SUPER::new(
      resv          => 0,
      sFlag         => 0,
      qrv           => 2,
      qqic          => 125,
      numSources    => 0,
      sourceAddress => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 4;
   $len += 16 for $self->sourceAddress;
   return $len;
}

sub pack {
   my $self = shift;

   my $resv   = Bit::Vector->new_Dec(4, $self->resv);
   my $sFlag  = Bit::Vector->new_Dec(1, $self->sFlag);
   my $qrv    = Bit::Vector->new_Dec(3, $self->qrv);
   my $bvlist = $resv->Concat_List($sFlag, $qrv);

   my $raw = $self->SUPER::pack('CCn',
      $bvlist->to_Dec,
      $self->qqic,
      $self->numSources
   ) or return;

   for ($self->sourceAddress) {
      $raw .= inet6Aton($_);
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $qqic, $numSources, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(8, $bv);
   $self->resv  ($bvlist->Chunk_Read(4, 4));
   $self->sFlag ($bvlist->Chunk_Read(1, 3));
   $self->qrv   ($bvlist->Chunk_Read(3, 0));

   $self->qqic($qqic);
   $self->numSources($numSources);

   my @sourceAddress = ();
   for my $num (0..$numSources-1) {
      if (defined($payload) && (length($payload) >= 16)) {
         my $addr = unpack 'a16', $payload;
         push @sourceAddress, inet6Ntoa($addr);
         $payload = substr $payload, 16;
      }
   }
   $self->sourceAddress(\@sourceAddress);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'ICMPv6::MLD::Query';
   }

   NF_LAYER_NONE;
}

sub computeLengths {
   my $self = shift;

   # Calculate numSources from sourceAddress array items
   if (scalar($self->sourceAddress) && ($self->numSources == 0)) {
      $self->numSources(scalar($self->sourceAddress))
   }

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: resv:%d  sFlag:%d  qrv:%d  qqic:%d  numSources:%d",
         $self->resv, $self->sFlag, $self->qrv, $self->qqic, $self->numSources;

   for ($self->sourceAddress) {
      $buf .= sprintf
      "\n$l: sourceAddress:%s",
         $_
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::MLD::Query - MLD Query Message

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::ICMPv6::MLD qw(:consts);

   my $layer = Net::Frame::Layer::ICMPv6::MLD::Query->new(
      resv          => 0,
      sFlag         => 0,
      qrv           => 2,
      qqic          => 125,
      numSources    => 0,
      sourceAddress => [],
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::ICMPv6::MLD::Query->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the MLD Query message.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3810.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<resv>

Reserved.

=item B<sFlag>

Suppress router-side processing.

=item B<qrv>

Querier's robustness variable.

=item B<qqic>

Querier's query interval code.

=item B<numSources>

Number of sources present in query.

=item B<sourceAddress>

Array of B<numSources> IPv6 unicast addresses.

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

=head1 SEE ALSO

L<Net::Frame::Layer>, L<Net::Frame::Layer::ICMPv6>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
