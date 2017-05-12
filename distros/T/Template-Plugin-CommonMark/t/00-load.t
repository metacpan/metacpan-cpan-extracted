#!perl -T
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::CommonMark' ) || print "Bail out!\n";
}

diag( "Testing Template::Plugin::CommonMark $Template::Plugin::CommonMark::VERSION, Perl $], $^X" );
