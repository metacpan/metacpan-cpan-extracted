#!/usr/bin/perl
#
# $Id: nf-read.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '1.00';

use Getopt::Std;
my %opts;
getopts('f:F:', \%opts);

my $oDump;

die("Usage: $0\n".
    "\n".
    "   -f  file to read\n".
    "   -F  pcap filter to use\n".
    "") unless $opts{f};

use Net::Frame::Dump::Offline;
use Net::Frame::Simple;

$oDump = Net::Frame::Dump::Offline->new(file => $opts{f});
$oDump->filter($opts{F}) if $opts{F};

$oDump->start;

my $count = 0;
while (my $h = $oDump->next) {
   my $f = Net::Frame::Simple->newFromDump($h);
   my $len = length($h->{raw});
   my $ts  = $h->{timestamp};
   print 'o Frame number: '.++$count." (length: $len, timestamp: $ts)\n";
   print $f->print."\n";
}

END { $oDump && $oDump->isRunning && $oDump->stop }

__END__

=head1 NAME

nf-read - Net::Frame Read tool

=head1 SYNOPSIS

   # nf-read.pl -f some-llc-frames.pcap 
   *** Net::Frame::Layer::HPEXTLLC module not found.
   *** Either install it (if avail), or implement it.
   *** You can also send the pcap file to perl@gomor.org.
   o Frame number: 1 (length: 98, timestamp: 1175506804.783716)
   ETH: dst:09:00:09:aa:bb:cc  src:00:12:79:aa:bb:cc  length:84
   LLC: dsap:0x7c  ig:0  ssap:0x7c  cr:0  control:0x03
   LLC: payload:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA...
   o Frame number: 2 (length: 60, timestamp: 1175506804.789921)
   ETH: dst:01:80:c2:00:00:00  src:00:12:79:aa:bb:cc  length:38
   LLC: dsap:0x21  ig:0  ssap:0x21  cr:0  control:0x03
   STP: protocolIdentifier:0x0000  protocolVersionIdentifier:0
   STP: bpduType:0x00  bpduFlags:0x00
   STP: rootIdentifier:32768/00:12:79:aa:bb:cc  rootPathCost:0
   STP: bridgeIdentifier:32768/00:12:79:aa:bb:cc  portIdentifier:0x8003
   STP: messageAge:0  maxAge:20  helloTime:2  forwardDelay:15
   STP: payload:00000000000000
   Padding: 00
   *** Net::Frame::Layer::CDP module not found.
   *** Either install it (if avail), or implement it.
   *** You can also send the pcap file to perl@gomor.org.
   o Frame number: 3 (length: 154, timestamp: 1175506804.792671)
   ETH: dst:01:00:0c:cc:cc:cc  src:00:12:79:aa:bb:cc  length:140
   LLC: dsap:0x55  ig:0  ssap:0x55  cr:0  control:0x03
   LLC::SNAP: oui:0x00000c  pid:0x2000
   LLC::SNAP: payload:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA...

=head1 DESCRIPTION

This tool implements a twireshark/tethereal like program. It is able to decode all layers that Net::Frame supports at the time of writing.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
