#!perl
use strict;
use warnings;
use String::TtyLength qw/ tty_width /;
use Test2::V0;
use utf8;

my @TESTS = (
    ["word",                    4,  "regular string"],
    ["café",                    4,  "non-wide unicode character"],
    ["😄",                      2,  "double-width emoji"],
    ["こんにちは",              10, "hiragana"],
    ["\e[32mこんにちは\e[0m",   10, "red hiragana"],
);

foreach my $test (@TESTS) {
    my ($string, $expected_width, $label) = @$test;
    my $width = tty_width($string);

    is($width, $expected_width, $label,
       sprintf("expected width of <<%s>> to be %d but it was %d",
               $string, $expected_width, $width));
}

done_testing();
