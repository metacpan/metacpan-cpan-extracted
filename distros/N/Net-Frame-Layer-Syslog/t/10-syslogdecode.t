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
use Net::Frame::Layer::Syslog qw(:consts);

my ($packet, $decode, $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "586d8f78ad40c417fe127d750800450000b55f30000080115417c0a80a644a7d7167eb72020200a131453c3139303e4a616e2032332031343a35323a35382031302e3230302e3230302e32353420433a5c737472617762657272795c7065726c5c736974655c62696e2f7379736c6f67642d73656e64746573742e6261745b323731325d3a204d6573736167652066726f6d20433a5c737472617762657272795c7065726c5c736974655c62696e2f7379736c6f67642d73656e64746573742e626174";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:181  id:24368
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0x5417
IPv4: src:192.168.10.100  dst:74.125.113.103
UDP: src:60274  dst:514  length:161  checksum:0x3145
Syslog: facility:23 (local7)  severity:6 (Informational)
Syslog: timestamp:Jan 23 14:52:58  host:10.200.200.254
Syslog: tag:C:
Syslog: content:\strawberry\perl\site\bin/syslogd-sendtest.bat[2712]: Message from C:\strawberry\perl\site\bin/syslogd-sendtest.bat';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "586d8f78ad40c417fe127d7508004500002d5f4c000080115282c0a80a644a7d7368dd740202001949dd54686973206973206120626164206f6e65";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:45  id:24396
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0x5282
IPv4: src:192.168.10.100  dst:74.125.115.104
UDP: src:56692  dst:514  length:25  checksum:0x49dd
Syslog: message:This is a bad one';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
