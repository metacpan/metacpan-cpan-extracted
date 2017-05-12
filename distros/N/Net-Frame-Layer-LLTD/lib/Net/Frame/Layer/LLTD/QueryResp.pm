#
# $Id: QueryResp.pm 12 2015-01-14 06:29:59Z gomor $
#
package Net::Frame::Layer::LLTD::QueryResp;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   flags
   numDescs
);
our @AA = qw(
   recveeDescList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::LLTD::RecveeDesc;

sub new {
   shift->SUPER::new(
      flags          => 0,
      numDescs       => 0,
      recveeDescList => [],
      @_,
   );
}

sub getRecveeDescListLength {
   my $self = shift;
   my $len = 0;
   for ($self->recveeDescList) {
      $len += $_->getLength;
   }
   $len;
}

sub getLength {
   my $self = shift;
   my $len = 2;
   $len += $self->getRecveeDescListLength if $self->recveeDescList;
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CC', $self->flags, $self->numDescs)
      or return undef;

   for ($self->recveeDescList) {
      $raw .= $_->pack;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($flags, $numDescs, $payload) =
      $self->SUPER::unpack('CC a*', $self->raw)
         or return undef;

   $self->flags($flags);
   $self->numDescs($numDescs);

   my @recveeDescList = ();
   if ($self->numDescs && $self->numDescs > 0) {
      for (1..$self->numDescs) {
         my $recvee = Net::Frame::Layer::LLTD::RecveeDesc->new(raw => $payload);
         $recvee->unpack;
         push @recveeDescList, $recvee;
         $payload = $recvee->payload;
      }
   }

   $self->recveeDescList(\@recveeDescList);
   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: flags:0x%02x  numDescs:%d",
         $self->flags, $self->numDescs;

   for ($self->recveeDescList) {
      $buf .= "\n".$_->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LLTD::QueryResp - LLTD QueryResp upper layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LLTD::QueryResp;

   # Build a layer
   my $layer = Net::Frame::Layer::LLTD::QueryResp->new(
      flags          => 0,
      numDescs       => 0,
      recveeDescList => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LLTD::QueryResp->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LLTD QueryResp layer.

Protocol specifications: http://www.microsoft.com/whdc/Rally/LLTD-spec.mspx .

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<flags>

=item B<numDescs>

=item B<recveeDescList> ( [ B<Net::Frame::Layer::LLTD::RecveeDesc>, ... ] )

This last attribute will store an array ref of B<Net::Frame::Layer::LLTD::RecveeDesc> objects.

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

=item B<getRecveeDescListLength>

This method will compute the length of all RecveeDesc objects contained in B<recveeDescList> attribute.

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

See L<Net::Frame::Layer::LLTD>.

=head1 SEE ALSO

L<Net::Frame::Layer::LLTD>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
