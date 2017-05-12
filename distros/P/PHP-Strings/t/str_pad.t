#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;
BEGIN { use_ok 'PHP::Strings', ':str_pad' };

# Good inputs
{
    is( str_pad( "Alien", 10)                      => "Alien     " => "Defaults" );
    is( str_pad( "Alien", 10, "-=", STR_PAD_LEFT)  => "-=-=-Alien" => "From left" );
    is( str_pad( "Alien", 10, "_", STR_PAD_BOTH)   => "__Alien___" => "From both" );
    is( str_pad( "Alien", 6 , "___")               => "Alien_"     => "With padstring" );
    is( str_pad( "Alien", 4 , "___")               => "Alien"      => "Shorter" );
}

# Bad inputs
{
    eval { str_pad( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { str_pad( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { str_pad( "Foo" ) };
    like( $@, qr/^1 param/, "Insufficient arguments" );
    eval { str_pad( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for length" );
    eval { str_pad( "Foo", 4, "", 0 ) };
    like( $@, qr/^Invalid 4th/, "Bad options" );
    eval { str_pad( "Foo", "Not a number" ) };
    like( $@, qr/^Parameter #2.*regex/, "Length not a number" );
}
