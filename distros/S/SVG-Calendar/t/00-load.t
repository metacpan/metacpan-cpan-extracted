#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'SVG::Calendar' );
}

diag( "Testing SVG::Calendar $SVG::Calendar::VERSION, Perl $], $^X" );
done_testing();
