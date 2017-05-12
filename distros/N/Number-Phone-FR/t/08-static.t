use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

my @impl = map { "Number::Phone::FR$_" } ('', qw(::Simple ::Full));

plan tests => scalar @impl + 1;

foreach my $impl (@impl) {
    subtest $impl, sub {
        plan tests => 3;
        eval "require $impl; 1";
        ok($impl->isa('Number::Phone::FR'), 'isa Number::Phone::FR');
        is($impl->country, 'FR', 'Country code (letters)');
        is($impl->country_code, '33', 'Country code (number)');
    };
}
