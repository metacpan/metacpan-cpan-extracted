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

# v1 query
$igmp = Net::Frame::Layer::IGMP->new;

$expectedOutput = 'IGMP: type:0x11  maxResp:0  checksum:0x0000
IGMP: groupAddress:0.0.0.0';

print $igmp->print;
print "\n";

ok($igmp->print eq $expectedOutput);

# v1 query Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "1100eeff00000000";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = 'IGMP: type:0x11  maxResp:0  checksum:0xeeff
IGMP: groupAddress:0.0.0.0';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# v1 report
$igmp = Net::Frame::Layer::IGMP->new(type=>NF_IGMP_TYPE_REPORTv1);

$expectedOutput = 'IGMP: type:0x12  maxResp:0  checksum:0x0000
IGMP: groupAddress:0.0.0.0';

print $igmp->print;
print "\n";

ok($igmp->print eq $expectedOutput);

# v1 report Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "1200edff00000000";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = 'IGMP: type:0x12  maxResp:0  checksum:0xedff
IGMP: groupAddress:0.0.0.0';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
