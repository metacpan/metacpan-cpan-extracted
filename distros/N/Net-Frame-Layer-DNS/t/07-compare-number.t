use Test;
BEGIN { plan(tests => 1) }

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

my ($packetUDP, $packetPay, $packetQry);

my $eth    = Net::Frame::Layer::ETH->new(src=>'C4:17:FE:12:7D:75',dst=>'58:6d:8f:78:ad:40');
my $ipv4   = Net::Frame::Layer::IPv4->new(id=>16383,src=>'192.168.10.100',dst=>'8.8.8.8',protocol=>NF_IPv4_PROTOCOL_UDP);
my $udp    = Net::Frame::Layer::UDP->new(dst=>53,src=>1025);
my $udpPay = Net::Frame::Layer::UDP->new(dst=>53,src=>1025,payload=>pack "H*", '4000010000010000000000000237340331323503313133033130340000010001');
my $dnsPay = Net::Frame::Layer::DNS->new(id=>16384,payload=>pack "H*", '0237340331323503313133033130340000010001');
my $dns    = Net::Frame::Layer::DNS->new(id=>16384);
my $query  = Net::Frame::Layer::DNS::Question->new(name=>'74.125.113.104');

skip ($NO_HAVE_NetFrameSimple,
sub {
$packetUDP = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udpPay ]
);

$packetPay = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $dnsPay ]
);

$packetQry  = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $dns, $query ]
);

print "\nUDP\n";
print $packetUDP->print;
print "\nPayload\n";
print $packetPay->print;
print "\nQuery\n";
print $packetQry->print;
print "\nUDP\n";
print unpack "H*", $packetUDP->pack;
print "\nPayload\n";
print unpack "H*", $packetPay->pack;
print "\nQuery\n";
print unpack "H*", $packetQry->pack;
print "\n";

((unpack "H*", $packetUDP->pack) eq (unpack "H*", $packetPay->pack) &&
 (unpack "H*", $packetPay->pack) eq (unpack "H*", $packetQry->pack) &&
 (unpack "H*", $packetUDP->pack) eq (unpack "H*", $packetQry->pack));
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
if (pcap_sendpacket($fp, $packetUDP->pack) != 0) {
    printf "\nError sending the packet: %s\n", pcap_geterr($fp);
    exit 1;
}
if (pcap_sendpacket($fp, $packetPay->pack) != 0) {
    printf "\nError sending the packet: %s\n", pcap_geterr($fp);
    exit 1;
}
if (pcap_sendpacket($fp, $packetQry->pack) != 0) {
    printf "\nError sending the packet: %s\n", pcap_geterr($fp);
    exit 1;
}

}
