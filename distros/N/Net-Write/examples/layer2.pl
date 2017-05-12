#!/usr/bin/perl
#
# $Id: layer2.pl 1637 2009-06-10 18:38:50Z gomor $
#
use strict;
use warnings;

my $dev = shift || die("Specify a network interface as a parameter\n");

use Net::Write::Layer2;

my $l2 = Net::Write::Layer2->new(
   dev => $dev,
);

use Net::Packet::Consts qw(:eth);
use Net::Packet::ETH;

my $eth = Net::Packet::ETH->new(type => NP_ETH_TYPE_ARP);
$eth->pack;

print $eth->print."\n";

$l2->open;
$l2->send($eth->raw);
$l2->close;
