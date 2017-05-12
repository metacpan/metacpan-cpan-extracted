use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::Duplex;

my $l = Net::Frame::Layer::CDP::Duplex->new;
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

my ($cdp, $duplex, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$duplex = Net::Frame::Layer::CDP::Duplex->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::Duplex: type:0x000b  length:5  duplex:1 (full)';

print $cdp->print . "\n";
print $duplex->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $duplex->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fd3a000b000501";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfd3a
CDP::Duplex: type:0x000b  length:5  duplex:1 (full)';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
