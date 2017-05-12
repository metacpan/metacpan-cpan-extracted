#!perl -w
$|++;

use strict;
use Test::More tests => 326;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( regex_range );

my $range;

# test option management (via commenting option)
$range = regex_range( 3, 4 );
ok($range); # regex_range works before we call init()
$range = regex_range( 3, 4, {no_leading_zeroes => 1} );
ok($range); # regex_range with options works before we call init()
ok($range =~ /[?][#]/); # range has a comment by default (as per $default_opts)

# call init(comment => 0) (legacy format, no hashref), make sure comments go away
eval { Number::Range::Regex->init( comment => 0 ); };
ok(!$@); # called init without dying
$range = regex_range( 3, 4 );
ok($range);
ok($range !~ /[?][#]/);
$range = regex_range( 3, 4, {comment => 1} );
ok($range);
ok($range =~ /[?][#]/);

# call init( {comment => 1} ) (new format w/ hashref), check commenting
eval { Number::Range::Regex->init( { comment => 1 } ); };
ok(!$@); # called init without dying
$range = regex_range( 3, 4 );
ok($range);
ok($range =~ /[?][#]/);
$range = regex_range( 3, 4, {comment => 0} );
ok($range);
ok($range !~ /[?][#]/);

# tests for explicit comment => 0 vs comment => 1 differences
my $range_uncommented = regex_range( 3, 59, { comment => 0 } );
ok($range_uncommented);
my $range_commented = regex_range( 3, 59, { comment => 1 } );
ok($range_commented);
ok($range_commented ne $range_uncommented);
ok(length $range_commented > length $range_uncommented);
ok($range_commented =~ /[?][#]/);

# tests for readable => 1
$range = test_range_exhaustive( 17, 1123, {readable => 1} );
ok($range);
$range = test_range_partial( 53, undef, [53, 103], {readable => 1} );
ok($range);
$range = test_range_partial( undef, 53, [0, 53], {readable => 1} );
ok($range);

# tests for option-setting and default-restoring of init()
Number::Range::Regex->init( foo => "bar" );
ok(1); #called init() without dying
eval {
  Number::Range::Regex->regex_range( 3, 4 );
}; ok($@);
eval { regex_range( "three", 4 ); }; ok($@);
eval { regex_range( 0, "four" ); }; ok($@);
Number::Range::Regex->init();
ok(1); #called init() without dying (again)

# min must not be less than max unless autoswap option is set
$range = eval { regex_range( 12, 8 ) }; ok($@); # min > max
$range = eval { regex_range( 12, 8, { autoswap => 1 } ) }; ok(!$@);
ok( $range );
ok(7 !~ /^$range$/);
ok(8 =~ /^$range$/);
ok(9 =~ /^$range$/);
ok(10 =~ /^$range$/);
ok(11 =~ /^$range$/);
ok(12 =~ /^$range$/);
ok(13 !~ /^$range$/);

# tests for regex_range(undef, undef) aka "wildcarding"
eval { regex_range() }; ok($@); # must specify at least a min or a max
ok($@);
my $wildcard_range = eval { regex_range( undef, undef, { allow_wildcard => 1 } ) };
ok(!$@);
ok($wildcard_range);
$wildcard_range = eval { regex_range( '-inf', undef, {allow_wildcard => 0 } ) };
ok(!$@);
ok($wildcard_range);
$wildcard_range = eval { regex_range( undef, '+inf', {allow_wildcard => 0 } ) };
ok(!$@);
ok($wildcard_range);
ok( "-90" =~ /^$wildcard_range$/ );
ok( "67" =~ /^$wildcard_range$/ );
ok( "+67" =~ /^$wildcard_range$/ );
ok( "0" =~ /^$wildcard_range$/ );
ok( ".3" !~ /^$wildcard_range$/ ); #no decimal support

my $equals_four = regex_range( 4, 4 );
ok($equals_four);
ok("3" !~ /^$equals_four$/);
ok("4" =~ /^$equals_four$/);
ok("4.1" !~ /^$equals_four$/);
ok("40" !~ /^$equals_four$/);
ok("5" !~ /^$equals_four$/);

my $equals_one = regex_range( 1, 1 );
ok($equals_one);
ok("0" !~ /^$equals_one$/);
ok("1" =~ /^$equals_one$/);
ok("1.1" !~ /^$equals_one$/);
ok("10" !~ /^$equals_one$/);
ok("2" !~ /^$equals_one$/);

my $equals_zero = regex_range( 0, 0 );
ok($equals_zero);
ok("-1" !~ /^$equals_zero$/);
ok("0" =~ /^$equals_zero$/);
ok("0.1" !~ /^$equals_zero$/);
ok("00" =~ /^$equals_zero$/); # leading zeroes ok for zero!
ok("1" !~ /^$equals_zero$/);

my $four_or_five = regex_range( 4, 5 );
ok($four_or_five);
ok("3" !~ /^$four_or_five$/);
ok("4" =~ /^$four_or_five$/);
ok("4.1" !~ /^$four_or_five$/);
ok("40" !~ /^$four_or_five$/);
ok("5" =~ /^$four_or_five$/);
ok("6" !~ /^$four_or_five$/);

my $nine_or_ten = regex_range( 9, 10 );
ok($nine_or_ten);
ok("8" !~ /^$nine_or_ten$/);
ok("9" =~ /^$nine_or_ten$/);
ok("9.1" !~ /^$nine_or_ten$/);
ok("90" !~ /^$nine_or_ten$/);
ok("10" =~ /^$nine_or_ten$/);
ok("11" !~ /^$nine_or_ten$/);

my $zero_or_more = regex_range( 0, undef );
ok($zero_or_more);
ok("0" =~ /^$zero_or_more$/);
ok("1" =~ /^$zero_or_more$/);
ok("1.5" !~ /^$zero_or_more$/);
ok("99" =~ /^$zero_or_more$/);

my $zero_or_less = regex_range( undef, 0 );
ok($zero_or_less);
ok("0" =~ /^$zero_or_less$/);
ok("1" !~ /^$zero_or_less$/);

my $one_or_more = regex_range( 1, undef );
ok($one_or_more);
ok("0" !~ /^$one_or_more$/);
ok("1" =~ /^$one_or_more$/);
ok("1.5" !~ /^$zero_or_more$/);
ok("99" =~ /^$one_or_more$/);

my $one_or_less = regex_range( undef, 1 );
ok($one_or_less);
ok("0" =~ /^$one_or_less$/);
ok("1" =~ /^$one_or_less$/);
ok("2" !~ /^$one_or_less$/);

my $nine_ninety_seven_or_more = regex_range( 997, undef );
ok($nine_ninety_seven_or_more);
ok("0" !~ /^$nine_ninety_seven_or_more$/);
ok("9" !~ /^$nine_ninety_seven_or_more$/);
ok("99" !~ /^$nine_ninety_seven_or_more$/);
ok("996" !~ /^$nine_ninety_seven_or_more$/);
ok("997" =~ /^$nine_ninety_seven_or_more$/);
ok("998" =~ /^$nine_ninety_seven_or_more$/);
ok("1000" =~ /^$nine_ninety_seven_or_more$/);
ok("23456" =~ /^$nine_ninety_seven_or_more$/);

my $nine_ninety_seven_or_less = regex_range( undef, 997 );
ok($nine_ninety_seven_or_less);
ok("0" =~ /^$nine_ninety_seven_or_less$/);
ok("9" =~ /^$nine_ninety_seven_or_less$/);
ok("99" =~ /^$nine_ninety_seven_or_less$/);
ok("996" =~ /^$nine_ninety_seven_or_less$/);
ok("997" =~ /^$nine_ninety_seven_or_less$/);
ok("998" !~ /^$nine_ninety_seven_or_less$/);
ok("1000" !~ /^$nine_ninety_seven_or_less$/);
ok("23456" !~ /^$nine_ninety_seven_or_less$/);

# no_leading_zeroes tests
$range = regex_range( 0, 0, {no_leading_zeroes => 0} );
ok($range);
ok(0 =~ /^$range$/);
ok("00" =~ /^$range$/);
$range = regex_range( 0, 0, {no_leading_zeroes => 1} );
ok($range);
ok(0 =~ /^$range$/);
ok("00" !~ /^$range$/);
$range = regex_range( 1, 1, {no_leading_zeroes => 0} );
ok($range);
ok(1 =~ /^$range$/);
ok("01" =~ /^$range$/);
$range = regex_range( 1, 1, {no_leading_zeroes => 1} );
ok($range);
ok(1 =~ /^$range$/);
ok("01" !~ /^$range$/);
$range = regex_range( 9, 10, {no_leading_zeroes => 0} );
ok($range);
ok(9 =~ /^$range$/);
ok("09" =~ /^$range$/);
ok(10 =~ /^$range$/);
ok("010" =~ /^$range$/);
$range = regex_range( 9, 10, {no_leading_zeroes => 1} );
ok($range);
ok(9 =~ /^$range$/);
ok("09" !~ /^$range$/);
ok(10 =~ /^$range$/);
ok("010" !~ /^$range$/);


$range = test_range_exhaustive(19825, 20120);
ok($range);
#$range = test_range_partial(19825, 32101, [19800, 19911]);
#$range = test_range_partial(19825, 32101, [31990, 32200]);
$range = test_range_exhaustive(19825, 32101);
ok($range);
ok(0 !~ /^$range$/);
ok(1982 !~ /^$range$/);
ok(2000 !~ /^$range$/);
ok(3000 !~ /^$range$/);
ok(25000 =~ /^$range$/);

#$range = test_range_random(354, 13123, 100);
$range = test_range_exhaustive(354, 13123);
ok($range);
ok(0 !~ /^$range$/);
ok(3 !~ /^$range$/);
ok(35 !~ /^$range$/);
ok(354 =~ /^$range$/);
ok(355 =~ /^$range$/);
ok(1000 =~ /^$range$/);
ok(2000 =~ /^$range$/);
ok(3000 =~ /^$range$/);
ok(4000 =~ /^$range$/);
ok(5000 =~ /^$range$/);
ok(6000 =~ /^$range$/);
ok(7000 =~ /^$range$/);
ok(8000 =~ /^$range$/);
ok(9000 =~ /^$range$/);
ok(10000 =~ /^$range$/);
ok(11000 =~ /^$range$/);
ok(12000 =~ /^$range$/);
ok(13000 =~ /^$range$/);
ok(13100 =~ /^$range$/);
ok(13120 =~ /^$range$/);
ok(13123 =~ /^$range$/);
ok(131234 !~ /^$range$/);

ok(test_range_exhaustive(123, 129));
ok(test_range_exhaustive(103, 129));
ok(test_range_exhaustive(1234, 1239));
ok(test_range_exhaustive(1229, 1239));
ok(test_range_exhaustive(1129, 1239));

# leading zero tests
$range = test_range_exhaustive("07", 128);
ok($range);
ok(6 !~ /^$range$/);
ok("06" !~ /^$range$/);
ok("006" !~ /^$range$/);
ok(7 =~ /^$range$/);
ok("07" =~ /^$range$/);
ok("007" =~ /^$range$/);
ok(8 =~ /^$range$/);
ok("08" =~ /^$range$/);
ok("008" =~ /^$range$/);
ok(60 =~ /^$range$/);
ok("060" =~ /^$range$/);
ok(600 !~ /^$range$/);
ok("0600" !~ /^$range$/);
ok("0700" !~ /^$range$/);
ok("0800" !~ /^$range$/);

$range = test_range_exhaustive(7, "0128");
ok($range);
ok(128 =~ /^$range$/);
ok("0128" =~ /^$range$/);
ok(129 !~ /^$range$/);
ok("0129" !~ /^$range$/);
ok(130 !~ /^$range$/);
ok("0130" !~ /^$range$/);

# this fuller test mirrors the algorithm's internal workings
$range = regex_range(345, 35123);
ok($range);
ok(344 !~ /^$range$/);
ok("0344" !~ /^$range$/);
ok(345 =~ /^$range$/);
ok("0345" =~ /^$range$/);
ok("00345" =~ /^$range$/);
ok(349 =~ /^$range$/);
ok("0349" =~ /^$range$/);
ok("00349" =~ /^$range$/);
ok(350 =~ /^$range$/);
ok("0350" =~ /^$range$/);
ok("00350" =~ /^$range$/);
ok(399 =~ /^$range$/);
ok("0399" =~ /^$range$/);
ok("00399" =~ /^$range$/);
ok(400 =~ /^$range$/);
ok("0400" =~ /^$range$/);
ok("00400" =~ /^$range$/);
ok(999 =~ /^$range$/);
ok("0999" =~ /^$range$/);
ok("00999" =~ /^$range$/);
ok(1000 =~ /^$range$/);
ok("01000" =~ /^$range$/);
ok(9999 =~ /^$range$/);
ok("09999" =~ /^$range$/);
ok(10000 =~ /^$range$/);
ok(29999 =~ /^$range$/);
ok(30000 =~ /^$range$/);
ok(34999 =~ /^$range$/);
ok(35000 =~ /^$range$/);
ok(35099 =~ /^$range$/);
ok(35100 =~ /^$range$/);
ok(35119 =~ /^$range$/);
ok(35120 =~ /^$range$/);
ok(35123 =~ /^$range$/);
ok(35124 !~ /^$range$/);

## do some random tests searching vainly for hard to find bugs
my $MAX_INT = 65535;
eval { require POSIX }; if($@) {
  diag "POSIX::LONG_MAX unavailable, using a very conservative MAX_INT: $MAX_INT";
} else {
  $MAX_INT = POSIX::LONG_MAX();
}
my ($end, $start);
# test as large a spread as possible
$end   = int rand $MAX_INT;
$start = int rand $end;
$range = test_range_random($start, $end, 1000, 0);
ok($range);
my $ss = $start-5;
$ss = 0  if  $ss < 0;
$range = test_range_partial($start, $end, [$ss, $start+5], [$end-5, $end+5] );
ok($range);
# test a spread that involves a lot of digit boundary crossings
$end   = int rand $MAX_INT;
my $log_end = log($end)/log(10);
my $max_power = int($log_end / 2);
$start = int rand($end/10**$max_power);
$range = test_range_random($start, $end, 1000, 0);
ok($range);
$ss = $start-5;
$ss = 0  if  $ss < 0;
$range = test_range_partial($start, $end, [$ss, $start+5], [$end-5, $end+5] );
ok($range);

# max has leading zero(es)
$range = test_range_exhaustive( 17, "01123" );
ok($range);
$range = test_range_exhaustive( 17, "001123" );
ok($range);

# try all of 0..12 x 0..12 exhaustively (this catches the bug from r2820)
ok( test_all_ranges_exhaustively( 0, 12 ) );

# try to catch more corner cases
ok( test_all_ranges_exhaustively( "098", 102 ) );
ok( test_all_ranges_exhaustively( 98, 102 ) );
ok( test_all_ranges_exhaustively( 198, 202 ) );
ok( test_all_ranges_exhaustively( 898, 902 ) );
ok( test_all_ranges_exhaustively( 988, 992 ) );
ok( test_all_ranges_exhaustively( 998, 1002 ) );
ok( test_all_ranges_exhaustively( 1998, 2002 ) );
ok( test_all_ranges_exhaustively( 1098, 1102 ) );

# more tests of negative values
ok( test_all_ranges_exhaustively( "-098", -102 ) );
ok( test_all_ranges_exhaustively( -98, -102 ) );
ok( test_all_ranges_exhaustively( -198, -202 ) );
ok( test_all_ranges_exhaustively( -898, -902 ) );
ok( test_all_ranges_exhaustively( -988, -992 ) );
ok( test_all_ranges_exhaustively( -998, -1002 ) );
ok( test_all_ranges_exhaustively( -1998, -2002 ) );
ok( test_all_ranges_exhaustively( -1098, -1102 ) );

$range = regex_range( -4, -3 );
ok($range);
ok($range !~ m/\[\+\]/);
ok(-5    !~ /^$range$/);
ok('-05' !~ /^$range$/);
ok(-4    =~ /^$range$/);
ok('-04' =~ /^$range$/);
ok(-3    =~ /^$range$/);
ok('-03' =~ /^$range$/);
ok(-2    !~ /^$range$/);
ok('-02' !~ /^$range$/);

$range = regex_range( -4, -3, {no_leading_zeroes => 1} );
ok($range);
ok($range !~ m/\[\+\]/);
ok($range !~ m/0\*/);
ok(-5    !~ /^$range$/);
ok('-05' !~ /^$range$/);
ok(-4    =~ /^$range$/);
ok('-04' !~ /^$range$/);
ok(-3    =~ /^$range$/);
ok('-03' !~ /^$range$/);
ok(-2    !~ /^$range$/);
ok('-02' !~ /^$range$/);

$range = regex_range( -41, -39 );
ok($range);
ok($range !~ m/\[\+\]/);
ok(-42    !~ /^$range$/);
ok('-042' !~ /^$range$/);
ok(-41    =~ /^$range$/);
ok('-041' =~ /^$range$/);
ok(-40    =~ /^$range$/);
ok('-040' =~ /^$range$/);
ok(-39    =~ /^$range$/);
ok('-039' =~ /^$range$/);
ok(-38    !~ /^$range$/);
ok('-038' !~ /^$range$/);

$range = regex_range( -41, -39, {no_leading_zeroes => 1} );
ok($range);
ok($range !~ m/\[\+\]/);
ok($range !~ m/0\*/);
ok(-42    !~ /^$range$/);
ok('-042' !~ /^$range$/);
ok(-41    =~ /^$range$/);
ok('-041' !~ /^$range$/);
ok(-40    =~ /^$range$/);
ok('-040' !~ /^$range$/);
ok(-39    =~ /^$range$/);
ok('-039' !~ /^$range$/);
ok(-38    !~ /^$range$/);
ok('-038' !~ /^$range$/);

$range = regex_range( -401, -399 );
ok($range);
ok($range !~ m/\[\+\]/);
ok(-402    !~ /^$range$/);
ok('-0402' !~ /^$range$/);
ok(-401    =~ /^$range$/);
ok('-0401' =~ /^$range$/);
ok(-400    =~ /^$range$/);
ok('-0400' =~ /^$range$/);
ok(-399    =~ /^$range$/);
ok('-0399' =~ /^$range$/);
ok(-398    !~ /^$range$/);
ok('-0398' !~ /^$range$/);

$range = regex_range( -401, -399, {no_leading_zeroes => 1} );
ok($range);
ok($range !~ m/\[\+\]/);
ok($range !~ m/0\*/);
ok(-402    !~ /^$range$/);
ok('-0402' !~ /^$range$/);
ok(-401    =~ /^$range$/);
ok('-0401' !~ /^$range$/);
ok(-400    =~ /^$range$/);
ok('-0400' !~ /^$range$/);
ok(-399    =~ /^$range$/);
ok('-0399' !~ /^$range$/);
ok(-398    !~ /^$range$/);
ok('-0398' !~ /^$range$/);

