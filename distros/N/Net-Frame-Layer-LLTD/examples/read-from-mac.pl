#!/usr/bin/perl
use strict;
use warnings;

my $file = shift || die("Specify file to read\n");
my $mac  = shift || die("Specify source MAC address\n");

use Net::Frame::Simple;
use Net::Frame::Dump::Offline;

my $oDump = Net::Frame::Dump::Offline->new(
   file          => $file,
   keepTimestamp => 1,
);
$oDump->start;

while (my $next = $oDump->next) {
   my $oSimple = Net::Frame::Simple->newFromDump($next);
   my $eth = $oSimple->ref->{ETH};
   if ($eth && $eth->src eq lc($mac)) {
      my @ts = localtime($oSimple->timestamp);
      print "TIME: $ts[2]:$ts[1]:$ts[0]\n";
      print $oSimple->print."\n";
   }
}

$oDump->stop;
