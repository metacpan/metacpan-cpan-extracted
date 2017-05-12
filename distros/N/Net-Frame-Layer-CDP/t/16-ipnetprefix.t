use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::IPNetPrefix;

my $l = Net::Frame::Layer::CDP::IPNetPrefix->new;
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

my ($cdp, $IpNetPrefix, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$IpNetPrefix = Net::Frame::Layer::CDP::IPNetPrefix->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::IPNetPrefix: type:0x0007  length:9
CDP::IPNetPrefix: IpNetPrefix:127.0.0.1/8';

print $cdp->print . "\n";
print $IpNetPrefix->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $IpNetPrefix->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4d87a00070009c0a8640018";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xd87a
CDP::IPNetPrefix: type:0x0007  length:9
CDP::IPNetPrefix: IpNetPrefix:192.168.100.0/24';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
