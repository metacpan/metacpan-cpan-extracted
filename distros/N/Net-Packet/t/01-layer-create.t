use Test;
BEGIN { plan(tests => 1) }

use Net::Packet::Frame;
use Net::Packet::ARP;
use Net::Packet::ETH;
use Net::Packet::ICMPv4;
use Net::Packet::IPv4;
use Net::Packet::IPv6;
use Net::Packet::NULL;
use Net::Packet::RAW;
use Net::Packet::SLL;
use Net::Packet::TCP;
use Net::Packet::UDP;
use Net::Packet::VLAN;
use Net::Packet::PPPoE;
use Net::Packet::PPP;
use Net::Packet::PPPLCP;
use Net::Packet::LLC;
use Net::Packet::CDP;
use Net::Packet::CDP::Address;
use Net::Packet::CDP::Type;
use Net::Packet::CDP::TypeDeviceId;
use Net::Packet::CDP::TypeAddresses;
use Net::Packet::CDP::TypePortId;
use Net::Packet::CDP::TypeCapabilities;
use Net::Packet::CDP::TypeSoftwareVersion;
use Net::Packet::STP;
use Net::Packet::OSPF;
use Net::Packet::IGMPv4;

my $f = Net::Packet::Frame->new;
$f->pack;

my $a = Net::Packet::ARP->new;
$a->pack;

my $e = Net::Packet::ETH->new;
$e->pack;

my $i = Net::Packet::ICMPv4->new;
$i->pack;

my $i2 = Net::Packet::IPv4->new;
$i2->pack;

my $i3 = Net::Packet::IPv6->new;
$i3->pack;

my $n = Net::Packet::NULL->new;
$n->pack;

my $r = Net::Packet::RAW->new;
$r->pack;

my $s = Net::Packet::SLL->new;
$s->pack;

my $t = Net::Packet::TCP->new;
$t->pack;

my $u = Net::Packet::UDP->new;
$u->pack;

my $v = Net::Packet::VLAN->new;
$v->pack;

my $p1 = Net::Packet::PPPoE->new;
$p1->pack;

my $p2 = Net::Packet::PPP->new;
$p2->pack;

my $p3 = Net::Packet::PPPLCP->new;
$p3->pack;

my $llc = Net::Packet::LLC->new;
$llc->pack;

my $cdp = Net::Packet::CDP->new;
$cdp->pack;

my $cdpType1 = Net::Packet::CDP::TypeDeviceId->new;
$cdpType1->pack;

my $cdpAddress = Net::Packet::CDP::Address->new;
$cdpAddress->pack;

my $cdpType2 = Net::Packet::CDP::TypeAddresses->new;
$cdpType2->pack;

my $cdpType3 = Net::Packet::CDP::TypePortId->new;
$cdpType3->pack;

my $cdpType4 = Net::Packet::CDP::TypeCapabilities->new;
$cdpType4->pack;

my $cdpType5 = Net::Packet::CDP::TypeSoftwareVersion->new;
$cdpType5->pack;

my $stp = Net::Packet::STP->new;
$stp->pack;

my $ospf = Net::Packet::OSPF->new;
$ospf->pack;

my $igmp = Net::Packet::IGMPv4->new;
$igmp->pack;

ok(1);
