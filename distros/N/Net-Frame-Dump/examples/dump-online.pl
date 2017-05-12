#!/usr/bin/perl
use strict;
use warnings;

my $oDump;
my $dev = shift || die("Specify network interface to use\n");

use Net::Frame::Dump::Online;
use Net::Frame::Simple;
use Class::Gomor qw($Debug);
$Debug = 3;


$oDump = Net::Frame::Dump::Online->new(dev => $dev);
$oDump->start;

my $count = 0;
while (1) {
   if (my $h = $oDump->next) {
      my $f = Net::Frame::Simple->new(
         raw        => $h->{raw},
         firstLayer => $h->{firstLayer},
         timestamp  => $h->{timestamp},
      );
      my $len = length($h->{raw});
      print 'o Frame number: '.$count++." (length: $len)\n";
      print $f->print."\n";
   }
}
