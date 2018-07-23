#
# $Id: IPv4.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Ext::IP::IPv4;
use strict;
use warnings;

use base qw(Net::SinFP3::Ext::IP);
our @AS = qw(
   global
   next
   _ipid
   _tcp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::TCP qw(:consts);

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $ipid = $self->_getInitial16bits;
   $self->_ipid($ipid);

   return $self;
}

sub _getInitial16bits {
   my $self = shift;
   my $i16 = getRandom16bitsInt();
   $i16 += 666 unless $i16 > 0;
   return $i16;
}

sub getResponseIpTtl {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv4}->ttl;
}

sub getResponseIpId {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv4}->id;
}

sub getResponseIpDfBit {
   my $self = shift;
   my ($response) = @_;
   return $response->reply->ref->{IPv4}->flags & NF_IPv4_DONT_FRAGMENT;
}

sub getProbeIpId {
   my $self = shift;
   my ($response) = @_;
   return $response->ref->{IPv4}->id;
}

sub _getIpv4Header {
   my $self = shift;
   my ($id) = @_;
   return Net::Frame::Layer::IPv4->new(
      tos      => 0,
      id       => $id,
      flags    => 0,
      offset   => 0,
      ttl      => 255,
      protocol => NF_IPv4_PROTOCOL_TCP,
      src      => $self->global->ip,
      dst      => $self->next->ip,
   );
}

sub getP1 {
   my $self = shift;
   my $ip4 = $self->_getIpv4Header($self->_ipid);
   my $tcp = $self->_tcp->_getP1Tcp;
   return Net::Frame::Simple->new(layers => [ $ip4, $tcp, ]);
}

sub getP2 {
   my $self = shift;
   my $ip4 = $self->_getIpv4Header($self->_ipid + 1);
   my $tcp = $self->_tcp->_getP2Tcp;
   return Net::Frame::Simple->new(layers => [ $ip4, $tcp, ]);
}

sub getP3 {
   my $self = shift;
   my $ip4 = $self->_getIpv4Header($self->_ipid + 2);
   my $tcp = $self->_tcp->_getP3Tcp;
   return Net::Frame::Simple->new(layers => [ $ip4, $tcp, ]);
}

1;

__END__

=head1 NAME

Net::SinFP3::Ext::IP::IPv4 - methods used when in IPv4 mode

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
