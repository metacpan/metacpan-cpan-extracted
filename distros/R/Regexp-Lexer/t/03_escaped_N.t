use strict;
use warnings;
use utf8;

use Regexp::Lexer qw(tokenize);
use Regexp::Lexer::TokenType;

use Test::More;
use Test::Deep;

SKIP: {
    if ($] < 5.012) {
        # Not newline character (\N) is not supported by lower 5.12 perl
        skip "Perl version is lower than 5.12 (current version: $])", 1;
    }

    subtest 'has not newline and unicode specifier' => sub {
        my $re = eval 'qr/\N\N{U+000}\N/'; ## no critic
        my $tokens = tokenize($re);
        cmp_deeply($tokens->{tokens}, [
            {
                char => "\\N",
                index => 1,
                type => Regexp::Lexer::TokenType::EscapedNotNewline,
            },
            {
                char => "\\N",
                index => 2,
                type => Regexp::Lexer::TokenType::EscapedCharUnicode,
            },
            {
                char => "{",
                index => 3,
                type => Regexp::Lexer::TokenType::LeftBrace,
            },
            {
                char => "U",
                index => 4,
                type => Regexp::Lexer::TokenType::Character,
            },
            {
                char => "+",
                index => 5,
                type => Regexp::Lexer::TokenType::Plus,
            },
            {
                char => 0,
                index => 6,
                type => Regexp::Lexer::TokenType::Character,
            },
            {
                char => 0,
                index => 7,
                type => Regexp::Lexer::TokenType::Character,
            },
            {
                char => 0,
                index => 8,
                type => Regexp::Lexer::TokenType::Character,
            },
            {
                char => "}",
                index => 9,
                type => Regexp::Lexer::TokenType::RightBrace,
            },
            {
                char => "\\N",
                index => 10,
                type => Regexp::Lexer::TokenType::EscapedNotNewline,
            }
        ]);
    };
}

subtest 'has unicode specifier' => sub {
    my $tokens = tokenize(qr/\N{U+000}/);
    cmp_deeply($tokens->{tokens}, [
        {
            char => "\\N",
            index => 1,
            type => Regexp::Lexer::TokenType::EscapedCharUnicode,
        },
        {
            char => "{",
            index => 2,
            type => Regexp::Lexer::TokenType::LeftBrace,
        },
        {
            char => "U",
            index => 3,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => "+",
            index => 4,
            type => Regexp::Lexer::TokenType::Plus,
        },
        {
            char => 0,
            index => 5,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 0,
            index => 6,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 0,
            index => 7,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => "}",
            index => 8,
            type => Regexp::Lexer::TokenType::RightBrace,
        },
    ]);
};

done_testing;

