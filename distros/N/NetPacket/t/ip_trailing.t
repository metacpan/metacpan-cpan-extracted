#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 2;
#use Data::Dumper;

use_ok 'NetPacket::IP';

my $raw_packet = <<PACKET; # hex-encoded

45 10
00 2d d1 8a 00 00 31 06 fc 28 40 e9 b9 13 c0 a8  
01 63 00 50 d8 7b 65 a4 13 f8 6d 4d 81 b7 50 19  
3e 2d 30 0a 00 00 30 0d 0a 0d 0a 15              

PACKET

# Convert the above dump to the original Ethernet frame
$raw_packet =~ s!^\d{4}!!mg;
$raw_packet =~ s!\s!!g;
$raw_packet =~ s!([a-f0-9]{2})!chr hex $1!eg;

my $ip = NetPacket::IP->decode($raw_packet);
#warn Dumper $ip;

is length $ip->{data}, $ip->{len}- $ip->{hlen}*4;
