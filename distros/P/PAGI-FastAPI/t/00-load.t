#!/usr/bin/env perl

use v5.38;
use Test::More tests => 12;

use_ok($_) for qw(
    PAGI::FastAPI
    PAGI::FastAPI::Context
    PAGI::FastAPI::Depends
    PAGI::FastAPI::BotProtection
    PAGI::FastAPI::BotProtection::ProofOfWork
    PAGI::FastAPI::Middleware::BotProtection
    PAGI::FastAPI::Middleware::RateLimit
    PAGI::FastAPI::RateLimit::Driver
    PAGI::FastAPI::RateLimit::Driver::Memory
    PAGI::FastAPI::Response
    PAGI::FastAPI::Response::HTML
    PAGI::FastAPI::Response::SSE
);

diag( "Testing PAGI::FastAPI $PAGI::FastAPI::VERSION, Perl $], $^X" );
