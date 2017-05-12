#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Plack::Middleware::UnicodePictogramFallback::TypeCast';
}

diag "Testing Plack::Middleware::UnicodePictogramFallback::TypeCast/$Plack::Middleware::UnicodePictogramFallback::TypeCast::VERSION";
