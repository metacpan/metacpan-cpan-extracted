#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $class = 'Number::Phone::Formatter::NationalDigits';

use_ok $class;

my %tests = (
    '+44 20 8771 2924' => '2087712924',   # UK
    '+1 202 418 1440'  => '2024181440',   # NANP::US
    '+81 3-3580-3311'  => '335803311'     # StubCountry::JP
);

while (my ($in, $expect) = each %tests) {
    is $class->format($in), $expect;
}

done_testing;
