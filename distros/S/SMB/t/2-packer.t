#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 105;

use lib '../lib', 'lib';

use_ok('SMB::Packer');

my $packer = SMB::Packer->new;
isa_ok($packer, 'SMB::Packer');

my @uints = (
	[ 72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100 ],
	[ 25928, 27756, 11375, 30496, 29295, 25708 ],
	[ 18533, 27756, 28460, 8311, 28530, 27748 ],
	[ 1819043144, 1998597231, 1684828783 ],
	[ 1214606444, 1865162871, 1869769828 ],
);

# test uint*
for my $n (1 .. @uints) {
	my $uints = $uints[$n - 1];
	my $suffix = $n == 1 ? '8' : $n == 2 ? '16' : $n == 3 ? '16_be' : $n == 4 ? '32' : $n == 5 ? '32_be' : die;
	my $method = "uint$suffix";
	my ($factor) = $suffix =~ /(\d+)/;
	$packer->reset;
	is($packer->offset, 0, "$n reset");
	for my $i (1 .. @$uints) {
		ok($packer->$method($uints->[$i - 1]), "$n $method $i");
	}
	is($packer->size, $factor / 8 * @$uints, "$n size");
	is($packer->offset, $packer->size, "$n offset");
	is($packer->data, 'Hello, world', "$n data");
}

$packer->reset;
ok($packer->bytes('Hello'),      "bytes('Hello')");
is($packer->size, 5,             "size +5");
ok($packer->bytes(', world'),    "bytes(', world')");
is($packer->offset, 12,          "offset +7");
ok($packer->bytes('!'),          "bytes('!')");
is($packer->size, 13,            "size +1");

ok($packer->skip(1),             "skip(1)");
is($packer->offset, 14,          "offset +1");
ok($packer->mark('timestr'),     "mark('timestr')");
ok($packer->bytes(scalar localtime), "bytes(localtime)");
is($packer->offset, $packer->size, "offset end");
ok($packer->jump('timestr'),     "jump('timestr')");
is($packer->offset, 14,          "offset 14");
isnt($packer->offset, $packer->size, "offset not at end");
ok($packer->stub('a', 'uint16'), "stub('a', 'uint16')");
is($packer->offset, 16,          "offset +2");
ok($packer->stub('b', 2000),     "stub('b', '2000')");
is($packer->offset, 2016,        "offset +2000");
ok($packer->fill('b', ' ' x 2000), "fill('b', ' ' x 2000)");
is($packer->size, 2016,          "size 2016");
ok($packer->fill('a', 11111),    "fill('a', 11111)");
is($packer->offset, $packer->size, "offset at end");

$packer->reset;
ok($packer->str('Hello'),        "str('Hello')");
is($packer->size, 10,            "size +10");
ok($packer->mark('a'),           "mark('a')");
ok($packer->str('OK', 'ascii'),  "str('OK', 'C')");
is($packer->size, 12,            "size +2");
ok($packer->mark('b'),           "mark('b')");
ok($packer->stub('', 'uint8'),   "stub('', 'uint8')");
ok($packer->utf16('OK'),         "utf16('OK')");
is($packer->offset, $packer->size, "offset at end");
ok($packer->fill('', 0x77),      "fill('', 0x77)");
is($packer->data, "H\0e\0l\0l\0o\0OK\x77O\0K\0", "data");

ok($packer->jump('b'),           "jump('b')");
is($packer->size, 17,            "size is 17");
is($packer->offset, 12,          "offset is 12");
ok($packer->skip(1),             "skip(1)");
is($packer->data, "H\0e\0l\0l\0o\0OK\x77O\0K\0", "data still the same");
ok($packer->align,               "align");
is($packer->size, 17,            "size is still 17");
is($packer->offset, 16,          "offset is 16");
ok($packer->align,               "align again");
is($packer->size, 17,            "size is again 17");
is($packer->offset, 16,          "offset is still 16");
ok($packer->mark('b'),           "mark('b') again");
ok($packer->uint8(0321),         "uint8(0321)");
ok($packer->align('a'),          "align('a')");
is($packer->size, 18,            "size is 18");
is($packer->offset, 18,          "offset is 18");
is($packer->data, "H\0e\0l\0l\0o\0OK\x77O\0K\321\0", "new data");
ok($packer->jump('b'),           "jump('b') again");
ok($packer->skip(3),             "skip(3)");
is($packer->data, "H\0e\0l\0l\0o\0OK\x77O\0K\321\0\0", "another new data");
