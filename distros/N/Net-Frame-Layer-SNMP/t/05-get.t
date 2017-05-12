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

# Get
$snmp = Net::Frame::Layer::SNMP->Get(requestId=>1);

$expectedOutput = 'SNMP: version:1  community:public  pdu:get_request
SNMP: requestId:1  errorStatus:0  errorIndex:0
SNMP: varbindlist:';

print $snmp->print;
print "\n";

ok($snmp->print eq $expectedOutput);

# Get Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "302702010004067075626c6963a01a02024b3c020100020100300e300c06082b060104018386500500";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'SNMP'
);

$expectedOutput = 'SNMP: version:0  community:public  pdu:get_request
SNMP: requestId:19260  errorStatus:0  errorIndex:0
SNMP: varbindlist:
SNMP: 1.3.6.1.4.1.50000 = (null)';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
