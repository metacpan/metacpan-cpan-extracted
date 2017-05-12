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

my ($igmp, $qry, $rpt1, $rpt2, $packet, $decode, $expectedOutput);

# v3 query
$igmp = Net::Frame::Layer::IGMP->new;
$qry  = Net::Frame::Layer::IGMP::v3Query->new(sourceAddress=>['1.1.1.1']);
$qry->computeLengths;

$expectedOutput = 'IGMP: type:0x11  maxResp:0  checksum:0x0000
IGMP: groupAddress:0.0.0.0
IGMP::v3Query: resv:0  sFlag:0  qrv:2  qqic:125  numSources:1
IGMP::v3Query: sourceAddress:1.1.1.1';

print $igmp->print . "\n";
print $qry->print . "\n";

ok(($igmp->print . "\n" . $qry->print) eq $expectedOutput);

# v3 query Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "1100fe7c00000000027d000101010101";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = 'IGMP: type:0x11  maxResp:0  checksum:0xfe7c
IGMP: groupAddress:0.0.0.0
IGMP::v3Query: resv:0  sFlag:0  qrv:2  qqic:125  numSources:1
IGMP::v3Query: sourceAddress:1.1.1.1';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# v3 report
$igmp = Net::Frame::Layer::IGMP->v3report(numGroupRecs=>2);
$rpt1 = Net::Frame::Layer::IGMP::v3Report->new(sourceAddress=>['1.1.1.1','2.2.2.2'],auxData=>"aux Data is present");
$rpt2 = Net::Frame::Layer::IGMP::v3Report->new;
$rpt1->computeLengths;
$rpt2->computeLengths;

$expectedOutput = "IGMP: type:0x22  maxResp:0  checksum:0x0000
IGMP: reserved:0  numGroupRecs:2
IGMP::v3Report: type:1  auxDataLen:5  numSources:2
IGMP::v3Report: multicastAddress:0.0.0.0
IGMP::v3Report: sourceAddress:1.1.1.1
IGMP::v3Report: sourceAddress:2.2.2.2
IGMP::v3Report: auxData:aux Data is present\0
IGMP::v3Report: type:1  auxDataLen:0  numSources:0
IGMP::v3Report: multicastAddress:0.0.0.0";

print $igmp->print . "\n";
print $rpt1->print . "\n";
print $rpt2->print . "\n";

ok(($igmp->print . "\n" . $rpt1->print . "\n" . $rpt2->print) eq $expectedOutput);

# v3 report Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "220000ba000000020105000200000000010101010202020261757820446174612069732070726573656e74000100000000000000";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'IGMP'
);

$expectedOutput = "IGMP: type:0x22  maxResp:0  checksum:0x00ba
IGMP: reserved:0  numGroupRecs:2
IGMP::v3Report: type:1  auxDataLen:5  numSources:2
IGMP::v3Report: multicastAddress:0.0.0.0
IGMP::v3Report: sourceAddress:1.1.1.1
IGMP::v3Report: sourceAddress:2.2.2.2
IGMP::v3Report: auxData:aux Data is present\0
IGMP::v3Report: type:1  auxDataLen:0  numSources:0
IGMP::v3Report: multicastAddress:0.0.0.0";

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
