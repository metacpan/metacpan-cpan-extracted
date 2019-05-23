#
# $Id: TCP.pm,v ce68fbcc7f6d 2019/05/23 05:58:40 gomor $
#
package Net::Frame::Layer::TCP;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_TCP_HDR_LEN
      NF_TCP_FLAGS_FIN
      NF_TCP_FLAGS_SYN
      NF_TCP_FLAGS_RST
      NF_TCP_FLAGS_PSH
      NF_TCP_FLAGS_ACK
      NF_TCP_FLAGS_URG
      NF_TCP_FLAGS_ECE
      NF_TCP_FLAGS_CWR
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_TCP_HDR_LEN  => 20;
use constant NF_TCP_FLAGS_FIN => 0x01;
use constant NF_TCP_FLAGS_SYN => 0x02;
use constant NF_TCP_FLAGS_RST => 0x04;
use constant NF_TCP_FLAGS_PSH => 0x08;
use constant NF_TCP_FLAGS_ACK => 0x10;
use constant NF_TCP_FLAGS_URG => 0x20;
use constant NF_TCP_FLAGS_ECE => 0x40;
use constant NF_TCP_FLAGS_CWR => 0x80;

our @AS = qw(
   src
   dst
   flags
   win
   seq
   ack
   off
   x2
   checksum
   urp
   options
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub new {
   my $self = shift->SUPER::new(
      src      => getRandomHighPort(),
      dst      => 0,
      seq      => getRandom32bitsInt(),
      ack      => 0,
      x2       => 0,
      off      => 0,
      flags    => NF_TCP_FLAGS_SYN,
      win      => 0xffff,
      checksum => 0,
      urp      => 0,
      options  => '',
      @_,
   );

   return $self;
}

sub pack {
   my $self = shift;

   my $offX2Flags = ($self->[$__off] << 12)|(0x0f00 & ($self->[$__x2] << 8))
      |(0x00ff & $self->[$__flags]);

   $self->[$__raw] = $self->SUPER::pack('nnNNnnnn',
      $self->[$__src],
      $self->[$__dst],
      $self->[$__seq],
      $self->[$__ack],
      $offX2Flags,
      $self->[$__win],
      $self->[$__checksum],
      $self->[$__urp],
   ) or return;

   if ($self->[$__options]) {
      $self->[$__raw] =
         $self->[$__raw].$self->SUPER::pack('a*', $self->[$__options])
            or return;
   }

   return $self->[$__raw];
}

sub unpack {
   my $self = shift;

   # Pad it if less than the required length
   if (length($self->[$__raw]) < NF_TCP_HDR_LEN) {
      $self->[$__raw] .= ("\x00" x (NF_TCP_HDR_LEN - length($self->[$__raw])));
   }

   my ($src, $dst, $seq, $ack, $offX2Flags, $win, $checksum, $urp, $payload) =
      $self->SUPER::unpack('nnNNnnnn a*', $self->[$__raw])
         or return;

   $self->[$__src]      = $src;
   $self->[$__dst]      = $dst;
   $self->[$__seq]      = $seq;
   $self->[$__ack]      = $ack;
   $self->[$__off]      = ($offX2Flags & 0xf000) >> 12;
   $self->[$__x2]       = ($offX2Flags & 0x0f00) >> 8;
   $self->[$__flags]    = $offX2Flags & 0x00ff;
   $self->[$__win]      = $win;
   $self->[$__checksum] = $checksum;
   $self->[$__urp]      = $urp;
   $self->[$__payload]  = $payload;

   my ($options, $payload2) = $self->SUPER::unpack(
      'a'. $self->getOptionsLength. 'a*', $self->[$__payload]
   ) or return;

   $self->[$__options] = $options;
   $self->[$__payload] = $payload2;

   return $self;
}

sub getLength { my $self = shift; $self->[$__off] ? $self->[$__off] * 4 : 0 }

sub getOptionsLength {
   my $self = shift;
   my $gLen = $self->getLength;
   my $hLen = NF_TCP_HDR_LEN;
   return $gLen > $hLen ? $gLen - $hLen : 0;
}

sub computeLengths {
   my $self = shift;

   my $optLen = ($self->[$__options] && length($self->[$__options])) || 0;

   my $hLen = NF_TCP_HDR_LEN;
   $self->[$__off] = ($hLen + $optLen) / 4;

   return 1;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $len = $self->getLength;

   my $start   = 0;
   my $last    = $self;
   my $payload = '';
   for my $l (@$layers) {
      $last = $l;
      if (! $start) {
         $start++ if $l->layer eq 'TCP';
         next;
      }
      $len     += $l->getLength;
      $payload .= $l->pack;
   }

   if (defined($last->payload) && length($last->payload)) {
      $len     += length($last->payload);
      $payload .= $last->payload;
   }

   my $phpkt;
   for my $l (@$layers) {
      if ($l->layer eq 'IPv4') {
         $phpkt = $self->SUPER::pack('a4a4CCn',
            inetAton($l->src), inetAton($l->dst), 0, 6, $len);
      }
      elsif ($l->layer eq 'IPv6') {
         $phpkt = $self->SUPER::pack('a*a*NnCC',
            inet6Aton($l->src), inet6Aton($l->dst), $len, 0, 0, 6);
      }
   }

   my $offX2Flags = ($self->[$__off] << 12) | (0x0f00 & ($self->[$__x2] << 8))
                  | (0x00ff & $self->[$__flags]);

   $phpkt .= $self->SUPER::pack('nnNNnnnn',
      $self->[$__src], $self->[$__dst], $self->[$__seq], $self->[$__ack],
      $offX2Flags, $self->[$__win], 0, $self->[$__urp],
   ) or return;

   if ($self->[$__options]) {
      $phpkt .= $self->SUPER::pack('a*', $self->[$__options])
         or return;
   }

   if (length($payload)) {
      $phpkt .= $self->SUPER::pack('a*', $payload)
         or return;
   }

   $self->[$__checksum] = inetChecksum($phpkt);

   return 1;
}

our $Next = {
};

sub encapsulate {
   my $self = shift;
   return $Next->{$self->[$__dst]} || $Next->{$self->[$__src]}
                                   || $self->[$__nextLayer];
}

sub match {
   my $self = shift;
   my ($with) = @_;
      ($with->[$__ack] == $self->[$__seq] + 1)
   || ($with->[$__flags] & NF_TCP_FLAGS_RST);
}

sub getKey {
   my $self = shift;
   $self->layer.':'.$self->[$__src].'-'.$self->[$__dst];
}

sub getKeyReverse {
   my $self = shift;
   $self->layer.':'.$self->[$__dst].'-'.$self->[$__src];
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: src:%d  dst:%d  seq:0x%04x  ack:0x%04x \n".
      "$l: off:0x%02x  x2:0x%01x  flags:0x%02x  win:%d  checksum:0x%04x  ".
      "urp:0x%02x",
         $self->[$__src], $self->[$__dst], $self->[$__seq], $self->[$__ack],
         $self->[$__off], $self->[$__x2], $self->[$__flags], $self->[$__win],
         $self->[$__checksum], $self->[$__urp];

   if ($self->[$__options]) {
      $buf .= sprintf("\n$l: optionsLength:%d  options:%s",
         $self->getOptionsLength,
         $self->SUPER::unpack('H*', $self->[$__options])
      ) or return undef;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::TCP - Transmission Control Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::TCP qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::TCP->new(
      src      => getRandomHighPort(),
      dst      => 0,
      seq      => getRandom32bitsInt(),
      ack      => 0,
      x2       => 0,
      off      => 0,
      flags    => NF_TCP_FLAGS_SYN,
      win      => 0xffff,
      checksum => 0,
      urp      => 0,
      options  => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::TCP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the TCP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc793.txt
      
See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<src>

=item B<dst>

Source and destination ports.

=item B<flags>

TCP flags, see CONSTANTS.

=item B<win>

The window size.

=item B<seq>

=item B<ack>

Sequence and acknowledgment numbers.

=item B<off>

The size in number of words of the TCP header.

=item B<x2>

Reserved field.

=item B<checksum>

The TCP header checksum.

=item B<urp>

Urgent pointer.

=item B<options>

TCP options, as a hexadecimal string.

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

=item B<getHeaderLength>

Returns the header length in bytes, not including TCP options.

=item B<getOptionsLength>

Returns options length in bytes.

=item B<computeLengths>

Computes various lengths contained within this layer.

=item B<computeChecksums> ({ type => PROTO, src => IP, dst => IP })

In order to compute checksums of TCP, you need to pass the protocol type (IPv4, IPv6), the source and destination IP addresses (IPv4 for IPv4, IPv6 for IPv6).

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::TCP object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::TCP> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::TCP qw(:consts);

=over 4

=item B<NF_TCP_FLAGS_FIN>

=item B<NF_TCP_FLAGS_SYN>

=item B<NF_TCP_FLAGS_RST>

=item B<NF_TCP_FLAGS_PSH>

=item B<NF_TCP_FLAGS_ACK>

=item B<NF_TCP_FLAGS_URG>

=item B<NF_TCP_FLAGS_ECE>

=item B<NF_TCP_FLAGS_CWR>

TCP flags constants.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
