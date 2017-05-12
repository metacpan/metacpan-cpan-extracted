#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Rubyish;

use Test::More;
plan tests => 3;


if (true) {
    pass("true is boolean true")
}
else {
    fail("true is not boolean true")
}

if (!true) {
    fail "!true can't be boolean true";
}
else {
    pass "!true is boolean false";
}


{
    my $a = true;
    my $b = true;

    is $a->__id__, $b->__id__, 'nil returns the singleton object of NilClass';
}
