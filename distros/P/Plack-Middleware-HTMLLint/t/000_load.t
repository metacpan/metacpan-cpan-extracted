#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Plack::Middleware::HTMLLint';
}

diag "Testing Plack::Middleware::HTMLLint/$Plack::Middleware::HTMLLint::VERSION";
