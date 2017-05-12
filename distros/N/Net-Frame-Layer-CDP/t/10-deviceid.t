use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::DeviceId;

my $l = Net::Frame::Layer::CDP::DeviceId->new;
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

my ($cdp, $deviceid, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$deviceid = Net::Frame::Layer::CDP::DeviceId->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::DeviceId: type:0x0001  length:6  deviceId:R1';

print $cdp->print . "\n";
print $deviceid->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $deviceid->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4ab13000100065231";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xab13
CDP::DeviceId: type:0x0001  length:6  deviceId:R1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
