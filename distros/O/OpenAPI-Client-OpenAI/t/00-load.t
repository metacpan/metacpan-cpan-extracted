#!perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('OpenAPI::Client::OpenAI') || print "Bail out!\n";
}

diag("Testing OpenAPI::Client::OpenAI $OpenAPI::Client::OpenAI::VERSION, Perl $], $^X");
