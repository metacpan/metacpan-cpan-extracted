#!perl -T
use strict;
use Test::More;
use PerlIO::via::escape_ansi;
use lib "t";
use TestData;


my @data = load_test_data();

plan tests => scalar @data;

for my $datum (@data) {
    my $input = $datum->[1];
    open my $fh, "<:via(escape_ansi)", \$input;
    my $filtered = do { local $/; <$fh> };
    is($filtered, $datum->[2], "$datum->[0]");
}
