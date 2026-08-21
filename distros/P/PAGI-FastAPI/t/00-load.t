#!/usr/bin/env perl

use v5.38;
use Test::More tests => 21;

use_ok($_) for qw(
    PAGI::FastAPI
    PAGI::FastAPI::BotProtection
    PAGI::FastAPI::BotProtection::ProofOfWork
    PAGI::FastAPI::Context
    PAGI::FastAPI::Cookies
    PAGI::FastAPI::Depends
    PAGI::FastAPI::Middleware::BotProtection
    PAGI::FastAPI::Middleware::ExceptionHandler
    PAGI::FastAPI::Middleware::RateLimit
    PAGI::FastAPI::Queue
    PAGI::FastAPI::Queue::Driver
    PAGI::FastAPI::Queue::Driver::Memory
    PAGI::FastAPI::RateLimit::Driver
    PAGI::FastAPI::RateLimit::Driver::Memory
    PAGI::FastAPI::Response
    PAGI::FastAPI::Response::File
    PAGI::FastAPI::Response::HTML
    PAGI::FastAPI::Response::Redirect
    PAGI::FastAPI::Response::SSE
    PAGI::FastAPI::ResponseModel
    PAGI::FastAPI::TypedPath
);

diag( "Testing PAGI::FastAPI $PAGI::FastAPI::VERSION, Perl $], $^X" );
