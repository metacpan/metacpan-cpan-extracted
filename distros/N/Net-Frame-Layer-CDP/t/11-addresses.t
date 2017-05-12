use Test;
BEGIN { plan(tests => 4) }

## 1 ##
use Net::Frame::Layer::CDP::Address;

my $l = Net::Frame::Layer::CDP::Address->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);

## 2 ##
use Net::Frame::Layer::CDP::Addresses;

my $l = Net::Frame::Layer::CDP::Addresses->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);

## 3 ##
my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::CDP qw(:consts);

my ($cdp, $addresses, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
my $addr1 = Net::Frame::Layer::CDP::Address->new(address=>'192.168.100.1');
my $addr2 = Net::Frame::Layer::CDP::Address->ipv6Address(address=>'2001:db8:192:168::1');
$addresses = Net::Frame::Layer::CDP::Addresses->new(addresses=>[$addr1,$addr2]);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::Addresses: type:0x0002  length:8  numAddresses:0
CDP::Address: protocolType:1  protocolLength:1  protocol:0xcc
CDP::Address: addressLength:4  address:192.168.100.1
CDP::Address: protocolType:2  protocolLength:8  protocol:0xaaaa0300000086dd
CDP::Address: addressLength:16  address:2001:db8:192:168::1';

print $cdp->print . "\n";
print $addresses->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $addresses->print) eq $expectedOutput);

## 4 ##
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4bf1e00020049000000030101cc0004c0a864010208aaaa0300000086dd001020010db80192016800000000000000010208aaaa0300000086dd0010fe80000000000000c8001dfffe4c0038";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xbf1e
CDP::Addresses: type:0x0002  length:73  numAddresses:3
CDP::Address: protocolType:1  protocolLength:1  protocol:0xcc
CDP::Address: addressLength:4  address:192.168.100.1
CDP::Address: protocolType:2  protocolLength:8  protocol:0xaaaa0300000086dd
CDP::Address: addressLength:16  address:2001:db8:192:168::1
CDP::Address: protocolType:2  protocolLength:8  protocol:0xaaaa0300000086dd
CDP::Address: addressLength:16  address:fe80::c800:1dff:fe4c:38';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
