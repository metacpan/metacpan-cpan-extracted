#
# $Id: LinkStateUpdate.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::LinkStateUpdate;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   lsaNumber
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
      lsaNumber => 0,
      lsaList   => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 4;
   for ($self->lsaList) {
      $len += $_->getLength;
   }
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('N', $self->lsaNumber)
      or return undef;

   for ($self->lsaList) {
      $raw .= $_->pack;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($lsaNumber, $payload) = $self->SUPER::unpack('N a*', $self->raw)
      or return undef;

   $self->lsaNumber($lsaNumber);

   my @lsaList = ();
   while ($payload && length($payload) > 0) {
      my $lsa = Net::Frame::Layer::OSPF::Lsa->new(raw => $payload);
      $lsa->unpack;
      push @lsaList, $lsa;
      $payload = $lsa->payload;
   }

   $self->lsaList(\@lsaList);
   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: lsaNumber:%d",
         $self->lsaNumber,
   ;

   for ($self->lsaList) {
      $buf .= "\n".$_->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::LinkStateUpdate - OSPF LinkStateUpdate type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::LinkStateUpdate;

   my $layer = Net::Frame::Layer::OSPF::LinkStateUpdate->new(
      lsaNumber => 0,
      lsaList   => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::LinkStateUpdate->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF LinkStateUpdate object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<lsaNumber>

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
