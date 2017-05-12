#!/usr/bin/perl
#
# $Id: layer3.pl 2011 2015-02-15 17:07:47Z gomor $
#
use strict;
use warnings;

my $target = shift || die("Specify an IPv4 address as a parameter\n");
# We choose a different source IP than 127.0.0.1
# Under Mac OS, we won't be able to correctly send frame otherwise.
(my $src = $target) =~ s/^\d+(\..*)$/2$1/;

use Net::Write::Layer3;

my $l3 = Net::Write::Layer3->new(
   dst => $target,
);

use Net::Frame::Simple;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;

my $ip4 = Net::Frame::Layer::IPv4->new(
   src => $src,
   dst => $target,
);
my $tcp = Net::Frame::Layer::TCP->new(
   dst => 11,  # Easier for pcap filtering
   options => "\x02\x04\x54\x0b",
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip4, $tcp ],
);

print $oSimple->print."\n";
print unpack('H*', $oSimple->raw)."\n";

$l3->open;
$l3->send($oSimple->raw);
$l3->close;
