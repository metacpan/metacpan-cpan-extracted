#
# $Id: Lsa.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::Lsa;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   lsAge
   options
   lsType
   linkStateId
   advertisingRouter
   lsSequenceNumber
   lsChecksum
   length
   lsa
   full
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::OSPF qw(:consts);
require Net::Frame::Layer::OSPF::Lsa::Opaque;
require Net::Frame::Layer::OSPF::Lsa::Router;
require Net::Frame::Layer::OSPF::Lsa::Network;
require Net::Frame::Layer::OSPF::Lsa::SummaryIp;

sub new {
   shift->SUPER::new(
      lsAge             => 30,
      options           => 0,
      lsType            => NF_OSPF_LSTYPE_ROUTER,
      linkStateId       => '0.0.0.0',
      advertisingRouter => '0.0.0.0',
      lsSequenceNumber  => 0,
      lsChecksum        => 0,
      length            => NF_OSPF_LSA_HDR_LEN,
      full              => 1,
      @_,
   );
}

# Lsa begins with standard 20 bytes header
sub getLength {
   my $self = shift;
   my $len = NF_OSPF_LSA_HDR_LEN;
   $len += $self->lsa->getLength if $self->lsa;
   $len;
}

sub computeLengths {
   my $self = shift;
   my $len = $self->getLength;
   $self->length($len);
}

sub computeChecksums {
   my $self = shift;

   $self->lsChecksum(0);
   my $raw   = $self->pack;
   my $data  = substr($raw, 2);
   # We pad the data to the possibly fake length
   my @chars = unpack('C*', $data.("0"x($self->length - length($data))));

   my $c0     = 0;
   my $c1     = 0;
   my $length = $self->length - 2;
   my $MODX   = 4102;
   my ($sp, $ep, $p, $q);
   $sp = 0;
   for ($ep = $length; $sp < $ep; $sp = $q) {
      $q = $sp + $MODX;
      if ($q > $ep) {
         $q = $ep;
      }
      for ($p = $sp; $p < $q; $p++) {
         $c0 += $chars[$p];
         $c1 += $c0;
      }
      $c0 %= 255;
      $c1 %= 255;
   }
   my $x = (($length - 15) * $c0 - $c1) % 255;
   if ($x <= 0) {
      $x += 255;
   }
   my $y = 510 - $c0 - $x;
   if ($y > 255) {
      $y -= 255;
   }

   $self->lsChecksum(($x << 8) + $y);
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('nCCa4a4Nnn a*',
      $self->lsAge, $self->options, $self->lsType, inetAton($self->linkStateId),
      inetAton($self->advertisingRouter), $self->lsSequenceNumber,
      $self->lsChecksum, $self->length,
   ) or return undef;

   $raw .= $self->lsa->pack if $self->lsa;

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($lsAge, $options, $lsType, $linkStateId, $advertisingRouter,
       $lsSequenceNumber, $lsChecksum, $length, $payload)
          = $self->SUPER::unpack('nCCa4a4Nnn a*', $self->raw)
             or return undef;

   $self->lsAge($lsAge);
   $self->options($options);
   $self->lsType($lsType);
   $self->linkStateId(inetNtoa($linkStateId));
   $self->advertisingRouter(inetNtoa($advertisingRouter));
   $self->lsSequenceNumber($lsSequenceNumber);
   $self->lsChecksum($lsChecksum);
   $self->length($length);

   my $next;
   if ($self->full && $payload) {
      if ($lsType == NF_OSPF_LSTYPE_OPAQUELINKLOCAL
      ||  $lsType == NF_OSPF_LSTYPE_OPAQUEAREALOCAL
      ||  $lsType == NF_OSPF_LSTYPE_OPAQUEDOMAIN) {
         my $pLen = length($payload);
         if ($length > $pLen) {
            my $oLen   = $length - NF_OSPF_LSA_HDR_LEN;
            my $opaque = substr($payload, 0, $oLen);
            $next = Net::Frame::Layer::OSPF::Lsa::Opaque->new(raw => $opaque);
            $payload = substr($payload, $oLen);
            $next->payload($payload);
         }
      }
      elsif ($lsType == NF_OSPF_LSTYPE_ROUTER) {
         $next = Net::Frame::Layer::OSPF::Lsa::Router->new(raw => $payload);
      }
      elsif ($lsType == NF_OSPF_LSTYPE_NETWORK) {
         $next = Net::Frame::Layer::OSPF::Lsa::Network->new(raw => $payload);
      }
      elsif ($lsType == NF_OSPF_LSTYPE_SUMMARYIP) {
         $next = Net::Frame::Layer::OSPF::Lsa::SummaryIp->new(raw => $payload);
      }
   }

   if ($next) {
      $next->unpack;
      $self->lsa($next);
      $payload = $next->payload;
   }

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: lsAge:%d  options:0x%02x  lsType:0x%02x  linkStateId:%s\n".
      "$l: advertisingRouter:%s  lsSequenceNumber:0x%08x\n".
      "$l: lsChecksum:0x%04x  length:%d",
         $self->lsAge,
         $self->options,
         $self->lsType,
         $self->linkStateId,
         $self->advertisingRouter,
         $self->lsSequenceNumber,
         $self->lsChecksum,
         $self->length,
   ;

   if ($self->lsa) {
      $buf .= "\n".$self->lsa->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::Lsa - OSPF Lsa type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF qw(:consts);
   use Net::Frame::Layer::OSPF::Lsa;
   use Net::Frame::Layer::OSPF::Lsa::Router;

   # Build a LSA-Router
   my $lsa = Net::Frame::Layer::OSPF::Lsa->new(
      lsAge             => 30,
      options           => 0,
      lsType            => NF_OSPF_LSTYPE_ROUTER,
      linkStateId       => '0.0.0.0',
      advertisingRouter => '0.0.0.0',
      lsSequenceNumber  => 0,
      lsChecksum        => 0,
      length            => NF_OSPF_LSA_HDR_LEN,
      full              => 1,
   );
   my $router = Net::Frame::Layer::OSPF::Lsa::Router->new(
      flags    => 0,
      zero     => 0,
      nLink    => 1,
      linkId   => $ip,
      linkData => $netmask,
      type     => 0x03,
      nTos     => 0,
      metric   => 10,
   );
   $lsa->lsa($router);
   $lsa->computeLengths;
   $lsa->computeChecksums;
   print $lsa->print."\n";

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF Lsa object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<lsAge>

=item B<options>

=item B<lsType>

=item B<linkStateId>

=item B<advertisingRouter>

=item B<lsSequenceNumber>

=item B<lsChecksum>

=item B<length>

=item B<lsa>

=item B<full>

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

L<Net::Frame::Layer::OSPF>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
