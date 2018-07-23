#
# $Id: Active.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Mode::Active;
use strict;
use warnings;

use base qw(Net::SinFP3::Mode);
our @AS = qw(
   doP1
   doP2
   doP3
   p1
   p2
   p3
   s1
   s2
   s3
   _ip
   _tcp
   _dump
   _write
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Ext::S;
use Net::SinFP3::Ext::TCP;
use Net::SinFP3::Ext::IP::IPv4;
use Net::SinFP3::Ext::IP::IPv6;
use Net::SinFP3::Search;

use Net::Frame::Layer::TCP qw(:consts);

sub take {
   return [
      'Net::SinFP3::Next::IpPort',
      'Net::SinFP3::Next::Frame',
      'Net::SinFP3::Next::MultiFrame',
      'Net::SinFP3::Next::Active',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
      @_,
   );

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;

   # Initiliase PRNG (used to generate IPv4 ID and TCP SEQ/ACK/SRC port
   srand();

   $global->ipv6 ? $self->_ip(Net::SinFP3::Ext::IP::IPv6->new)
                 : $self->_ip(Net::SinFP3::Ext::IP::IPv4->new);

   $self->_tcp(Net::SinFP3::Ext::TCP->new);
   $self->_ip->_tcp($self->_tcp);

   $self->_ip->global($global);
   $self->_tcp->global($global);

   return 1;
}

sub _buildProbes {
   my $self = shift;
   $self->p1($self->_ip->getP1) if $self->doP1;
   $self->p2($self->_ip->getP2) if $self->doP2;
   $self->p3($self->_ip->getP3) if $self->doP3;
   return 1;
}

sub _sendVerbose {
   my $self = shift;
   my ($p) = @_;

   my $log = $self->global->log;

   my $tcp = $self->$p->ref->{TCP};
   my $ip  = exists $self->$p->ref->{IPv4}
      ? $self->$p->ref->{IPv4}
      : $self->$p->ref->{IPv6};
   $log->debug(
      "Probe ".uc($p)." sent: [".$ip->src."]:".$tcp->src." > [".
      $ip->dst."]:".$tcp->dst." size:".length($self->$p->raw)
   );
}

sub _sendProbes {
   my $self = shift;
   my $oWrite = $self->_write;
   if ($self->p1 && ! $self->p1->reply) {
      $self->p1->send($oWrite);
      $self->_sendVerbose('p1');
   }
   if ($self->p2 && ! $self->p2->reply) {
      $self->p2->send($oWrite);
      $self->_sendVerbose('p2');
   }
   if ($self->p3 && ! $self->p3->reply) {
      $self->p3->send($oWrite);
      $self->_sendVerbose('p3');
   }
   return 1;
}

sub _getVerbose {
   my $self = shift;
   my ($p) = @_;

   my $log = $self->global->log;

   my $tcp = $self->$p->reply->ref->{TCP};
   my $ip  = exists $self->$p->reply->ref->{IPv4}
      ? $self->$p->reply->ref->{IPv4}
      : $self->$p->reply->ref->{IPv6};
   $log->debug(
      "Response for ".uc($p)." received: ".$ip->src.":".$tcp->src." > ".
      $ip->dst.":".$tcp->dst." size:".length($self->$p->raw)
   );
}

sub _getResponses {
   my $self = shift;

   my $oDump = $self->_dump;
   my $log   = $self->global->log;

   if ($self->p1 && ! $self->p1->reply) {
      my $recv = $self->p1->_recv($oDump);
      if ($recv) {
         $self->p1->reply($recv);
         $self->_getVerbose('p1');
      }
   }
   if ($self->p2 && ! $self->p2->reply) {
      my $recv = $self->p2->_recv($oDump);
      if ($recv) {
         $self->p2->reply($recv);
         $self->_getVerbose('p2');
      }
   }
   if ($self->p3 && ! $self->p3->reply) {
      my $recv = $self->p3->_recv($oDump);
      if ($recv) {
         $self->p3->reply($recv);
         $self->_getVerbose('p3');
      }
   }
   return 1;
}

# With Connect input, the P2 probe is not our own, so timestamp is not
# built as we want. We rewrite it to be able to match.
sub _rewriteTcpOptions {
   my $self = shift;
   my ($o) = @_;

   if ($o =~ m/^(.*080a)(.{8})(.{8})(.*)/) {
      my $head = $1;
      my $a    = $2;
      my $b    = $3;
      my $tail = $4;
      #print "[*] DEBUG: toks: 1[$1] 2[$2] 3[$3] 4[$4]\n";
      # Some systems put timestamp values to 00. We keep it for
      # fingerprint matching
      if ($a !~ /00000000/ && $a !~ /44454144/) {
         $a = "........";
      }
      if ($b !~ /00000000/ && $b !~ /44454144/) {
         $b = "........";
      }
      $o = $head.$a.$b.$tail;
      #print "[*] DEBUG: toks: 1[$head] a[$a] b[$b] 4[$tail]\n";
      #print "[*] DEBUG: rewriteTcpOptions: [$o]\n";
   }

   return $o;
}

sub _getResponseSignature {
   my $self = shift;
   my ($p, $p2) = @_;

   my $global = $self->global;

   if (!$p || !$p->reply) {
      return Net::SinFP3::Ext::S->new;
   }

   my $b = $self->_ip->_analyzeBinary($p, $p2);
   my $f = $self->_tcp->_analyzeTcpFlags($p);
   my $w = $self->_tcp->_analyzeTcpWindow($p);
   my $o = $self->_tcp->_analyzeTcpOptions($p);

   # Specific for Connect input module
   if (ref($global->input) =~ /^Net::SinFP3::Input::Connect$/) {
      $o->[0] = $self->_rewriteTcpOptions($o->[0]);
   }

   # Specific for Next next object
   if (ref($global->next) =~ /^Net::SinFP3::Next::Frame$/) {
      $b = 'B.....';
   }

   return Net::SinFP3::Ext::S->new(
      B => $b,
      F => $f,
      W => $w,
      O => $o->[0],
      M => $o->[1],
      S => $o->[2],
      L => $o->[3],
   );
}

sub _analyzeResponses {
   my $self = shift;

   $self->doP1 && $self->s1($self->_getResponseSignature($self->p1));
   $self->doP2 && $self->s2($self->_getResponseSignature($self->p2));
   $self->doP3 && $self->s3($self->_getResponseSignature($self->p3, $self->p2));

   # Some systems do not respond to P1, but do for P2
   # We write a fake P1 response to be able to match
   if ($self->p2 && $self->p2->reply && $self->p1 && !$self->p1->reply) {
      $self->p1->reply($self->p1->cgClone);
   }

   return 1;
}

sub _allResponsesReceived {
   my $self = shift;
   if (($self->doP1 && $self->p1->reply || !$self->doP1)
   &&  ($self->doP2 && $self->p2->reply || !$self->doP2)
   &&  ($self->doP3 && $self->p3->reply || !$self->doP3)) {
      $self->global->log->verbose("All responses received");
      return 1;
   }
   return;
}

sub _getFilter {
   my $self = shift;

   my $global = $self->global;
   my $next   = $global->next;

   return $global->ipv6
      ? '(ip6 and host '.$next->ip.' and host '.$global->ip6.')'
      : 'host '.$next->ip.' and host '.$global->ip;
}

sub _runOnline {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   my $oDump = $global->getDumpOnline or return;
   $self->_dump($oDump);

   $self->_buildProbes;

   my $filter = $self->_getFilter;
   $filter .= ' and tcp and port '.$next->port.
              ' and (';
   my $putOr;
   if ($self->p1) {
      $filter .= 'port '.$self->p1->ref->{TCP}->src;
      $putOr++;
   }
   if ($self->p2) {
      $filter .= ' or ' if $putOr;
      $filter .= 'port '.$self->p2->ref->{TCP}->src;
      $putOr++;
   }
   if ($self->p3) {
      $filter .= ' or ' if $putOr;
      $filter .= 'port '.$self->p3->ref->{TCP}->src;
      $putOr++;
   }
   $filter .= ')';

   $oDump->filter($filter);
   $oDump->start or return;

   my $oWrite = $global->getWrite(
      dst => $next->ip,
   ) or return;
   $self->_write($oWrite);

   $oWrite->open or return;

   my $stop = 0;
   for (1..$global->retry) {
      $self->_sendProbes;

      until ($oDump->timeout) {
         if (my $h = $oDump->next) {
            $oDump->store(Net::Frame::Simple->newFromDump($h));
            $self->_getResponses;
         }

         if ($self->_allResponsesReceived) {
            $stop++;
            last;
         }
      }

      $oDump->timeoutReset;
      last if $stop;
   }

   $oWrite->close;

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   my $ref = ref($next);
   if ($ref =~ /^Net::SinFP3::Next::IpPort$/) {
      $self->_ip->next($next);
      $self->_tcp->next($next);
      $self->_runOnline;
      $self->_analyzeResponses;
   }
   elsif ($ref =~ /^Net::SinFP3::Next::Frame$/) {
      $self->_ip->next($next);
      $self->_tcp->next($next);
      $self->_runOfflineFrame;
      $self->_analyzeResponses;
   }
   elsif ($ref =~ /^Net::SinFP3::Next::MultiFrame$/) {
      $self->_ip->next($next);
      $self->_tcp->next($next);
      $self->_runOfflineMultiFrame;
      $self->_analyzeResponses;
   }
   elsif ($ref =~ /^Net::SinFP3::Next::Active$/) {
      $self->s1($next->s1);
      $self->s2($next->s2);
      $self->s3($next->s3);
   }
   else {
      $log->warning("Don't know what to do with Next object: [$ref]");
      return;
   }

   return 1;
}

# For offline analysis only: case Next::Frame
sub _runOfflineFrame {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   $self->p2($next->frame);
   $self->p2->reply($next->frame);

   return 1;
}

# For offline analysis only: case Next::MultiFrame
sub _runOfflineMultiFrame {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   $self->_rebuildProbes;
   if (!$self->p1 && !$self->p2 && !$self->p3) {
      $log->fatal("No IP".($global->ipv6 ? 'v6' : 'v4')." SinFP probes found");
   }
}

sub _getReply {
   my $self = shift;
   my ($f, $ip, $tcp, $p) = @_;

   if ($self->$p && !$self->$p->reply) {
      my $pIp  = $self->$p->ref->{IPv4} || $self->$p->ref->{IPv6};
      my $pTcp = $self->$p->ref->{TCP};
      if ($ip->src eq $pIp->dst && $tcp->src eq $pTcp->dst) {
         $self->$p->reply($f);
         return 1;
      }
   }

   return;
}

sub _getReplyFixed {
   my $self = shift;
   my ($f, $ip, $tcp, $p) = @_;

   if ($self->$p && !$self->$p->reply) {
      my $pIp  = $self->$p->ref->{IPv4} || $self->$p->ref->{IPv6};
      my $pTcp = $self->$p->ref->{TCP};
      # Here was the break. All frames have the same src IP address.
      # So we disable to src IP comparison.
      if ($ip->dst eq $pIp->dst && $tcp->src eq $pTcp->dst) {
         $self->$p->reply($f);
         return 1;
      }
   }

   return;
}

sub _rebuildProbes {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   # Lengths for IPv4
   my $p1IpLen1 = 58;
   my $p1IpLen2 = 54; # For backward compat with SinFP2
   my $p2IpLen  = 74;
   my $p3IpLen  = 54;
   # Lengths for IPv6
   if ($global->ipv6) {
      $p1IpLen1 = 78;
      $p1IpLen2 = 74; # For backward compat with SinFP2
      $p2IpLen  = 94;
      $p3IpLen  = 74;
   }

   my $myIp;
   for my $f ($next->frameList) {
      my $ip  = $f->ref->{IPv4} || $f->ref->{IPv6};
      my $tcp = $f->ref->{TCP};

      next unless $ip && $tcp;

      # The first packet in the pcap is considered to come from our IP
      $myIp ||= $ip->src;

      # Requests
      if (!$self->p1) {
         if ($ip->src eq $myIp
         &&  (length($f->raw) == $p1IpLen1 || length($f->raw) == $p1IpLen2)
         &&  $tcp->flags == 0x02) {
            $self->p1($f);
            #$log->debug("P1 found");
            next;
         }
      }
      if (!$self->p2) {
         if ($ip->src eq $myIp
         &&  length($f->raw) == $p2IpLen && $tcp->flags == 0x02) {
            $self->p2($f);
            #$log->debug("P2 found");
            next;
         }
      }
      if (!$self->p3) {
         if ($ip->src eq $myIp
         &&  length($f->raw) == $p3IpLen && $tcp->flags == 0x12) {
            $self->p3($f);
            #$log->debug("P3 found");
            next;
         }
      }

      # Replies
      if ($self->_getReply($f, $ip, $tcp, 'p1')) {
         #$log->debug("P1r found");
         next;
      }
      if ($self->_getReply($f, $ip, $tcp, 'p2')) {
         #$log->debug("P2r found");
         next;
      }
      if ($self->_getReply($f, $ip, $tcp, 'p3')) {
         #$log->debug("P3r found");
         next;
      }

      # We have all we need, so stop
      if ($self->p1 && $self->p1->reply
      &&  $self->p2 && $self->p2->reply
      &&  $self->p3 && $self->p3->reply) {
         last;
      }
   }

   # Some anon pcaps were broken somewhere in time. This is to handle them.
   # But I should rewrite those active pcaps.
   if (($self->p1 && !$self->p1->reply)
   &&  ($self->p2 && !$self->p2->reply)
   &&  ($self->p3 && !$self->p3->reply)) {
      for my $f ($next->frameList) {
         my $ip  = $f->ref->{IPv4} || $f->ref->{IPv6};
         my $tcp = $f->ref->{TCP};

         next unless $ip && $tcp;

         # Replies
         if ($self->_getReplyFixed($f, $ip, $tcp, 'p1')) {
            next;
         }
         if ($self->_getReplyFixed($f, $ip, $tcp, 'p2')) {
            next;
         }
         if ($self->_getReplyFixed($f, $ip, $tcp, 'p3')) {
            next;
         }

         # We have all we need, so stop
         if ($self->p1->reply && $self->p2->reply && $self->p3->reply) {
            last;
         }
      }
   }

   #$log->debug("P1: ".$self->p1->print) if $self->p1;
   #$log->debug("P2: ".$self->p2->print) if $self->p2;
   #$log->debug("P3: ".$self->p3->print) if $self->p3;
   #$log->debug("P1r: ".$self->p1->reply->print) if $self->p1->reply;
   #$log->debug("P2r: ".$self->p2->reply->print) if $self->p2->reply;
   #$log->debug("P3r: ".$self->p3->reply->print) if $self->p3->reply;

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Mode::Active - methods used when in active mode

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
