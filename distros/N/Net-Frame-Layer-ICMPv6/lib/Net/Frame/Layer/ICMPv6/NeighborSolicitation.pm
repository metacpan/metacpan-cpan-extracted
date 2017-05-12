#
# $Id: NeighborSolicitation.pm 45 2014-04-09 06:32:08Z gomor $
#
package Net::Frame::Layer::ICMPv6::NeighborSolicitation;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   reserved
   targetAddress
);
our @AA = qw(
   options
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::ICMPv6::Option;

sub new {
   shift->SUPER::new(
      reserved      => 0,
      targetAddress => '::1',
      options       => [],
      @_,
   );
}

sub getOptionsLength {
   my $self = shift;
   my $len = 0;
   $len += $_->getLength for $self->options;
   return $len;
}

sub getLength {
   my $self = shift;
   return 20 + $self->getOptionsLength;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('Na16',
      $self->reserved, inet6Aton($self->targetAddress),
   ) or return;

   for ($self->options) {
      $raw .= $_->pack;
   }

   return $self->raw($raw);
}

sub _unpackOptions {
   my $self = shift;
   my ($payload) = @_;

   my @options = ();
   while (defined($payload) && length($payload)) {
      my $opt = Net::Frame::Layer::ICMPv6::Option->new(raw => $payload)->unpack;
      push @options, $opt;
      $payload = $opt->payload;
      $opt->payload(undef);
   }
   $self->options(\@options);
   return $payload;
}

sub unpack {
   my $self = shift;

   my ($reserved, $targetAddress, $payload) =
      $self->SUPER::unpack('Na16 a*', $self->raw)
         or return;

   $self->reserved($reserved);
   $self->targetAddress(inet6Ntoa($targetAddress));

   if (defined($payload) && length($payload)) {
      $payload = $self->_unpackOptions($payload);
   }

   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: reserved:%d\n".
                     "$l: targetAddress:%s",
                        $self->reserved, $self->targetAddress;

   for ($self->options) {
      $buf .= "\n".$_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::NeighborSolicitation - ICMPv6 Neighbor Solicitation type object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv6::NeighborSolicitation;

   my $layer = Net::Frame::Layer::ICMPv6::NeighborSolicitation->new(
      reserved      => 0,
      targetAddress => '::1',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv6::NeighborSolicitation->new(
      raw => $raw,
   );

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv6 Neighbor Solicitation object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<reserved>

Should be zeroed.

=item B<targetAddress>

An IPv6 address.

=item B<options>

An arrayref of B<Net::Frame::Layer::Option> objects.

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

=item B<getOptionsLength>

Returns the length in bytes of options, 0 if none.

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

L<Net::Frame::Layer::ICMPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
