#
# $Id: RAW.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::RAW;
use strict;
use warnings;

use Net::Frame::Layer qw(:consts);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);
__PACKAGE__->cgBuildIndices;

our %EXPORT_TAGS = (
   consts => [],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

no strict 'vars';

sub pack {
   my $self = shift;
   $self->[$__raw] = '';
   $self->[$__raw];
}

sub unpack {
   my $self = shift;
   $self->[$__payload] = $self->[$__raw];
   $self;
}

sub encapsulate {
   my $self = shift;

   return $self->[$__nextLayer] if $self->[$__nextLayer];

   return NF_LAYER_NONE if ! $self->[$__payload];

   # With RAW layer, we must guess which type is the first layer
   my $payload = CORE::unpack('H*', $self->[$__payload]);

   # XXX: may not work on big-endian arch
   if ($payload =~ /^4/) {
      return 'IPv4';
   }
   elsif ($payload =~ /^6/) {
      return 'IPv6';
   }
   elsif ($payload =~ /^0001....06/) {
      return 'ARP';
   }

   return NF_LAYER_UNKNOWN;
}

sub print {
   my $self = shift;
   my $l = $self->layer;
   "$l: empty";
}

1;

__END__

=head1 NAME

Net::Frame::Layer::RAW - empty layer object

=head1 SYNOPSIS
  
   use Net::Frame::Layer::RAW qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::RAW->new;
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::RAW->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the raw layer 2.
 
See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

No attributes in this layer.

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. No default values, because no attributes here.

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

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
