#!/usr/bin/env perl

use v5.36;
use Test::More;

BEGIN {
    use_ok('PAGI::FastAPI')          || bail_out("Failed to load PAGI::FastAPI");
    use_ok('PAGI::FastAPI::Context') || bail_out("Failed to load PAGI::FastAPI::Context");
    use_ok('PAGI::FastAPI::Depends') || bail_out("Failed to load PAGI::FastAPI::Depends");
}

diag( "Testing PAGI::FastAPI $PAGI::FastAPI::VERSION, Perl $], $^X" );

done_testing;
