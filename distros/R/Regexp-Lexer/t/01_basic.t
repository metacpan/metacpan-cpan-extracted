use strict;
use warnings;
use utf8;
use Regexp::Lexer qw(tokenize);
use Regexp::Lexer::TokenType;

use Test::More;
use Test::Deep;

subtest 'basic pass' => sub {
    my $tokens = tokenize(qr{^hello\s+world's\\ end\\$}mi);
    cmp_deeply($tokens->{tokens}, [
        {
            char => '^',
            index => 1,
            type => Regexp::Lexer::TokenType::BeginningOfLine,
        },
        {
            char => 'h',
            index => 2,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'e',
            index => 3,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'l',
            index => 4,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'l',
            index => 5,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'o',
            index => 6,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => '\s',
            index => 7,
            type => Regexp::Lexer::TokenType::EscapedWhiteSpaceChar,
        },
        {
            char => '+',
            index => 8,
            type => Regexp::Lexer::TokenType::Plus,
        },
        {
            char => 'w',
            index => 9,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'o',
            index => 10,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'r',
            index => 11,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'l',
            index => 12,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'd',
            index => 13,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => q<'>,
            index => 14,
            type => Regexp::Lexer::TokenType::SingleQuote,
        },
        {
            char => 's',
            index => 15,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => '\\\\',
            index => 16,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => ' ',
            index => 17,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'e',
            index => 18,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'n',
            index => 19,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => 'd',
            index => 20,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => '\\\\',
            index => 21,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => '$',
            index => 22,
            type => Regexp::Lexer::TokenType::EndOfLine,
        },
    ]);

    ok grep {$_ eq 'm'} @{$tokens->{modifiers}};
    ok grep {$_ eq 'i'} @{$tokens->{modifiers}};
};

done_testing;
