#!/usr/bin/env perl

use v5.36;
use Test::More tests => 1;

use_ok(qw/PAGI::FastAPI::RateLimit::Driver::CHI/);

diag( "Testing PAGI::FastAPI::RateLimit::Driver::CHI $PAGI::FastAPI::RateLimit::Driver::CHI::VERSION, Perl $], $^X" );
