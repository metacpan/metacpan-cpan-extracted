#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Path::Iterator::Rule::RT' ) || print "Bail out!\n";
}

diag( "Testing Path::Iterator::Rule::RT $Path::Iterator::Rule::RT::VERSION, Perl $], $^X" );
