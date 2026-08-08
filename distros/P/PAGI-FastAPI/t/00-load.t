#!/usr/bin/env perl

use v5.36;
use Test::More tests => 4;

use_ok($_) for qw(
    PAGI::FastAPI
    PAGI::FastAPI::Context
    PAGI::FastAPI::Depends
    PAGI::FastAPI::WebSocket
);

diag( "Testing PAGI::FastAPI $PAGI::FastAPI::VERSION, Perl $], $^X" );
