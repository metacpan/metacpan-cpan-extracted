#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;
BEGIN { use_ok 'PHP::Strings', ':addcslashes' };

# Good inputs
{
    is( addcslashes('foo[ ]', 'A..z') => '\f\o\o\[ \]', "foo" );
    is( addcslashes("zoo['.']", 'z..A') => q{\zoo['\.']}, "zoo" );
}

# Bad inputs
{
    eval { addcslashes( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { addcslashes( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { addcslashes( "Foo" ) };
    like( $@, qr/^1 param/, "Insufficient arguments" );
    eval { addcslashes( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for length" );
}
