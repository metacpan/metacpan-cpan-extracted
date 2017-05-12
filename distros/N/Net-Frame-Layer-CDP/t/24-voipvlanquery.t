use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::VoipVlanQuery;

my $l = Net::Frame::Layer::CDP::VoipVlanQuery->new;
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

my ($cdp, $voipVlan, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$voipVlan = Net::Frame::Layer::CDP::VoipVlanQuery->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::VoipVlanQuery: type:0x000f  length:5  data:1  voipVlan:';

print $cdp->print . "\n";
print $voipVlan->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $voipVlan->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fbd1000f0007010064";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfbd1
CDP::VoipVlanQuery: type:0x000f  length:7  data:1  voipVlan:100';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
