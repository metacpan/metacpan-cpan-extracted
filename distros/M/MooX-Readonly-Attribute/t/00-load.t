#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Moo' ) || print "Bail out\n";
    use_ok( 'MooX::Readonly::Attribute' ) || print "Bail out!\n";
}

diag( "Testing MooX::Readonly::Attribute $MooX::Readonly::Attribute::VERSION, Perl $], $^X" );
