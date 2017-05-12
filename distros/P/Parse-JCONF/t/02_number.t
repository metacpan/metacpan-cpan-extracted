use strict;
use Test::More;
use Parse::JCONF;

my $parser = Parse::JCONF->new();
my $res = $parser->parse_file('t/files/number_int.jconf');
is_deeply($res, {
	numner1        => 999,
	number2        => -23,
	super_number   => 1111,
	zero           => 0,
	hero           => 0,
	big_number     => 1234567890,
	strange_number => 8
}, "parse integer numbers");

$res = $parser->parse_file('t/files/number_float.jconf');
is_deeply($res, {
	'1_float' => 0.25,
	'2_float' => 100.0,
	'3_float' => -25.43210,
	'4_float' => -99.999
}, "parse float numbers");

$res = $parser->parse_file('t/files/number_scientific_notation.jconf');
is_deeply($res, {
	boobs_size     => 1E20,
	book_pages     => 1E2,
	bacterium_size => 1E-10,
	bank_account   => -123.8e5
}, "parse numbers in scientific notation");

done_testing;
