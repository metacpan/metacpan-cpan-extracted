use strict;
use warnings;

use Test::Most;
use Number::Phone::AU;


my @Valid_Numbers = (
    "+61 3 1234 5678",
    "+61 03 1234 5678",
    "+672 923 456",

    131234,
    131000,
    "13 01 00",
    "1300 123456",

    "5      234      56789   ",
    "72   34567    89",

    323456789,
    '0423456789',
    "(82)3456789",
    "(22)3456789",
    "03 5551 1234",

    '180 1234',
    '1800 123456',
    1800123456,
    1801234,
);

my @Invalid_Numbers = (
    "foo",

    2,
    32,
    423,
    5234,
    72345,
    8234567,
    "9876 1234", 
    22345678,
    "212345678998765432",
    "723  45678    90",

    130000,
    '13 012 3456',
    '13 123 45',

    181000,
    '180 123',
    '180 12345',
    '1800 12345',
    '1800 1234567',

    "+61",
    "+672",

    "11238492384",
    "0092834792",
    "106",
    "01 123456578",
    "06 123456578",
    "09 123456578",
    "12 1234",
    "14 123456578",
    "04 5551 1234",
    "03 7010 1234",
    "02 7010 1234",
    "0672 923 456",
    # TODO: an otherwise valid number whose last 8 digits begin with 0 or 1
);


note "valid numbers";
for my $number (@Valid_Numbers) {
    ok( Number::Phone::AU->new($number)->is_valid_contact, "...$number is a valid contact" );
}


note "invalid numbers";
for my $number (@Invalid_Numbers) {
    ok !Number::Phone::AU->new($number)->is_valid_contact, "...$number is not a valid contact";
}

done_testing;
