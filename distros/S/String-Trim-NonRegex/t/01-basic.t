#!perl

use strict;
use warnings;
use Test::More 0.98;

use String::Trim::NonRegex qw(
                                 ltrim
                                 rtrim
                                 trim
                                 ltrim_lines
                                 rtrim_lines
                                 trim_lines
                                 trim_blank_lines
                                 ellipsis
                          );

subtest ltrim => sub {
    is(ltrim(" \ta")             , "a");
    is(ltrim("\n \ta")           , "a");
    is(ltrim("a \t")             , "a \t");
    is(ltrim("a\n \t")           , "a\n \t");
    is(ltrim(" \ta\n b\n")       , "a\n b\n");
    is(ltrim("a\n \tb \n\n")     , "a\n \tb \n\n");
};

subtest rtrim => sub {
    is(rtrim(" \ta")             , " \ta");
    is(rtrim("\n \ta")           , "\n \ta");
    is(rtrim("a \t")             , "a");
    is(rtrim("a\n \t")           , "a");
    is(rtrim(" \ta\n b\n")       , " \ta\n b");
    is(rtrim("a\n \tb \n\n")     , "a\n \tb");
};

subtest trim => sub {
    is(trim(" \ta")             , "a");
    is(trim("\n \ta")           , "a");
    is(trim("a \t")             , "a");
    is(trim("a\n \t")           , "a");
    is(trim(" \ta\n b\n")       , "a\n b");
    is(trim("a\n \tb \n\n")     , "a\n \tb");
};

#subtest ltrim_lines => sub {
#    is(ltrim_lines(" \ta")             , "a");
#    is(ltrim_lines("\n \ta")           , "\na");
#    is(ltrim_lines("a \t")             , "a \t");
#    is(ltrim_lines("a\n \t")           , "a\n");
#    is(ltrim_lines(" \ta\n b\n")       , "a\nb\n");
#    is(ltrim_lines("a\n \tb \n\n")     , "a\nb \n\n");
#};

#subtest rtrim_lines => sub {
#    is(rtrim_lines(" \ta")             , " \ta");
#    is(rtrim_lines("\n \ta")           , "\n \ta");
#    is(rtrim_lines("a \t")             , "a");
#    is(rtrim_lines("a\n \t")           , "a\n");
#    is(rtrim_lines(" \ta\n b\n")       , " \ta\n b\n");
#    is(rtrim_lines("a\n \tb \n\n")     , "a\n \tb\n\n");
#};

#subtest trim_lines => sub {
#    is(trim_lines(" \ta")             , "a");
#    is(trim_lines("\n \ta")           , "\na");
#    is(trim_lines("a \t")             , "a");
#    is(trim_lines("a\n \t")           , "a\n");
#    is(trim_lines(" \ta\n b\n")       , "a\nb\n");
#    is(trim_lines("a\n \tb \n\n")     , "a\nb\n\n");
#};

#ok( !defined(trim_blank_lines(undef)), "trim_blank_lines undef" );
#is( trim_blank_lines("\n1\n\n2\n\n \n"), "1\n\n2\n", "trim_blank_lines 1" );

#is(ellipsis("", 10), "", "ellipsis 1");
#is(ellipsis("12345678", 10), "12345678", "ellipsis 1");
#is(ellipsis("1234567890", 10), "1234567890", "ellipsis 2");
#is(ellipsis("12345678901", 10), "1234567...", "ellipsis 3");
#is(ellipsis("123456789012345", 10), "1234567...", "ellipsis 4");
#is(ellipsis("12345678901", 10, "xxx"), "1234567xxx", "ellipsis 5");

DONE_TESTING:
done_testing();
