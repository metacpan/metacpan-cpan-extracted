#!/usr/bin/perl
use strict;
use warnings;

my $oDump;
my $target = shift || die("Specify target\n");

use Net::Write::Layer2;
use Net::Frame::Device;
use Net::Frame::Simple;
use Net::Frame::Dump::Online;

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::ARP;

my $oDevice = Net::Frame::Device->new(target => $target);

my $eth = Net::Frame::Layer::ETH->new(
   src  => $oDevice->mac,
   type => NF_ETH_TYPE_ARP,
);
my $arp = Net::Frame::Layer::ARP->new(
   src   => $oDevice->mac,
   srcIp => $oDevice->ip,
   dstIp => $target,
);

my $oWrite = Net::Write::Layer2->new(
   dev => $oDevice->dev,
);

$oDump = Net::Frame::Dump::Online->new(
   dev => $oDevice->dev,
);
$oDump->start;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $arp ],
);
$oWrite->open;
$oSimple->send($oWrite);
$oWrite->close;

until ($oDump->timeout) {
   if (my $recv = $oSimple->recv($oDump)) {
      print $recv->print."\n";
      last;
   }
}

END { $oDump && $oDump->isRunning && $oDump->stop }
