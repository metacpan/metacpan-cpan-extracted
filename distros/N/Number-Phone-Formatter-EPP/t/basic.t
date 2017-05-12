#!/usr/bin/env perl
#

use strict;
use warnings;
use Test::More;
use Number::Phone;

my %tests = (
    '+44 20 8771 2924' => '+44.2087712924',   # UK
    '+1 202 418 1440'  => '+1.2024181440',    # NANP::US
    '+81 3-3580-3311'  => '+81.335803311'     # StubCountry::JP
);

while (my ($num, $expect) = each %tests) {
    my $number = Number::Phone->new($num);
    is $number->format_using('EPP'), $expect;
}

done_testing;
