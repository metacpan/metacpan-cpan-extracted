#!perl

use strict;
use warnings;

use Runops::Trace;
BEGIN { Runops::Trace::enable_tracing() }

use Test::More;

BEGIN {
    if ($] < 5.010) {
        plan skip_all => "Requires 5.10";
        exit(0);
    }
    else {
        plan tests => 2;
    }
}

use feature qw(say state);

state $foo = 42;
say "# $foo" and pass("say returns 1");
is($foo, 42);
