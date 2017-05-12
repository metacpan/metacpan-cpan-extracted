#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Moo' ) || print "Bail out!\n";
    use_ok( 'MooX::VariantAttribute' ) || print "Bail out!\n";
}

diag( "Testing MooX::VariantAttribute $MooX::VariantAttribute::VERSION, Perl $], $^X" );
