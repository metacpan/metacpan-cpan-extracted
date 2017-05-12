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
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);
use Net::Frame::Layer::RIP qw(:consts);

my ($packet, $decode, $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "01005e000009ca0007a0001c080045c00048000000000211b332c0a86401e0000009020802080034aa660202000000020000c0a86500ffffff00000000000000000100020000c0a86600ffffff000000000000000001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:01:00:5e:00:00:09  src:ca:00:07:a0:00:1c  type:0x0800
IPv4: version:4  hlen:5  tos:0xc0  length:72  id:0
IPv4: flags:0x00  offset:0  ttl:2  protocol:0x11  checksum:0xb332
IPv4: src:192.168.100.1  dst:224.0.0.9
UDP: src:520  dst:520  length:52  checksum:0xaa66
RIP: command:2  version:2  reserved:0
RIP::v2: addressFamily:2  routeTag:0
RIP::v2: address:192.168.101.0  subnetMask:255.255.255.0  nextHop:0.0.0.0
RIP::v2: metric:1
RIP::v2: addressFamily:2  routeTag:0
RIP::v2: address:192.168.102.0  subnetMask:255.255.255.0  nextHop:0.0.0.0
RIP::v2: metric:1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "01005e000009ca0007a0001c080045c0005c000000000211b31ec0a86401e0000009020802080048646f02020000ffff0002636973636f000000000000000000000000020000c0a86500ffffff00000000000000000100020000c0a86600ffffff000000000000000001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:01:00:5e:00:00:09  src:ca:00:07:a0:00:1c  type:0x0800
IPv4: version:4  hlen:5  tos:0xc0  length:92  id:0
IPv4: flags:0x00  offset:0  ttl:2  protocol:0x11  checksum:0xb31e
IPv4: src:192.168.100.1  dst:224.0.0.9
UDP: src:520  dst:520  length:72  checksum:0x646f
RIP: command:2  version:2  reserved:0
RIP::v2: addressFamily:0xffff  authType:2
RIP::v2: authentication:cisco
RIP::v2: addressFamily:2  routeTag:0
RIP::v2: address:192.168.101.0  subnetMask:255.255.255.0  nextHop:0.0.0.0
RIP::v2: metric:1
RIP::v2: addressFamily:2  routeTag:0
RIP::v2: address:192.168.102.0  subnetMask:255.255.255.0  nextHop:0.0.0.0
RIP::v2: metric:1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
