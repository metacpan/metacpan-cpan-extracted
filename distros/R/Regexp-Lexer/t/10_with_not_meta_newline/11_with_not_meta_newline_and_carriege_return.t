use strict;
use warnings;
use utf8;
use Regexp::Lexer qw(tokenize);
use Regexp::Lexer::TokenType;

use Test::More;
use Test::Deep;

# Very edge case!!
subtest 'has not meta newline' => sub {
    my $tokens = tokenize(qr{h\\\r\n\\
w\\\\});

    my $i = 0;
    my @expected = (
        {
            char => "h",
            index => ++$i,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => "\\\\",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => "\\r",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedReturn,
        },
        {
            char => "\\n",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedNewline,
        },
        {
            char => "\\\\",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        }
    );

    if ($^O ne 'MSWin32') {
        push @expected, {
            char => "\\r",
            index => ++$i,
            type => Regexp::Lexer::TokenType::Return,
        };
    }

    push @expected, (
        {
            char => "\\n",
            index => ++$i,
            type => Regexp::Lexer::TokenType::Newline,
        },
        {
            char => "w",
            index => ++$i,
            type => Regexp::Lexer::TokenType::Character,
        },
        {
            char => "\\\\",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
        {
            char => "\\\\",
            index => ++$i,
            type => Regexp::Lexer::TokenType::EscapedCharacter,
        },
    );

    cmp_deeply($tokens->{tokens}, \@expected);
};

done_testing;

