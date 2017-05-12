#
# $Id: ICMPv4.pm 56 2015-01-20 18:55:33Z gomor $
#
package Net::Frame::Layer::ICMPv4;
use strict; use warnings;

our $VERSION = '1.05';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_ICMPv4_HDR_LEN
      NF_ICMPv4_CODE_ZERO
      NF_ICMPv4_TYPE_DESTUNREACH
      NF_ICMPv4_CODE_NETWORK
      NF_ICMPv4_CODE_HOST
      NF_ICMPv4_CODE_PROTOCOL
      NF_ICMPv4_CODE_PORT
      NF_ICMPv4_CODE_FRAGMENTATION_NEEDED
      NF_ICMPv4_CODE_SOURCE_ROUTE_FAILED
      NF_ICMPv4_TYPE_TIMEEXCEED
      NF_ICMPv4_CODE_TTL_IN_TRANSIT
      NF_ICMPv4_CODE_FRAGMENT_REASSEMBLY
      NF_ICMPv4_TYPE_PARAMETERPROBLEM
      NF_ICMPv4_CODE_POINTER
      NF_ICMPv4_TYPE_SOURCEQUENCH
      NF_ICMPv4_TYPE_REDIRECT
      NF_ICMPv4_CODE_FOR_NETWORK
      NF_ICMPv4_CODE_FOR_HOST
      NF_ICMPv4_CODE_FOR_TOS_AND_NETWORK
      NF_ICMPv4_CODE_FOR_TOS_AND_HOST
      NF_ICMPv4_TYPE_ECHO_REQUEST
      NF_ICMPv4_TYPE_ECHO_REPLY
      NF_ICMPv4_TYPE_TIMESTAMP_REQUEST
      NF_ICMPv4_TYPE_TIMESTAMP_REPLY
      NF_ICMPv4_TYPE_INFORMATION_REQUEST
      NF_ICMPv4_TYPE_INFORMATION_REPLY
      NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST
      NF_ICMPv4_TYPE_ADDRESS_MASK_REPLY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_ICMPv4_HDR_LEN                      => 8;
use constant NF_ICMPv4_CODE_ZERO                    => 0;
use constant NF_ICMPv4_TYPE_DESTUNREACH             => 3;
use constant NF_ICMPv4_CODE_NETWORK                 => 0;
use constant NF_ICMPv4_CODE_HOST                    => 1;
use constant NF_ICMPv4_CODE_PROTOCOL                => 2;
use constant NF_ICMPv4_CODE_PORT                    => 3;
use constant NF_ICMPv4_CODE_FRAGMENTATION_NEEDED    => 4;
use constant NF_ICMPv4_CODE_SOURCE_ROUTE_FAILED     => 5;
use constant NF_ICMPv4_TYPE_TIMEEXCEED              => 11;
use constant NF_ICMPv4_CODE_TTL_IN_TRANSIT          => 0;
use constant NF_ICMPv4_CODE_FRAGMENT_REASSEMBLY     => 1;
use constant NF_ICMPv4_TYPE_PARAMETERPROBLEM        => 12;
use constant NF_ICMPv4_CODE_POINTER                 => 0;
use constant NF_ICMPv4_TYPE_SOURCEQUENCH            => 4;
use constant NF_ICMPv4_TYPE_REDIRECT                => 5;
use constant NF_ICMPv4_CODE_FOR_NETWORK             => 0;
use constant NF_ICMPv4_CODE_FOR_HOST                => 1;
use constant NF_ICMPv4_CODE_FOR_TOS_AND_NETWORK     => 2;
use constant NF_ICMPv4_CODE_FOR_TOS_AND_HOST        => 3;
use constant NF_ICMPv4_TYPE_ECHO_REQUEST            => 8;
use constant NF_ICMPv4_TYPE_ECHO_REPLY              => 0;
use constant NF_ICMPv4_TYPE_TIMESTAMP_REQUEST       => 13;
use constant NF_ICMPv4_TYPE_TIMESTAMP_REPLY         => 14;
use constant NF_ICMPv4_TYPE_INFORMATION_REQUEST     => 15;
use constant NF_ICMPv4_TYPE_INFORMATION_REPLY       => 16;
use constant NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST    => 17; # RFC 950
use constant NF_ICMPv4_TYPE_ADDRESS_MASK_REPLY      => 18; # RFC 950

our @AS = qw(
   type
   code
   checksum
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::ICMPv4::AddressMask;
use Net::Frame::Layer::ICMPv4::DestUnreach;
use Net::Frame::Layer::ICMPv4::Echo;
use Net::Frame::Layer::ICMPv4::Information;
use Net::Frame::Layer::ICMPv4::Redirect;
use Net::Frame::Layer::ICMPv4::TimeExceed;
use Net::Frame::Layer::ICMPv4::Timestamp;

sub new {
   my $self = shift->SUPER::new(
      type     => NF_ICMPv4_TYPE_ECHO_REQUEST,
      code     => NF_ICMPv4_CODE_ZERO,
      checksum => 0,
      @_,
   );

   return $self;
}

sub match {
   my $self = shift;
   my ($with) = @_;
   my $sType = $self->type;
   my $wType = $with->type;
   if ($sType eq NF_ICMPv4_TYPE_ECHO_REQUEST
   &&  $wType eq NF_ICMPv4_TYPE_ECHO_REPLY) {
      return 1;
   }
   elsif ($sType eq NF_ICMPv4_TYPE_TIMESTAMP_REQUEST
      &&  $wType eq NF_ICMPv4_TYPE_TIMESTAMP_REPLY) {
      return 1;
   }
   elsif ($sType eq NF_ICMPv4_TYPE_INFORMATION_REQUEST
      &&  $wType eq NF_ICMPv4_TYPE_INFORMATION_REPLY) {
      return 1;
   }
   elsif ($sType eq NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST
      &&  $wType eq NF_ICMPv4_TYPE_ADDRESS_MASK_REPLY) {
      return 1;
   }
   0;
}

# XXX: may be better, by keying on type also
sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

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
   for my $l (@$layers) {
      if ($l->layer =~ /ICMPv4::/) { $icmpType = $l; last; }
   }

   my $packed = $self->SUPER::pack('CCna*',
      $self->type, $self->code, 0, $icmpType->pack,
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
      if ($type eq NF_ICMPv4_TYPE_ECHO_REQUEST
      ||  $type eq NF_ICMPv4_TYPE_ECHO_REPLY) {
         return 'ICMPv4::Echo';
      }
      elsif ($type eq NF_ICMPv4_TYPE_TIMESTAMP_REQUEST
         ||  $type eq NF_ICMPv4_TYPE_TIMESTAMP_REPLY) {
         return 'ICMPv4::Timestamp';
      }
      elsif ($type eq NF_ICMPv4_TYPE_INFORMATION_REQUEST
         ||  $type eq NF_ICMPv4_TYPE_INFORMATION_REPLY) {
         return 'ICMPv4::Information';
      }
      elsif ($type eq NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST
         ||  $type eq NF_ICMPv4_TYPE_ADDRESS_MASK_REPLY) {
         return 'ICMPv4::AddressMask';
      }
      elsif ($type eq NF_ICMPv4_TYPE_DESTUNREACH) {
         return 'ICMPv4::DestUnreach';
      }
      elsif ($type eq NF_ICMPv4_TYPE_REDIRECT) {
         return 'ICMPv4::Redirect';
      }
      elsif ($type eq NF_ICMPv4_TYPE_TIMEEXCEED) {
         return 'ICMPv4::TimeExceed';
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

Net::Frame::Layer::ICMPv4 - Internet Control Message Protocol v4 layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::ICMPv4 qw(:consts);

   my $icmp = Net::Frame::Layer::ICMPv4->new(
      type     => NF_ICMPv4_TYPE_ECHO_REQUEST,
      code     => NF_ICMPv4_CODE_ZERO,
      checksum => 0,
   );

   # Build an ICMPv4 echo-request
   use Net::Frame::Layer::ICMPv4::Echo;
   my $echo = Net::Frame::Layer::ICMPv4::Echo->new(
      payload => 'echo'
   );

   my $echoReq = Net::Frame::Simple->new(
      layers => [ $icmp, $echo ]
   );
   print $echoReq->print."\n";

   # Build an information-request
   use Net::Frame::Layer::ICMPv4::Information;
   my $info = Net::Frame::Layer::ICMPv4::Information->new(
      payload => 'info'
   );
   $icmp->type(NF_ICMPv4_TYPE_INFORMATION_REQUEST);

   my $infoReq = Net::Frame::Simple->new(
      layers => [ $icmp, $info ]
   );
   print $infoReq->print."\n";

   # Build an address-mask request
   use Net::Frame::Layer::ICMPv4::AddressMask;
   my $mask = Net::Frame::Layer::ICMPv4::AddressMask->new(
      payload => 'mask'
   );
   $icmp->type(NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST);

   my $maskReq = Net::Frame::Simple->new(
      layers => [ $icmp, $mask ]
   );
   print $maskReq->print."\n";

   # Build a timestamp request
   use Net::Frame::Layer::ICMPv4::Timestamp;
   my $timestamp = Net::Frame::Layer::ICMPv4::Timestamp->new(
      payload => 'time'
   );
   $icmp->type(NF_ICMPv4_TYPE_TIMESTAMP_REQUEST);

   my $timestampReq = Net::Frame::Simple->new(
      layers => [ $icmp, $timestamp ]
   );
   print $timestampReq->print."\n";

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::ICMPv4->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv4 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc792.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

=item B<code>

Type and code fields. See B<CONSTANTS>.

=item B<checksum>

The checksum of ICMPv4 header.

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

Computes the ICMPv4 checksum.

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::ICMPv4 object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::ICMPv4> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::ICMPv4 qw(:consts);

=over 4

=item B<NF_ICMPv4_CODE_ZERO>

ICMP code zero, used by various ICMP messages.

=item B<NF_ICMPv4_TYPE_DESTUNREACH>

=item B<NF_ICMPv4_CODE_NETWORK>

=item B<NF_ICMPv4_CODE_HOST>

=item B<NF_ICMPv4_CODE_PROTOCOL>

=item B<NF_ICMPv4_CODE_PORT>

=item B<NF_ICMPv4_CODE_FRAGMENTATION_NEEDED>

=item B<NF_ICMPv4_CODE_SOURCE_ROUTE_FAILED>

Destination unreachable type, with possible code numbers.

=item B<NF_ICMPv4_TYPE_REDIRECT>

=item B<NF_ICMPv4_CODE_FOR_NETWORK>

=item B<NF_ICMPv4_CODE_FOR_HOST>

=item B<NF_ICMPv4_CODE_FOR_TOS_AND_NETWORK>

=item B<NF_ICMPv4_CODE_FOR_TOS_AND_HOST>

Redirect type message, with possible code numbers.

=item B<NF_ICMPv4_TYPE_TIMEEXCEED>

=item B<NF_ICMPv4_CODE_TTL_IN_TRANSIT>

=item B<NF_ICMPv4_CODE_FRAGMENT_REASSEMBLY>

Time exceeded message, with possible code numbers.

=item B<NF_ICMPv4_TYPE_PARAMETERPROBLEM>

=item B<NF_ICMPv4_CODE_POINTER>

Parameter problem, with possible code numbers.

=item B<NF_ICMPv4_TYPE_SOURCEQUENCH>

Source quench type.

=item B<NF_ICMPv4_TYPE_ECHO_REQUEST>

=item B<NF_ICMPv4_TYPE_ECHO_REPLY>

=item B<NF_ICMPv4_TYPE_TIMESTAMP_REQUEST>

=item B<NF_ICMPv4_TYPE_TIMESTAMP_REPLY>

=item B<NF_ICMPv4_TYPE_INFORMATION_REQUEST>

=item B<NF_ICMPv4_TYPE_INFORMATION_REPLY>

=item B<NF_ICMPv4_TYPE_ADDRESS_MASK_REQUEST>

=item B<NF_ICMPv4_TYPE_ADDRESS_MASK_REPLY>

Other request/reply ICMP messages types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
