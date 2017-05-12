use Test;
BEGIN { plan(tests => 4) }

use strict;
use warnings;

use Net::Frame::Layer::RIPng qw(:consts);

my ($ripng, $expectedOutput);

# RIPng new
$ripng = Net::Frame::Layer::RIPng::v1->new;
$expectedOutput = 'RIPng::v1: prefix:::
RIPng::v1: routeTag:0  prefixLength:64  metric:1';
print $ripng->print . "\n";
ok($ripng->print, $expectedOutput);

$expectedOutput = '0000000000000000000000000000000000004001';
print unpack "H*", $ripng->pack;
print "\n";
ok((unpack "H*", $ripng->pack), $expectedOutput);

# RIPng full
$ripng = Net::Frame::Layer::RIPng::v1->full;
$expectedOutput = 'RIPng::v1: prefix:::
RIPng::v1: routeTag:0  prefixLength:0  metric:16';
print $ripng->print . "\n";
ok($ripng->print, $expectedOutput);

$expectedOutput = '0000000000000000000000000000000000000010';
print unpack "H*", $ripng->pack;
print "\n";
ok((unpack "H*", $ripng->pack), $expectedOutput);
