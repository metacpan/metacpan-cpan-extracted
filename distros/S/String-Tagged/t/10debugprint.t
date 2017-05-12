#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

my $str = String::Tagged->new( "Hello, world" );

is( $str->debug_sprintf,
    "  Hello, world\n",
    'untagged' );

$str->apply_tag( 0, 5, word => 1 );

is( $str->debug_sprintf,
    "  Hello, world\n" .
    "  [---]         word => 1\n",
    'one tag' );

$str->apply_tag( 6, 1, space => 1 );

is( $str->debug_sprintf,
    "  Hello, world\n" .
    "  [---]         word  => 1\n" .
    "        |       space => 1\n",
    'single-char tag' );

$str->apply_tag( -1, -1, everywhere => 1 );

is( $str->debug_sprintf,
    "  Hello, world\n" .
    "  [---]         word       => 1\n" .
    " <[----------]> everywhere => 1\n" .
    "        |       space      => 1\n",
    'everywhere tag' );

done_testing;
