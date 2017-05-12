#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 19;
use Test::Differences;
use lib 't';
use TestPHP;
BEGIN { use_ok 'PHP::Strings', ':strtr' };

my $php = find_php;

sub test_tr
{
    my ( $input, $to, $from, $expected, $comment ) = @_;

    is( strtr( $input, $to, $from ) => $expected, $comment );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $answer = read_php( sprintf q{<?= strtr( "%s", "%s", "%s" ) ?>},
            $input, $to, $from,
        );
        is( $answer => $expected, "$comment - in PHP" );
    }
}

sub test_pairs
{
    my ( $input, $pairs, $expected, $comment ) = @_;

    is( strtr( $input, $pairs ) => $expected, $comment );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $array = '';
        $array .= qq,\$pairs["$_"] = "$pairs->{$_}";\n, for keys %$pairs;
        my $answer = read_php( sprintf q{<?
            $pairs = array();
            %s
            echo strtr( "%s", $pairs );
            ?>},
            $array, $input,
        );
        is( $answer => $expected, "$comment - in PHP" );
    }
}

# Good inputs, simple tr
{
    test_tr( "Hello", "e", "f", "Hfllo", "Simple" );
    test_tr( "Hello", "eloH", "xyzw", "wxyyz", "Multiple characters" );
    test_tr( "Hello", "elo", "xyzw", "Hxyyz", "Ignore excess \$to" );
    test_tr( "Hello", "eloH", "xyz", "Hxyyz", "Ignore excess \$from" );
}

# Good inputs, paired tr
{
    test_pairs( "hi all, I said hello", {
            "hello" => "hi", "hi" => "hello"
        }, "hello all, I said hi", "Pairs from docs" );
    test_pairs( "longest match of keywords goes first", {qw(
            long wumpus longest xyzzy
            )}, "xyzzy match of keywords goes first", "Longest pair" );
}

# Bad inputs
{
    eval { strtr( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { strtr( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { strtr( "Foo", { foo => "bar" }, "grep" ) };
    like( $@, qr/^Parameter #3 .* present when it should not be/,
        "Wrong type of second argument" );
    eval { strtr( "Foo", "foo" ) };
    like( $@, qr/^Parameter #3 .* missing from 3-arg/,
        "Wrong type of second argument" );
    eval { strtr( "Foo", 3 ) };
    like( $@, qr/^Parameter #3 .* missing from 3-arg/,
        "Invalid format number" );
    eval { strtr( "Foo", 2, "foo", 4 ) };
    like( $@, qr/^4 parameters were passed .* but 2 - 3 were expected/,
        "Too many arguments" );
}
