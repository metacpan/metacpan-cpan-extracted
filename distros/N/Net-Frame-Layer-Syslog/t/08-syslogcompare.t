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
use Net::Frame::Layer::Syslog qw(:consts);

my ($eth, $ipv4, $udp, $udpPay, $syslog);
my %packet;

$eth    = Net::Frame::Layer::ETH->new(src=>'C4:17:FE:12:7D:75',dst=>'58:6d:8f:78:ad:40');
$ipv4   = Net::Frame::Layer::IPv4->new(id=>16383,src=>'192.168.10.100',dst=>'8.8.8.8',protocol=>NF_IPv4_PROTOCOL_UDP);
$udp    = Net::Frame::Layer::UDP->new(dst=>514,src=>52001);
$udpPay = Net::Frame::Layer::UDP->new(dst=>514,src=>52001,payload=>pack "H*", '3c3139303e4a616e2032332031343a33323a3534206c6f63616c686f73742030382d7379736c6f67636f6d706172652e745b323538385d207379736c6f67206d657373616765');
$syslog = Net::Frame::Layer::Syslog->new(timestamp=>'Jan 23 14:32:54',host=>'localhost',tag=>'08-syslogcompare.t[2588]');

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet{'01-UDP'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udpPay ]
);

$packet{'02-Syslog'} = Net::Frame::Simple->new(
    layers => [ $eth, $ipv4, $udp, $syslog ]
);

print "\nUDP\n";
print $packet{'01-UDP'}->print;
print "\nSyslog\n";
print $packet{'02-Syslog'}->print;
print "\nUDP\n";
print unpack "H*", $packet{'01-UDP'}->pack;
print "\nSyslog\n";
print unpack "H*", $packet{'02-Syslog'}->pack;
print "\n";

(unpack "H*", $packet{'01-UDP'}->pack) eq (unpack "H*", $packet{'02-Syslog'}->pack);
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
