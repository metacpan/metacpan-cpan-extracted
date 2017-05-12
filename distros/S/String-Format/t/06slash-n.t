#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use String::Format;

my $unknown_fmt = "This is awesome.%x";
is(stringf($unknown_fmt), $unknown_fmt, "unknown %-entities are left intact");

my $with_n = "End in n.%n";
is(stringf($with_n), "End in n.\n", '%s becomes \n');

is(stringf($with_n, n => undef), 'End in n.%n', '(n=>undef) and %n untouched');

is(stringf($with_n, n => '%n'), 'End in n.%n', '(n=>%n) and %n still %n');

my $with_nl = "Newline!\n";
is(stringf($with_nl), "Newline!\n", '\n in string is unmolested');
