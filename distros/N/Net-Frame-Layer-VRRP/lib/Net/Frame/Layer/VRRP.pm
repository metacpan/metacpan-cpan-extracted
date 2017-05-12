#
# $Id: VRRP.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::VRRP;
use strict; use warnings;

our $VERSION = '1.00';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_VRRP_ALLVRRPRTRS
      NF_VRRP_ALLVRRPRTRS_MAC
      NF_VRRP_VERSION
      NF_VRRP_TYPE_ADVERT
      NF_VRRP_PRIORITY_OWNER
      NF_VRRP_PRIORITY_DEFAULT
      NF_VRRP_PRIORITY_NOMASTER
      NF_VRRP_AUTH_NO
      NF_VRRP_AUTH_TEXT
      NF_VRRP_AUTH_AH
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_VRRP_ALLVRRPRTRS     => '224.0.0.18';
use constant NF_VRRP_ALLVRRPRTRS_MAC => '01:00:5e:00:00:12';
use constant NF_VRRP_VERSION         => 2;
use constant NF_VRRP_TYPE_ADVERT     => 1;
use constant NF_VRRP_PRIORITY_OWNER    => 255;
use constant NF_VRRP_PRIORITY_DEFAULT  => 100;
use constant NF_VRRP_PRIORITY_NOMASTER => 0;
use constant NF_VRRP_AUTH_NO         => 0;
use constant NF_VRRP_AUTH_TEXT       => 1;
use constant NF_VRRP_AUTH_AH         => 2;

our @AS = qw(
   version
   type
   vrId
   priority
   countIp
   authType
   interval
   checksum
   authentication
);
our @AA = qw(
   ipAddresses
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

#no strict 'vars';

use Bit::Vector;

sub new {
   shift->SUPER::new(
      version     => NF_VRRP_VERSION,
      type        => NF_VRRP_TYPE_ADVERT,
      vrId        => 1,
      priority    => NF_VRRP_PRIORITY_DEFAULT,
      countIp     => 1,
      authType    => NF_VRRP_AUTH_NO,
      interval    => 1,
      checksum    => 0,
      ipAddresses => ['127.0.0.1'],
      authentication => '',
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 16;
   $len += 4 for $self->ipAddresses;
   return $len;
}

sub pack {
   my $self = shift;

   my $version = Bit::Vector->new_Dec(4, $self->version);
   my $type    = Bit::Vector->new_Dec(4, $self->type);
   my $bvlist  = $version->Concat_List($type);

   my $raw = $self->SUPER::pack('CCCCCCn',
      $bvlist->to_Dec,
      $self->vrId,
      $self->priority,
      $self->countIp,
      $self->authType,
      $self->interval,
      $self->checksum,
   ) or return;

   for ($self->ipAddresses) {
      $raw .= inetAton($_);
   }
   
   $raw .= $self->SUPER::pack('a8',
       $self->authentication,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $vrId, $priority, $countIp, $authType,
       $interval, $checksum, $payload) =
      $self->SUPER::unpack('CCCCCCn a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(8, $bv);
   $self->version ($bvlist->Chunk_Read(4, 4));
   $self->type    ($bvlist->Chunk_Read(4, 0));

   $self->vrId($vrId);
   $self->priority($priority);
   $self->countIp($countIp);
   $self->authType($authType);
   $self->interval($interval);
   $self->checksum($checksum);

   my @ipAddresses = ();
   for my $num (0..$countIp-1) {
      if (defined($payload) && (length($payload) >= 4)) {
         my $addr = unpack 'a4', $payload;
         push @ipAddresses, inetNtoa($addr);
         $payload = substr $payload, 4;
      }
   }
   $self->ipAddresses(\@ipAddresses);

   my $authentication = unpack 'a8', $payload;
   $payload = substr $payload, 8;

   $self->authentication($authentication);

   $self->payload($payload);

   return $self;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $version = Bit::Vector->new_Dec(4, $self->version);
   my $type    = Bit::Vector->new_Dec(4, $self->type);
   my $bvlist  = $version->Concat_List($type);

   my $phpkt = $self->SUPER::pack('CCCCCCn',
      $bvlist->to_Dec,
      $self->vrId,
      $self->priority,
      $self->countIp,
      $self->authType,
      $self->interval,
      0,
   ) or return;

   for ($self->ipAddresses) {
      $phpkt .= inetAton($_);
   }
   
   $phpkt .= $self->SUPER::pack('a8',
       $self->authentication,
   ) or return;

   my $start   = 0;
   my $last    = $self;
   my $payload = '';
   for my $l (@$layers) {
      $last = $l;
      if (! $start) {
	 $start++ if $l->layer eq 'VRRP';
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

   NF_LAYER_NONE;
}

sub computeLengths {
   my $self = shift;

   # Calculate countIp from ipAddresses array items
   if (scalar($self->ipAddresses) && ($self->countIp == 0)) {
      $self->countIp(scalar($self->ipAddresses))
   }

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  type:%d  vrId:%d  priority:%d\n".
      "$l: countIp:%d  authType:%d  interval:%d  checksum:0x%04x",
         $self->version, $self->type, $self->vrId, $self->priority,
         $self->countIp, $self->authType, $self->interval, $self->checksum;

   for ($self->ipAddresses) {
      $buf .= sprintf
      "\n$l: ipAddresses:%s",
         $_
   }

   $buf .= sprintf
      "\n$l: authentication:%s",
         $self->authentication;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::VRRP - Virtual Router Redundancy Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::VRRP qw(:consts);

   my $layer = Net::Frame::Layer::VRRP->new(
      version     => NF_VRRP_VERSION,
      type        => NF_VRRP_TYPE_ADVERT,
      vrId        => 1,
      priority    => NF_VRRP_PRIORITY_DEFAULT,
      countIp     => 1,
      authType    => NF_VRRP_AUTH_NO,
      interval    => 1,
      checksum    => 0,
      ipAddresses => ['127.0.0.1'],
      authentication => '',
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::VRRP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the VRRP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2338.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

VRRP protocol version.  See B<CONSTANTS> for more information.

=item B<type>

VRRP type.  See B<CONSTANTS> for more information.

=item B<vrId>

VRRP ID.

=item B<priority>

VRRP router priority.  Higher values equal higher priority.  See B<CONSTANTS> for more information.

=item B<countIp>

The number of IP addresses contained in this VRRP advertisement.

=item B<authType>

The authentication method being utilized.

=item B<interval>

Time interval in seconds between advertisements.

=item B<checksum>

16-bit one's complement of the one's complement sum of the entire VRRP message starting with the version field. For computing the checksum, the checksum field is cleared to zero.

=item B<ipAddresses>

One or more IP addresses that are associated with the virtual router.

=item B<authentication>

Upto 8 characters of plain text zero-padded.

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

Computes the VRRP checksum.

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

Load them: use Net::Frame::Layer::VRRP qw(:consts);

=over 4

=item B<NF_VRRP_ALLVRRPRTRS_MAC>

Default Layer 2 destination addresses.

=item B<NF_VRRP_ALLVRRPRTRS>

Default Layer 3 destination addresses.

=item B<NF_VRRP_VERSION>

VRRP version.

=item B<NF_VRRP_TYPE_ADVERT>

VRRP type.

=item B<NF_VRRP_PRIORITY_OWNER>

=item B<NF_VRRP_PRIORITY_DEFAULT>

=item B<NF_VRRP_PRIORITY_NOMASTER>

VRRP priorities.

=item B<NF_VRRP_AUTH_NO>

=item B<NF_VRRP_AUTH_TEXT>

=item B<NF_VRRP_AUTH_AH>

VRRP authentication types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
