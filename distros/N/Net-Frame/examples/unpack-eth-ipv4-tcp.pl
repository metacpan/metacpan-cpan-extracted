#!/usr/bin/perl
use strict;
use warnings;

use Net::Frame::Simple;

my $raw = pack('H*', "ffffffffffff00000000000008004500001483d80000800600007f0000017f0000018e100000212c69e5000000006002ffff000000000204540b");

my $oSimple = Net::Frame::Simple->new(
   raw        => $raw,
   firstLayer => 'ETH',
);

print $oSimple->print."\n";
