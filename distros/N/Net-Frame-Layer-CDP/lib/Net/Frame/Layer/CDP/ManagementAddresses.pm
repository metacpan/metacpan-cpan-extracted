#
# $Id: ManagementAddresses.pm 1640 2013-03-28 17:58:27Z VinsWorldcom $
#
package Net::Frame::Layer::CDP::ManagementAddresses;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   numAddresses
);
our @AA = qw(
   addresses
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

#no strict 'vars';

use Net::Frame::Layer::CDP::Constants qw(:consts);

sub new {
   shift->SUPER::new(
      type         => NF_CDP_TYPE_MANAGEMENT_ADDR,
      length       => 8,
      numAddresses => 0,
      addresses    => [],
      @_,
   );
}

sub getLength {
   my $self = shift;

   my $length = 8;
   $length += $_->getLength for $self->addresses;

   return $length
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nnN',
      $self->type,
      $self->length,
      $self->numAddresses
   ) or return;

   for ($self->addresses) {
      $raw .= $_->pack;
   }

   return $self->raw($raw);
}

sub _unpackAddresses {
   my $self = shift;
   my ($payload) = @_;

   my @addressesList;
   while (defined($payload) && length($payload)) {
      my $addr = Net::Frame::Layer::CDP::Address->new(raw => $payload)->unpack;
      push @addressesList, $addr;
      $payload = $addr->payload;
      $addr->payload(undef);
   }
   $self->addresses(\@addressesList);
   return $payload;
}

sub unpack {
   my $self = shift;

   my ($type, $length, $numAddresses, $tail) =
      $self->SUPER::unpack('nnN a*', $self->raw)
         or return;

   $self->type($type);
   $self->length($length);
   $self->numAddresses($numAddresses);

   my $valLen = $length - 8; # 4 + TLValue(4) then addresses array
   my ($addresses, $payload) = 
      $self->SUPER::unpack("a$valLen a*", $tail)
         or return;

   $self->_unpackAddresses($addresses);

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $length = 8;
   $length += $_->getLength for $self->addresses;
   $self->length($length);

   # Calculate numAddresses from addresses array items
   if (scalar($self->addresses) && ($self->numAddresses == 0)) {
      $self->numAddresses(scalar($self->addresses))
   }

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%04x  length:%d  numAddresses:%d",
         $self->type, $self->length, $self->numAddresses;

   for ($self->addresses) {
      $buf .=  "\n" . $_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::CDP::ManagementAddresses - CDP ManagementAddresses TLV

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::CDP qw(:consts);

   my $layer = Net::Frame::Layer::CDP::ManagementAddresses->new(
      type         => NF_CDP_TYPE_MANAGEMENT_ADDR
      length       => 8,
      numAddresses => 0,
      addresses    => [],
   );

   #
   # Read a raw layer
   #
   my $layer = Net::Frame::Layer::CDP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ManagementAddresses CDP message type.

=head1 ATTRIBUTES

=over 4

=item B<type>

Type.

=item B<length>

Length of TLV option.

=item B<numAddresses>

Number of address records to follow.

=item B<addresses>

Array of B<Net::Frame::Layer::CDP::Address> objects.

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

L<Net::Frame::Layer::CDP::Address>, L<Net::Frame::Layer::CDP>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
