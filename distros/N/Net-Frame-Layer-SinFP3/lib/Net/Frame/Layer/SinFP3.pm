#
# $Id: SinFP3.pm 9 2012-11-22 19:13:54Z gomor $
#
package Net::Frame::Layer::SinFP3;
use strict;
use warnings;

our $VERSION = '1.01';

use base qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_SINFP3_VERSION1
      NF_SINFP3_FLAG_FULL
      NF_SINFP3_FLAG_TRUSTED
      NF_SINFP3_FLAG_IPVERSION
      NF_SINFP3_FLAG_SYSTEMCLASS
      NF_SINFP3_FLAG_VENDOR
      NF_SINFP3_FLAG_OS
      NF_SINFP3_FLAG_OSVERSION
      NF_SINFP3_FLAG_OSVERSIONFAMILY
      NF_SINFP3_FLAG_MATCHTYPE
      NF_SINFP3_FLAG_MATCHMASK
      NF_SINFP3_FLAG_MATCHSCORE
      NF_SINFP3_FLAG_P1SIG
      NF_SINFP3_FLAG_P2SIG
      NF_SINFP3_FLAG_P3SIG
      NF_SINFP3_TYPE_REQUESTACTIVE
      NF_SINFP3_TYPE_REQUESTPASSIVE
      NF_SINFP3_TYPE_RESPONSEACTIVE
      NF_SINFP3_TYPE_RESPONSEPASSIVE
      NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL
      NF_SINFP3_TLV_TYPE_FRAMEPASSIVE
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1R
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2R
      NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3R
      NF_SINFP3_TLV_TYPE_TRUSTED
      NF_SINFP3_TLV_TYPE_IPVERSION
      NF_SINFP3_TLV_TYPE_SYSTEMCLASS
      NF_SINFP3_TLV_TYPE_VENDOR
      NF_SINFP3_TLV_TYPE_OS
      NF_SINFP3_TLV_TYPE_OSVERSION
      NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY
      NF_SINFP3_TLV_TYPE_MATCHTYPE
      NF_SINFP3_TLV_TYPE_MATCHMASK
      NF_SINFP3_TLV_TYPE_MATCHSCORE
      NF_SINFP3_TLV_TYPE_P1SIG
      NF_SINFP3_TLV_TYPE_P2SIG
      NF_SINFP3_TLV_TYPE_P3SIG
      NF_SINFP3_TLV_VALUE_ETH
      NF_SINFP3_TLV_VALUE_IPv4
      NF_SINFP3_TLV_VALUE_IPv6
      NF_SINFP3_TLV_VALUE_TCP
      NF_SINFP3_CODE_SUCCESSUNKNOWN
      NF_SINFP3_CODE_SUCCESSRESULT
      NF_SINFP3_CODE_BADVERSION
      NF_SINFP3_CODE_BADTYPE
      NF_SINFP3_CODE_BADTLVCOUNT
      NF_SINFP3_CODE_BADTLV
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_SINFP3_VERSION1 => 0x01;

use constant NF_SINFP3_FLAG_FULL            => 0x0000;
use constant NF_SINFP3_FLAG_TRUSTED         => 0x0001;
use constant NF_SINFP3_FLAG_IPVERSION       => 0x0002;
use constant NF_SINFP3_FLAG_SYSTEMCLASS     => 0x0004;
use constant NF_SINFP3_FLAG_VENDOR          => 0x0008;
use constant NF_SINFP3_FLAG_OS              => 0x0010;
use constant NF_SINFP3_FLAG_OSVERSION       => 0x0020;
use constant NF_SINFP3_FLAG_OSVERSIONFAMILY => 0x0040;
use constant NF_SINFP3_FLAG_MATCHTYPE       => 0x0080;
use constant NF_SINFP3_FLAG_MATCHMASK       => 0x0100;
use constant NF_SINFP3_FLAG_MATCHSCORE      => 0x0200;
use constant NF_SINFP3_FLAG_P1SIG           => 0x0400;
use constant NF_SINFP3_FLAG_P2SIG           => 0x0800;
use constant NF_SINFP3_FLAG_P3SIG           => 0x1000;

use constant NF_SINFP3_TYPE_REQUESTACTIVE   => 0x01;
use constant NF_SINFP3_TYPE_REQUESTPASSIVE  => 0x02;
use constant NF_SINFP3_TYPE_RESPONSEACTIVE  => 0x03;
use constant NF_SINFP3_TYPE_RESPONSEPASSIVE => 0x04;

use constant NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL  => 0x01;
use constant NF_SINFP3_TLV_TYPE_FRAMEPASSIVE   => 0x02;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1  => 0x03;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2  => 0x04;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3  => 0x05;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1R => 0x06;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2R => 0x07;
use constant NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3R => 0x08;
use constant NF_SINFP3_TLV_TYPE_P1SIG          => 0x09;
use constant NF_SINFP3_TLV_TYPE_P2SIG          => 0x0a;
use constant NF_SINFP3_TLV_TYPE_P3SIG          => 0x0b;

use constant NF_SINFP3_TLV_VALUE_ETH  => 0x01;
use constant NF_SINFP3_TLV_VALUE_IPv4 => 0x02;
use constant NF_SINFP3_TLV_VALUE_IPv6 => 0x03;
use constant NF_SINFP3_TLV_VALUE_TCP  => 0x04;

use constant NF_SINFP3_TLV_TYPE_TRUSTED         => 0x20;
use constant NF_SINFP3_TLV_TYPE_IPVERSION       => 0x21;
use constant NF_SINFP3_TLV_TYPE_SYSTEMCLASS     => 0x22;
use constant NF_SINFP3_TLV_TYPE_VENDOR          => 0x23;
use constant NF_SINFP3_TLV_TYPE_OS              => 0x24;
use constant NF_SINFP3_TLV_TYPE_OSVERSION       => 0x25;
use constant NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY => 0x26;
use constant NF_SINFP3_TLV_TYPE_MATCHTYPE       => 0x27;
use constant NF_SINFP3_TLV_TYPE_MATCHMASK       => 0x28;
use constant NF_SINFP3_TLV_TYPE_MATCHSCORE      => 0x29;

use constant NF_SINFP3_CODE_SUCCESSUNKNOWN => 0x00;
use constant NF_SINFP3_CODE_SUCCESSRESULT  => 0x01;
use constant NF_SINFP3_CODE_BADVERSION     => 0x02;
use constant NF_SINFP3_CODE_BADTYPE        => 0x03;
use constant NF_SINFP3_CODE_BADTLVCOUNT    => 0x04;
use constant NF_SINFP3_CODE_BADTLV         => 0x05;

our @AS = qw(
   version
   type
   flags
   code
   tlvCount
   length
);
our @AA = qw(
   tlvList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::SinFP3::Tlv;

sub new {
   my $self = shift->SUPER::new(
      version  => NF_SINFP3_VERSION1,
      type     => NF_SINFP3_TYPE_RESPONSEPASSIVE,
      flags    => NF_SINFP3_FLAG_FULL,
      code     => NF_SINFP3_CODE_SUCCESSRESULT,
      tlvCount => 0,
      length   => 0,
      tlvList  => [],
      @_,
   );

   return $self;
}

sub getLength {
   my $self = shift;

   my $len = 8; # 8-byte header

   for my $tlv ($self->tlvList) {
      $len += $tlv->getLength;
   }

   return $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCnCCn',
      $self->version,
      $self->type,
      $self->flags,
      $self->code,
      $self->tlvCount,
      $self->length,
   ) or return;

   for my $tlv ($self->tlvList) {
      $raw .= $tlv->pack or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($version, $type, $flags, $code, $tlvCount, $length, $payload) =
      $self->SUPER::unpack('CCnCCn a*', $self->raw)
         or return;

   $self->version($version);
   $self->type($type);
   $self->flags($flags);
   $self->code($code);
   $self->tlvCount($tlvCount);
   $self->length($length);

   if (defined($payload) && length($payload) >= $length) {
      my $tlv  = substr($payload, 0, $length);
      $payload = substr($payload, $length);
      my @tlvList = ();
      while (defined($tlv) && length($tlv)) {
         my $new = Net::Frame::Layer::SinFP3::Tlv->new(
            raw => $tlv,
         )->unpack;
         $tlv = $new->payload;
         $new->payload(undef);
         push @tlvList, $new;
      }
      $self->tlvList(\@tlvList);
   }

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $tlvCount = 0;
   # Request types, tlvCount is the total number of TLVs
   if ($self->type == NF_SINFP3_TYPE_REQUESTACTIVE
   ||  $self->type == NF_SINFP3_TYPE_REQUESTPASSIVE) {
      $tlvCount = scalar($self->tlvList);
   }
   # Response types, tlvCount is the number of TLV per result
   elsif ($self->type == NF_SINFP3_TYPE_RESPONSEACTIVE
      || $self->type == NF_SINFP3_TYPE_RESPONSEPASSIVE) {
      if ($self->type == NF_SINFP3_TYPE_RESPONSEACTIVE && $self->flags == NF_SINFP3_FLAG_FULL) {
         $tlvCount = 13;
      }
      elsif ($self->type == NF_SINFP3_TYPE_RESPONSEPASSIVE && $self->flags == NF_SINFP3_FLAG_FULL) {
         $tlvCount = 11;
      }
      else {
         for my $flag (
            NF_SINFP3_FLAG_TRUSTED,
            NF_SINFP3_FLAG_IPVERSION,
            NF_SINFP3_FLAG_SYSTEMCLASS,
            NF_SINFP3_FLAG_VENDOR,
            NF_SINFP3_FLAG_OS,
            NF_SINFP3_FLAG_OSVERSION,
            NF_SINFP3_FLAG_OSVERSIONFAMILY,
            NF_SINFP3_FLAG_MATCHTYPE,
            NF_SINFP3_FLAG_MATCHMASK,
            NF_SINFP3_FLAG_MATCHSCORE,
            NF_SINFP3_FLAG_P1SIG,
            NF_SINFP3_FLAG_P2SIG,
            NF_SINFP3_FLAG_P3SIG,
         ) {
            if ($self->flags & $flag) {
               $tlvCount++;
            }
         }
      }
   }
   $self->tlvCount($tlvCount);

   my $len = 0;
   for my $tlv ($self->tlvList) {
      $tlv->computeLengths;
      $len += $tlv->getLength;
   }
   $self->length($len);

   return 1;
}

sub print {
   my $self = shift;

   my $l   = $self->layer;
   my $buf = sprintf("$l: version:%d  type:0x%02x  flags:0x%04x\n".
                     "$l: code:0x%02x  tlvCount:%d  length:%d",
      $self->version,
      $self->type,
      $self->flags,
      $self->code,
      $self->tlvCount,
      $self->length,
   );

   for my $tlv ($self->tlvList) {
      $buf .= "\n".$tlv->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::SinFP3 - SinFP3 communication protocol

=head1 SYNOPSIS

   use Net::Frame::Layer::SinFP3 qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::SinFP3->new(
      version  => NF_SINFP3_VERSION1,
      type     => NF_SINFP3_TYPE_RESPONSEPASSIVE,
      flags    => NF_SINFP3_FLAG_FULL,
      code     => NF_SINFP3_CODE_SUCCESSRESULT,
      tlvCount => 0,
      length   => 0,
      tlvList  => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::SinFP3->new(raw => $raw);
   $layer->unpack;

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the SinFP3 protocol.

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

Load them: use Net::Frame::Layer::SinFP3 qw(:consts);

=over 4

=item B<NF_SINFP3_VERSION1>

=item B<NF_SINFP3_FLAG_FULL>

=item B<NF_SINFP3_FLAG_TRUSTED>

=item B<NF_SINFP3_FLAG_IPVERSION>

=item B<NF_SINFP3_FLAG_SYSTEMCLASS>

=item B<NF_SINFP3_FLAG_VENDOR>

=item B<NF_SINFP3_FLAG_OS>

=item B<NF_SINFP3_FLAG_OSVERSION>

=item B<NF_SINFP3_FLAG_OSVERSIONFAMILY>

=item B<NF_SINFP3_FLAG_MATCHTYPE>

=item B<NF_SINFP3_FLAG_MATCHMASK>

=item B<NF_SINFP3_FLAG_MATCHSCORE>

=item B<NF_SINFP3_FLAG_P1SIG>

=item B<NF_SINFP3_FLAG_P2SIG>

=item B<NF_SINFP3_FLAG_P3SIG>

=item B<NF_SINFP3_TYPE_REQUESTACTIVE>

=item B<NF_SINFP3_TYPE_REQUESTPASSIVE>

=item B<NF_SINFP3_TYPE_RESPONSEACTIVE>

=item B<NF_SINFP3_TYPE_RESPONSEPASSIVE>

=item B<NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL>

=item B<NF_SINFP3_TLV_TYPE_FRAMEPASSIVE>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP1R>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP2R>

=item B<NF_SINFP3_TLV_TYPE_FRAMEACTIVEP3R>

=item B<NF_SINFP3_TLV_TYPE_TRUSTED>

=item B<NF_SINFP3_TLV_TYPE_IPVERSION>

=item B<NF_SINFP3_TLV_TYPE_SYSTEMCLASS>

=item B<NF_SINFP3_TLV_TYPE_VENDOR>

=item B<NF_SINFP3_TLV_TYPE_OS>

=item B<NF_SINFP3_TLV_TYPE_OSVERSION>

=item B<NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY>

=item B<NF_SINFP3_TLV_TYPE_MATCHTYPE>

=item B<NF_SINFP3_TLV_TYPE_MATCHMASK>

=item B<NF_SINFP3_TLV_TYPE_MATCHSCORE>

=item B<NF_SINFP3_TLV_TYPE_P1SIG>

=item B<NF_SINFP3_TLV_TYPE_P2SIG>

=item B<NF_SINFP3_TLV_TYPE_P3SIG>

=item B<NF_SINFP3_TLV_VALUE_ETH>

=item B<NF_SINFP3_TLV_VALUE_IPv4>

=item B<NF_SINFP3_TLV_VALUE_IPv6>

=item B<NF_SINFP3_TLV_VALUE_TCP>

=item B<NF_SINFP3_CODE_SUCCESSUNKNOWN>

=item B<NF_SINFP3_CODE_SUCCESSRESULT>

=item B<NF_SINFP3_CODE_BADVERSION>

=item B<NF_SINFP3_CODE_BADTYPE>

=item B<NF_SINFP3_CODE_BADTLVCOUNT>

=item B<NF_SINFP3_CODE_BADTLV>

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
