#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>2;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Exception');
}

isa_ok(exception { Password::Policy::Exception->throw }, 'Password::Policy::Exception');
