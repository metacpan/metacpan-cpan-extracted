use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Common::Numeric qw(
    PositiveNum PositiveOrZeroNum
    PositiveInt PositiveOrZeroInt
    NegativeNum NegativeOrZeroNum
    NegativeInt NegativeOrZeroInt
    SingleDigit
);

ok(!is_SingleDigit(100), 'SingleDigit 100');
ok(!is_SingleDigit(10), 'SingleDigit 10');
ok(is_SingleDigit(9), 'SingleDigit 9');
ok(is_SingleDigit(1), 'SingleDigit 1');
ok(is_SingleDigit(0), 'SingleDigit 0');
ok(is_SingleDigit(-1), 'SingleDigit -1');
ok(is_SingleDigit(-9), 'SingleDigit -9');
ok(!is_SingleDigit(-10), 'SingleDigit -10');


ok(!is_PositiveInt(-100), 'PositiveInt (-100)');
ok(!is_PositiveInt(0), 'PositiveInt (0)');
ok(!is_PositiveInt(100.885), 'PositiveInt (100.885)');
ok(is_PositiveInt(100), 'PositiveInt (100)');
ok(!is_PositiveNum(0), 'PositiveNum (0)');
ok(is_PositiveNum(100.885), 'PositiveNum (100.885)');
ok(!is_PositiveNum(-100.885), 'PositiveNum (-100.885)');
ok(is_PositiveNum(0.0000000001), 'PositiveNum (0.0000000001)');

ok(!is_PositiveOrZeroInt(-100), 'PositiveOrZeroInt (-100)');
ok(is_PositiveOrZeroInt(0), 'PositiveOrZeroInt (0)');
ok(!is_PositiveOrZeroInt(100.885), 'PositiveOrZeroInt (100.885)');
ok(is_PositiveOrZeroInt(100), 'PositiveOrZeroInt (100)');
ok(is_PositiveOrZeroNum(0), 'PositiveOrZeroNum (0)');
ok(is_PositiveOrZeroNum(100.885), 'PositiveOrZeroNum (100.885)');
ok(!is_PositiveOrZeroNum(-100.885), 'PositiveOrZeroNum (-100.885)');
ok(is_PositiveOrZeroNum(0.0000000001), 'PositiveOrZeroNum (0.0000000001)');

ok(!is_NegativeInt(100), 'NegativeInt (100)');
ok(!is_NegativeInt(-100.885), 'NegativeInt (-100.885)');
ok(is_NegativeInt(-100), 'NegativeInt (-100)');
ok(!is_NegativeInt(0), 'NegativeInt (0)');
ok(is_NegativeNum(-100.885), 'NegativeNum (-100.885)');
ok(!is_NegativeNum(100.885), 'NegativeNum (100.885)');
ok(!is_NegativeNum(0), 'NegativeNum (0)');
ok(is_NegativeNum(-0.0000000001), 'NegativeNum (-0.0000000001)');

ok(!is_NegativeOrZeroInt(100), 'NegativeOrZeroInt (100)');
ok(!is_NegativeOrZeroInt(-100.885), 'NegativeOrZeroInt (-100.885)');
ok(is_NegativeOrZeroInt(-100), 'NegativeOrZeroInt (-100)');
ok(is_NegativeOrZeroInt(0), 'NegativeOrZeroInt (0)');
ok(is_NegativeOrZeroNum(-100.885), 'NegativeOrZeroNum (-100.885)');
ok(!is_NegativeOrZeroNum(100.885), 'NegativeOrZeroNum (100.885)');
ok(is_NegativeOrZeroNum(0), 'NegativeOrZeroNum (0)');
ok(is_NegativeOrZeroNum(-0.0000000001), 'NegativeOrZeroNum (-0.0000000001)');

done_testing;
