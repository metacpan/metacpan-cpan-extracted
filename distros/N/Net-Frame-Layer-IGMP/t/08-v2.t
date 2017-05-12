use Test;
BEGIN { plan(tests => 4) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::IGMP qw(:consts);

my ($igmp, $packet, $decode, $expectedOutput);

# v2 query
$igmp = Net::Frame::Layer::IGMP->new(maxResp=>2);

$expectedOutput = 'IGMP: type:0x11  maxResp:2  checksum:0x0000
IGMP: groupAddress:0.0.0.0';

print $igmp->print;
print "\n";

ok($igmp->print eq $expectedOutput);

# v2 query Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "1102eefd00000000";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = 'IGMP: type:0x11  maxResp:2  checksum:0xeefd
IGMP: groupAddress:0.0.0.0';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# v2 report
$igmp = Net::Frame::Layer::IGMP->new(type=>NF_IGMP_TYPE_REPORTv2);

$expectedOutput = 'IGMP: type:0x16  maxResp:0  checksum:0x0000
IGMP: groupAddress:0.0.0.0';

print $igmp->print;
print "\n";

ok($igmp->print eq $expectedOutput);

# v2 report Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "1600e9ff00000000";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = 'IGMP: type:0x16  maxResp:0  checksum:0xe9ff
IGMP: groupAddress:0.0.0.0';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
