#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;
use Number::Phone;
use Number::Phone::NO;

$Number::Phone::NO::Data::DEBUG = 0;
# Class interface

is(Number::Phone::NO::subscriber("+47 922 86 382"), "92286382", "subscriber works on valid");
is(Number::Phone::NO::subscriber("922"), undef, "Subscriber returns undef on invalid");