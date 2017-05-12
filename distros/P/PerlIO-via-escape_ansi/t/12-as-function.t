#!perl -T
use strict;
use Test::More;
use PerlIO::via::escape_ansi -as_function;
use lib "t";
use TestData;


my @data = load_test_data();

plan tests => scalar @data;

for my $datum (@data) {
    my $input = $datum->[1];
    my $filtered = escape_non_printable_chars($input);
    is($filtered, $datum->[2], "$datum->[0]");
}
