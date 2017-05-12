use strict;
use warnings;
use utf8;
use Regexp::Lexer qw(tokenize);
use Regexp::Lexer::TokenType;

use Test::More;
use Test::Deep;

subtest 'basic pass' => sub {
    my $tokens = tokenize(qr{"\"\\"'\'\\'});
    cmp_deeply($tokens->{tokens}, [
        {
            char => '"',
            index => 1,
            type => Regexp::Lexer::TokenType::DoubleQuote,
        },
        {
            char => '\\"',
            index => 2,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => '\\\\',
            index => 3,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => '"',
            index => 4,
            type => Regexp::Lexer::TokenType::DoubleQuote,
        },
        {
            char => q<'>,
            index => 5,
            type => Regexp::Lexer::TokenType::SingleQuote,
        },
        {
            char => q<\\'>,
            index => 6,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => '\\\\',
            index => 7,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => q<'>,
            index => 8,
            type => Regexp::Lexer::TokenType::SingleQuote,
        },
    ]);
};

done_testing;
