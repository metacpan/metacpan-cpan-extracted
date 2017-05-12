#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

my $str = String::Tagged->new( "Hello, world" );

is( $str->str, "Hello, world", 'Plain string accessor' );

is( $str->length, 12, 'Plain string length' );
is( length($str), 12, 'length() str also works' );

is( $str->plain_substr( 0, 5 ), "Hello", 'Plain substring accessor' );

isa_ok( $str->substr( 0, 5 ), "String::Tagged", 'Tagged substring accessor' );

$str->set_substr( 7, 5, "planet" );
is( $str->str, "Hello, planet", "After set_substr" );

is( $str->length, 13, 'String length after set_substr' );

$str->insert( 7, "lovely " );
is( $str->str, "Hello, lovely planet", 'After insert' );

$str->append( "!" );
is( $str->str, "Hello, lovely planet!", 'After append' );

done_testing;
