#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use Number::Phone;
use Number::Phone::NO;

$Number::Phone::NO::Data::DEBUG = 0;
# Class interface

ok(Number::Phone::NO::is_valid("+47 922 86 382"));
ok(Number::Phone::NO::is_valid("92286382"));

# Object

{
    my $n = new Number::Phone('+47 982 93 610');
    isa_ok($n, "Number::Phone::NO");
    isa_ok($n, "Number::Phone");

    ok($n->is_valid(), "Valid number");
}

$Number::Phone::NO::Data::DEBUG = 0;
ok(Number::Phone::NO::is_specialrate("02224"));
$Number::Phone::NO::Data::DEBUG = 0;

ok(Number::Phone::NO::is_tollfree("+47 800 80 800"));

ok(Number::Phone::NO::is_network_service("113"));
