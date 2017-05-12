use Test;
BEGIN { plan(tests => 4) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

my $HAVE_NP = 0;
eval "use Net::Pcap qw(:functions)";
if(!$@) {
    $HAVE_NP = 1;
}

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);
use Net::Frame::Layer::DNS qw(:consts);
use Net::Frame::Layer::DNS::Question qw(:consts);
use Net::Frame::Layer::DNS::RR qw(:consts);
use Net::Frame::Layer::DNS::RR::A;
use Net::Frame::Layer::DNS::RR::AAAA;

my ($rdata, $rr, $expectedOutput, $packetA, $packetAAAA);

my $eth   = Net::Frame::Layer::ETH->new(src=>'c4:17:fe:12:7d:75',dst=>'58:6d:8f:78:ad:40');
my $ipv4  = Net::Frame::Layer::IPv4->new(id=>16383,src=>'192.168.10.100',dst=>'10.10.10.10',protocol=>NF_IPv4_PROTOCOL_UDP);
my $udp   = Net::Frame::Layer::UDP->new(dst=>1025,src=>53);
my $dns   = Net::Frame::Layer::DNS->new(id=>16384,anCount=>1);
my $query = Net::Frame::Layer::DNS::Question->new(name=>'localhost');

# A
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::A->new;
$rr    = Net::Frame::Layer::DNS::RR->new(rdata=>$rdata->pack);

$packetA = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $dns, $query, $rr ]
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:80  id:16383
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0x1b7e
IPv4: src:192.168.10.100  dst:10.10.10.10
UDP: src:53  dst:1025  length:60  checksum:0x8440
DNS: id:16384  qr:0  opcode:0  flags:0x10  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:0  arCount:0
DNS::Question: name:localhost
DNS::Question: type:1  class:1
DNS::RR: name:localhost
DNS::RR: type:1  class:1  ttl:0  rdlength:4';
print $packetA->print . "\n";

$packetA->print eq $expectedOutput;
});

skip ($NO_HAVE_NetFrameSimple,
sub {
$expectedOutput = '586d8f78ad40c417fe127d750800450000503fff000080111b7ec0a80a640a0a0a0a00350401003c8440400001000001000100000000096c6f63616c686f73740000010001096c6f63616c686f737400000100010000000000047f000001';
print unpack "H*", $packetA->pack;
print "\n";

(unpack "H*", $packetA->pack) eq $expectedOutput;
});

# AAAA
skip ($NO_HAVE_NetFrameSimple,
sub {
$rdata = Net::Frame::Layer::DNS::RR::AAAA->new;
$rr    = Net::Frame::Layer::DNS::RR->new(
   type  => NF_DNS_TYPE_AAAA,
   rdata => $rdata->pack
);

$packetAAAA = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $dns, $query, $rr ]
);

$expectedOutput = 'ETH: dst:58:6d:8f:78:ad:40  src:c4:17:fe:12:7d:75  type:0x0800
IPv4: version:4  hlen:5  tos:0x00  length:92  id:16383
IPv4: flags:0x00  offset:0  ttl:128  protocol:0x11  checksum:0x1b72
IPv4: src:192.168.10.100  dst:10.10.10.10
UDP: src:53  dst:1025  length:72  checksum:0x302
DNS: id:16384  qr:0  opcode:0  flags:0x10  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:0  arCount:0
DNS::Question: name:localhost
DNS::Question: type:1  class:1
DNS::RR: name:localhost
DNS::RR: type:28  class:1  ttl:0  rdlength:16';
print $packetAAAA->print . "\n";

$packetAAAA->print eq $expectedOutput;
});

skip ($NO_HAVE_NetFrameSimple,
sub {
$expectedOutput = '586d8f78ad40c417fe127d7508004500005c3fff000080111b72c0a80a640a0a0a0a0035040100480302400001000001000100000000096c6f63616c686f73740000010001096c6f63616c686f737400001c000100000000001000000000000000000000000000000001';
print unpack "H*", $packetAAAA->pack;
print "\n";

(unpack "H*", $packetAAAA->pack) eq $expectedOutput;
});

if ($HAVE_NP && (!$NO_HAVE_NetFrameSimple)) {

my %devinfo;
my $err;

if (!@ARGV) { exit 0 }

my $fp= pcap_open($ARGV[0], 100, 0, 1000, \%devinfo, \$err);
if (!defined($fp)) {
    printf "\nUnable to open the adapter. %s is not supported by WinPcap\n", $ARGV[0];
    exit 1;
}
if (pcap_sendpacket($fp, $packetA->pack) != 0) {
    printf "\nError sending the packet: %s\n", pcap_geterr($fp);
    exit 1;
}
if (pcap_sendpacket($fp, $packetAAAA->pack) != 0) {
    printf "\nError sending the packet: %s\n", pcap_geterr($fp);
    exit 1;
}

}
