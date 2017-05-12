#
# $Id: SynScan.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::SynScan;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   fingerprint
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::IpPort;

use POSIX qw(:sys_wait_h ceil);
use Net::Frame::Dump::Online2;
use Net::Frame::Simple;
use Net::Write::Fast;
use Time::Interval;

sub give {
   return [
      'Net::SinFP3::Next::IpPort',
      'Net::SinFP3::Next::Frame',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      fingerprint => 0,
      nextList => [],
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   if (! defined($global->target)) {
      $log->fatal("You must provide a `target' attribute in Global object");
   }

   if (! defined($global->port)) {
      $log->fatal("You must provide a `port' attribute in Global object");
   }

   return $self;
}

sub _addToResult {
   my $self = shift;
   my ($f) = @_;

   my $global = $self->global;

   if ($self->fingerprint) {
      return Net::SinFP3::Next::Frame->new(
         global => $global,
         frame  => $f,
      );
   }
   else {
      my $eth = $f->ref->{ETH};
      my $ip  = $f->ref->{IPv4} || $f->ref->{IPv6};
      my $tcp = $f->ref->{TCP};

      my $res;
      if ($ip && $tcp) {
         $res = Net::SinFP3::Next::IpPort->new(
            global => $global,
            ip => $ip->src,
            port => $tcp->src,
         ) or return;
         if ($eth) {
            $res->mac($eth->src);
         }
         return $res;
      }
   }

   return;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   my $portList = $global->portList;
   my $portCount = $global->portCount;
   my $targetCount = $global->targetCount;
   my $targetList = $global->targetListAsInt;
   if ($global->ipv6) {
      $targetList = [ $global->targetIp ];
   }
  
   my $mask = $global->targetSubnet || $global->targetIp;

   # Prepare Dump object
   my $filter;
   if ($targetCount > 1) {
      if (!$global->ipv6) {
         $filter = '((tcp and dst host '.$global->ip.') or ('.
                   'icmp and dst host '.$global->ip.'))';
      }
      else {
         $filter = '((tcp and dst host '.$global->ip6.' and src host '.
                   $mask.') or (icmp6 and dst host '.$global->ip6.'))';
      }
   }
   else {
      if (!$global->ipv6) {
         $filter = '((tcp and dst host '.$global->ip.' and src host '.
                   $mask.') or (icmp and dst host '.$global->ip.'))';
      }
      else {
         $filter = '((tcp and dst host '.$global->ip6.' and src host '.
                   $mask.') or (icmp6 and dst host '.$global->ip6.'))';
      }
   }
   if ($global->targetSubnet) {
       $filter .= ' and src net '.$global->targetSubnet;
   }

   my $oDump = $global->getDumpOnline(
      filter => $filter,
   ) or return;
   $oDump->start or return;

   # Main SYN scan loop
   my $retry = $global->retry;
   my $pps = $global->pps;

   my $ipv6 = $global->ipv6;
   my $ip = $global->ip;
   my $ip6 = $global->ip6;

   my $seconds = ($retry * $portCount * $targetCount / $pps) + $global->timeout;
   $seconds =~ s/\.\d+$//;

   my $estim = Time::Interval::parseInterval(seconds => $seconds);
   $log->info(sprintf("Estimated running time: %d day(s) %d hour(s) ".
              "%d minute(s) %d second(s) for %d host(s)",
      $estim->{days},
      $estim->{hours},
      $estim->{minutes},
      $estim->{seconds},
      $targetCount,
   ));

   defined(my $pid = fork()) or $log->fatal("Can't fork() [$!]\n");
   if (! $pid) { # Son
      $log->debug("run send(): targets[$targetCount] ports[$portCount] ".
                  "packets[".($retry * $portCount * $targetCount)."]");

      if ($ipv6) {
         my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
            $ip6,
            $targetList,
            $portList,
            $pps,
            $retry,
            $ipv6,
            $log->level,  # display warnings or not
         );
         if ($r == 0) {
            $log->fatal(Net::Write::Fast::nwf_geterror());
         }
      }
      else {
         # We have to split by chunks of 500_000 elements, to avoid taking to
         # much memory in one row. And there is a SIGSEGV if we don't do so ;)
         my $nChunks = ceil($targetCount / 500_000);
         for my $n (0..$nChunks-1) {
            my $first = 500_000 * $n;
            my $last = 499_999 + (500_000 * $n);
            if ($last > ($targetCount - 1)) {
               $last = $targetCount - 1;
            }

            if ($nChunks > 1) {
               $log->info("Scanning chunk @{[$n+1]}/@{[($nChunks)]} ".
                          "($first-$last)");
            }

            my @this = @$targetList[$first..$last];
            my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
               $ipv6 ? $ip6 : $ip,
               \@this,
               $portList,
               $pps,
               $retry,
               $ipv6,
               $log->level,  # display warnings or not
            );
            if ($r == 0) {
               $log->error(Net::Write::Fast::nwf_geterror());
            }
         }
      }

      $log->debug("stop send()");
      exit(0);
   }
   # Parent
   my $start;
   my %skip = ();
   while (1) {
      if (my $f = $oDump->next) {
         my $s = Net::Frame::Simple->newFromDump($f);
         if ($s->ref->{TCP}) {
            my $ip  = $ipv6 ? $s->ref->{IPv6} : $s->ref->{IPv4};
            my $tcp = $s->ref->{TCP};
            # Skip ports which already had a reply
            if ($skip{$ip->src}{$tcp->src}) {
            }
            elsif ($tcp->flags == 0x12) { # SYN+ACK
               my $res = $self->_addToResult($s) or next;
               my @old = $self->nextList;
               $self->nextList([ @old, $res ]);
               $log->verbose("Found ".$res->print);
               $skip{$ip->src}{$tcp->src}++;
            }
            elsif ($tcp->flags == 0x14) { # RST+ACK
               $skip{$ip->src}{$tcp->src}++;
            }
         }
      }
      my $r = waitpid($pid, WNOHANG);
      # First time, if process stopped, it returns the $pid
      # Other times, if process stopped, it returns -1
      if ($r == $pid || $r == -1) {  # Process stopped
         if (! $start) {             # Start counting for the timeout
            $start = time();
         }
         # Check error code
         if (($r == $pid) && $?) {
            $log->fatal("Child returned: ".${^CHILD_ERROR_NATIVE});
         }
         # If stopped since $timeout seconds, we exit
         if (time() - $start > $global->timeout) {
            $log->debug("Process stopped since ".$global->timeout." second(s)");
            last;
         }
      }
   }

   $log->debug("Parent finished");

   # Cleanup before end of init()
   $oDump->stop;

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my @nextList = $self->nextList;
   my $next     = shift @nextList;
   $self->nextList(\@nextList);

   return $next;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::SynScan - TCP SYN scanning input method

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
