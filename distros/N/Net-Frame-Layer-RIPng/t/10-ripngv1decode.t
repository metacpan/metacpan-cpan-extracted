use Test;
BEGIN { plan(tests => 2) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);
use Net::Frame::Layer::RIPng qw(:consts);

my ($packet, $decode, $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "33330000000902004c4f4f5086dd60000000002011fffe80000000000000f800da2716917d0dff02000000000000000000000000000904cf020900209471010100000000000000000000000000000000000000000010";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:33:33:00:00:00:09  src:02:00:4c:4f:4f:50  type:0x86dd
IPv6: version:6  trafficClass:0x00  flowLabel:0x00000  nextHeader:0x11
IPv6: payloadLength:32  hopLimit:255
IPv6: src:fe80::f800:da27:1691:7d0d  dst:ff02::9
UDP: src:1231  dst:521  length:32  checksum:0x9471
RIPng: command:1  version:1  reserved:0
RIPng::v1: prefix:::
RIPng::v1: routeTag:0  prefixLength:0  metric:16';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "33330000000902004c4f4f5086dd60000000002011fffe80000000000000f800da2716917d0dff0200000000000000000000000000090209020900208aef0201000020010db8deadbeef000000000000000000004001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:33:33:00:00:00:09  src:02:00:4c:4f:4f:50  type:0x86dd
IPv6: version:6  trafficClass:0x00  flowLabel:0x00000  nextHeader:0x11
IPv6: payloadLength:32  hopLimit:255
IPv6: src:fe80::f800:da27:1691:7d0d  dst:ff02::9
UDP: src:521  dst:521  length:32  checksum:0x8aef
RIPng: command:2  version:1  reserved:0
RIPng::v1: prefix:2001:db8:dead:beef::
RIPng::v1: routeTag:0  prefixLength:64  metric:1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
