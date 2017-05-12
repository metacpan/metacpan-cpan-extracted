#
# $Id: UDP.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::UDP;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

use Net::Packet::Utils qw(inetChecksum getRandomHighPort inetAton inet6Aton);
use Net::Packet::Consts qw(:udp :layer);

our @AS = qw(
   src
   dst
   length
   checksum
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   shift->SUPER::new(
      src      => getRandomHighPort(),
      dst      => 0,
      length   => 0,
      checksum => 0,
      @_,
   );
}

sub recv {
   my $self = shift;
   my ($frame) = @_;

   my $env = $frame->env;

   for ($env->dump->framesFor($frame)) {
      return $_ if $_->timestamp ge $frame->timestamp;
   }

   my $l2Key = ($frame->l2 && $frame->l2->getKeyReverse($frame))  || 'all';
   my $l3Key = ($frame->l3 && $frame->l3->is.':'.$frame->l3->src) || 'all';
   my $l4Key = ($frame->l4 && 'ICMP')                             || 'all';

   my $href = $env->dump->framesSorted;
   for (@{$href->{$l2Key}{$l3Key}{$l4Key}}) {
      if (($_->timestamp ge $frame->timestamp)
      &&   $_->l4->error
      &&  ($_->l4->error->l4->src == $self->src)
      &&  ($_->l4->error->l4->dst == $self->dst)) {
         return $_;
      }
   }

   undef;
}

sub pack {
   my $self = shift;

   $self->[$__raw] = $self->SUPER::pack('nnnn',
      $self->[$__src],
      $self->[$__dst],
      $self->[$__length],
      $self->[$__checksum],
   ) or return undef;

   1;
}

sub unpack {
   my $self = shift;

   my ($src, $dst, $len, $checksum, $payload) =
      $self->SUPER::unpack('nnnn a*', $self->[$__raw])
         or return undef;

   $self->[$__src]      = $src;
   $self->[$__dst]      = $dst;
   $self->[$__length]   = $len;
   $self->[$__checksum] = $checksum;
   $self->[$__payload]  = $payload;

   1;
}

sub getLength { NP_UDP_HDR_LEN }

sub getPayloadLength {
   my $self = shift;
   my $len  = $self->[$__length];
   my $gLen = $self->getLength;
   ($len > $gLen) ? do { $len - $gLen } : 0;
}

sub _computeTotalLength {
   my $self = shift;
   my ($l7) = @_;

   my $totalLength = $self->getLength;
   $totalLength += $l7->getLength if $l7;
   $self->[$__length] = $totalLength;
}

sub computeLengths {
   my $self = shift;
   my ($env, $l2, $l3, $l4, $l7) = @_;

   $self->_computeTotalLength($l7);
   1;
}

sub computeChecksums {
   my $self = shift;
   my ($env, $l2, $l3, $l4, $l7) = @_;

   my $phpkt;
   if ($l3) {
      if ($l3->isIpv4) {
         $phpkt = $self->SUPER::pack('a4a4CCn',
            inetAton($l3->src),
            inetAton($l3->dst),
            0,
            $l3->protocol,
            $self->[$__length],
         ) or return undef;
      }
      elsif ($l3->isIpv6) {
         $phpkt = $self->SUPER::pack('a*a*NnCC',
            inet6Aton($l3->src),
            inet6Aton($l3->dst),
            $l3->payloadLength,
            0,
            0,
            $l3->nextHeader,
         ) or return undef;
      }
   }
   else {
      my $totalLength = $self->getLength;
      $totalLength += $l7->getLength if $l7;

      if ($env->desc->isFamilyIpv4) {
         $phpkt = $self->SUPER::pack('a4a4CCn',
            inetAton($env->ip),
            inetAton($env->desc->target),
            0,
            $env->desc->protocol,
            $totalLength,
         ) or return undef;
      }
      elsif ($env->desc->isFamilyIpv6) {
         $phpkt = $self->SUPER::pack('a*a*NnCC',
            inet6Aton($env->ip6),
            inet6Aton($env->desc->target),
            $totalLength,
            0,
            0,
            $env->desc->protocol,
         ) or return undef;
      }
   }

   # Reset the checksum if already filled by a previous pack
   $self->[$__checksum] = 0;

   $phpkt .= $self->SUPER::pack('nnnn',
      $self->[$__src],
      $self->[$__dst],
      $self->[$__length],
      $self->[$__checksum],
   ) or return undef;

   if ($l7 && $l7->data) {
      $phpkt .= $self->SUPER::pack('a*', $l7->data)
         or return undef;
   }

   $self->[$__checksum] = inetChecksum($phpkt);

   1;
}

sub encapsulate { shift->[$__payload] ? NP_LAYER_7 : NP_LAYER_NONE }

sub getKey {
   my $self = shift;
   $self->is.':'.$self->[$__src].'-'.$self->[$__dst];
}

sub getKeyReverse {
   my $self = shift;
   $self->is.':'.$self->[$__dst].'-'.$self->[$__src];
}

sub print {
   my $self = shift;

   my $i = $self->is;
   my $l = $self->layer;
   sprintf
      "$l:+$i: src:%d  dst:%d  length:%d  checksum:0x%02x",
         $self->[$__src], $self->[$__dst], $self->[$__length],
         $self->[$__checksum];
}

1;

__END__

=head1 NAME

Net::Packet::UDP - User Datagram Protocol layer 4 object

=head1 SYNOPSIS

   use Net::Packet::Consts qw(:udp);
   require Net::Packet::UDP;

   # Build a layer
   my $layer = Net::Packet::UDP->new(
      dst => 31222,
   );
   $layer->pack;

   print 'RAW: '.unpack('H*', $layer->raw)."\n";

   # Read a raw layer
   my $layer = Net::Packet::UDP->new(raw = $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the UDP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc768.txt

See also B<Net::Packet::Layer> and B<Net::Packet::Layer4> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<src>

=item B<dst>

Source and destination ports.

=item B<length>

The length in bytes of the datagram, including layer 7 payload (that is, layer 4 + layer 7).

=item B<checksum>

Checksum of the datagram.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You can pass attributes that will overwrite default ones. Default values:

src:      getRandomHighPort()

dst:      0

length:   0

checksum: 0

=item B<recv>

Will search for a matching replies in B<framesSorted> or B<frames> from a B<Net::Packet::Dump> object.

=item B<pack>

Packs all attributes into a raw format, in order to inject to network. Returns 1 on success, undef otherwise.

=item B<unpack>

Unpacks raw data from network and stores attributes into the object. Returns 1 on success, undef otherwise.

=item B<getPayloadLength>

Returns the length in bytes of payload (layer 7 object).

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
