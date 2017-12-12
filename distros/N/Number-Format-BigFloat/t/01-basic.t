#!perl -T

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Number::Format::BigFloat qw(format_number);

subtest "opt:decimal_digits" => sub {
    is(format_number(1.1), "1.10");
    is(format_number(1.1, {decimal_digits=>20}), "1.10000000000000000000");
    is(format_number("1.123456789012345678901", {decimal_digits=>20}), "1.12345678901234567890");
    is(format_number("NaN"), "NaN");
};

subtest "opt:decimal_point" => sub {
    is(format_number(1.1, {decimal_point=>","}), "1,10");
};

subtest "opt:thousands_sep" => sub {
    is(format_number(1234567.1, {thousands_sep=>" ", decimal_point=>","}), "1 234 567,10");
};

DONE_TESTING:
done_testing();
