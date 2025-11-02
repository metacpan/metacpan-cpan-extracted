#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('OpenAPI::Linter') || print "Bail out!\n"; }

diag( "Testing OpenAPI::Linter $OpenAPI::Linter::VERSION, Perl $], $^X" );
