#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MooX::ReturnModifiers' ) || print "Bail out!\n";
}

diag( "Testing MooX::ReturnModifiers $MooX::ReturnModifiers::VERSION, Perl $], $^X" );
