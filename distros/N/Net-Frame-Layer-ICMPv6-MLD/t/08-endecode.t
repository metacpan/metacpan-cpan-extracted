use Test;
BEGIN { plan(tests => 4) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.08";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.08 required";
}

use Net::Frame::Layer::ICMPv6::MLD qw(:consts);

my ($mld, $qry, $rpt1, $rpt2, $packet, $decode, $expectedOutput);

# query
$mld = Net::Frame::Layer::ICMPv6::MLD->new;
$qry = Net::Frame::Layer::ICMPv6::MLD::Query->new(
    sourceAddress=>[
        '2001:db8::1'
    ]
);
$qry->computeLengths;

$expectedOutput = 'ICMPv6::MLD: maxResp:0  reserved:0
ICMPv6::MLD: groupAddress:::
ICMPv6::MLD::Query: resv:0  sFlag:0  qrv:2  qqic:125  numSources:1
ICMPv6::MLD::Query: sourceAddress:2001:db8::1';

print $mld->print . "\n";
print $qry->print . "\n";

ok(($mld->print . "\n" . $qry->print) eq $expectedOutput);

# query Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "0000000000000000000000000000000000000000027d000120010db8000000000000000000000001";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ICMPv6::MLD'
);

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# report
$mld = Net::Frame::Layer::ICMPv6::MLD::Report->new(numGroupRecs=>1);
$rpt1 = Net::Frame::Layer::ICMPv6::MLD::Report::Record->new(
    sourceAddress=>[
        '2001:db8:a::1',
        '2001:db8:b::1'
    ],
    auxData=>"aux Data is present"
);
$rpt1->computeLengths;

$expectedOutput = "ICMPv6::MLD::Report: reserved:0  numGroupRecs:1
ICMPv6::MLD::Report::Record: type:1  auxDataLen:5  numSources:2
ICMPv6::MLD::Report::Record: multicastAddress:::
ICMPv6::MLD::Report::Record: sourceAddress:2001:db8:a::1
ICMPv6::MLD::Report::Record: sourceAddress:2001:db8:b::1
ICMPv6::MLD::Report::Record: auxData:aux Data is present\0";

print $mld->print . "\n";
print $rpt1->print . "\n";

ok(($mld->print . "\n" . $rpt1->print) eq $expectedOutput);

# report Decode
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "00000001010500020000000000000000000000000000000020010db8000a0000000000000000000120010db8000b0000000000000000000161757820446174612069732070726573656e7400";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ICMPv6::MLD::Report'
);

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
