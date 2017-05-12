#
# $Id: UDPLite.pm 29 2015-01-23 06:28:43Z gomor $
#
package Net::Frame::Layer::UDPLite;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

our @AS = qw(
   src
   dst
   coverage
   checksum
);

__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer qw(:subs);

sub new {
   my $self = shift->SUPER::new(
      src      => getRandomHighPort(),
      dst      => getRandomHighPort(),
      coverage => 0,
      checksum => 0,
      @_,
   );
   return $self;
}

sub getLength { 8 }

sub computeChecksums {
   my $self = shift;
   my ($h)  = @_;

   my $phpkt;
   if ($h->{type} eq 'IPv4') {
      $phpkt = $self->SUPER::pack('a4a4CCn',
         inetAton($h->{src}), inetAton($h->{dst}), 0, 17, $self->getLength,
      ) or return;
   }
   elsif ($h->{type} eq 'IPv6') {
      $phpkt = $self->SUPER::pack('a*a*NnCC',
         inet6Aton($h->{src}),
         inet6Aton($h->{dst}), $self->getLength, 0, 0, 17,
      ) or return
   }

   $phpkt .= $self->SUPER::pack('nnnn',
      $self->src, $self->dst, $self->getLength, 0,
   ) or return;

   if ($self->payload) {
      $phpkt .= $self->SUPER::pack('a*', $self->payload)
         or return;
   }

   $self->checksum(inetChecksum($phpkt));

   return 1;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack("nnnn",
      $self->src,
      $self->dst,
      $self->coverage,
      $self->checksum,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($src, $dst, $coverage, $checksum, $payload) =
      $self->SUPER::unpack("nnnn a*", $self->raw)
         or return;

   $self->src($src);
   $self->dst($dst);
   $self->coverage($coverage);
   $self->checksum($checksum);
   $self->payload($payload);

   return $self;
}

our $Next = {
};

sub encapsulate {
   my $self = shift;
   return $self->nextLayer;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l:+src:%d  dst:%d  coverage:%d  checksum:0x%04x",
      $self->src,
      $self->dst,
      $self->coverage,
      $self->checksum,
   ;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::UDPLite - UDPLite layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::UDPLite qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::UDPLite->new(
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::UDPLite->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the UDPLite layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

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

Load them: use Net::Frame::Layer::UDPLite qw(:consts);

=over 4

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
