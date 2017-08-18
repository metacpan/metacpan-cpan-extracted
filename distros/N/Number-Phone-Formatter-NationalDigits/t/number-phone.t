#!/usr/bin/env perl
#
# Test using Number::Phone (if available)
#

use strict;
use warnings;
use Test::More;

unless (eval { require Number::Phone; 1 }) {
    plan skip_all => 'Number::Phone is not installed';
}
elsif ($Number::Phone::VERSION < 3.1) {
    plan skip_all => 'Number::Phone v3.1 or later is required';
}

my %tests = (
    '+44 20 8771 2924' => '2087712924',   # UK
    '+1 202 418 1440'  => '2024181440',   # NANP::US
    '+81 3-3580-3311'  => '335803311'     # StubCountry::JP
);

while (my ($in, $expect) = each %tests) {
    my $number = Number::Phone->new($in);
    is $number->format_using('NationalDigits'), $expect;
}

done_testing;
