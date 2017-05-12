#!/usr/bin/perl
#
# $Id: nf-arpscan.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '1.00';

use Getopt::Std;
my %opts;
getopts('n:v', \%opts);

my $oWrite;
my $oDump;

die("Usage: $0\n".
    "\n".
    "   -n  network subnet\n".
    "   -v  be verbose\n".
    "") unless $opts{n};

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::ARP qw(:consts);
use Net::Frame::Simple;
use Net::Frame::Dump::Online;
use Net::Frame::Device;
use Net::Write::Layer2;
use Net::Netmask;

my $oNet = Net::Netmask->new2($opts{n}) or die("$Net::Netmask::errstr");
my @ipList = $oNet->enumerate;

my $oDevice = Net::Frame::Device->new(target => $ipList[1]);
if ($opts{v}) {
   print "Using device    : ".$oDevice->dev."\n";
   print "Using source MAC: ".$oDevice->mac."\n";
   print "Using source IP : ".$oDevice->ip."\n";
}

my @requestList;
for my $ip (@ipList) {
   my $eth = Net::Frame::Layer::ETH->new(
      type => NF_ETH_TYPE_ARP,
      src  => $oDevice->mac,
   );
   my $arp = Net::Frame::Layer::ARP->new(
      opCode => NF_ARP_OPCODE_REQUEST,
      srcIp => $oDevice->ip,
      dstIp => $ip,
      src   => $oDevice->mac,
   );
   my $request = Net::Frame::Simple->new(
      layers => [ $eth, $arp ],
   );
   push @requestList, $request;
}

$oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
$oWrite->open;

$oDump = Net::Frame::Dump::Online->new(
   dev    => $oDevice->dev,
   filter => 'arp',
);
$oDump->start;

my $reply;
for my $t (1..3) {
   for my $r (@requestList) {
      my $dstIp = $r->ref->{ARP}->dstIp;
      $oWrite->send($r->raw) unless exists $reply->{$dstIp};
   }
   until ($oDump->timeout) {
      if (my $h = $oDump->next) {
         my $r = Net::Frame::Simple->newFromDump($h);
         next unless $r->ref->{ARP}->opCode eq NF_ARP_OPCODE_REPLY;
         my $srcIp = $r->ref->{ARP}->srcIp;
         unless (exists $reply->{$srcIp}) {
            my $mac = $r->ref->{ARP}->src;
            print "> received $mac for $srcIp\n" if $opts{v};
            $reply->{$srcIp} = $r->ref->{ARP}->src;
         }
      }
   }
   $oDump->timeoutReset;
}

for (keys %$reply) {
   printf("%-16s => %s\n", $_, $reply->{$_});
}

END {
   $oWrite && $oWrite->close;
   $oDump  && $oDump->isRunning && $oDump->stop;
}

__END__

=head1 NAME

nf-arpscan - Net::Frame ARP Scan tool

=head1 SYNOPSIS

   # nf-arpscan.pl -n 192.168.0
   192.168.0.1      => 00:0c:29:aa:bb:cc
   192.168.0.69     => 00:13:d4:aa:bb:cc

=head1 DESCRIPTION

This tool will scan a specified C-class address space to find alive hosts (the ones who respond to ARP requests).

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
