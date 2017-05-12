use Test::Builder::Tester tests => 3;
use Test::More;
use Test::Data qw(Array);

#use Carp;
#$SIG{__WARN__} = \&confess;
my %line;

TEST_ARRAY_FUNCS: {
my @array = 4..6;
my @empty = ();

test_err();

array_any_ok(  5, @array );
test_out( "ok 1 - Array contains item" );

array_any_ok(  9, @array, "Array does not contain 9, go fish" ); $line{'9x0'} = __LINE__;
test_out( "not ok 2 - Array does not contain 9, go fish" );

array_once_ok( 5, @array, "Array contains 5 once" );
test_out( "ok 3 - Array contains 5 once" );

{
my @array = (5, 5);
array_once_ok( 5, @array, "Array has 5 twice, not once" ); $line{'5x2'} = __LINE__;
test_out( "not ok 4 - Array has 5 twice, not once" );

@array = ();
array_once_ok( 5, @array, "Array has no items" ); $line{'5x0'} = __LINE__;
test_out( "not ok 5 - Array has no items" ); 

@array = ( 6, 6 );
array_once_ok( 5, @array, "Array has no 5's, but two 6's" );  $line{'6x2'} = __LINE__;
test_out( "not ok 6 - Array has no 5's, but two 6's" );
}


array_none_ok( 7, @array );
array_sum_ok( 15, @array );
array_max_ok(  6, @array );
array_min_ok(  3, @array );
array_empty_ok( @empty );
array_length_ok( @array, 3 );
test_out( 
    "ok 7 - Array does not contain item",
    "ok 8 - Array sum is correct",
    "ok 9 - Array maximum is okay",
    "ok 10 - Array minimum is okay",
    "ok 11 - Array is empty",
    "ok 12 - Array length is correct",
	);

test_err( "#     Failed test ($0 at line $line{'9x0'})",
	"#     Failed test ($0 at line $line{'5x2'})",
	"#     Failed test ($0 at line $line{'5x0'})",
	"#     Failed test ($0 at line $line{'6x2'})"
	);
test_test('Array functions work');
}

TEST_STR_SORTS: {
my @array   = 'a' .. 'f';
my @reverse = reverse @array;

test_err();

array_sortedstr_ascending_ok( @array );
array_sortedstr_descending_ok( @reverse );

test_out(
	"ok 1 - Array is in ascending order",
	"ok 2 - Array is in descending order",
	);

array_sortedstr_ascending_ok( @reverse ); $line{'up'} = __LINE__;
array_sortedstr_descending_ok( @array ); $line{'down'} = __LINE__;
test_out(
	'not ok 3 - Array is in ascending order',
	'not ok 4 - Array is in descending order',
	);
test_err(
	"#     Failed test ($0 at line $line{up})",
	"#     Failed test ($0 at line $line{down})",
	);

my @bad = ( 'a' .. 'f', 'b' );
my @bad_reverse = reverse @bad;

array_sortedstr_ascending_ok( @bad ); $line{'up'} = __LINE__;
array_sortedstr_descending_ok( @bad_reverse ); $line{'down'} = __LINE__;
test_out(
	'not ok 5 - Array is in ascending order',
	'not ok 6 - Array is in descending order',
	);
test_err(
	"#     Failed test ($0 at line $line{up})",
	"#     Failed test ($0 at line $line{down})",
	);

test_test('Sort comparisons work');
}

TEST_NUM_SORTS: {
my @array   = 1 .. 5;
my @reverse = reverse @array;

test_err();

array_sorted_ascending_ok( @array );
array_sorted_descending_ok( @reverse );

test_out(
	"ok 1 - Array is in ascending order",
	"ok 2 - Array is in descending order",
	);

array_sorted_ascending_ok( @reverse ); $line{up} = __LINE__;
array_sorted_descending_ok( @array ); $line{down} = __LINE__;
test_out(
	'not ok 3 - Array is in ascending order',
	'not ok 4 - Array is in descending order',
	);
test_err(
	"#     Failed test ($0 at line $line{up})",
	"#     Failed test ($0 at line $line{down})",
	);

my @bad = ( 1 .. 5, 3 );
my @bad_reverse = reverse @bad;

array_sorted_ascending_ok( @bad ); $line{up} = __LINE__;
array_sorted_descending_ok( @bad_reverse ); $line{down} = __LINE__;
test_out(
	'not ok 5 - Array is in ascending order',
	'not ok 6 - Array is in descending order',
	);
test_err(
	"#     Failed test ($0 at line $line{up})",
	"#     Failed test ($0 at line $line{down})",
	);

test_test('Sort comparisons work');
}
