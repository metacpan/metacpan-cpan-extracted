#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Test::Deep::Between';
}

diag "Testing Test::Deep::Between/$Test::Deep::Between::VERSION";
