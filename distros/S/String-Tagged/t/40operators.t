#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $str = String::Tagged->new( "Hello, world" );

is( sprintf( "%s", $str ),
    "Hello, world",
    'STRINGify operator' );

my $s = $str . "!";
is( $s->str, "Hello, world!", 'concat after' );

$s = "I say, " . $str;
is( $s->str, "I say, Hello, world", 'concat before' );

$str .= "!";

is( $str->str, "Hello, world!", 'str after .= operator' );

done_testing;
