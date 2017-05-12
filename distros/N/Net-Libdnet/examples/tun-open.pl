#!/usr/bin/perl
use strict; use warnings;

use Net::Libdnet::Tun;

my $h = Net::Libdnet::Tun->new(src => "192.168.0.101", dst => "192.168.0.1");

my $buf = $h->recv;
#print unpack('H*', $buf)."\n";

use Net::Frame::Simple;

my $fr = Net::Frame::Simple->new(
   raw => $buf,
   firstLayer => 'IPv4',
);
$fr->unpack;
print $fr->print."\n";

my $ret = $h->send($buf);
print "RET: $ret\n";
