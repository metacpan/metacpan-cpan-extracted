#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 40;
use Test::Differences;
use lib 't';
use TestPHP;
BEGIN { use_ok 'PHP::Strings', ':str_word_count' };

my $php = find_php;

sub test_0
{
    my ( $input, $expected, $comment ) = @_;

    is( str_word_count( $input ) => $expected, $comment );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $answer = read_php( sprintf q{<?= str_word_count( "%s" ) ?>},
            $input
        );
        is( $answer => $expected, "$comment - in PHP" );
    }
}

sub test_1
{
    my ( $input, $expected, $comment ) = @_;

    my @words = str_word_count( $input, 1 );
    is ( scalar @words => scalar @$expected, "$comment - sizes" );
    ok( eq_array( \@words, $expected ), "$comment - arrays match" );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $answer = read_php( sprintf q{<?= join( " ", str_word_count( "%s", 1 ) ) ?>},
            $input
        );
        is( $answer => "@$expected", "$comment - in PHP" );
    }
}

sub test_2
{
    my ( $input, $expected, $comment ) = @_;

    my %words = str_word_count( $input, 2 );
    is ( scalar keys %words => scalar keys %$expected, "$comment - sizes" );
    ok( eq_hash( \%words, $expected ), "$comment - hashes match" );

    SKIP: {
        skip "No PHP found", 1 unless $php;
        my $answer = read_php( sprintf <<'EOP',
<?
            $words = str_word_count( "%s", 2 );
            foreach( $words as $i => $word ) {
                print "$i = $word\n";
            }
?>
EOP
            $input
        );
        eq_or_diff( $answer => join( '', map {
                    "$_ = $expected->{$_}\n"
                } sort { $a <=> $b } keys %$expected),
            "$comment - in PHP" );
    }
}

# Good inputs
{
    test_0(''          => 0, "Test format 0, 0 words" );
    test_0('word'      => 1, "Test format 0, 1 word" );
    test_0('two words' => 2, "Test format 0, 2 words" );
    test_0("Ka D'argo" => 2, "Test format 0, 2 words, apostrophe" );
    test_0("Doubled Doubled Words Words" => 4, "Test format 0, doubled words" );

    test_1("Ka" => [qw( Ka )], "Test format 1, 1 word" );
    test_1("Ka D'argo" => [qw( Ka D'argo )], "Test format 1, 2 words, apostrophe" );
    test_1("Doubled Doubled Words Words" =>
        [qw( Doubled Doubled Words Words)],
        "Test format 1, doubled words" );
    test_1("" => [] , "Test format 1, 0 words" );

    test_2("Ka" => {qw( 0 Ka )}, "Test format 2, 1 word" );
    test_2("Ka D'argo" => {qw( 0 Ka 3 D'argo )}, "Test format 2, 2 words, apostrophe" );
    test_2("Doubled Doubled Words Words" =>
        {qw( 0 Doubled 8 Doubled 16 Words 22 Words)},
        "Test format 2, doubled words" );
    test_2("" => {} , "Test format 2, 0 words" );
}

# Bad inputs
{
    eval { str_word_count( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { str_word_count( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { str_word_count( "Foo", "foo" ) };
    like( $@, qr/^Parameter #2 .* 'Number between 0 and 2/,
        "Wrong type of second argument" );
    eval { str_word_count( "Foo", 3 ) };
    like( $@, qr/^Parameter #2 .* 'Number between 0 and 2/,
        "Invalid format number" );
    eval { str_word_count( "Foo", 2, "foo" ) };
    like( $@, qr/^3 parameters were passed .* but 2 were expected/,
        "Too many arguments" );
}
