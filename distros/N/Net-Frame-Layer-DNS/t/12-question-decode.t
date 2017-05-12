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
use Net::Frame::Layer::DNS qw(:consts);
use Net::Frame::Layer::DNS::Question qw(:consts);

my ($packet, $decode, $expectedOutput);

# A
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "586d8f78ad40c417fe127d7508004500003c042900008011df3ec0a80a64445747e6e25400350028d214650e010000010000000000000377777706676f6f676c6503636f6d0000010001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:60  id:1065
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0xdf3e
IPv4: src:192.168.10.100  dst:68.87.71.230
UDP: src:57940  dst:53  length:40  checksum:0xd214
DNS: id:25870  qr:0  opcode:0  flags:0x10  rcode:0
DNS: qdCount:1  anCount:0
DNS: nsCount:0  arCount:0
DNS::Question: name:www.google.com
DNS::Question: type:1  class:1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# AAAA
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "586d8f78ad40c417fe127d7508004500003d043400008011df32c0a80a64445747e6e25d003500290fa5372701000001000000000000046970763606676f6f676c6503636f6d00001c0001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:61  id:1076
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0xdf32
IPv4: src:192.168.10.100  dst:68.87.71.230
UDP: src:57949  dst:53  length:41  checksum:0xfa5
DNS: id:14119  qr:0  opcode:0  flags:0x10  rcode:0
DNS: qdCount:1  anCount:0
DNS: nsCount:0  arCount:0
DNS::Question: name:ipv6.google.com
DNS::Question: type:28  class:1';

print $decode->print;
print "\n";

$decode->print, $expectedOutput;
});
