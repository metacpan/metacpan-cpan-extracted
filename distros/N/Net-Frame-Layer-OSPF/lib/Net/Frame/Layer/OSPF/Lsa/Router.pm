#
# $Id: Router.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::Lsa::Router;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   flags
   zero
   nLink
);
our @AA = qw(
   linkList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::OSPF qw(:consts);
use Net::Frame::Layer::OSPF::Lsa::Router::Link;

sub new {
   shift->SUPER::new(
      flags    => 0,
      zero     => 0,
      nLink    => 0,
      linkList => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 4;
   for ($self->linkList) {
      $len += $_->getLength;
   }
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCn', $self->flags, $self->zero, $self->nLink)
      or return undef;

   for ($self->linkList) {
      $raw .= $_->pack;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($flags, $zero, $nLink, $payload) = $self->SUPER::unpack('CCn a*',
      $self->raw)
          or return undef;

   $self->flags($flags);
   $self->zero($zero);
   $self->nLink($nLink);

   my @linkList = ();
   while ($payload && length($payload) > 0) {
      my $r = Net::Frame::Layer::OSPF::Lsa::Router::Link->new(raw => $payload);
      $r->unpack;
      $payload = $r->payload;
      push @linkList, $r;
   }
   $self->linkList(\@linkList);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: flags:0x%02x  zero:0x%02x  nLink:%d",
         $self->flags,
         $self->zero,
         $self->nLink,
   ;

   for ($self->linkList) {
      $buf .= "\n".$_->print;
   }
   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::Lsa::Router - OSPF Lsa Router type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::Lsa::Router;

   my $layer = Net::Frame::Layer::OSPF::Lsa::Router->new(
      flags    => 0,
      zero     => 0,
      nLink    => 0,
      linkList => [],
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::Lsa::Router->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF Lsa::Router object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<flags>

=item B<zero>

=item B<nLink>

Previous attributes set and get scalar values.

=item B<linkList> ( [ B<Net::Frame::Layer::Lsa::Router::Link>, ... ] )

This attribute takes an array ref of B<Net::Frame::Layer::Lsa::Router::Link> objects.

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
