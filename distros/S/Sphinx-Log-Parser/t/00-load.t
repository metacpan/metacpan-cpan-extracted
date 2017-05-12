#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
    use_ok('Sphinx::Log::Parser');
}

diag(
    "Testing Sphinx::Log::Parser $Sphinx::Log::Parser::VERSION, Perl $], $^X" );
