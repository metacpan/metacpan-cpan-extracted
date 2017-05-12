use Test;
BEGIN { plan(tests => 2) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::SNMP qw(:consts);

my ($snmp, $packet, $decode, $expectedOutput);

# Trap
$snmp = Net::Frame::Layer::SNMP->Trap(timeticks=>1);

$expectedOutput = 'SNMP: version:0  community:public  pdu:trap
SNMP: entOid:1.3.6.1.4.1.50000  agentAddr:127.0.0.1  genericTrap:6
SNMP: specificTrap:1  timeTicks:1
SNMP: varbindlist:';

print $snmp->print;
print "\n";

ok($snmp->print eq $expectedOutput);

# Trap Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "3081ef02010004067075626c6963a481e106082b060104018386504004c0a80a660201060201014304513f364c3081c2300f060a2b0601040183865001030201013014060a2b0601040183865001040406537472696e673016060a2b060104018386500105040801020304050607083016060a2b06010401838650010606082a030405060708093012060a2b06010401838650010740040a0a0a013012060a2b060104018386500108410401ed36a03012060a2b0601040183865001094204028757b23012060a2b06010401838650010a4304513f364c3019060a2b06010401838650010b440b6f70617175652064617461";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'SNMP'
);

$expectedOutput = 'SNMP: version:0  community:public  pdu:trap
SNMP: entOid:1.3.6.1.4.1.50000  agentAddr:192.168.10.102  genericTrap:6
SNMP: specificTrap:1  timeTicks:1363097164
SNMP: varbindlist:
SNMP: 1.3.6.1.4.1.50000.1.3 = 1 (integer)
SNMP: 1.3.6.1.4.1.50000.1.4 = String (string)
SNMP: 1.3.6.1.4.1.50000.1.5 = 0x0102030405060708 ([hex]string)
SNMP: 1.3.6.1.4.1.50000.1.6 = 1.2.3.4.5.6.7.8.9 (oid)
SNMP: 1.3.6.1.4.1.50000.1.7 = 10.10.10.1 (ipaddr)
SNMP: 1.3.6.1.4.1.50000.1.8 = 32323232 (counter32)
SNMP: 1.3.6.1.4.1.50000.1.9 = 42424242 (guage32)
SNMP: 1.3.6.1.4.1.50000.1.10 = 1363097164 (timeticks)
SNMP: 1.3.6.1.4.1.50000.1.11 = opaque data (opaque)';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
