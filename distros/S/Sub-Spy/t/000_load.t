#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Sub::Spy';
}

diag "Testing Sub::Spy/$Sub::Spy::VERSION";
