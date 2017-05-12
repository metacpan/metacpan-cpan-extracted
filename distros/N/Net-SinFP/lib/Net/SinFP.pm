#
# $Id: SinFP.pm 2237 2015-02-15 17:04:07Z gomor $
#
package Net::SinFP;
use strict;
use warnings;

our $VERSION = '2.10';

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

our @AS = qw(
   verbose
   target
   file
   wait
   retry
   h2Match
   ipv6UseIpv4
   offline
   passive
   passiveFrame
   filter
   doP1
   doP2
   doP3
   pktP1
   pktP2
   pktP3
   sigP1
   sigP2
   sigP3
   ipv6
   keepFile
   db
   _dump
   _pIpId
   _pTcpSrc
   _pTcpSeq
   _pTcpAck
);
our @AA = qw(
   resultList
);
our @AO = qw(
   passiveMatchCallback
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

use Carp;
use Net::Packet::Env qw($Env);
require Net::Packet::Dump;
use Net::Packet::Consts qw(:tcp :dump);
use Net::Packet::Utils qw(getRandom16bitsInt getRandom32bitsInt);
require Net::SinFP::SinFP4;
require Net::SinFP::SinFP6;
require Net::SinFP::Search;

sub passiveMatchCallback {
   my $self = shift;
   @_ ? $self->[$Net::SinFP::__passiveMatchCallback] = shift
      : &{$self->[$Net::SinFP::__passiveMatchCallback]}();
}

sub new {
   my $self = shift->SUPER::new(
      verbose     => 0,
      doP1        => 1,
      doP2        => 1,
      doP3        => 1,
      wait        => 3,
      retry       => 3,
      h2Match     => 0,
      keepFile    => 0,
      offline     => 0,
      passive     => 0,
      ipv6        => 0,
      ipv6UseIpv4 => 0,
      resultList  => [],
      @_,
   );

   if (! $self->db) {
      confess("You MUST specify an open SinFP DB in `db' attribute\n");
   }

   $self->_pIpId  ($self->_getInitialIpId);
   $self->_pTcpSrc($self->_getInitialTcpSrc);
   $self->_pTcpSeq($self->_getInitialTcpSeq);
   $self->_pTcpAck($self->_getInitialTcpAck);

   $SIG{INT}  = sub { $self->_signalClean };
   $SIG{TERM} = sub { $self->_signalClean };

   $self->ipv6 ? bless($self, 'Net::SinFP::SinFP6')
               : bless($self, 'Net::SinFP::SinFP4');
}

sub _getInitialIpId {
   my $ipId = getRandom16bitsInt();
   $ipId += 666 unless $ipId > 0;
   $ipId;
}

sub _getInitialTcpSrc {
   my $tcpSrc = getRandom16bitsInt() - 3;
   $tcpSrc += 1025 unless $tcpSrc > 1024;
   $tcpSrc;
}

sub _getInitialTcpSeq {
   my $tcpSeq = getRandom32bitsInt() - 3;
   $tcpSeq += 666 unless $tcpSeq > 0;
   $tcpSeq;
}

sub _getInitialTcpAck {
   my $tcpAck = getRandom32bitsInt() - 3;
   $tcpAck += 666 unless $tcpAck > 0;
   $tcpAck;
}

sub getFilter {
   my $self = shift;
   $self->passive ? $self->_getFilterPassive : $self->_getFilterActive;
}

sub getFileName {
   my $self = shift;
   $self->passive ? $self->_getFileNamePassive : $self->_getFileNameActive;
}

sub _getDumpOnlineActive {
   my $self = shift;
   Net::Packet::Dump->new(
      file          => $self->file,
      unlinkOnClean => $self->keepFile ? 0 : 1,
      overwrite     => 1,
      timeoutOnNext => $self->wait,
   );
}

sub _getDumpOnlinePassive {
   my $self = shift;
   Net::Packet::Dump->new(
      file          => $self->file,
      unlinkOnClean => 0,
      overwrite     => 1,
      timeoutOnNext => 0,
      noStore       => 1,
   );
}

sub _getDumpOffline {
   my $self = shift;
   Net::Packet::Dump->new(
      file          => $self->file,
      overwrite     => 0,
      unlinkOnClean => 0,
      mode          => NP_DUMP_MODE_OFFLINE,
   );
}

sub getDump {
   my $self = shift;
   my $dump;
   if ($self->offline) {
      $dump = $self->_getDumpOffline;
   }
   else {
      $self->passive ? do { $dump = $self->_getDumpOnlinePassive }
                     : do { $dump = $self->_getDumpOnlineActive  };
   }
   $dump;
}

sub _passiveMatchPrepare {
   my $self = shift;
   my ($frame) = @_;
   $self->pktP1(undef);
   $self->pktP3(undef);
   $self->passiveFrame($frame);
   $self->pktP2($frame);
   $self->pktP2->reply($frame);
}

sub _passiveMatchClean {
   my $self = shift;
   $self->passiveFrame(undef);
   $self->pktP2->reply(undef);
   $self->pktP2(undef);
   $self->resultList([]);
}

sub _startOnlinePassive {
   my $self = shift;

   $self->file($self->getFileName);
   $self->_dump($self->getDump);

   my $filter = $self->getFilter;
   $self->filter ? $self->_dump->filter('('.$self->filter.') and '.$filter)
                 : $self->_dump->filter($filter);

   $self->_dump->start;

   while (1) {
      if (my $frame = $self->_dump->next) {
         $self->_passiveMatchPrepare($frame);
         $self->passiveMatchCallback;
         $self->_passiveMatchClean;
      }
   }
}

sub _startOfflinePassive {
   my $self = shift;

   $self->_dump($self->getDump);

   $self->_dump->filter($self->filter) if $self->filter;

   $self->_dump->start;
   $self->_dump->nextAll;
   croak("No frames captured\n") unless ($self->_dump->frames)[0];

   for my $frame ($self->_dump->frames) {
      if ($frame->l4 && $frame->l4->isTcp) {
         if ($frame->l4->flags == (NP_TCP_FLAG_SYN)
         ||  $frame->l4->flags == (NP_TCP_FLAG_SYN|NP_TCP_FLAG_ACK) ) {
            $self->_passiveMatchPrepare($frame);
            $self->passiveMatchCallback;
            $self->_passiveMatchClean;
         }
      }
   }

   $self->clean;
   exit(0);
}

sub _startOfflineActive {
   my $self = shift;

   $self->_dump($self->getDump);
   $self->_dump->start;
   $self->_dump->nextAll;
   croak("No frames captured\n") unless ($self->_dump->frames)[0];

   my $targetIp = ($self->_dump->frames)[0]->l3->dst;

   $self->getOfflineProbes($targetIp);
   croak("No SinFP probe found\n") if (! $self->pktP1 && ! $self->pktP2
                                                      && ! $self->pktP3);
   $self->getResponses;
}

sub _startOnlineActive {
   my $self = shift;

   $self->file($self->getFileName);
   $self->_dump($self->getDump);

   $self->buildProbes;

   my $filter = $self->getFilter;
   $filter .= ' and tcp and port '.$self->target->port.
              ' and (';
   my $putOr;
   if ($self->pktP1) {
      $filter .= 'port '.$self->pktP1->l4->src;
      $putOr++;
   }
   if ($self->pktP2) {
      $filter .= ' or ' if $putOr;
      $filter .= 'port '.$self->pktP2->l4->src;
      $putOr++;
   }
   if ($self->pktP3) {
      $filter .= ' or ' if $putOr;
      $filter .= 'port '.$self->pktP3->l4->src;
      $putOr++;
   }
   $filter .= ')';
   $self->_dump->filter($filter);

   $self->_dump->start;

   for (1..$self->retry) {
      $self->sendProbes;

      until ($self->_dump->timeout) {
         if ($self->_dump->next) {
            $self->getResponses;
         }

         return if $self->allResponsesReceived;
      }

      $self->_dump->timeoutReset;
   }
}

sub start {
   my $self = shift;

   if ($self->passive) {
      $self->doP1(0);
      $self->doP2(1);
      $self->doP3(0);
      $self->offline ? $self->_startOfflinePassive : $self->_startOnlinePassive;
   }
   else {
      $self->offline ? $self->_startOfflineActive : $self->_startOnlineActive;
   }
}

sub buildProbes {
   my $self = shift;
   $self->pktP1($self->getP1) if $self->doP1;
   $self->pktP2($self->getP2) if $self->doP2;
   $self->pktP3($self->getP3) if $self->doP3;
}

sub sendProbes {
   my $self = shift;
   $self->pktP1->send if ($self->pktP1 && ! $self->pktP1->reply);
   $self->pktP2->send if ($self->pktP2 && ! $self->pktP2->reply);
   $self->pktP3->send if ($self->pktP3 && ! $self->pktP3->reply);
}

sub getResponses {
   my $self = shift;
   $self->pktP1->recv if ($self->pktP1 && ! $self->pktP1->reply);
   $self->pktP2->recv if ($self->pktP2 && ! $self->pktP2->reply);
   $self->pktP3->recv if ($self->pktP3 && ! $self->pktP3->reply);
}

# This is to verify that RST packets are generated from the target with 
# the same TTL as a SYN|ACK packet. We accept a difference of 3 hops, but 
# if this is greater, we consider to not be the same generated TTL
# Example: SunOS 5.9 generates a TTL of 60 in a SYN|ACK from our probe,
#          but a TTL of 64 for a RST from our probe. So, $ttl = 0.
sub __analyzeIpTtl {
   my $self = shift;
   my ($p, $p2) = @_;
   return 1 if ! $p2 || ! $p2->reply;
   my $ttlSrc = $self->getResponseIpTtl($p2);
   my $ttlDst = $self->getResponseIpTtl($p);
   my $ttl = 1;
   $ttl = 0 if (($ttlSrc > $ttlDst) && ($ttlSrc - $ttlDst > 3));
   $ttl = 0 if (($ttlDst > $ttlSrc) && ($ttlDst - $ttlSrc > 3));
   $ttl;
}

sub __analyzeIpDfBit { shift->getResponseIpDfBit(shift()) ? '1' : '0' }

sub __analyzeIpIdPassive { shift->getResponseIpId(shift()) ? '1' : '0' }

sub __analyzeIpId {
   my $self = shift;
   my ($p) = @_;
   return $self->__analyzeIpIdPassive($p) if $self->passive;
   my $reqId = $self->getProbeIpId($p);
   my $repId = $self->getResponseIpId($p);
   my $flag  = 1;
   if    ($repId == 0)        { $flag = 0 }
   elsif ($repId == $reqId)   { $flag = 2 }
   elsif ($repId == ++$reqId) { $flag = 3 } # There is no reason for that, but
                                            # anyway, we have nothing to loose
   $flag;
}

sub __analyzeTcpSeqPassive { shift; shift->reply->l4->seq ? '1' : '0' }

sub __analyzeTcpSeq {
   my $self = shift;
   my ($p) = @_;
   return $self->__analyzeTcpSeqPassive($p) if $self->passive;
   my $reqAck = $p->l4->ack;
   my $repSeq = $p->reply->l4->seq;
   my $flag   = 1;
   if    ($repSeq == 0        ) { $flag = 0 }
   elsif ($repSeq == $reqAck  ) { $flag = 2 }
   elsif ($repSeq == ++$reqAck) { $flag = 3 }
   $flag;
}

sub __analyzeTcpAckPassive { shift; shift->reply->l4->ack ? '1' : '0' }

sub __analyzeTcpAck {
   my $self = shift;
   my ($p) = @_;
   return $self->__analyzeTcpAckPassive($p) if $self->passive;
   my $reqSeq = $p->l4->seq;
   my $repAck = $p->reply->l4->ack;
   my $flag   = 1;
   if    ($repAck == 0        ) { $flag = 0 }
   elsif ($repAck == $reqSeq  ) { $flag = 2 }
   elsif ($repAck == ++$reqSeq) { $flag = 3 }
   $flag;
}

sub _analyzeBinary {
   my $self = shift;
   my ($p, $p2) = @_;
   my $flagTtl = $self->__analyzeIpTtl($p, $p2);
   my $flagId  = $self->__analyzeIpId($p);
   my $flagDf  = $self->__analyzeIpDfBit($p);
   my $flagSeq = $self->__analyzeTcpSeq($p);
   my $flagAck = $self->__analyzeTcpAck($p);
   'B'.$flagTtl.$flagId.$flagDf.$flagSeq.$flagAck;
}

sub _analyzeTcpFlags {
   my $self = shift;
   my ($p) = @_;
   sprintf("F0x%02x", $p->reply->l4->flags);
}

sub _analyzeTcpWindow {
   my $self = shift;
   my ($p) = @_;
   'W'.$p->reply->l4->win;
}

sub _analyzeTcpOptionsAndMss {
   my $self = shift;
   my ($p) = @_;
   # Rewrite timestamp values, if > 0 overwrite with ffff, for each timestamp
   my $mss;
   my $opts;
   if ($opts = unpack('H*', $p->reply->l4->options)) {
      if ($opts =~ /080a(........)(........)/) {
         if ($1 && $1 !~ /44454144|00000000/) {
            $opts =~ s/(080a)........(........)/$1ffffffff$2/;
         }
         if ($2 && $2 !~ /44454144|00000000/) {
            $opts =~ s/(080a........)......../$1ffffffff/;
         }
      }
      # Move MSS value in its own field
      if ($opts =~ /0204(....)/) {
         if ($1) {
            $mss = sprintf("%d", hex($1));
            $opts =~ s/0204..../0204ffff/;
         }
      }
   }
   # bugfix: handling of padding vs payload. Should be corrected 
   # when using Net::Frame (Net::SinFP 3.x planned)
   # Ok, this is dirty hack.
   if ($p->reply->l3->isIpv4) {
      if ($p->reply->l3->length > 44 && $p->reply->l7) {
         $opts .= unpack('H*', $p->reply->l7->data);
      }
   }
   else {
      $opts .= unpack('H*', $p->reply->l7->data) if $p->reply->l7;
   }

   $opts = '0' unless $opts;
   $mss  = '0' unless $mss;
   [ 'O'.$opts, 'M'.$mss ];
}

sub getResponseSignature {
   my $self = shift;
   my ($p, $p2) = @_;
   return { B => 'B00000', F => 'F0', W => 'W0', O => 'O0', M => 'M0' }
      if (! $p || ! $p->reply);
   my $b  = $self->_analyzeBinary($p, $p2);
   my $f  = $self->_analyzeTcpFlags($p);
   my $w  = $self->_analyzeTcpWindow($p);
   my $om = $self->_analyzeTcpOptionsAndMss($p);
   my $o = $om->[0];
   my $m = $om->[1];
   { B => $b, F => $f, W => $w, O => $o, M => $m };
}

sub _passiveMatchUpdate {
   my $self = shift;
   $self->pktP2->reply->l4->flags(NP_TCP_FLAG_SYN|NP_TCP_FLAG_ACK);
   $self->pktP2->reply->l4->pack;
}

sub analyzeResponses {
   my $self = shift;

   # Rewrite TCP flags to be SinFP DB compliant
   $self->_passiveMatchUpdate if $self->passive;

   $self->sigP1($self->getResponseSignature($self->pktP1))
      if $self->doP1;
   $self->sigP2($self->getResponseSignature($self->pktP2))
      if $self->doP2;
   $self->sigP3($self->getResponseSignature($self->pktP3, $self->pktP2))
      if $self->doP3;

   # Some systems do not respond to P1, but do for P2
   # We write a fake P1 response to be able to match
   if ($self->pktP2 && $self->pktP2->reply
   &&  $self->pktP1 && ! $self->pktP1->reply) {
      $self->pktP1->reply($self->pktP1->cgClone);
      $self->sigP1({B => 'B00000', F => 'F0', W => 'W0', O => 'O0', M => 'M0'});
   }
}

sub allResponsesReceived {
   my $self = shift;
   if ((! $self->pktP1 || $self->pktP1->reply)
   &&  (! $self->pktP2 || $self->pktP2->reply)
   &&  (! $self->pktP3 || $self->pktP3->reply)) {
      return 1;
   }
   return undef;
}

sub matchOsfps {
   my $self = shift;
   my ($userMaskList) = @_;

   # Deactivate match only with P2 unless explicitely asked for
   my $doP2 = $self->doP1 ? 0 : 1;

   my $se = Net::SinFP::Search->new(
      db               => $self->db,
      useAdvancedMasks => $self->h2Match ? 1 : 0,
      maskUserList     => $userMaskList ? $userMaskList : [],
      ipv6             => $self->ipv6 ? 1 : 0,
      enableP2Match    => $doP2 ? 1 : 0,
   );
   $se->sigP1($self->sigP1) if $self->pktP1 && $self->pktP1->reply;
   $se->sigP2($self->sigP2) if $self->pktP2 && $self->pktP2->reply;
   $se->sigP3($self->sigP3) if $self->pktP3 && $self->pktP3->reply;

   if (my $result = $se->search) {
      $self->resultList($result);
   }

   if ($self->ipv6 && $self->ipv6UseIpv4 && ! $self->found) {
      my $se2 = Net::SinFP::Search->new(
         db               => $self->db,
         useAdvancedMasks => $self->h2Match ? 1 : 0,
         maskUserList     => $userMaskList ? $userMaskList : [],
         ipv6             => 0,
         enableP2Match    => $doP2 ? 1 : 0,
      );
      $se2->sigP1($self->sigP1) if $self->pktP1 && $self->pktP1->reply;
      $se2->sigP2($self->sigP2) if $self->pktP2 && $self->pktP2->reply;
      $se2->sigP3($self->sigP3) if $self->pktP3 && $self->pktP3->reply;

      # We reload with IPv4 signatures
      $se->db->ipv6(0);
      $se->db->loadSignatures;

      if (my $result = $se2->search) {
         $self->resultList($result);
      }
   }

   $self->found;
}

sub found { scalar shift->resultList }

sub _sigPAsString {
   my $self = shift;
   my ($p) = @_;
   my $sig = $self->$p;
   return 'B00000 F0 W0 O0 M0' unless $sig;
   join(' ', $sig->{B}, $sig->{F}, $sig->{W}, $sig->{O}, $sig->{M});
}
sub sigP1AsString { shift->_sigPAsString('sigP1') }
sub sigP2AsString { shift->_sigPAsString('sigP2') }
sub sigP3AsString { shift->_sigPAsString('sigP3') }

sub clean {
   my $self = shift;
   if ($self->_dump) {
      $self->_dump->stop;
      $self->_dump->clean;
      $self->_dump(undef);
      $Env->dump(undef);
   }
   return(0);
}

sub _signalClean {
   my $self = shift;
   $self->clean;
   exit(0);
}

1;

=head1 NAME

Net::SinFP - a full operating system stack fingerprinting suite

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
