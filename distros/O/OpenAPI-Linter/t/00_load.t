#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('OpenAPI::Linter')           || print "Bail out!\n";
    use_ok('OpenAPI::Linter::Location') || print "Bail out!\n";
}

diag( "Testing OpenAPI::Linter $OpenAPI::Linter::VERSION, Perl $], $^X" );
