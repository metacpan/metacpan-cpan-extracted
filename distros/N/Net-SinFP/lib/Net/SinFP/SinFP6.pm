#
# $Id: SinFP6.pm 2236 2015-02-15 17:03:25Z gomor $
#
package Net::SinFP::SinFP6;
use strict;
use warnings;

require Net::SinFP;
our @ISA = qw(Net::SinFP);
__PACKAGE__->cgBuildIndices;

require Net::Packet::Frame;
require Net::Packet::IPv6;
require Net::Packet::TCP;
require Net::Packet::ETH;
use Net::Packet::Consts qw(:tcp :ipv6 :eth);
use Net::Packet::Env qw($Env);

sub getIpVersion { 'IPv6' }

sub _getFilterPassive {
   '(ip6 and tcp and '.
   '((tcp[tcpflags] & tcp-syn != 0) and'.
   ' (tcp[tcpflags] & tcp-ack != 0)) or'.
   ' (tcp[tcpflags] & tcp-syn != 0))'.
   ' and (not src host '.$Env->ip6.')';
}

sub _getFilterActive {
   my $self = shift;
   '(ip6 and host '.$self->target->ip6.' and host '.$Env->ip6.')';
}

sub _getFileNamePassive { 'sinfp6-passive.pcap' }

sub _getFileNameActive {
   my $self = shift;
   'sinfp6-'.$self->target->ip6.'.'.$self->target->port.'.pcap';
}

sub getOfflineProbes {
   my $self = shift;
   my ($targetIp) = @_;

   for ($self->_dump->frames) {
      next unless $_->isIpv6 && $_->isTcp;

      if ($self->doP1
      &&  length($_->raw) == 74 && $_->l4->haveFlagSyn && ! $_->l4->haveFlagAck
      &&  ! $self->pktP1) {
         $self->pktP1($_);
         next;
      }  

      if ($self->doP2
      &&  length($_->raw) == 94 && $_->l4->haveFlagSyn && ! $_->l4->haveFlagAck
      &&  ! $self->pktP2) {
         $self->pktP2($_);
         next;
      }

      if ($self->doP3
      &&  length($_->raw) == 74 && $_->l4->haveFlagSyn && $_->l4->haveFlagAck
      &&  ! $self->pktP3) {
         $self->pktP3($_);
         next;
      }
   }
}

sub getResponseIpTtl   { shift; shift->reply->l3->hopLimit     }
sub getResponseIpId    { shift; shift->reply->l3->flowLabel    }
sub getResponseIpDfBit { shift; shift->reply->l3->trafficClass }

sub getProbeIpId { shift; shift->l3->flowLabel }

sub getP1 {
   my $self = shift;

   my $eth = Net::Packet::ETH->new(
      type => NP_ETH_TYPE_IPv6,
      dst  => $self->target->mac,
   );

   my $ip6 = Net::Packet::IPv6->new(
      version      => 6,
      trafficClass => 0,
      flowLabel    => 0,
      nextHeader   => NP_IPv6_PROTOCOL_TCP,
      hopLimit     => 0xff,
      dst          => $self->target->ip6,
   );

   my $tcp = Net::Packet::TCP->new(
      src   => $self->_pTcpSrc,
      seq   => $self->_pTcpSeq,
      ack   => $self->_pTcpAck,
      dst   => $self->target->port,
      x2    => 0,
      flags => NP_TCP_FLAG_SYN,
      win   => 5840,
   );

   Net::Packet::Frame->new(l2 => $eth, l3 => $ip6, l4 => $tcp)
}

sub getP2 {
   my $self = shift;

   my $eth = Net::Packet::ETH->new(
      type => NP_ETH_TYPE_IPv6,
      dst  => $self->target->mac,
   );

   my $ip6 = Net::Packet::IPv6->new(
      version      => 6,
      trafficClass => 0,
      flowLabel    => 0,
      nextHeader   => NP_IPv6_PROTOCOL_TCP,
      hopLimit     => 0xff,
      dst          => $self->target->ip6,
   );

   my $tcp = Net::Packet::TCP->new(
      src     => $self->_pTcpSrc + 1,
      seq     => $self->_pTcpSeq + 1,
      ack     => $self->_pTcpAck + 1,
      dst     => $self->target->port,
      x2      => 0,
      flags   => NP_TCP_FLAG_SYN,
      win     => 5840,
      options =>
         "\x02\x04\x05\xb4".
         "\x08\x0a\x44\x45".
         "\x41\x44\x00\x00".
         "\x00\x00\x03\x03".
         "\x01\x04\x02\x00".
         "",
   );

   Net::Packet::Frame->new(l2 => $eth, l3 => $ip6, l4 => $tcp)
}

sub getP3 {
   my $self = shift;

   my $eth = Net::Packet::ETH->new(
      type => NP_ETH_TYPE_IPv6,
      dst  => $self->target->mac,
   );

   my $ip6 = Net::Packet::IPv6->new(
      version      => 6,
      trafficClass => 0,
      flowLabel    => 0,
      nextHeader   => NP_IPv6_PROTOCOL_TCP,
      hopLimit     => 0xff,
      dst          => $self->target->ip6,
   );

   my $tcp = Net::Packet::TCP->new(
      src   => $self->_pTcpSrc + 2,
      seq   => $self->_pTcpSeq + 2,
      ack   => $self->_pTcpAck + 2,
      dst   => $self->target->port,
      x2    => 0,
      flags => NP_TCP_FLAG_SYN | NP_TCP_FLAG_ACK,
      win   => 5840,
   );

   Net::Packet::Frame->new(l2 => $eth, l3 => $ip6, l4 => $tcp)
}

1;

=head1 NAME

Net::SinFP::SinFP6 - IPv6 operating system fingerprinting

=head1 DESCRIPTION

Go to http://www.gomor.org/sinfp to know more.

=cut

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
