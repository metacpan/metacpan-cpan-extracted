use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::PortId;

my $l = Net::Frame::Layer::CDP::PortId->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::CDP qw(:consts);

my ($cdp, $portid, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$portid = Net::Frame::Layer::CDP::PortId->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::PortId: type:0x0003  length:19  portId:FastEthernet1/0';

print $cdp->print . "\n";
print $portid->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $portid->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b48c44000300134661737445746865726e6574312f30";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x8c44
CDP::PortId: type:0x0003  length:19  portId:FastEthernet1/0';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
