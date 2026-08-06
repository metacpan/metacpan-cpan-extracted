#!/usr/bin/env perl

use v5.36;
use Test::More;

use_ok($_) for qw(
    PAGI::FastAPI
    PAGI::FastAPI::Context
    PAGI::FastAPI::Depends
);

diag( "Testing PAGI::FastAPI $PAGI::FastAPI::VERSION, Perl $], $^X" );

done_testing;
