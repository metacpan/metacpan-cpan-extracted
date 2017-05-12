use Test::Builder::Tester tests => 58;
use Test::More;

use_ok( 'Test::Data', 'Scalar' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
foreach my $value ( [], {} ) {
	my $object = bless $value;
	test_out('ok 1 - Scalar is blessed');
	blessed_ok( $object );
	test_test('blessed_ok');
	}

foreach my $value ( [], {}, "Hello", undef, '', 1, 0 ) {
	my $ref = ref $value;

	test_diag("Expected a blessed value, but didn't get it",
		qq|\tReference type is "$ref"|,
		"    Failed test ($0 at line " . line_num(+4) . ")",);
	test_out('not ok 1 - Scalar is blessed');
	blessed_ok( $value );
	test_test('blessed_ok catches non-reference');
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out('ok 1 - Scalar is defined');
defined_ok( "defined" );
test_test('defined_ok');

test_diag("Expected a defined value, got an undefined one",
	"Scalar is defined",
	"    Failed test ($0 at line " . line_num(+4) . ")",);
test_out('not ok 1 - Scalar is defined');
defined_ok( undef );
test_test('defined_ok catches undef');

{
my $test;
test_out( map { "ok $_ - Scalar is undefined" } 1 .. 2 );
undef_ok( undef );
undef_ok( $test );
test_test('undef_ok');
}

foreach my $value ( 'foo', '', 0, '0' ) {
	my $test = 'foo';
	test_diag("Expected an undefined value, got a defined one",
		"    Failed test ($0 at line " . line_num(+3) . ")",);
	test_out( 'not ok 1 - Scalar is undefined' );
	undef_ok( 'foo' );
	test_test('undef_ok catches defined value');
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
foreach my $pair ( ( [2,1], [4,2], [0,-1], [-1,-2] ) ) {
	test_out('ok 1 - Scalar is greater than bound');
	greater_than( $pair->[0], $pair->[1] );
	test_test('greater_than');

	test_diag("Number is greater than the bound.",
		"\tExpected a number less than [$$pair[1]]",
		"\tGot [$$pair[0]]",
		"    Failed test ($0 at line " . line_num(+6) . ")",
		);
	test_out('not ok 1 - Scalar is less than bound');
	less_than( $pair->[0], $pair->[1] );
	test_test('less than catches out-of-bonds');

	test_out('ok 1 - Scalar is less than bound');
	less_than( $pair->[1], $pair->[0] );
	test_test('less_than');

	test_diag("Number is less than the bound.",
		"\tExpected a number greater than [$$pair[0]]",
		"\tGot [$$pair[1]]",
		"    Failed test ($0 at line " . line_num(+6) . ")",
		);
	test_out('not ok 1 - Scalar is greater than bound');
	greater_than( $pair->[1], $pair->[0] );
	test_test('greater_than catches out-of-bonds');
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
foreach my $string ( ( '', '123', ' ', 'Roscoe' ) ) {
	my $length = length $string;
	test_out(
"ok 1 - Scalar has right length",
"ok 2 - Scalar length is less than bound",
"ok 3 - Scalar length is less than bound",
"ok 4 - Scalar length is greater than bound",
"ok 5 - Scalar length is greater than bound",
"ok 6 - Scalar length is greater than bound",
);
	length_ok( $string, $length );
	maxlength_ok( $string, $length );
	maxlength_ok( $string, $length + 1 );
	minlength_ok( $string, $length );
	minlength_ok( $string, $length - 1 );
	minlength_ok( $string, 0 );
	test_test('length_ok, maxlength_ok, minlength_ok');

	foreach my $bad ( $length - 1, $length + 1, -1, 0 )
		{
		next if $bad == $length;

		test_diag("Length of value not within bounds",
			"\tExpected length=[$bad]",
			"\tGot [$length]",
			"    Failed test ($0 at line " . line_num(+6) . ")",
			);
		test_out('not ok 1 - Scalar has right length');
		length_ok( $string, $bad );
		test_test('length_ok catches errors');
		}

	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out(
"ok 1 - Scalar is a reference",
"ok 2 - Scalar is not a weak reference",
"ok 3 - Scalar is a reference",
"ok 4 - Scalar is not a weak reference",
 );
foreach my $value ( ( {}, [] ) ) {
	ref_ok( $value );
	strong_ok( $value );
	}
test_test('ref_ok, strong_ok');

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( map { "ok $_ - Scalar is in numerical range" } 1 .. 4 );
number_between_ok( 5, 5, 6 );
number_between_ok( 6, 5, 6 );
number_between_ok( 5, 4, 6 );
number_between_ok( 5.5, 5, 6 );
test_test('number_between_ok');

test_diag("Number [4] was not within bounds",
	"\tExpected lower bound [5]",
	"\tExpected upper bound [6]",
	"    Failed test ($0 at line " . line_num(+5) . ")",);
test_out( "not ok 1 - Scalar is in numerical range" );
number_between_ok( 4, 5, 6 );
test_test('number_between_ok catches failures');

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( map { "ok $_ - Scalar is in string range" } 1 .. 5 );
string_between_ok( 5, 5, 6 );
string_between_ok( 6, 5, 6 );
string_between_ok( 5, 4, 6 );
string_between_ok( 'dino', 'barney', 'fred' );
string_between_ok( 11, 1, 2 );
test_test('string_between_ok');

test_diag("String [wilma] was not within bounds",
	"\tExpected lower bound [fred]",
	"\tExpected upper bound [pebbles]",
	"    Failed test ($0 at line " . line_num(+5) . ")",);
test_out( "not ok 1 - Scalar is in string range" );
string_between_ok( 'wilma', 'fred', 'pebbles' );
test_test('string_between_ok catches failures');

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
test_out( map { "ok $_ - Scalar is not tainted" } 1 .. 1 );
untainted_ok( 'Foo' );
test_test('untainted_ok');
