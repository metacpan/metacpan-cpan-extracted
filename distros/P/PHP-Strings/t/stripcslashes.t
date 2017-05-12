#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 18;
use lib 't';
use TestPHP;
BEGIN { use_ok 'PHP::Strings', ':stripcslashes' };

my $php = find_php;

sub test
{
    my ( $input, $expected, $comment ) = @_;

    is( stripcslashes( $input ) => $expected, $comment );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $answer = read_php( sprintf q{<?= stripcslashes( '%s' ) ?>},
            $input
        );
        is( $answer => $expected, "$comment - in PHP" );
    }
}

# Good inputs
{
    my $note = "example from user-contrib notes";
    test('H\x65llo' => 'Hello', "Hex $note" );
    test('\x48ello' => 'Hello', "Note 2 digit limit in hex $note" );
    test('1\x323'   => '123', "Yes, 2 digits $note" );
    test('He\xallo' => "He\nllo", "One is possible $note" );
    test('H\xaello' => "H\xaello", "But 2 is usual $note" );

    test('\a\b\f\n\r\t\v\?\\\'\"' => "\a\b\f\n\r\t\013\?\'\"", "C style" );
    test('\052\055' => "\052\055", "Octal" );
}

# Bad inputs
{
    eval { stripcslashes( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { stripcslashes( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { stripcslashes( "Foo", "foo" ) };
    like( $@, qr/^2 parameters were passed .* but 1 was expected/,
        "Too many arguments" );
}
