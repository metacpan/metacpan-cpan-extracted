#
# $Id: v1.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::RIPng::v1;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_RIPNG_METRIC_INFINITY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_RIPNG_METRIC_INFINITY    => 16;

our @AS = qw(
   prefix
   routeTag
   prefixLength
   metric
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      prefix       => '::',
      routeTag     => 0,
      prefixLength => 64,
      metric       => 1,
      @_,
   );
}

sub full {
   shift->SUPER::new(
      prefix       => '::',
      routeTag     => 0,
      prefixLength => 0,
      metric        => NF_RIPNG_METRIC_INFINITY,
      @_,
   );
}

sub getLength { 20 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('a16nCC',
      inet6Aton($self->prefix),
      $self->routeTag,
      $self->prefixLength,
      $self->metric
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($prefix, $routeTag, $prefixLength, $metric, $payload) =
      $self->SUPER::unpack('a16nCC a*', $self->raw)
         or return;

   $self->prefix(inet6Ntoa($prefix));
   $self->routeTag($routeTag);
   $self->prefixLength($prefixLength);
   $self->metric($metric);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return "RIPng::v1";
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: prefix:%s\n".
      "$l: routeTag:%d  prefixLength:%d  metric:%d",
         $self->prefix,
         $self->routeTag, $self->prefixLength, $self->metric;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::RIPng::v1 - Routing Information Protocol ng v1 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::RIP::v1 qw(:consts);

   my $ripngv1 = Net::Frame::Layer::RIPng::v1->new(
      prefix       => '::',
      routeTag     => 0,
      prefixLength => 64,
      metric       => 1,
   );
   $ripngv1->pack;

   print 'RAW: '.$ripngv1->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::RIPng::v1->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the RIPng v1 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2080.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<prefix>

IPv6 prefix.

=item B<routeTag>

Attribute assigned to a route for separating routes within RIP domain.

=item B<prefixLength>

IPv6 prefix length of B<prefix>.

=item B<metric>

Metric for C<prefix>.

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

=item B<full>

=item B<full> (hash)

Object constructor. Same as B<new> but with RIPng Request header, requests full routing table.  You can pass attributes that will overwrite default ones.  Default values:  all fields 0 with B<NF_RIPNG_METRIC_INFINITY> set.

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

Load them: use Net::Frame::Layer::RIPng::v1 qw(:consts);

=over 4

=item B<NF_RIPNG_METRIC_INFINITY>

Infinity metric (16).

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
