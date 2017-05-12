#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Layer::IPv4;
use Net::Frame::Dump::Writer;
use Net::Frame::Simple;

my $oDump = Net::Frame::Dump::Writer->new(
   file      => 'new-file.pcap',
   overwrite => 1,
);

$oDump->start;

for (0..255) {
   my $ip = Net::Frame::Layer::IPv4->new(
      length   => 1480,
      protocol => $_,
   );
   $ip->pack;
   my $raw = pack('H*', 'f'x1000);
   $oDump->write({ timestamp => '10.10', raw => $ip->raw.$raw });
}

END { $oDump && $oDump->isRunning && $oDump->stop }
