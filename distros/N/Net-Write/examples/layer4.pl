#!/usr/bin/perl
#
# $Id: layer4.pl 1636 2009-06-10 18:38:24Z gomor $
#
use strict;
use warnings;

my $target = shift || die("Specify an IPv4 address as a parameter\n");

use Net::Write::Layer qw(:constants);
use Net::Write::Layer4;

my $l4 = Net::Write::Layer4->new(
   dst      => $target,
   protocol => NW_IPPROTO_TCP,
   family   => NW_AF_INET,
);

use Net::Packet::TCP;
my $tcp = Net::Packet::TCP->new;
$tcp->pack;

print $tcp->print."\n";

$l4->open;
$l4->send($tcp->raw);
$l4->close;
