#
# $Id: RAW.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::RAW;
use strict;
use warnings;

require Net::Packet::Layer2;
our @ISA = qw(Net::Packet::Layer2);
__PACKAGE__->cgBuildIndices;

use Net::Packet::Consts qw(:layer);

no strict 'vars';

sub pack { shift->[$__raw] = '' }

sub unpack {
   my $self = shift;
   $self->[$__payload] = $self->[$__raw];
   1;
}

sub encapsulate {
   my $self = shift;

   return NP_LAYER_NONE() if ! $self->[$__payload];

   # With RAW layer, we must guess which type is the first layer
   my $payload = CORE::unpack('H*', $self->[$__payload]);

   # XXX: may not work on big-endian arch
   if ($payload =~ /^4/) {
      return NP_LAYER_IPv4();
   }
   elsif ($payload =~ /^6/) {
      return NP_LAYER_IPv6();
   }
   elsif ($payload =~ /^0001....06/) {
      return NP_LAYER_ARP();
   }

   return NP_LAYER_UNKNOWN();
}

1;

__END__

=head1 NAME

Net::Packet::RAW - empty layer 2 object

=head1 SYNOPSIS
  
   #
   # Usually, you do not use this module directly
   #
   # No constants for RAW
   require Net::Packet::RAW;

   # Build a layer
   my $layer = Net::Packet::RAW->new;
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::RAW->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the raw layer 2.
 
See also B<Net::Packet::Layer> and B<Net::Packet::Layer2> for other attributes and methods.

=head1 METHODS

=over 4

=item B<new>

Object constructor. No default values, because no attributes.

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
