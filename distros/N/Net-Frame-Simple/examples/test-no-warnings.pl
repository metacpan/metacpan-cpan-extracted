#!/usr/bin/perl
use strict;
use warnings;

my $src    = '192.168.0.10';
my $target = '192.168.0.1';
my $port   = 22;

use Net::Frame::Simple qw($NoUnableToUnpackWarnings $NoModuleNotFoundWarnings);
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;

$NoUnableToUnpackWarnings = 1;
$NoModuleNotFoundWarnings = 1;

my $ip4 = Net::Frame::Layer::IPv4->new(
   src => $src,
   dst => $target,
   protocol => 0x02,
);
my $tcp = Net::Frame::Layer::TCP->new(
   dst     => $port,
   options => "\x02\x04\x54\x0b",
   payload => 'test',
);

my $oSimple = Net::Frame::Simple->new(
   layers => [ $ip4, $tcp ],
);

my $raw = $oSimple->pack;

# Should print unable to unpack when var set to 0 (default)
my $new1 = Net::Frame::Simple->new(
   raw => $raw,
);

# Should print not able to load module var set to 0 (default)
my $new2 = Net::Frame::Simple->new(
   raw => $raw,
   firstLayer => 'IPv4',
);

print $new2->print."\n";
print $new2->dump."\n";
