#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

require_ok( 'Module::Lazy' )
    or print "Bail out! Failed to load Module::Lazy";

diag( "Testing Module::Lazy $Module::Lazy::VERSION, Perl $], $^X" );

