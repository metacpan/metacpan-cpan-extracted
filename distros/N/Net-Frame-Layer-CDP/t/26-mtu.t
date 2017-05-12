use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::MTU;

my $l = Net::Frame::Layer::CDP::MTU->new;
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

my ($cdp, $mtu, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$mtu = Net::Frame::Layer::CDP::MTU->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::MTU: type:0x0011  length:8  mtu:1500';

print $cdp->print . "\n";
print $mtu->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $mtu->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4f8320011000800000500";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xf832
CDP::MTU: type:0x0011  length:8  mtu:1280';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
