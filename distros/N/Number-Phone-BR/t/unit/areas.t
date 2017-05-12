#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use Number::Phone::BR::Areas qw(
    code2name
    mobile_phone_digits_by_area
);

is code2name(11) => 'SP - Região Metropolitana de São Paulo', 'code2name(11)';
is code2name(54) => 'RS - Caxias do Sul e Região', 'code2name(54)';
is code2name(89) => 'PI - Região de Picos e Floriano', 'code2name(89)';
is code2name(99) => 'MA - Região de Imperatriz', 'code2name(99)';

subtest 'mobile digits - current year is 2014' => sub {
    no warnings 'redefine';
    *Number::Phone::BR::Areas::_get_current_year = sub { 2014 };

    is(mobile_phone_digits_by_area(11), 9, 'mobiles in 11 are 9 digits');
    is(mobile_phone_digits_by_area(16), 9, 'mobiles in 16 are 9 digits');
    is(mobile_phone_digits_by_area(19), 9, 'mobiles in 19 are 9 digits');
    is(mobile_phone_digits_by_area(21), 9, 'mobiles in 21 are 9 digits');
    is(mobile_phone_digits_by_area(28), 9, 'mobiles in 28 are 9 digits');

    is(mobile_phone_digits_by_area(91), 8, 'mobiles in 91 are 8 digits');
    is(mobile_phone_digits_by_area(95), 8, 'mobiles in 95 are 8 digits');
    is(mobile_phone_digits_by_area(99), 8, 'mobiles in 99 are 8 digits');

    is(mobile_phone_digits_by_area(31), 8, 'mobiles in 31 are 8 digits');
    is(mobile_phone_digits_by_area(73), 8, 'mobiles in 73 are 8 digits');
    is(mobile_phone_digits_by_area(89), 8, 'mobiles in 89 are 8 digits');

    is(mobile_phone_digits_by_area(41), 8, 'mobiles in 41 are 8 digits');
    is(mobile_phone_digits_by_area(61), 8, 'mobiles in 61 are 8 digits');
    is(mobile_phone_digits_by_area(69), 8, 'mobiles in 69 are 8 digits');
};

subtest 'mobile digits - current year is 2015' => sub {
    no warnings 'redefine';
    *Number::Phone::BR::Areas::_get_current_year = sub { 2015 };

    is mobile_phone_digits_by_area(11) => 9, 'mobiles in 11 are 9 digits';
    is mobile_phone_digits_by_area(16) => 9, 'mobiles in 16 are 9 digits';
    is mobile_phone_digits_by_area(19) => 9, 'mobiles in 19 are 9 digits';
    is mobile_phone_digits_by_area(21) => 9, 'mobiles in 21 are 9 digits';
    is mobile_phone_digits_by_area(28) => 9, 'mobiles in 28 are 9 digits';

    is mobile_phone_digits_by_area(91) => 9, 'mobiles in 91 are 9 digits';
    is mobile_phone_digits_by_area(95) => 9, 'mobiles in 95 are 9 digits';
    is mobile_phone_digits_by_area(99) => 9, 'mobiles in 99 are 9 digits';

    is mobile_phone_digits_by_area(31) => 8, 'mobiles in 31 are 8 digits';
    is mobile_phone_digits_by_area(73) => 8, 'mobiles in 73 are 8 digits';
    is mobile_phone_digits_by_area(89) => 8, 'mobiles in 89 are 8 digits';

    is mobile_phone_digits_by_area(41) => 8, 'mobiles in 41 are 8 digits';
    is mobile_phone_digits_by_area(61) => 8, 'mobiles in 61 are 8 digits';
    is mobile_phone_digits_by_area(69) => 8, 'mobiles in 69 are 8 digits';
};

subtest 'mobile digits - current year is 2016' => sub {
    no warnings 'redefine';
    *Number::Phone::BR::Areas::_get_current_year = sub { 2016 };

    is mobile_phone_digits_by_area(11) => 9, 'mobiles in 11 are 9 digits';
    is mobile_phone_digits_by_area(16) => 9, 'mobiles in 16 are 9 digits';
    is mobile_phone_digits_by_area(19) => 9, 'mobiles in 19 are 9 digits';
    is mobile_phone_digits_by_area(21) => 9, 'mobiles in 21 are 9 digits';
    is mobile_phone_digits_by_area(28) => 9, 'mobiles in 28 are 9 digits';

    is mobile_phone_digits_by_area(91) => 9, 'mobiles in 91 are 9 digits';
    is mobile_phone_digits_by_area(95) => 9, 'mobiles in 95 are 9 digits';
    is mobile_phone_digits_by_area(99) => 9, 'mobiles in 99 are 9 digits';

    is mobile_phone_digits_by_area(31) => 9, 'mobiles in 31 are 9 digits';
    is mobile_phone_digits_by_area(73) => 9, 'mobiles in 73 are 9 digits';
    is mobile_phone_digits_by_area(89) => 9, 'mobiles in 89 are 9 digits';

    is mobile_phone_digits_by_area(41) => 8, 'mobiles in 41 are 8 digits';
    is mobile_phone_digits_by_area(61) => 8, 'mobiles in 61 are 8 digits';
    is mobile_phone_digits_by_area(69) => 8, 'mobiles in 69 are 8 digits';
};

subtest 'mobile digits - current year is 2017' => sub {
    no warnings 'redefine';
    *Number::Phone::BR::Areas::_get_current_year = sub { 2017 };

    is mobile_phone_digits_by_area(11) => 9, 'mobiles in 11 are 9 digits';
    is mobile_phone_digits_by_area(16) => 9, 'mobiles in 16 are 9 digits';
    is mobile_phone_digits_by_area(19) => 9, 'mobiles in 19 are 9 digits';
    is mobile_phone_digits_by_area(21) => 9, 'mobiles in 21 are 9 digits';
    is mobile_phone_digits_by_area(28) => 9, 'mobiles in 28 are 9 digits';

    is mobile_phone_digits_by_area(91) => 9, 'mobiles in 91 are 9 digits';
    is mobile_phone_digits_by_area(95) => 9, 'mobiles in 95 are 9 digits';
    is mobile_phone_digits_by_area(99) => 9, 'mobiles in 99 are 9 digits';

    is mobile_phone_digits_by_area(31) => 9, 'mobiles in 31 are 9 digits';
    is mobile_phone_digits_by_area(73) => 9, 'mobiles in 73 are 9 digits';
    is mobile_phone_digits_by_area(89) => 9, 'mobiles in 89 are 9 digits';

    is mobile_phone_digits_by_area(41) => 9, 'mobiles in 41 are 9 digits';
    is mobile_phone_digits_by_area(61) => 9, 'mobiles in 61 are 9 digits';
    is mobile_phone_digits_by_area(69) => 9, 'mobiles in 69 are 9 digits';
};

done_testing;
