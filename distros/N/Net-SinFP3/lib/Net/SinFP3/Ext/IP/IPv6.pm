#
# $Id: IPv6.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Ext::IP::IPv6;
use strict;
use warnings;

use base qw(Net::SinFP3::Ext::IP);
our @AS = qw(
   global
   next
   _tcp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::TCP qw(:consts);

sub getResponseIpTtl {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv6}->hopLimit;
}

sub getResponseIpId {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv6}->flowLabel;
}

sub getResponseIpDfBit {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv6}->trafficClass;
}

sub getProbeIpId {
   my $self = shift;
   my ($response) = @_;
   return $response->ref->{IPv6}->flowLabel;
}

sub _getEthHeader {
   my $self = shift;
   return Net::Frame::Layer::ETH->new(
      type => NF_ETH_TYPE_IPv6,
      src  => $self->global->mac,
      dst  => $self->next->mac,
   );
}

sub _getIpv6Header {
   my $self = shift;
   return Net::Frame::Layer::IPv6->new(
      version      => 6,
      trafficClass => 0,
      flowLabel    => 0,
      nextHeader   => NF_IPv6_PROTOCOL_TCP,
      hopLimit     => 0xff,
      src          => $self->global->ip6,
      dst          => $self->next->ip,
   );
}

sub getP1 {
   my $self = shift;

   my $eth = $self->_getEthHeader;
   my $ip6 = $self->_getIpv6Header;
   my $tcp = $self->_tcp->_getP1Tcp;

   return Net::Frame::Simple->new(layers => [ $eth, $ip6, $tcp, ]);
}

sub getP2 {
   my $self = shift;

   my $eth = $self->_getEthHeader;
   my $ip6 = $self->_getIpv6Header;
   my $tcp = $self->_tcp->_getP2Tcp;

   return Net::Frame::Simple->new(layers => [ $eth, $ip6, $tcp, ]);
}

sub getP3 {
   my $self = shift;

   my $eth = $self->_getEthHeader;
   my $ip6 = $self->_getIpv6Header;
   my $tcp = $self->_tcp->_getP3Tcp;

   return Net::Frame::Simple->new(layers => [ $eth, $ip6, $tcp, ]);
}

1;

__END__

=head1 NAME

Net::SinFP3::Ext::IP::IPv6 - methods used when in IPv6 mode

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
