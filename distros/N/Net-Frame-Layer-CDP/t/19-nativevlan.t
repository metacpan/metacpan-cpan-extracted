use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::NativeVlan;

my $l = Net::Frame::Layer::CDP::NativeVlan->new;
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

my ($cdp, $nativeVlan, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$nativeVlan = Net::Frame::Layer::CDP::NativeVlan->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::NativeVlan: type:0x000a  length:6  nativeVlan:1';

print $cdp->print . "\n";
print $nativeVlan->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $nativeVlan->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fcd7000a00060064";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfcd7
CDP::NativeVlan: type:0x000a  length:6  nativeVlan:100';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
