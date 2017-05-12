# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format') }

my $deutsch = Number::Format->new(-thousands_sep   => '.',
                                  -decimal_point   => ',');

isa_ok($deutsch, 'Number::Format', 'object');

is($deutsch->format_number(1234567.509, 2),     '1.234.567,51', 'round');
is($deutsch->format_number(12345678.5, 2),      '12.345.678,5', 'tousends');
is($deutsch->format_number(1.23456789, 6),      '1,234568',     'big frac');

my $double_char = Number::Format->new(
    -thousands_sep => '&nbsp;',
    -decimal_point => ',',
);

is(
    $double_char->format_number(12345678.5),
    "12&nbsp;345&nbsp;678,5",
    'multi-char thousands separator'
);
