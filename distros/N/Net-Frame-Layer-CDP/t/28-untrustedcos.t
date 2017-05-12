use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::UntrustedCos;

my $l = Net::Frame::Layer::CDP::UntrustedCos->new;
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

my ($cdp, $untrustedCos, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$untrustedCos = Net::Frame::Layer::CDP::UntrustedCos->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::UntrustedCos: type:0x0013  length:5  untrustedCos:0';

print $cdp->print . "\n";
print $untrustedCos->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $untrustedCos->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fd2f0013000504";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfd2f
CDP::UntrustedCos: type:0x0013  length:5  untrustedCos:4';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
