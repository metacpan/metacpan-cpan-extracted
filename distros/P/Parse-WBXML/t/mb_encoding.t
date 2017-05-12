use strict;
use warnings;

use Test::More;
use Parse::WBXML;

my @cases = (
	"\xFF" => undef,
	"\x00" => 0x00,
	"\x20" => 0x20,
	"\x7F" => 0x7F,
	"\x80\x00" => 0x00,
	"\x81\x00" => 0x80,
	"\x81\x01" => 0x81,
	"\x81\x20" => 0xA0,
	"\x81\x81\x01" => 0x4081,
	"\x81\x81\x81\x01" => 0x204081,
	"\x81\x81\x81\x81\x01" => 0x10204081,
	"\x84\x81\x81\x81\x01" => 0x40204081,
);

plan tests => 1 * @cases;

while(@cases) {
	my ($str, $value) = splice @cases, 0, 2;
	my $copy = $str;
	my $v = Parse::WBXML->mb_to_int(\$copy);
	if(defined $value) {
		is($v, $value, "have $value");
		is(length($copy), 0, 'have removed all available chars');
	} else {
		ok(!defined($v), "value not defined");
		is($copy, $str, "original not affected");
	}
}
done_testing();

