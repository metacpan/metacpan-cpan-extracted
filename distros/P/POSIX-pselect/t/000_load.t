#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'POSIX::pselect';
}

diag "Testing POSIX::pselect/$POSIX::pselect::VERSION";
