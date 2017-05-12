#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Password::Policy::Encryption::SHA1');
}

done_testing;
