#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use Number::Phone;

{
    my $obj = Number::Phone->new('+55 11 91234-1234');
    isa_ok($obj, 'Number::Phone::BR');
    isa_ok($obj, 'Number::Phone');
    ok(!$obj->isa('Number::Phone::StubCountry::BR'), 'obj is not from the stub class');
}

SKIP: {
    skip 'We decided to break compatibility with upstream on invalid numbers', 1;
    my $obj = Number::Phone->new('+55 123');
    ok(!defined $obj, 'invalid phone is not defined');
}

done_testing;
