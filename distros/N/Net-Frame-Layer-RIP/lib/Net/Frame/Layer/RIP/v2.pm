#
# $Id: v2.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::RIP::v2;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_RIP_V2_ADDRESSFAMILY_IPV4
      NF_RIP_V2_ADDRESSFAMILY_AUTH
      NF_RIP_V2_AUTHTYPE_SIMPLE
      NF_RIP_V2_METRIC_INFINITY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_RIP_V2_ADDRESSFAMILY_IPV4 => 2;
use constant NF_RIP_V2_ADDRESSFAMILY_AUTH => 0xffff;
use constant NF_RIP_V2_AUTHTYPE_SIMPLE    => 2;
use constant NF_RIP_V2_METRIC_INFINITY    => 16;

our @AS = qw(
   addressFamily
   routeTag
   address
   subnetMask
   nextHop
   metric
   authType
   authentication
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      addressFamily => NF_RIP_V2_ADDRESSFAMILY_IPV4,
      routeTag      => 0,
      address       => '0.0.0.0',
      subnetMask    => '0.0.0.0',
      nextHop       => '0.0.0.0',
      metric        => 1,
      @_,
   );
}

sub full {
   shift->SUPER::new(
      addressFamily => 0,
      routeTag      => 0,
      address       => '0.0.0.0',
      subnetMask    => '0.0.0.0',
      nextHop       => '0.0.0.0',
      metric        => NF_RIP_V2_METRIC_INFINITY,
      @_,
   );
}

sub auth {
   my $self = shift;

   my %params = (
      authentication => ''
   );

   my %args = @_;
   for (keys(%args)) {
      if (/^authentication$/i) {
         $params{'authentication'} = substr $args{$_}, 0, 16
      }
   }

   $self->SUPER::new(
      addressFamily  => NF_RIP_V2_ADDRESSFAMILY_AUTH,
      authType       => NF_RIP_V2_AUTHTYPE_SIMPLE,
      authentication => '',
      @_,
      %params,
   );
}

sub getLength { 20 }

sub pack {
   my $self = shift;

   if ($self->addressFamily == NF_RIP_V2_ADDRESSFAMILY_AUTH) {
      $self->raw($self->SUPER::pack('nna16',
         $self->addressFamily,
         $self->authType,
         $self->authentication
      )) or return;

   } else {
      $self->raw($self->SUPER::pack('nna4a4a4N',
         $self->addressFamily,
         $self->routeTag,
         inetAton($self->address),
         inetAton($self->subnetMask),
         inetAton($self->nextHop),
         $self->metric
      )) or return;
   }

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($addressFamily, $remain) =
      $self->SUPER::unpack('n a*', $self->raw)
         or return;

   if ($addressFamily == NF_RIP_V2_ADDRESSFAMILY_AUTH) {
      my ($authType, $authentication, $payload) =
         $self->SUPER::unpack('na16 a*', $remain)
            or return;

      $self->addressFamily($addressFamily);
      $self->authType($authType);
      $authentication =~ s/\0{0,}$//g;
      $self->authentication($authentication);

      $self->payload($payload);

   } else {
      my ($routeTag, $address, $subnetMask, $nextHop, $metric, $payload) =
         $self->SUPER::unpack('na4a4a4N a*', $remain)
            or return;

      $self->addressFamily($addressFamily);
      $self->routeTag($routeTag);
      $self->address(inetNtoa($address));
      $self->subnetMask(inetNtoa($subnetMask));
      $self->nextHop(inetNtoa($nextHop));
      $self->metric($metric);

      $self->payload($payload);
   }

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return "RIP::v2";
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf;
   
   if ($self->addressFamily == NF_RIP_V2_ADDRESSFAMILY_AUTH) {
      $buf = sprintf
         "$l: addressFamily:0x%02x  authType:%d\n".
         "$l: authentication:%s",
            $self->addressFamily, $self->authType,
            $self->authentication;

   } else {
      $buf = sprintf
         "$l: addressFamily:%d  routeTag:%d\n".
         "$l: address:%s  subnetMask:%s  nextHop:%s\n".
         "$l: metric:%d",
            $self->addressFamily, $self->routeTag,
            $self->address, $self->subnetMask, $self->nextHop,
            $self->metric;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::RIP::v2 - Routing Information Protocol v2 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::RIP::v2 qw(:consts);

   my $ripv2 = Net::Frame::Layer::RIP::v2->new(
      addressFamily => NF_RIP_V2_ADDRESSFAMILY_IPV4,
      routeTag      => 0,
      address       => '0.0.0.0',
      subnetMask    => '0.0.0.0',
      nextHop       => '0.0.0.0',
      metric        => 1,
   );
   $ripv2->pack;

   print 'RAW: '.$ripv2->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::RIP::v2->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the RIP v2 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2453.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<addressFamily>

Address family.  See B<CONSTANTS> for more information.

=item B<routeTag>

Attribute assigned to a route for separating routes within RIP domain.

=item B<address>

Address information for route.

=item B<subnetMask>

Subnet mask for C<address>.

=item B<nextHop>

Next hop for C<address>.

=item B<metric>

Metric for C<address>.

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

=item B<full>

=item B<full> (hash)

Object constructor. Same as B<new> but with RIPv2 Request header, requests full routing table.  You can pass attributes that will overwrite default ones.  Default values:  all fields 0 with B<NF_RIP_V2_METRIC_INFINITY> set.

=item B<auth>

=item B<auth> (hash)

Object constructor. RIPv2 authentication entry.  Only need to set B<authentication>.

=over 4

=item B<addressFamily>

Authentication.  See B<CONSTANTS> for values.

=item B<authType>

Authentication type.  See B<CONSTANTS> for values.

=item B<authentication>

Authentication string.  (Max 16 characters).

=back

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

Load them: use Net::Frame::Layer::RIP::v2 qw(:consts);

=over 4

=item B<NF_RIP_V2_ADDRESSFAMILY_IPv4>

=item B<NF_RIP_V2_ADDRESSFAMILY_AUTH>

Address family.  Auth isn't really an address family, but indicates authentication.  If used, this must be the first Route Table Entry after the RIPv2 header.

=item B<NF_RIP_V2_AUTHTYPE_SIMPLE>

Authentication type.  Only Simple (cleartext password) currently supported.

=item B<NF_RIP_V2_METRIC_INFINITY>

Infinity metric (16).

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
