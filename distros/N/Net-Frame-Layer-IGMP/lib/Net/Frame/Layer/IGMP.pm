#
# $Id: IGMP.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::IGMP;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_IGMP_ALLIGMPRTRS
      NF_IGMP_ALLIGMPRTRS_MAC
      NF_IGMP_TYPE_QUERY
      NF_IGMP_TYPE_DVMRP
      NF_IGMP_TYPE_REPORTv1
      NF_IGMP_TYPE_REPORTv2
      NF_IGMP_TYPE_REPORTv3
      NF_IGMP_TYPE_LEAVE
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_IGMP_ALLIGMPRTRS     => '224.0.0.22';
use constant NF_IGMP_ALLIGMPRTRS_MAC => '01:00:5e:00:00:16';
use constant NF_IGMP_TYPE_QUERY    => 0x11;
use constant NF_IGMP_TYPE_DVMRP    => 0x13;
use constant NF_IGMP_TYPE_REPORTv1 => 0x12;
use constant NF_IGMP_TYPE_REPORTv2 => 0x16;
use constant NF_IGMP_TYPE_REPORTv3 => 0x22;
use constant NF_IGMP_TYPE_LEAVE    => 0x17;

our @AS = qw(
   type
   maxResp
   checksum
   groupAddress
   reserved
   numGroupRecs
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Net::Frame::Layer::IGMP::v3Query;
use Net::Frame::Layer::IGMP::v3Report qw(:consts);

sub new {
   shift->SUPER::new(
      type         => NF_IGMP_TYPE_QUERY,
      maxResp      => 0,
      checksum     => 0,
      groupAddress => '0.0.0.0',
      reserved     => 0,
      numGroupRecs => 0,
      @_,
   );
}

sub v3report {
   shift->SUPER::new(
      type         => NF_IGMP_TYPE_REPORTv3,
      maxResp      => 0,
      checksum     => 0,
      reserved     => 0,
      numGroupRecs => 0,
      @_,
   );
}

sub getLength { 8 }

sub pack {
   my $self = shift;

   my $raw;
   if ($self->type == NF_IGMP_TYPE_REPORTv3) {
      $raw = $self->SUPER::pack('CCnnn',
         $self->type,
         $self->maxResp,
         $self->checksum,
         $self->reserved,
         $self->numGroupRecs
      ) or return;
   } else {
      $raw = $self->SUPER::pack('CCna4',
         $self->type,
         $self->maxResp,
         $self->checksum,
         inetAton($self->groupAddress)
      ) or return;
   }

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($type, $maxResp, $checksum, $groupAddress, $payload) =
      $self->SUPER::unpack('CCna4 a*', $self->raw)
         or return;

   $self->type($type);
   $self->maxResp($maxResp);
   $self->checksum($checksum);
   
   if ($self->type == NF_IGMP_TYPE_REPORTv3) {
      $self->reserved(unpack "n", (substr $groupAddress, 0, 2));
      $self->numGroupRecs(unpack "n", (substr $groupAddress, 2, 2));
   } else {
      $self->groupAddress(inetNtoa($groupAddress))
   }

   $self->payload($payload);

   return $self;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $phpkt;
   if ($self->type == NF_IGMP_TYPE_REPORTv3) {
      $phpkt .= $self->SUPER::pack('CCnnn',
         $self->type, $self->maxResp, 0, $self->reserved, $self->numGroupRecs)
            or return;
   } else {
      $phpkt .= $self->SUPER::pack('CCna4',
         $self->type, $self->maxResp, 0, inetAton($self->groupAddress))
            or return;
   }

   my $start   = 0;
   my $last    = $self;
   my $payload = '';
   for my $l (@$layers) {
      $last = $l;
      if (! $start) {
	 $start++ if $l->layer eq 'IGMP';
         next;
      }
      $payload .= $l->pack;
   }

   if (defined($last->payload) && length($last->payload)) {
      $payload .= $last->payload;
   }

   if (length($payload)) {
      $phpkt .= $self->SUPER::pack('a*', $payload)
         or return;
   }

   $self->checksum(inetChecksum($phpkt));

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      if ($self->type == 0x11) {
         return 'IGMP::v3Query';
      } elsif ($self->type == 0x22) {
         return 'IGMP::v3Report';
      } elsif ($self->type == 0x13) {
         return 'DVMRP';
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: type:0x%02x  maxResp:%d  checksum:0x%04x\n",
         $self->type, $self->maxResp, $self->checksum;

   if ($self->type == NF_IGMP_TYPE_REPORTv3) {
      $buf .= sprintf
      "$l: reserved:%d  numGroupRecs:%d",
         $self->reserved, $self->numGroupRecs;
   } else {
      $buf .= sprintf
      "$l: groupAddress:%s",
         $self->groupAddress;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::IGMP - Internet Group Management Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::IGMP qw(:consts);

   my $layer = Net::Frame::Layer::IGMP->new(
      type         => NF_IGMP_TYPE_QUERY,
      maxResp      => 0,
      checksum     => 0,
      groupAddress => '0.0.0.0',
   );

   # v3 Report
   my $layer = Net::Frame::Layer::IGMP->new(
      type         => NF_IGMP_TYPE_REPORTv3,
      maxResp      => 0,
      checksum     => 0,
      reserved     => 0,
      numGroupRecs => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::IGMP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the IGMP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc1112.txt

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2236.txt

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc3376.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

IGMP message type.  See B<CONSTANTS> for more information.

=item B<maxResp>

Max response time (version 2) or code (version 3).  Unused in version 1.

=item B<checksum>

Message checksum.

=item B<groupAddress>

Multicast group address.

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

=item B<v3report>

=item B<v3report> (hash)

Object constructor. You can pass attributes that will overwrite default ones. Default values:

   my $layer = Net::Frame::Layer::IGMP->new(
      type         => NF_IGMP_TYPE_REPORTv3,
      maxResp      => 0,
      checksum     => 0,
      reserved     => 0,
      numGroupRecs => 0,
   );

=item B<computeChecksums>

Computes the IGMP checksum.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::IGMP qw(:consts);

=over 4

=item B<NF_IGMP_ALLIGMPRTRS_MAC>

Default Layer 2 destination addresses.

=item B<NF_IGMP_ALLIGMPRTRS>

Default Layer 3 destination addresses.

=item B<NF_IGMP_TYPE_QUERY>

=item B<NF_IGMP_TYPE_DVMRP>

=item B<NF_IGMP_TYPE_REPORTv1>

=item B<NF_IGMP_TYPE_REPORTv2>

=item B<NF_IGMP_TYPE_REPORTv3>

=item B<NF_IGMP_TYPE_LEAVE>

IGMP message types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
