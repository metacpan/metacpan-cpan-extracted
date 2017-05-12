#
# $Id: TypePortId.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::CDP::TypePortId;
use strict;
use warnings;

require Net::Packet::CDP::Type;
our @ISA = qw(Net::Packet::CDP::Type);

use Net::Packet::Consts qw(:cdp);

our @AS = qw(
   sentThrough
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      type        => NP_CDP_TYPE_PORT_ID,
      length      => 8,
      sentThrough => '1/4',
      @_,
   );
}

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nnH*',
      $self->type,
      $self->length,
      CORE::unpack('H*', $self->sentThrough),
   )) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($type, $length, $tail) = $self->SUPER::unpack('nna*', $self->raw)
      or return undef;

   $self->type($type);
   $self->length($length);

   my $sentThroughLen = ($length - 4) * 2;

   my ($sentThrough, $payload) =
      $self->SUPER::unpack("H$sentThroughLen a*", $tail)
         or return undef;

   $self->type($type);
   $self->length($length);
   $self->sentThrough(CORE::pack('H*', $sentThrough));

   $self->payload($payload);

   1;
}

sub print {
   my $self = shift;

   my $i = $self->is;
   my $l = $self->layer;
   sprintf "$l: $i: type:0x%04x  length:%d  sentThrough:%s",
      $self->type, $self->length, $self->sentThrough;
}

1;

__END__

=head1 NAME

Net::Packet::CDP::TypePortId - Cisco Discovery Protocol Port ID extension header

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:cdp);
   require Net::Packet::CDP::TypePortId;

   # Build a layer
   my $layer = Net::Packet::CDP::TypePortId->new(
      type        => NP_CDP_TYPE_PORT_ID,
      length      => 8,
      sentThrough => '1/4',
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::CDP::TypePortId->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Cisco Discovery Protocol Port ID type extension header.

=head1 ATTRIBUTES

=over 4

=item B<type> - 16 bits

=item B<length> - 16 bits

=item B<sentThrough> - variable length

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

type:        NP_CDP_TYPE_PORT_ID

length:      8

sentThrough: '1/4'

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
