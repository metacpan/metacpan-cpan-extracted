#!/usr/bin/env perl

use v5.36;
use Test::More tests => 1;

use_ok(qw/PAGI::FastAPI::RateLimit::Driver::Redis/);

diag( "Testing PAGI::FastAPI::RateLimit::Driver::Redis $PAGI::FastAPI::RateLimit::Driver::Redis::VERSION, Perl $], $^X" );
