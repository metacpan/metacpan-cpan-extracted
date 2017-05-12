#
# $Id: OSPF.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts :subs);
require Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_OSPF_HDR_LEN
      NF_OSPF_TYPE_HELLO
      NF_OSPF_TYPE_DATABASEDESC
      NF_OSPF_TYPE_LINKSTATEREQUEST
      NF_OSPF_TYPE_LINKSTATEUPDATE
      NF_OSPF_TYPE_LINKSTATEACK
      NF_OSPF_AUTHTYPE_NULL
      NF_OSPF_AUTHTYPE_SIMPLE
      NF_OSPF_AUTHTYPE_CRYPTO
      NF_OSPF_LSA_HDR_LEN
      NF_OSPF_LSTYPE_ROUTER
      NF_OSPF_LSTYPE_NETWORK
      NF_OSPF_LSTYPE_SUMMARYIP
      NF_OSPF_LSTYPE_SUMMARYASBR
      NF_OSPF_LSTYPE_ASEXTERNAL
      NF_OSPF_LSTYPE_OPAQUELINKLOCAL
      NF_OSPF_LSTYPE_OPAQUEAREALOCAL
      NF_OSPF_LSTYPE_OPAQUEDOMAIN
      NF_OSPF_HELLO_OPTIONS_UNK
      NF_OSPF_HELLO_OPTIONS_E
      NF_OSPF_HELLO_OPTIONS_MC
      NF_OSPF_HELLO_OPTIONS_NP
      NF_OSPF_HELLO_OPTIONS_EA
      NF_OSPF_HELLO_OPTIONS_DC
      NF_OSPF_HELLO_OPTIONS_O
      NF_OSPF_HELLO_OPTIONS_DN
      NF_OSPF_DATABASEDESC_OPTIONS_DN
      NF_OSPF_DATABASEDESC_OPTIONS_0
      NF_OSPF_DATABASEDESC_OPTIONS_DC
      NF_OSPF_DATABASEDESC_OPTIONS_L 
      NF_OSPF_DATABASEDESC_OPTIONS_NP
      NF_OSPF_DATABASEDESC_OPTIONS_MC
      NF_OSPF_DATABASEDESC_OPTIONS_E
      NF_OSPF_DATABASEDESC_FLAGS_MS
      NF_OSPF_DATABASEDESC_FLAGS_M
      NF_OSPF_DATABASEDESC_FLAGS_I
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_OSPF_HDR_LEN     => 24;
use constant NF_OSPF_LSA_HDR_LEN => 20;

use constant NF_OSPF_TYPE_HELLO            => 0x01;
use constant NF_OSPF_TYPE_DATABASEDESC     => 0x02;
use constant NF_OSPF_TYPE_LINKSTATEREQUEST => 0x03;
use constant NF_OSPF_TYPE_LINKSTATEUPDATE  => 0x04;
use constant NF_OSPF_TYPE_LINKSTATEACK     => 0x05;

use constant NF_OSPF_AUTHTYPE_NULL   => 0x0000;
use constant NF_OSPF_AUTHTYPE_SIMPLE => 0x0001;
use constant NF_OSPF_AUTHTYPE_CRYPTO => 0x0002;

use constant NF_OSPF_LSTYPE_ROUTER      => 0x01;
use constant NF_OSPF_LSTYPE_NETWORK     => 0x02;
use constant NF_OSPF_LSTYPE_SUMMARYIP   => 0x03;
use constant NF_OSPF_LSTYPE_SUMMARYASBR => 0x04;
use constant NF_OSPF_LSTYPE_ASEXTERNAL  => 0x05;
use constant NF_OSPF_LSTYPE_OPAQUELINKLOCAL => 0x0a;
use constant NF_OSPF_LSTYPE_OPAQUEAREALOCAL => 0x0b;
use constant NF_OSPF_LSTYPE_OPAQUEDOMAIN    => 0x0c;

use constant NF_OSPF_HELLO_OPTIONS_UNK => 0x01; # Not in RFC 2328
use constant NF_OSPF_HELLO_OPTIONS_E   => 0x02;
use constant NF_OSPF_HELLO_OPTIONS_MC  => 0x04;
use constant NF_OSPF_HELLO_OPTIONS_NP  => 0x08;
use constant NF_OSPF_HELLO_OPTIONS_EA  => 0x10;
use constant NF_OSPF_HELLO_OPTIONS_DC  => 0x20;
use constant NF_OSPF_HELLO_OPTIONS_O   => 0x40; # Not in RFC 2328
use constant NF_OSPF_HELLO_OPTIONS_DN  => 0x80; # Not in RFC 2328

use constant NF_OSPF_DATABASEDESC_OPTIONS_DN => 0x01;
use constant NF_OSPF_DATABASEDESC_OPTIONS_0  => 0x02;
use constant NF_OSPF_DATABASEDESC_OPTIONS_DC => 0x04;
use constant NF_OSPF_DATABASEDESC_OPTIONS_L  => 0x08;
use constant NF_OSPF_DATABASEDESC_OPTIONS_NP => 0x10;
use constant NF_OSPF_DATABASEDESC_OPTIONS_MC => 0x20;
use constant NF_OSPF_DATABASEDESC_OPTIONS_E  => 0x40;

use constant NF_OSPF_DATABASEDESC_FLAGS_MS => 0x01;
use constant NF_OSPF_DATABASEDESC_FLAGS_M  => 0x02;
use constant NF_OSPF_DATABASEDESC_FLAGS_I  => 0x04;

our @AS = qw(
   version
   type
   length
   routerId
   areaId
   checksum
   authType
   authData
   packet
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

require Net::Frame::Layer::OSPF::Hello;
require Net::Frame::Layer::OSPF::DatabaseDesc;
require Net::Frame::Layer::OSPF::LinkStateUpdate;
require Net::Frame::Layer::OSPF::LinkStateRequest;
require Net::Frame::Layer::OSPF::LinkStateAck;
require Net::Frame::Layer::OSPF::Lls;

sub new {
   shift->SUPER::new(
      version  => 2,
      type     => 0,
      length   => NF_OSPF_HDR_LEN,
      routerId => '127.0.0.1',
      areaId   => '127.0.0.1',
      checksum => 0,
      authType => NF_OSPF_AUTHTYPE_NULL,
      authData => "0000000000000000",
      @_,
   );
}

sub match {
   my $self = shift;
   my ($with) = @_;
   if ($self->packet && $with->packet) {
      my $s    = $self->packet->layer;
      my $sHdr = $self->packet;
      my $w    = $with->packet->layer;
      my $wHdr = $with->packet;
      if (($s eq 'OSPF::Hello') && ($w eq 'OSPF::DatabaseDesc')) {
         return 1;
      }
      elsif (($s eq 'OSPF::DatabaseDesc') && ($w eq 'OSPF::DatabaseDesc')) {
         if ($sHdr->flags == 0x07 && $wHdr->flags == 0x02) {
            return 1;
         }
         elsif ($sHdr->flags == 0x03 && $wHdr->flags == 0x00) {
            return 1;
         }
         elsif ($sHdr->flags == 0x01 && $wHdr->flags == 0x00) {
            return 1;
         }
      }
      elsif (($s eq 'OSPF::LinkStateRequest')
         &&  ($w eq 'OSPF::LinkStateRequest')) {
         return 1;
      }
   }
   0;
}

sub getLength { shift->length }

sub computeLengths {
   my $self = shift;
   my $len = $self->getLength;

   # If packet is not a ref, it is not an object, but a raw data (LinkStateAck)
   if ($self->packet && ! ref($self->packet)) {
      $len += length($self->packet);
   }
   # Else, standard object
   elsif ($self->packet) {
      $len += $self->packet->getLength;
   }
   $self->length($len);
}

sub computeChecksums {
   my $self = shift;

   # When simple password auth is used, we MUST calculate 
   # the checksum without the plaintext password
   my $authData = $self->authData;
   $self->authData("0000000000000000");

   $self->checksum(0);
   $self->checksum(inetChecksum($self->pack));

   # Restore the simple password
   $self->authData($authData);
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('CCna4a4nnH16',
      $self->version, $self->type, $self->length,
      inetAton($self->routerId), inetAton($self->areaId),
      $self->checksum, $self->authType, $self->authData,
   ) or return undef;

   if ($self->packet && ref($self->packet)) {
      $raw .= $self->packet->pack;
   }
   elsif ($self->packet) {
      $raw .= $self->packet;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($version, $type, $length, $routerId, $areaId, $checksum,
      $authType, $authData, $payload) =
         $self->SUPER::unpack('CCna4a4nnH16 a*', $self->raw)
            or return undef;

   $self->version($version);
   $self->type($type);
   $self->length($length);
   $self->routerId(inetNtoa($routerId));
   $self->areaId(inetNtoa($areaId));
   $self->checksum($checksum);
   $self->authType($authType);
   $self->authData($authData);

   my $keep = $length - NF_OSPF_HDR_LEN;
   my $tail = substr($payload, 0, $keep);
   $payload = substr($payload, $keep);

   # Handle type of OSPF frame
   my $next;
   if ($tail) {
      if ($type == NF_OSPF_TYPE_HELLO) {
         $next = Net::Frame::Layer::OSPF::Hello->new(raw => $tail);
      }
      elsif ($type == NF_OSPF_TYPE_DATABASEDESC) {
         $next = Net::Frame::Layer::OSPF::DatabaseDesc->new(raw => $tail);
      }
      elsif ($type == NF_OSPF_TYPE_LINKSTATEUPDATE) {
         $next = Net::Frame::Layer::OSPF::LinkStateUpdate->new(raw => $tail);
      }
      elsif ($type == NF_OSPF_TYPE_LINKSTATEREQUEST) {
         $next = Net::Frame::Layer::OSPF::LinkStateRequest->new(raw => $tail);
      }
      elsif ($type == NF_OSPF_TYPE_LINKSTATEACK) {
         $next = Net::Frame::Layer::OSPF::LinkStateAck->new(raw => $tail);
      }
   }

   if ($next) {
      $next->unpack;
      my $newPayload = $next->payload;
      if ($payload) { $newPayload .= $payload }
      $next->payload($newPayload);
      $self->packet($next);
      $payload = $next->payload;

      if ($payload) {
         # Handle special options for OSPF::Hello frame
         if ($next->layer eq 'OSPF::Hello') {
            if ($next->options & NF_OSPF_HELLO_OPTIONS_EA) {
               my $lls = Net::Frame::Layer::OSPF::Lls->new(raw => $payload);
               $lls->unpack;
               $next->lls($lls);
               $payload = $lls->payload;
            }
         }
         # Handle special options for OSPF::DatabaseDesc frame
         elsif ($next->layer eq 'OSPF::DatabaseDesc') {
            # XXX: ugly hack, should rework
            if ($next->options == 0x52) {
               my $lls = Net::Frame::Layer::OSPF::Lls->new(raw => $payload);
               $lls->unpack;
               $next->lls($lls);
               $payload = $lls->payload;
            }
         }
      }
   }
   else {
      $payload = $tail.$payload;
   }

   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: version:%d  type:0x%02x length:%d\n".
           "$l: routerId:%s  areaId:%s\n".
           "$l: checksum:0x%04x  authType:0x%04x\n".
           "$l: authData:%s",
              $self->version, $self->type, $self->length,
              $self->routerId, $self->areaId, $self->checksum,
              $self->authType, $self->authData;

   if ($self->packet && ref($self->packet)) {
      $buf .= "\n".$self->packet->print;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF - Open Shortest Path First layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::OSPF->new(
      version  => 2,
      type     => 0,
      length   => NF_OSPF_HDR_LEN,
      routerId => '127.0.0.1',
      areaId   => '127.0.0.1',
      checksum => 0,
      authType => NF_OSPF_AUTHTYPE_NULL,
      authData => "0000000000000000",
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the Open Shortest Path First layer.

RFC: http://www.rfc-editor.org/rfc/rfc2328.txt

RFC: http://www.rfc-editor.org/rfc/rfc2370.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version> - 8 bits

=item B<type> - 8 bits

=item B<length> - 16 bits

=item B<routerId> - 32 bits

=item B<areaId> - 32 bits

=item B<checksum> - 16 bits

=item B<authType> - 16 bits

=item B<authData> - 64 bits

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

=item B<match> (Net::Frame::Layer::OSPF object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::OSPF> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

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

Load them: use Net::Frame::Layer::OSPF qw(:consts);

=over 4

=item B<NF_OSPF_HDR_LEN>

=item B<NF_OSPF_LSA_HDR_LEN>

Various OSPF layer types header length.

=item B<NF_OSPF_AUTHTYPE_NULL>

=item B<NF_OSPF_AUTHTYPE_SIMPLE>

=item B<NF_OSPF_AUTHTYPE_CRYPTO>

Supported OSPF authentication schemes.

=item B<NF_OSPF_TYPE_HELLO>

=item B<NF_OSPF_TYPE_DATABASEDESC>

=item B<NF_OSPF_TYPE_LINKSTATEREQUEST>

=item B<NF_OSPF_TYPE_LINKSTATEUPDATE>

=item B<NF_OSPF_TYPE_LINKSTATEACK>

Supported OSPF message types.

=item B<NF_OSPF_LSTYPE_ROUTER>

=item B<NF_OSPF_LSTYPE_NETWORK>

=item B<NF_OSPF_LSTYPE_SUMMARYIP>

=item B<NF_OSPF_LSTYPE_SUMMARYASBR>

=item B<NF_OSPF_LSTYPE_ASEXTERNAL>

=item B<NF_OSPF_LSTYPE_OPAQUELINKLOCAL>

=item B<NF_OSPF_LSTYPE_OPAQUEAREALOCAL>

=item B<NF_OSPF_LSTYPE_OPAQUEDOMAIN>

Supported OSPF LinkState types.

=item B<NF_OSPF_HELLO_OPTIONS_UNK>

=item B<NF_OSPF_HELLO_OPTIONS_E>

=item B<NF_OSPF_HELLO_OPTIONS_MC>

=item B<NF_OSPF_HELLO_OPTIONS_NP>

=item B<NF_OSPF_HELLO_OPTIONS_EA>

=item B<NF_OSPF_HELLO_OPTIONS_DC>

=item B<NF_OSPF_HELLO_OPTIONS_O>

=item B<NF_OSPF_HELLO_OPTIONS_DN>

OSPF Hello header options flags.

=item B<NF_OSPF_DATABASEDESC_OPTIONS_DN>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_0>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_DC>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_L>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_NP>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_MC>

=item B<NF_OSPF_DATABASEDESC_OPTIONS_E>

OSPF DatabaseDesc header options flags.

=item B<NF_OSPF_DATABASEDESC_FLAGS_MS>

=item B<NF_OSPF_DATABASEDESC_FLAGS_M>

=item B<NF_OSPF_DATABASEDESC_FLAGS_I>

OSPF DatabaseDesc header flags.

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
