#!/usr/bin/perl
use strict;
use warnings;

my $dev    = shift || die("Specify network interface to use\n");
my $target = shift || die("Specify target IPv6 address\n");
my $mac    = shift || die("Specify target MAC address\n");

use Net::Frame::Layer qw(:subs);
if ($target) {
   $target = getHostIpv6Addr($target) || die("Unable to resolve hostname\n");
}

use Net::Frame::Device;
use Net::Frame::Simple;
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::ICMPv6;
use Net::Frame::Layer::ICMPv6::Echo;

my $oDevice = Net::Frame::Device->new(dev => $dev);

my $eth = Net::Frame::Layer::ETH->new(
   src  => $oDevice->mac,
   dst  => $mac,
   type => NF_ETH_TYPE_IPv6,
);

my $ip = Net::Frame::Layer::IPv6->new(
   src => $oDevice->ip6,
   dst => $target,
   nextHeader => NF_IPv6_PROTOCOL_ICMPv6,
);

my $icmp = Net::Frame::Layer::ICMPv6->new;
my $echo = Net::Frame::Layer::ICMPv6::Echo->new(payload => 'test');

my $oSimple = Net::Frame::Simple->new(
   layers => [ $eth, $ip, $icmp, $echo, ],
);
print $oSimple->print."\n";

use Net::Write::Layer2;

use Net::Frame::Dump::Online;
my $oDump = Net::Frame::Dump::Online->new(
   dev    => $oDevice->dev,
   filter => 'icmp6',
);
$oDump->start;

my $oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
$oWrite->open;
$oWrite->send($oSimple->raw);
$oWrite->close;

while (1) {
   if (my $recv = $oSimple->recv($oDump)) {
      print 'RECV:'."\n".$recv->print."\n";
      last;
   }
}

END { $oDump && $oDump->isRunning && $oDump->stop }
