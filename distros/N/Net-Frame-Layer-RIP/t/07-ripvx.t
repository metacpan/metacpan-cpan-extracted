use Test;
BEGIN { plan(tests => 14) }

use strict;
use warnings;

use Net::Frame::Layer::RIP qw(:consts);

my ($rip, $expectedOutput);

# RIPv1 new
$rip = Net::Frame::Layer::RIP::v1->new;
$expectedOutput = 'RIP::v1: addressFamily:2  reserved1:0
RIP::v1: address:0.0.0.0  reserved2:0  reserved3:0
RIP::v1: metric:1';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = '0002000000000000000000000000000000000001';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv1 full
$rip = Net::Frame::Layer::RIP::v1->full;
$expectedOutput = 'RIP::v1: addressFamily:0  reserved1:0
RIP::v1: address:0.0.0.0  reserved2:0  reserved3:0
RIP::v1: metric:16';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = '0000000000000000000000000000000000000010';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv2 new
$rip = Net::Frame::Layer::RIP::v2->new;
$expectedOutput = 'RIP::v2: addressFamily:2  routeTag:0
RIP::v2: address:0.0.0.0  subnetMask:0.0.0.0  nextHop:0.0.0.0
RIP::v2: metric:1';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = '0002000000000000000000000000000000000001';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv2 full
$rip = Net::Frame::Layer::RIP::v2->full;
$expectedOutput = 'RIP::v2: addressFamily:0  routeTag:0
RIP::v2: address:0.0.0.0  subnetMask:0.0.0.0  nextHop:0.0.0.0
RIP::v2: metric:16';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = '0000000000000000000000000000000000000010';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv2 auth
$rip = Net::Frame::Layer::RIP::v2->auth;
$expectedOutput = 'RIP::v2: addressFamily:0xffff  authType:2
RIP::v2: authentication:';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = 'ffff000200000000000000000000000000000000';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv2 auth too short
$rip = Net::Frame::Layer::RIP::v2->auth(authentication=>"ThisIsIt");
$expectedOutput = 'RIP::v2: addressFamily:0xffff  authType:2
RIP::v2: authentication:ThisIsIt';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = 'ffff000254686973497349740000000000000000';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

# RIPv2 auth too long
$rip = Net::Frame::Layer::RIP::v2->auth(authentication=>"ThisIsTooLongSoLetsSee");
$expectedOutput = 'RIP::v2: addressFamily:0xffff  authType:2
RIP::v2: authentication:ThisIsTooLongSoL';
print $rip->print . "\n";
ok($rip->print, $expectedOutput);

$expectedOutput = 'ffff0002546869734973546f6f4c6f6e67536f4c';
print unpack "H*", $rip->pack;
print "\n";
ok((unpack "H*", $rip->pack), $expectedOutput);

