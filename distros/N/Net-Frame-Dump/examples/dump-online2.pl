#!/usr/bin/perl
use strict;
use warnings;

my $dev    = shift || die("Specify network interface to use\n");
my $filter = shift;

my $oDump;

use Net::Frame::Dump::Online2;
use Net::Frame::Simple;
use Class::Gomor qw($Debug);
$Debug = 3;

$oDump = Net::Frame::Dump::Online2->new(
   dev    => $dev,
   filter => $filter ? $filter : '',
);
$oDump->start;

while (1) {
   if (my $f = $oDump->next) {
      my $raw            = $f->{raw};
      my $firstLayerType = $f->{firstLayer};
      my $timestamp      = $f->{timestamp};
      print "Received at: $timestamp\n";
      my $frame = Net::Frame::Simple->newFromDump($f);
      print $frame->print."\n";
   }

   if ($oDump->timeout) {
      print "Timeout occured, end of capture\n";
      last;
   }
}
