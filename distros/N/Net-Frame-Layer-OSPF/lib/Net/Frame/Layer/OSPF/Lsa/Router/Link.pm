#
# $Id: Link.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::Lsa::Router::Link;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   linkId
   linkData
   type
   nTos
   metric
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::OSPF qw(:consts);

sub new {
   shift->SUPER::new(
      linkId   => '0.0.0.0',
      linkData => '0.0.0.0',
      type     => 0,
      nTos     => 0,
      metric   => 0,
      @_,
   );
}

sub getLength { 12 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('a4a4CCn',
      inetAton($self->linkId), inetAton($self->linkData), $self->type,
      $self->nTos, $self->metric,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($linkId, $linkData, $type, $nTos, $metric, $payload)
      = $self->SUPER::unpack('a4a4CCn a*', $self->raw)
          or return undef;

   $self->linkId(inetNtoa($linkId));
   $self->linkData(inetNtoa($linkData));
   $self->type($type);
   $self->nTos($nTos);
   $self->metric($metric);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf
      "$l: linkId:%s  linkData:%s  type:0x%02x  nTos:%d  metric:%d",
         $self->linkId,
         $self->linkData,
         $self->type,
         $self->nTos,
         $self->metric,
   ;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::Lsa::Router::Link - OSPF Lsa  Router  Link type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::Lsa::Router::Link;

   my $layer = Net::Frame::Layer::OSPF::Lsa::Router::Link->new(
      linkId   => '0.0.0.0',
      linkData => '0.0.0.0',
      type     => 0,
      nTos     => 0,
      metric   => 0,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::Lsa::Router::Link->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF Lsa::Router::Link object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<linkId>

=item B<linkData>

=item B<type>

=item B<nTos>

=item B<metric>

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
