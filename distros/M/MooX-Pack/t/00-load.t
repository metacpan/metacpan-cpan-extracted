#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok('Moo');
    use_ok( 'MooX::Pack' ) || print "Bail out!\n";
}

diag( "Testing MooX::Pack $MooX::Pack::VERSION, Perl $], $^X" );
