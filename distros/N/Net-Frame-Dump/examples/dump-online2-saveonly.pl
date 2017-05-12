#!/usr/bin/perl
use strict;
use warnings;

my $oDump;
my $dev = shift || die("Specify network interface to use\n");

use Net::Frame::Dump::Online2;
use Net::Frame::Simple;
use Class::Gomor qw($Debug);
$Debug = 3;

$oDump = Net::Frame::Dump::Online2->new(
   dev       => $dev,
   file      => 'save-example-online2.pcap',
   overwrite => 1,
);
$oDump->start;

<>;
$oDump->stop;
