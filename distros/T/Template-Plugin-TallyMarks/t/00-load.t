#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Template::Plugin::TallyMarks' ) || print "Bail out!\n";
}

diag( "Testing Template::Plugin::TallyMarks $Template::Plugin::TallyMarks::VERSION, Perl $], $^X" );
