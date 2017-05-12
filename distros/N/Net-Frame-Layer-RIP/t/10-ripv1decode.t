use Test;
BEGIN { plan(tests => 1) }

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
$packet = pack "H*", "ffffffffffffca0007a0001c080045c00048000000000211933cc0a86401ffffffff02080208003488730201000000020000c0a8650000000000000000000000000100020000c0a86600000000000000000000000001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:ff:ff:ff:ff:ff:ff  src:ca:00:07:a0:00:1c  type:0x0800
IPv4: version:4  hlen:5  tos:0xc0  length:72  id:0
IPv4: flags:0x00  offset:0  ttl:2  protocol:0x11  checksum:0x933c
IPv4: src:192.168.100.1  dst:255.255.255.255
UDP: src:520  dst:520  length:52  checksum:0x8873
RIP: command:2  version:1  reserved:0
RIP::v1: addressFamily:2  reserved1:0
RIP::v1: address:192.168.101.0  reserved2:0  reserved3:0
RIP::v1: metric:1
RIP::v1: addressFamily:2  reserved1:0
RIP::v1: address:192.168.102.0  reserved2:0  reserved3:0
RIP::v1: metric:1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
