#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Password::Policy::Encryption::MD5');
}

done_testing;
