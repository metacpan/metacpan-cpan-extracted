#!/usr/bin/perl
use strict;
use warnings;

my $oDump;
my $file = shift || die("Specify file\n");

use Net::Frame::Dump::Offline;
use Net::Frame::Simple;

$oDump = Net::Frame::Dump::Offline->new(file => $file);
$oDump->start;

my $count = 0;
while (my $h = $oDump->next) {
   my $f = Net::Frame::Simple->new(
      raw        => $h->{raw},
      firstLayer => $h->{firstLayer},
      timestamp  => $h->{timestamp},
   );
   my $len = length($h->{raw});
   print 'o Frame number: '.$count++." (length: $len)\n";
   print $f->print."\n";
}

END { $oDump && $oDump->isRunning && $oDump->stop }
