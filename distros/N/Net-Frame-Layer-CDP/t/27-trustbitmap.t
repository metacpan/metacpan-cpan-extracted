use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::TrustBitmap;

my $l = Net::Frame::Layer::CDP::TrustBitmap->new;
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

my ($cdp, $trustBitmap, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$trustBitmap = Net::Frame::Layer::CDP::TrustBitmap->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::TrustBitmap: type:0x0012  length:5  trustBitmap:0x00 (noTrust)';

print $cdp->print . "\n";
print $trustBitmap->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $trustBitmap->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fd330012000501";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfd33
CDP::TrustBitmap: type:0x0012  length:5  trustBitmap:0x01 (trusted)';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
