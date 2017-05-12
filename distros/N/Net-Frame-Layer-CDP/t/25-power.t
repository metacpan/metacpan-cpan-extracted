use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::Power;

my $l = Net::Frame::Layer::CDP::Power->new;
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

my ($cdp, $power, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$power = Net::Frame::Layer::CDP::Power->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::Power: type:0x0010  length:6  power:6400 mW';

print $cdp->print . "\n";
print $power->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $power->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4ed95001000060fa0";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xed95
CDP::Power: type:0x0010  length:6  power:4000 mW';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
