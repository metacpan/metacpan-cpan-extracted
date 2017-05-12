#!/usr/bin/perl

use Test::More tests => 51;

use lib '../lib', 'lib';

use_ok('SMB::Parser');

my $parser = SMB::Parser->new("Hello, world");
isa_ok($parser, 'SMB::Parser');

my @expected = (
	[ 72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, undef, undef ],
	[ 25928, 27756, 11375, 30496, 29295, 25708 ],
	[ 18533, 27756, 28460, 8311, 28530, 27748 ],
	[ 1819043144, 1998597231, 1684828783 ],
	[ 1214606444, 1865162871, 1869769828 ],
);

# test uint*
for my $n (1 .. @expected) {
	my $expected = $expected[$n - 1];
	my $suffix = $n == 1 ? '8' : $n == 2 ? '16' : $n == 3 ? '16_be' : $n == 4 ? '32' : $n == 5 ? '32_be' : die;
	my $method = "uint$suffix";
	$parser->reset;
	is($parser->offset, 0, "$n reset");
	for my $i (1 .. @$expected) {
		is($parser->$method(), $expected->[$i - 1], "$n $method $i");
	}
}

$parser->reset;
is($parser->bytes(1), 'H',       "bytes(1)");
is($parser->offset, 1,           "offset +1");
is($parser->bytes(4), 'ello',    "bytes(4)");
is($parser->offset, 5,           "offset +4");
is($parser->bytes(8), ', world', "bytes(8)");
is($parser->offset, 13,          "offset +8");
is($parser->bytes(2), '',        "bytes(2)");
is($parser->offset, 15,          "offset +2");

$parser->set(scalar localtime);
is($parser->bytes($parser->size), $parser->data, "bytes(all)");
is($parser->offset, $parser->size, "offset end");
is($parser->uint32, undef,       "uint32");
is($parser->bytes(2000), '',     "bytes(2000)");
