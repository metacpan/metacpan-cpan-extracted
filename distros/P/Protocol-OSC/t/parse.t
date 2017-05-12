use strict;
use warnings;
use Test::More;
use Protocol::OSC;

my @tests = (
    ['pattern i0'  => "/test\x00\x00\x00".",i\x00\x00"."\x00\x00\x00\x00" => ['/test','i',0]],
    ['pattern i1'  => "/test\x00\x00\x00".",i\x00\x00"."\x00\x00\x00\x01" => ['/test','i',1]],
    ['pattern i0i0' => "/test\x00\x00\x00".",ii\x00"."\x00\x00\x00\x00"."\x00\x00\x00\x00" => ['/test','ii',0,0]],
    ['pattern i0i1' => "/test\x00\x00\x00".",ii\x00"."\x00\x00\x00\x00"."\x00\x00\x00\x01" => ['/test','ii',0,1]],
    ['pattern i1i0' => "/test\x00\x00\x00".",ii\x00"."\x00\x00\x00\x01"."\x00\x00\x00\x00" => ['/test','ii',1,0]],
    ['pattern i1i1' => "/test\x00\x00\x00".",ii\x00"."\x00\x00\x00\x01"."\x00\x00\x00\x01" => ['/test','ii',1,1]],
    ['pattern s0s0' => "/test\x00\x00\x00".",ss\x00"."\x00\x00\x00\x00"."\x00\x00\x00\x00" => ['/test','ss','','']],
    ['pattern f0f0' => "/test\x00\x00\x00".",ff\x00"."\x00\x00\x00\x00"."\x00\x00\x00\x00" => ['/test','ff',0,0]],
);

my $osc = Protocol::OSC->new;

sub test_parse {
    my ($label, $data, $expected) = @_;
    is_deeply($osc->parse($data), $expected, "$label");
}

foreach (@tests) {
    test_parse($_->[0], $_->[1], $_->[2]);
}

done_testing();
