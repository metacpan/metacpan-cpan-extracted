#
# $Id: ICMPv6.pm 45 2014-04-09 06:32:08Z gomor $
#
package Net::Frame::Layer::ICMPv6;
use strict; use warnings;

our $VERSION = '1.09';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_ICMPv6_CODE_ZERO
      NF_ICMPv6_TYPE_DESTUNREACH
      NF_ICMPv6_CODE_NOROUTE
      NF_ICMPv6_CODE_ADMINPROHIBITED
      NF_ICMPv6_CODE_NOTASSIGNED
      NF_ICMPv6_CODE_ADDRESSUNREACH
      NF_ICMPv6_CODE_PORTUNREACH
      NF_ICMPv6_CODE_FAILPOLICY
      NF_ICMPv6_CODE_REJECTROUTE
      NF_ICMPv6_TYPE_TOOBIG
      NF_ICMPv6_TYPE_TIMEEXCEED
      NF_ICMPv6_CODE_HOPLIMITEXCEED
      NF_ICMPv6_CODE_FRAGREASSEMBLYEXCEEDED
      NF_ICMPv6_TYPE_PARAMETERPROBLEM
      NF_ICMPv6_CODE_ERRONEOUSHERDERFIELD
      NF_ICMPv6_CODE_UNKNOWNNEXTHEADER
      NF_ICMPv6_CODE_UNKNOWNOPTION
      NF_ICMPv6_TYPE_ECHO_REQUEST
      NF_ICMPv6_TYPE_ECHO_REPLY
      NF_ICMPv6_TYPE_ROUTERSOLICITATION
      NF_ICMPv6_TYPE_ROUTERADVERTISEMENT
      NF_ICMPv6_TYPE_NEIGHBORSOLICITATION
      NF_ICMPv6_TYPE_NEIGHBORADVERTISEMENT
      NF_ICMPv6_OPTION_SOURCELINKLAYERADDRESS
      NF_ICMPv6_OPTION_TARGETLINKLAYERADDRESS
      NF_ICMPv6_OPTION_PREFIXINFORMATION
      NF_ICMPv6_OPTION_REDIRECTEDHEADER
      NF_ICMPv6_OPTION_MTU
      NF_ICMPv6_FLAG_ROUTER
      NF_ICMPv6_FLAG_SOLICITED
      NF_ICMPv6_FLAG_OVERRIDE
      NF_ICMPv6_FLAG_MANAGEDADDRESSCONFIGURATION
      NF_ICMPv6_FLAG_OTHERCONFIGURATION
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_ICMPv6_CODE_ZERO                    => 0;
use constant NF_ICMPv6_TYPE_DESTUNREACH             => 1;
use constant NF_ICMPv6_CODE_NOROUTE                 => 0;
use constant NF_ICMPv6_CODE_ADMINPROHIBITED         => 1;
use constant NF_ICMPv6_CODE_NOTASSIGNED             => 2;
use constant NF_ICMPv6_CODE_ADDRESSUNREACH          => 3;
use constant NF_ICMPv6_CODE_PORTUNREACH             => 4;
use constant NF_ICMPv6_CODE_FAILPOLICY              => 5;
use constant NF_ICMPv6_CODE_REJECTROUTE             => 6;
use constant NF_ICMPv6_TYPE_TOOBIG                  => 2;
use constant NF_ICMPv6_TYPE_TIMEEXCEED              => 3;
use constant NF_ICMPv6_CODE_HOPLIMITEXCEED          => 0;
use constant NF_ICMPv6_CODE_FRAGREASSEMBLYEXCEEDED  => 1;
use constant NF_ICMPv6_TYPE_PARAMETERPROBLEM        => 4;
use constant NF_ICMPv6_CODE_ERRONEOUSHERDERFIELD    => 0;
use constant NF_ICMPv6_CODE_UNKNOWNNEXTHEADER       => 1;
use constant NF_ICMPv6_CODE_UNKNOWNOPTION           => 2;
use constant NF_ICMPv6_TYPE_ECHO_REQUEST            => 128;
use constant NF_ICMPv6_TYPE_ECHO_REPLY              => 129;
use constant NF_ICMPv6_TYPE_ROUTERSOLICITATION      => 133;
use constant NF_ICMPv6_TYPE_ROUTERADVERTISEMENT     => 134;
use constant NF_ICMPv6_TYPE_NEIGHBORSOLICITATION    => 135;
use constant NF_ICMPv6_TYPE_NEIGHBORADVERTISEMENT   => 136;

use constant NF_ICMPv6_OPTION_SOURCELINKLAYERADDRESS => 0x01;
use constant NF_ICMPv6_OPTION_TARGETLINKLAYERADDRESS => 0x02;
use constant NF_ICMPv6_OPTION_PREFIXINFORMATION      => 0x03;
use constant NF_ICMPv6_OPTION_REDIRECTEDHEADER       => 0x04;
use constant NF_ICMPv6_OPTION_MTU                    => 0x05;

use constant NF_ICMPv6_FLAG_ROUTER    => 0x04;
use constant NF_ICMPv6_FLAG_SOLICITED => 0x02;
use constant NF_ICMPv6_FLAG_OVERRIDE  => 0x01;

use constant NF_ICMPv6_FLAG_MANAGEDADDRESSCONFIGURATION => 1 << 5;
use constant NF_ICMPv6_FLAG_OTHERCONFIGURATION          => 1 << 4;
use constant NF_ICMPv6_FLAG_MOBILEIPv6HOMEAGENT         => 1 << 3;
use constant NF_ICMPv6_FLAG_ROUTERSELECTIONPREFHIGH     => 1 << 1; # 01b
use constant NF_ICMPv6_FLAG_ROUTERSELECTIONPREFMEDIUM   => 0;      # 00b
use constant NF_ICMPv6_FLAG_ROUTERSELECTIONPREFLOW      => 3 << 1; # 11b
use constant NF_ICMPv6_FLAG_ROUTERSELECTIONPREFRESERVED => 2 << 1; # 10b
use constant NF_ICMPv6_FLAG_NEIGHBORDISCOVERYPROXY      => 1;

our @AS = qw(
   type
   code
   checksum
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Bit::Vector;

sub new {
   shift->SUPER::new(
      type     => NF_ICMPv6_TYPE_ECHO_REQUEST,
      code     => NF_ICMPv6_CODE_ZERO,
      checksum => 0,
      @_,
   );
}

# XXX: may be better, by keying on type also
sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

sub match {
   my $self = shift;
   my ($with) = @_;
   my $sType = $self->type;
   my $wType = $with->type;
   if ($sType eq NF_ICMPv6_TYPE_ECHO_REQUEST
   &&  $wType eq NF_ICMPv6_TYPE_ECHO_REPLY) {
      return 1;
   }
   elsif ($sType eq NF_ICMPv6_TYPE_NEIGHBORSOLICITATION
      &&  $wType eq NF_ICMPv6_TYPE_NEIGHBORADVERTISEMENT) {
      return 1;
   }
   elsif ($sType eq NF_ICMPv6_TYPE_ROUTERSOLICITATION
      &&  $wType eq NF_ICMPv6_TYPE_ROUTERADVERTISEMENT) {
      return 1;
   }
   return 0;
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCn',
      $self->type, $self->code, $self->checksum,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $code, $checksum, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   $self->type($type);
   $self->code($code);
   $self->checksum($checksum);
   $self->payload($payload);

   return $self;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $icmpType;
   my $ip;
   my $rh0;
   my $hbh; # Hop-by-hop Ext Hdr
   my $dst; # Destination Ext Hdr
   my $mob; # Mobility Ext Hdr
   my $lastNextHeader;
   my $fragmentFlag = 0;
   for my $l (@$layers) {
      if (! $icmpType && $l->layer =~ /ICMPv6::/)          { $icmpType = $l; }
      if (! $ip       && $l->layer eq 'IPv6')              { $ip       = $l; }
      if (! $rh0      && $l->layer eq 'IPv6::Routing')     { $rh0      = $l; }
      if (! $hbh      && $l->layer eq 'IPv6::HopByHop')    { $hbh      = $l; }
      if (! $dst      && $l->layer eq 'IPv6::Destination') { $dst      = $l; }
      if (! $mob      && $l->layer eq 'IPv6::Mobility')    { $mob      = $l; }

      if ($l->can('nextHeader')) { $lastNextHeader = $l->nextHeader; }

      if ($l->layer eq 'IPv6::Fragment') { $fragmentFlag = 1; }
   }

   my $lastIpDst       = $ip->dst;
   my $ipPayloadLength = $ip->payloadLength;
   # If RH0, need to set $ip->dst to last $rh0->addresses
   # unless segmentsLeft == 0 (RFC 2460 sec 8.1)
   if ($rh0 && $rh0->segmentsLeft != 0) {
      for ($rh0->addresses) {
         $lastIpDst = $_;
      }
      # Pseudo header length is upper layer minus any EH (RFC 2460 sec 8.1)
      $ipPayloadLength -= $rh0->getLength;
   }
   # Pseudo header length is upper layer minus any EH (RFC 2460 sec 8.1)
   if ($fragmentFlag) {
      $ipPayloadLength -= 8; # 8 = length of fragment EH
   }
   if ($hbh) {
      $ipPayloadLength -= $hbh->getLength;
   }
   if ($dst) {
      $ipPayloadLength -= $dst->getLength;
   }
   if ($mob) {
      $ipPayloadLength -= $mob->getLength;
   }

   # Build pseudo-header and pack ICMPv6 packet
   my $zero       = Bit::Vector->new_Dec(24, 0);
   my $nextHeader = Bit::Vector->new_Dec( 8, $lastNextHeader);
   my $v32        = $zero->Concat_List($nextHeader);

   my $packed = $self->SUPER::pack('a*a*NNCCna*',
      inet6Aton($ip->src), inet6Aton($lastIpDst), $ipPayloadLength,
      $v32->to_Dec, $self->type, $self->code, 0, $icmpType->pack,
   ) or return;

   my $payload = $layers->[-1]->payload || '';
   $self->checksum(inetChecksum($packed.$payload));

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      my $type = $self->type;
#     if ($type eq NF_ICMPv6_TYPE_REDIRECT) {
#        return 'IPv6';
#     }
      if ($type eq NF_ICMPv6_TYPE_ECHO_REQUEST
      ||  $type eq NF_ICMPv6_TYPE_ECHO_REPLY) {
         return 'ICMPv6::Echo';
      }
      elsif ($type eq NF_ICMPv6_TYPE_NEIGHBORSOLICITATION) {
         return 'ICMPv6::NeighborSolicitation';
      }
      elsif ($type eq NF_ICMPv6_TYPE_NEIGHBORADVERTISEMENT) {
         return 'ICMPv6::NeighborAdvertisement';
      }
      elsif ($type eq NF_ICMPv6_TYPE_ROUTERSOLICITATION) {
         return 'ICMPv6::RouterSolicitation';
      }
      elsif ($type eq NF_ICMPv6_TYPE_ROUTERADVERTISEMENT) {
         return 'ICMPv6::RouterAdvertisement';
      }
      elsif ($type eq NF_ICMPv6_TYPE_DESTUNREACH) {
         return 'ICMPv6::DestUnreach';
      }
      elsif ($type eq NF_ICMPv6_TYPE_TIMEEXCEED) {
         return 'ICMPv6::TimeExceed';
      }
      elsif ($type eq NF_ICMPv6_TYPE_TOOBIG) {
         return 'ICMPv6::TooBig';
      }
      elsif ($type eq NF_ICMPv6_TYPE_PARAMETERPROBLEM) {
         return 'ICMPv6::ParameterProblem';
      }
   }

   return NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: type:%d  code:%d  checksum:0x%04x",
      $self->type, $self->code, $self->checksum;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6 - Internet Control Message Protocol v6 layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::ICMPv6 qw(:consts);

   my $icmp = Net::Frame::Layer::ICMPv6->new(
      type     => NF_ICMPv6_TYPE_ECHO_REQUEST,
      code     => NF_ICMPv6_CODE_ZERO,
      checksum => 0,
   );

   # Build an ICMPv6 echo-request
   use Net::Frame::Layer::ICMPv6::Echo;
   my $echo = Net::Frame::Layer::ICMPv6::Echo->new(payload => 'echo');

   my $echoReq = Net::Frame::Simple->new(layers => [ $icmp, $echo ]);
   print $echoReq->print."\n";

   # Build an ICMPv6 neighbor-solicitation
   use Net::Frame::Layer::ICMPv6::NeighborSolicitation;
   my $solicit = Net::Frame::Layer::ICMPv6::NeighborSolicitation->new(
      targetAddress => $targetIpv6Address,
   );
   $icmp->type(NF_ICMPv6_TYPE_NEIGHBORSOLICITATION);

   my $nsReq = Net::Frame::Simple->new(layers => [ $icmp, $solicit ]);
   print $nsReq->print."\n";

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::ICMPv6->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv6 layer.

RFC: http://www.rfc-editor.org/rfc/rfc4861.txt

RFC: http://www.rfc-editor.org/rfc/rfc4389.txt

RFC: http://www.rfc-editor.org/rfc/rfc4191.txt

RFC: http://www.rfc-editor.org/rfc/rfc3775.txt

RFC: http://www.rfc-editor.org/rfc/rfc2463.txt

RFC: http://www.rfc-editor.org/rfc/rfc2461.txt

RFC: http://www.rfc-editor.org/rfc/rfc2460.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

=item B<code>

Type and code fields. See B<CONSTANTS>.

=item B<checksum>

The checksum of ICMPv6 header.

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

=item B<computeChecksums>

Computes the ICMPv6 checksum.

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::ICMPv6 object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::ICMPv6> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::ICMPv6 qw(:consts);

Various types and codes for ICMPv6 header.

=over 4

=item B<NF_ICMPv6_CODE_ZERO>

=item B<NF_ICMPv6_TYPE_DESTUNREACH>

=item B<NF_ICMPv6_CODE_NOROUTE>

=item B<NF_ICMPv6_CODE_ADMINPROHIBITED>

=item B<NF_ICMPv6_CODE_NOTASSIGNED>

=item B<NF_ICMPv6_CODE_ADDRESSUNREACH>

=item B<NF_ICMPv6_CODE_PORTUNREACH>

=item B<NF_ICMPv6_CODE_FAILPOLICY>

=item B<NF_ICMPv6_CODE_REJECTROUTE>

=item B<NF_ICMPv6_TYPE_TOOBIG>

=item B<NF_ICMPv6_TYPE_TIMEEXCEED>

=item B<NF_ICMPv6_CODE_HOPLIMITEXCEED>

=item B<NF_ICMPv6_CODE_FRAGREASSEMBLYEXCEEDED>

=item B<NF_ICMPv6_TYPE_PARAMETERPROBLEM>

=item B<NF_ICMPv6_CODE_ERRONEOUSHERDERFIELD>

=item B<NF_ICMPv6_CODE_UNKNOWNNEXTHEADER>

=item B<NF_ICMPv6_CODE_UNKNOWNOPTION>

=item B<NF_ICMPv6_TYPE_ECHO_REQUEST>

=item B<NF_ICMPv6_TYPE_ECHO_REPLY>

=item B<NF_ICMPv6_TYPE_ROUTERSOLICITATION>

=item B<NF_ICMPv6_TYPE_ROUTERADVERTISEMENT>

=item B<NF_ICMPv6_TYPE_NEIGHBORSOLICITATION>

=item B<NF_ICMPv6_TYPE_NEIGHBORADVERTISEMENT>

=item B<NF_ICMPv6_OPTION_SOURCELINKLAYERADDRESS>

=item B<NF_ICMPv6_OPTION_TARGETLINKLAYERADDRESS>

=item B<NF_ICMPv6_OPTION_PREFIXINFORMATION>

=item B<NF_ICMPv6_OPTION_REDIRECTEDHEADER>

=item B<NF_ICMPv6_OPTION_MTU>

=back

Various flags for some ICMPv6 messages.

=over 4

=item B<NF_ICMPv6_FLAG_ROUTER>

=item B<NF_ICMPv6_FLAG_SOLICITED>

=item B<NF_ICMPv6_FLAG_OVERRIDE>

=item B<NF_ICMPv6_FLAG_MANAGEDADDRESSCONFIGURATION>

=item B<NF_ICMPv6_FLAG_OTHERCONFIGURATION>

=item B<NF_ICMPv6_FLAG_MOBILEIPv6HOMEAGENT>

=item B<NF_ICMPv6_FLAG_ROUTERSELECTIONPREFHIGH>

=item B<NF_ICMPv6_FLAG_ROUTERSELECTIONPREFMEDIUM>

=item B<NF_ICMPv6_FLAG_ROUTERSELECTIONPREFLOW>

=item B<NF_ICMPv6_FLAG_ROUTERSELECTIONPREFRESERVED>

=item B<NF_ICMPv6_FLAG_NEIGHBORDISCOVERYPROXY>

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
