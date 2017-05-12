use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::VoipVlanReply;

my $l = Net::Frame::Layer::CDP::VoipVlanReply->new;
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
$voipVlan = Net::Frame::Layer::CDP::VoipVlanReply->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::VoipVlanReply: type:0x000e  length:5  data:1  voipVlan:';

print $cdp->print . "\n";
print $voipVlan->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $voipVlan->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b4fc6e000e00070100c8";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0xfc6e
CDP::VoipVlanReply: type:0x000e  length:7  data:1  voipVlan:200';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
