use Test;
BEGIN { plan(tests => 6) }

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
use Net::Frame::Layer::RIP qw(:consts);

my ($eth, $ipv4, $udp, $udpPay, $ripPay, $rip, $rte);
my %packet;

$eth    = Net::Frame::Layer::ETH->new(src=>'ca:00:07:a0:00:1c',dst=>NF_RIP_V1_DEST_HWADDR);
$ipv4   = Net::Frame::Layer::IPv4->new(id=>16383,src=>'192.168.100.254',dst=>NF_RIP_V1_DEST_ADDR,protocol=>NF_IPv4_PROTOCOL_UDP);
$udp    = Net::Frame::Layer::UDP->new(dst=>NF_RIP_V1_DEST_PORT,src=>NF_RIP_V1_DEST_PORT);
$udpPay = Net::Frame::Layer::UDP->new(dst=>NF_RIP_V1_DEST_PORT,src=>NF_RIP_V1_DEST_PORT,payload=>pack "H*", '010100000000000000000000000000000000000000000010');
$ripPay = Net::Frame::Layer::RIP->new(version=>1,payload=>pack "H*", '0000000000000000000000000000000000000010');
$rip    = Net::Frame::Layer::RIP->new(version=>1);
$rte    = Net::Frame::Layer::RIP::v1->full;

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet{'01-UDP'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udpPay ]
);

$packet{'02-Pay'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $ripPay ]
);

$packet{'03-Rte'}  = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $rip, $rte ]
);

print "\nUDP\n";
print $packet{'01-UDP'}->print;
print "\nPayload\n";
print $packet{'02-Pay'}->print;
print "\nRTE\n";
print $packet{'03-Rte'}->print;
print "\nUDP\n";
print unpack "H*", $packet{'01-UDP'}->pack;
print "\nPayload\n";
print unpack "H*", $packet{'02-Pay'}->pack;
print "\nRTE\n";
print unpack "H*", $packet{'03-Rte'}->pack;
print "\n";

(unpack "H*", $packet{'01-UDP'}->pack) eq (unpack "H*", $packet{'02-Pay'}->pack);
});

skip ($NO_HAVE_NetFrameSimple,
sub {
(unpack "H*", $packet{'02-Pay'}->pack) eq (unpack "H*", $packet{'03-Rte'}->pack);
});

skip ($NO_HAVE_NetFrameSimple,
sub {
(unpack "H*", $packet{'01-UDP'}->pack) eq (unpack "H*", $packet{'03-Rte'}->pack);
});

$eth    = Net::Frame::Layer::ETH->new(src=>'ca:00:07:a0:00:1c',dst=>NF_RIP_V1_DEST_HWADDR);
$ipv4   = Net::Frame::Layer::IPv4->new(id=>16383,src=>'192.168.100.254',dst=>NF_RIP_V1_DEST_ADDR,protocol=>NF_IPv4_PROTOCOL_UDP);
$udp    = Net::Frame::Layer::UDP->new(dst=>NF_RIP_V1_DEST_PORT,src=>NF_RIP_V1_DEST_PORT);
$udpPay = Net::Frame::Layer::UDP->new(dst=>NF_RIP_V1_DEST_PORT,src=>NF_RIP_V1_DEST_PORT,payload=>pack "H*", '020100000002000001010101000000000000000000000001');
$ripPay = Net::Frame::Layer::RIP->new(version=>1,command=>NF_RIP_V1_COMMAND_RESPONSE,payload=>pack "H*", '0002000001010101000000000000000000000001');
$rip    = Net::Frame::Layer::RIP->new(version=>1,command=>NF_RIP_V1_COMMAND_RESPONSE);
$rte    = Net::Frame::Layer::RIP::v1->new(address=>'1.1.1.1');

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet{'04-UDP'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udpPay ]
);

$packet{'05-Pay'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $ripPay ]
);

$packet{'06-Rte'}  = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $rip, $rte ]
);

print "\nUDP\n";
print $packet{'04-UDP'}->print;
print "\nPayload\n";
print $packet{'05-Pay'}->print;
print "\nRTE\n";
print $packet{'06-Rte'}->print;
print "\nUDP\n";
print unpack "H*", $packet{'04-UDP'}->pack;
print "\nPayload\n";
print unpack "H*", $packet{'05-Pay'}->pack;
print "\nRTE\n";
print unpack "H*", $packet{'06-Rte'}->pack;
print "\n";

(unpack "H*", $packet{'04-UDP'}->pack) eq (unpack "H*", $packet{'05-Pay'}->pack);
});

skip ($NO_HAVE_NetFrameSimple,
sub {
(unpack "H*", $packet{'05-Pay'}->pack) eq (unpack "H*", $packet{'06-Rte'}->pack);
});

skip ($NO_HAVE_NetFrameSimple,
sub {
(unpack "H*", $packet{'04-UDP'}->pack) eq (unpack "H*", $packet{'06-Rte'}->pack);
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
for (sort(keys(%packet))) {
    if (pcap_sendpacket($fp, $packet{$_}->pack) != 0) {
        printf "\nError sending the packet: %s\n", pcap_geterr($fp);
        exit 1;
    }
}

}
