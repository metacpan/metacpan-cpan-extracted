#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Sub::Inspector';
}

diag "Testing Sub::Inspector/$Sub::Inspector::VERSION";
