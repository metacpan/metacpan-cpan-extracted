#
# $Id: v1.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::RIP::v1;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_RIP_V1_ADDRESSFAMILY_IPV4
      NF_RIP_V1_METRIC_INFINITY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_RIP_V1_ADDRESSFAMILY_IPV4 => 2;
use constant NF_RIP_V1_METRIC_INFINITY    => 16;

our @AS = qw(
   addressFamily
   reserved1
   address
   reserved2
   reserved3
   metric
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      addressFamily => NF_RIP_V1_ADDRESSFAMILY_IPV4,
      reserved1     => 0,
      address       => '0.0.0.0',
      reserved2     => 0,
      reserved3     => 0,
      metric        => 1,
      @_,
   );
}

sub full {
   shift->SUPER::new(
      addressFamily => 0,
      reserved1     => 0,
      address       => '0.0.0.0',
      reserved2     => 0,
      reserved3     => 0,
      metric        => NF_RIP_V1_METRIC_INFINITY,
      @_,
   );
}

sub getLength { 20 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nna4NNN',
      $self->addressFamily,
      $self->reserved1,
      inetAton($self->address),
      $self->reserved2,
      $self->reserved3,
      $self->metric
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($addressFamily, $reserved1, $address, $reserved2, $reserved3, $metric, $payload) =
      $self->SUPER::unpack('nna4NNN a*', $self->raw)
         or return;

   $self->addressFamily($addressFamily);
   $self->reserved1($reserved1);
   $self->address(inetNtoa($address));
   $self->reserved2($reserved2);
   $self->reserved3($reserved3);
   $self->metric($metric);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return "RIP::v1";
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: addressFamily:%d  reserved1:%d\n".
      "$l: address:%s  reserved2:%d  reserved3:%d\n".
      "$l: metric:%d",
         $self->addressFamily, $self->reserved1,
         $self->address, $self->reserved2, $self->reserved3,
         $self->metric;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::RIP::v1 - Routing Information Protocol v1 layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::RIP::v1 qw(:consts);

   my $ripv1 = Net::Frame::Layer::RIP::v1->new(
      addressFamily => NF_RIP_V1_ADDRESSFAMILY_IPV4,
      reserved1     => 0,
      address       => '0.0.0.0',
      reserved2     => 0,
      reserved3     => 0,
      metric        => 1,
   );
   $ripv1->pack;

   print 'RAW: '.$ripv1->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::RIP::v1->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the RIP v1 layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc1058.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<addressFamily>

Address family.  See B<CONSTANTS> for more information.

=item B<reserved1>

Default set to 0.

=item B<address>

Address information for route.

=item B<reserved2>

Default set to 0.

=item B<reserved3>

Default set to 0.

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

Object constructor. Same as B<new> but with RIPv1 Request header, requests full routing table.  You can pass attributes that will overwrite default ones.  Default values:  all fields 0 with B<NF_RIP_V1_METRIC_INFINITY> set.

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

Load them: use Net::Frame::Layer::RIP::v1 qw(:consts);

=over 4

=item B<NF_RIP_V1_ADDRESSFAMILY_IPv4>

Address family.

=item B<NF_RIP_V1_METRIC_INFINITY>

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
