use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::Capabilities;

my $l = Net::Frame::Layer::CDP::Capabilities->new;
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

my ($cdp, $capabilities, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$capabilities = Net::Frame::Layer::CDP::Capabilities->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::Capabilities: type:0x0004  length:8  capabilities:0x00000000';

print $cdp->print . "\n";
print $capabilities->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $capabilities->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fd160004000800000029";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfd16
CDP::Capabilities: type:0x0004  length:8  capabilities:0x00000029';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
