#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Perl6ish;

if ('foo' eq any(qw(lorem ipsum foo bar))) {
    pass("There is foo");
}
else {
    fail "No foo?";
}


