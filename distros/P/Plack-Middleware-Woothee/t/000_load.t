#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Plack::Middleware::Woothee';
}

diag "Testing Plack::Middleware::Woothee/$Plack::Middleware::Woothee::VERSION";
