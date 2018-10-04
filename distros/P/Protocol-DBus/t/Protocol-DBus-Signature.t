#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use_ok('Protocol::DBus::Signature');

my @positive_tests = (
    '(ii)',
    '(i(ii))',
    'ai',
    'a{sv}',
    'a{s(i(ii))}',
);

for my $sig (@positive_tests) {
    is(
        Protocol::DBus::Signature::get_sct_length($sig, 0),
        length($sig),
        "bare string: $sig",
    );

    my $offset_sig = 'iii' . $sig;

    is(
        Protocol::DBus::Signature::get_sct_length($offset_sig, 3),
        length($sig),
        "prefixed string: $sig",
    );

    $offset_sig .= 'lll';

    is(
        Protocol::DBus::Signature::get_sct_length($offset_sig, 3),
        length($sig),
        "prefixed & postfixed string: $sig",
    );
}

done_testing();

1;
