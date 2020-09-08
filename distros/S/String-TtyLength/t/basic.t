#!perl
use strict;
use warnings;
use String::TtyLength qw/ tty_length /;
use Test2::V0;

my @TESTS = (
    ["Hello world\n",               12, "regular string"],
    ["",                             0, "empty string"],
    ["\e[2;2Hmove cursor",          11, "cursor movement"],
    ["\e[2;2fmove cursor",          11, "cursor movement"],
    ["\e[22Ahello",                  5, "cursor up"],
    ["\e[22Bhello",                  5, "cursor down"],
    ["\e[22Chello",                  5, "cursor forward"],
    ["\e[shello\e[uworld",          10, "save and restore cursor"],
    ["\e[2Jcls",                     3, "erase display"],
    ["\e[Kline",                     4, "erase line"],
    ["\e[1mbold\e[0m",               4, "bold text"],
    ["\e[31m\e[43mbold\e[0m",        4, "sequential escape sequences"],
    ["\e[31;43mred on yellow\e[0m", 13, "combined escape sequences"],
);

foreach my $test (@TESTS) {
    my ($string, $expected_length, $label) = @$test;

    is(tty_length($string), $expected_length, $label);
}

done_testing();
