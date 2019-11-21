#!perl
use 5.008;
use strict;
use lib qw<bin>;

use Test::More;
use Test::Exception;

BEGIN {
    eval { require 'rcon-minecraft' };
    BAIL_OUT("require failed: $@") if $@;
}

ok 1;

done_testing;
