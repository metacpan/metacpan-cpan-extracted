#!/usr/bin/perl
use strict;
use warnings;

my $oDump;
my $dev = shift || die("Specify network interface to use\n");

use Net::Frame::Dump::Online;
use Net::Frame::Simple;

sub callOnRecv {
   my ($h, $data) = @_;
   print "Data: $data\n";
   my $oSimple = Net::Frame::Simple->newFromDump($h);
   print $oSimple->print."\n";
}

$oDump = Net::Frame::Dump::Online->new(
   dev         => $dev,
   onRecv      => \&callOnRecv,
   onRecvCount => 1,
   onRecvData  => 'test',
);

$oDump->start;

END { $oDump && $oDump->isRunning && $oDump->stop }
