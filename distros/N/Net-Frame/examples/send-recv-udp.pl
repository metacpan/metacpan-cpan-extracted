#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Pass target as first param\n");
my $port   = shift || die("Pass port as second param\n");

use Net::Frame::Device;

use Net::Write::Layer3;
use Net::Frame::Simple;
use Net::Frame::Dump::Online;

use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP;

my $oDevice = Net::Frame::Device->new(target => $target);

my $ip4 = Net::Frame::Layer::IPv4->new(
   src => $oDevice->ip,
   dst => $target,
   protocol => NF_IPv4_PROTOCOL_UDP,
);
my $udp = Net::Frame::Layer::UDP->new(
   dst     => $port,
   payload => 'test',
);

my $oWrite = Net::Write::Layer3->new(dst => $target);

my $oDump = Net::Frame::Dump::Online->new(
   dev    => $oDevice->dev,
   filter => 'udp or icmp',
);
$oDump->start;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip4, $udp ],
);
$oWrite->open;
$oSimple->send($oWrite);
$oWrite->close;

until ($oDump->timeout) {
   if (my $recv = $oSimple->recv($oDump)) {
      print "RECV:\n".$recv->print."\n";
      last;
   }
}

$oDump->stop;
