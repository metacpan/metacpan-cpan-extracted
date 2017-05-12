#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    local $@;
    eval {use Script::Ichigeki ();};
    ok !$@, 'use_ok';
}

diag "Testing Script::Ichigeki/$Script::Ichigeki::VERSION";
