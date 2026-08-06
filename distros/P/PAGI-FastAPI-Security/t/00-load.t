#!/usr/bin/env perl

use v5.36;
use Test::More;

use_ok($_) for qw(
    PAGI::FastAPI::Security
    PAGI::FastAPI::Security::Base
    PAGI::FastAPI::Security::HTTPBearer
    PAGI::FastAPI::Security::HTTPBasic
    PAGI::FastAPI::Security::APIKey
    PAGI::FastAPI::Security::OAuth2::PasswordBearer
);

diag("Testing PAGI::FastAPI::Security $PAGI::FastAPI::Security::VERSION, Perl $], $^X");

done_testing;
