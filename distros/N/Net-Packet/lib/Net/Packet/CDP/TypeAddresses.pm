#
# $Id: TypeAddresses.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::CDP::TypeAddresses;
use strict;
use warnings;

require Net::Packet::CDP::Type;
our @ISA = qw(Net::Packet::CDP::Type);

use Net::Packet::Consts qw(:cdp);
require Net::Packet::CDP::Address;

our @AS = qw(
   numberOfAddresses
);
our @AA = qw(
   addresses
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      type              => NP_CDP_TYPE_ADDRESSES,
      length            => 8,
      numberOfAddresses => 0,
      addresses         => [],
      @_,
   );
}

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nn',
      $self->type,
      $self->length,
   )) or return undef;

   my $raw = $self->raw;
   $raw .= $_->pack for $self->addresses;
   $self->raw($raw);

   1;
}

sub unpack {
   my $self = shift;

   my ($type, $length, $numberOfAddresses, $tail) =
      $self->SUPER::unpack('nnNa*', $self->raw)
         or return undef;

   $self->type($type);
   $self->length($length);
   $self->numberOfAddresses($numberOfAddresses);

   my @addressList;
   for my $n (1..$numberOfAddresses) {
      my $a = Net::Packet::CDP::Address->new(raw => $tail);
      push @addressList, $a;
      $tail = $a->payload;
   }

   $self->addresses(\@addressList);
   $self->payload($tail);

   1;
}

sub print {
   my $self = shift;

   my $buf = '';
   my $i = $self->is;
   my $l = $self->layer;
   $buf .= sprintf "$l: $i: type:0x%04x  length:%d numberOfAddresses:%d",
      $self->type, $self->length, $self->numberOfAddresses;

   for ($self->addresses) {
      $buf .= "\n".$_->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Packet::CDP::TypeAddresses - Cisco Discovery Protocol Addresses extension header

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:cdp);
   require Net::Packet::CDP::TypeAddresses;

   # Build a layer
   my $layer = Net::Packet::CDP::TypeAddresses->new(
      type              => NP_CDP_TYPE_ADDRESSES,
      length            => 8,
      numberOfAddresses => 0,
      addresses         => [],
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::CDP::TypeAddresses->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Cisco Discovery Protocol Addresses type extension header.

=head1 ATTRIBUTES

=over 4

=item B<type> - 16 bits

=item B<length> - 16 bits

=item B<numberOfAddresses> - 32 bits

=item B<addresses> - variable length

The last one contains an arrayref of B<Net::Packet::CDP::Address> objects.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

type:              NP_CDP_TYPE_ADDRESSES

length:            8

numberOfAddresses: 0

addresses:         []

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=back

=head1 CONSTANTS

See B<Net::Packet::CDP> CONSTANTS.

=over 4

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
