#
# $Id: DatabaseDesc.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::DatabaseDesc;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   interfaceMtu
   options
   flags
   ddSequenceNumber
   lls
);
our @AA = qw(
   lsaList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::OSPF qw(:consts);
require Net::Frame::Layer::OSPF::Lsa;

sub new {
   shift->SUPER::new(
      interfaceMtu     => 1500,
      options          => 0,
      flags            => 0,
      ddSequenceNumber => 1,
      lsaList          => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 8;
   for ($self->lsaList) {
      $len += $_->getLength;
   }
   if ($self->lls) {
      $len += $self->lls->getLength;
   }
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nCCN',
      $self->interfaceMtu, $self->options, $self->flags,
      $self->ddSequenceNumber,
   ) or return undef;

   for ($self->lsaList) {
      $raw .= $_->pack or return undef;
   }

   if ($self->lls) {
      $raw .= $self->lls->pack or return undef;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($interfaceMtu, $options, $flags, $ddSequenceNumber, $payload) =
      $self->SUPER::unpack('nCCN a*', $self->raw)
         or return undef;

   $self->interfaceMtu($interfaceMtu);
   $self->options($options);
   $self->flags($flags);
   $self->ddSequenceNumber($ddSequenceNumber);

   my @lsaList = ();
   if ($payload) {
      my $count;
      while ($payload || (++$count > 100)) {
         my $lsa = Net::Frame::Layer::OSPF::Lsa->new(
            raw  => $payload,
            full => 0,
         ) or last;
         $lsa->unpack;
         $payload = $lsa->payload;
         push @lsaList, $lsa;
      }
   }

   $self->lsaList(\@lsaList);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: interfaceMtu:%d  options:0x%02x  flags:0x%02x\n".
      "$l: ddSequenceNumber:%d",
         $self->interfaceMtu,
         $self->options,
         $self->flags,
         $self->ddSequenceNumber,
   ;

   for ($self->lsaList) {
      $buf .= "\n".$_->print;
   }

   if ($self->lls) {
      $buf .= "\n".$self->lls->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::DatabaseDesc - OSPF DatabaseDesc type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::DatabaseDesc;

   my $layer = Net::Frame::Layer::OSPF::DatabaseDesc->new(
      interfaceMtu     => 1500,
      options          => 0,
      flags            => 0,
      ddSequenceNumber => 1,
      lsaList          => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::DatabaseDesc->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF DatabaseDesc object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<interfaceMtu>

=item B<options>

=item B<flags>

=item B<ddSequenceNumber>

=item B<lls>

Previous attributes set and get scalar values.

=item B<lsaList> ( [ B<Net::Frame::Layer::Lsa>, ... ] )

This attribute takes an array ref of B<Net::Frame::Layer::Lsa> objects.

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

L<Net::Frame::Layer::OSPF>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
