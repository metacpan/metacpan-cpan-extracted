#!/usr/bin/perl
#
# $Id: nf-trace.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '0.10';

my $target = shift || die("Specify target IPv4 address\n");
my $port   = shift || die("Specify target open port\n");
my $data   = shift || die("Specify application layer data to send\n");
my $proto  = shift || 'tcp';

use Net::Frame::Device;
use Net::Write::Layer3;
use IO::Socket;
use Net::Frame::Simple;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP qw(:consts);
use Net::Frame::Layer::UDP;
use Net::Frame::Dump::Online;

my $oDevice = Net::Frame::Device->new(target => $target);

my $oDump = getDump($oDevice, $target, $port)
   or die("Unable to open Dump object\n");

my $s = connectTo($target, $port, $proto)
   or die("Unable to connect()\n");

sendData($s, $data)
   or die("Unable to send data to target\n");

my $probeFrame = getProbeFrame($oDump, $oDevice, $target, $port)
   or die("Unable to get probe frame\n");

#
# Once we have the probe frame, we can build frames used to identify the 
# path to the target. Thanks to this probe frame, a state entry has been 
# created through the target, and our tracing frame should go unfiltered 
# to the target
#

my $result = tracePath($probeFrame, $oDevice, $oDump);
#sleep(10);

#use Data::Dumper;
#print Dumper($result)."\n";

END { $oDump && $oDump->isRunning && $oDump->stop }

#
# Subs
#

sub getDump {
   my ($oDevice, $target, $port) = @_;
   my $oDump = Net::Frame::Dump::Online->new(
      dev    => $oDevice->dev,
      filter =>
         "   (ip host @{[$oDevice->ip]} and port $port) ".
         "or (dst host @{[$oDevice->ip]} and icmp)",
      timeoutOnNext => 5,
      keepTimestamp => 1,
   );
   $oDump->start;
   $oDump;
}

sub connectTo {
   my ($target, $port, $proto) = @_;

   IO::Socket::INET->new(
      PeerAddr => "$target:$port",
      Proto    => $proto,
   ) or die("IO::Socket::INET::new: $!\n");
}

sub sendData {
   my ($s, $data) = @_;
   $s->send($data) or die("send: $!\n");
}

sub getProbeFrame {
   my ($oDump, $oDevice, $target, $port) = @_;
   my $probe;
   until ($oDump->timeout) {
      if (my $h = $oDump->next) {
         unless ($probe) {
            my $f   = Net::Frame::Simple->newFromDump($h);
            my $ip  = $f->ref->{IPv4};
            my $tcp = $f->ref->{TCP};
            if (($ip && $ip->dst eq $target
                     && $ip->src eq $oDevice->ip)
            &&  ($tcp && $tcp->dst eq $port && $tcp->payload)) {
               $probe = $f;
            }
         }
      }
   }
   $probe;
}

sub tracePath {
   my ($probe, $oDevice, $oDump) = @_;

   my $ip  = $probe->ref->{IPv4}->cgClone;
   my $tcp = $probe->ref->{TCP}->cgClone;

   my $baseTtl = $ip->id;
   print "Base TTL: $baseTtl\n";

   my $frames;
   for (1..17) {
      $ip->checksum(0);
      $ip->id($baseTtl + $_);
      $ip->ttl($_);
      my $send = Net::Frame::Simple->new(
         layers => [ $ip->cgClone, $tcp->cgClone, ],
      );
      $frames->{$_} = $send;
   }

   my $w = Net::Write::Layer3->new(dst => $probe->ref->{IPv4}->dst);
   $w->open;

   my $last;
   for (1..3) {
      print "Try number: $_\n";
      for my $thisId (sort { $a <=> $b } keys %$frames) {
         if ($last && $thisId > $last) {
            delete $frames->{$thisId};
            next;
         }
         my $this = $frames->{$thisId};

         unless ($this->reply) {
            $this->send($w);

            my $thisReply;

            $oDump->timeoutReset;
            until ($oDump->timeout) {
               if (my $h = $oDump->next) {
                  my $reply = Net::Frame::Simple->newFromDump($h);
                  if ($reply->timestamp > $this->timestamp) {
                     my $ip   = $reply->ref->{IPv4};
                     my $icmp = $reply->ref->{ICMPv4};
                     my $tcp  = $reply->ref->{TCP};
                     if ($icmp && $icmp->type == 11) {
                        for ($reply->layers) {
                           if ($_->layer eq 'IPv4') {
                              last if $_->dst ne $oDevice->ip;
                              my $hop = $ip->id - $baseTtl;
                              print "ICMP($hop): ".$_->src."\n";
                              $thisReply = $_->src;
                           }
                        }
                     }
                     elsif ($tcp && $ip->src eq $probe->ref->{IPv4}->dst) {
                        my $hop = $ip->id - $baseTtl;
                        print "TCP($hop): ".$reply->ref->{IPv4}->src."\n";
                        $thisReply = $reply->ref->{IPv4}->src;
                        $last = $hop;
                     }
                  }
               }
               if ($thisReply) {
                  $this->reply($thisReply);
                  last;
               }
            }
         }
      }
   }

   for (sort { $a <=> $b } keys %$frames) {
      if ($frames->{$_}->reply) {
         print "HOP($_): ".$frames->{$_}->reply."\n";
      }
      else {
         print "HOP($_): unknown\n";
      }
   }

   $w->close;
}

__END__

=head1 NAME

nf-trace - Net::Frame TCP traceroute tool

=head1 SYNOPSIS

   None for now.

=head1 DESCRIPTION

This tool tries to implement Michal Zalewski's 0trace.sh script.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
