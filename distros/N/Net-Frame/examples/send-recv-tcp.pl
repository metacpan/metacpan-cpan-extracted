#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Pass target as first param\n");
my $port   = shift || die("Pass port as second param\n");

use Net::Frame::Device;

use Net::Write::Layer3;
use Net::Frame::Simple;
use Net::Frame::Dump::Online;

use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;

my $oDevice = Net::Frame::Device->new(target => $target);

my $ip4 = Net::Frame::Layer::IPv4->new(
   src => $oDevice->ip,
   dst => $target,
);
my $tcp = Net::Frame::Layer::TCP->new(
   dst     => $port,
   options => "\x02\x04\x54\x0b",
   payload => 'test',
);

my $oWrite = Net::Write::Layer3->new(dst => $target);

my $oDump = Net::Frame::Dump::Online->new(dev => $oDevice->dev);
$oDump->start;

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip4, $tcp ],
);
print "raw: ".unpack('H*', $oSimple->raw)."\n";
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
