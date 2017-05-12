use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::Platform;

my $l = Net::Frame::Layer::CDP::Platform->new;
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

my ($cdp, $platform, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$platform = Net::Frame::Layer::CDP::Platform->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::Platform: type:0x0006  length:4  platform:';

print $cdp->print . "\n";
print $platform->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $platform->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b42d3100060011436973636f3132303030475352";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x2d31
CDP::Platform: type:0x0006  length:17  platform:Cisco12000GSR';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
