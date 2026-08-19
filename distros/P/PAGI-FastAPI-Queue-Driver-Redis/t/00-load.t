#!/usr/bin/env perl

use v5.38;
use Test::More tests => 1;

use_ok('PAGI::FastAPI::Queue::Driver::Redis');

diag( "Testing PAGI::FastAPI::Queue::Driver::Redis $PAGI::FastAPI::Queue::Driver::Redis::VERSION, Perl $], $^X" );
