#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Rubyish;

use Test::More;
plan tests => 5;


if (nil) {
    fail("nil can't be boolean true");
}
else {
    pass("nil is boolean false");
}

if (!nil) {
    pass "!nil is boolean true";
}
else {
    fail "!nil can't be boolean false";
}

ok !nil, "neg nil";

is nil->to_a->size, 0, "nil.to_a is an empty array";


{
    my $a = nil;
    my $b = nil;

    is $a->__id__, $b->__id__, 'nil returns the singleton object of NilClass';
}
