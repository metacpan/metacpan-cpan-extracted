[![Build Status](https://travis-ci.org/moznion/Regexp-Lexer.svg?branch=master)](https://travis-ci.org/moznion/Regexp-Lexer)
# NAME

Regexp::Lexer - Lexer for regular expression of perl

# SYNOPSIS

    use Regexp::Lexer qw(tokenize);
    my $tokens = tokenize(qr{\Ahello\s+world\z}i);

# DESCRIPTION

Regexp::Lexer is a lexer for regular expression of perl.

This module splits the regular expression string to tokens
which has minimum meaning.

# FUNCTIONS

- `tokenize($re:Regexp)`

    Tokenizes the regular expression.

    This function takes an argument as `Regexp`, namely it must be regexp quoted variable (i.e. `qr/SOMETHING/`).
    If not `Regexp` argument is given, this function throws exception.

    This function returns the result like so;

        {
            tokens => [
                {
                    char => '\A',
                    index => 1,
                    type => {
                        id => 67,
                        name => 'EscapedBeginningOfString',
                    },
                },
                {
                    char => 'h',
                    index => 2,
                    type => {
                        id => 1,
                        name => 'Character',
                    },
                },
                ...
            ],
            modifiers => ['^', 'i'],
        }

    `tokens` is the tokens list. Information about `type` of token is located in the [Regexp::Lexer::TokenType](https://metacpan.org/pod/Regexp::Lexer::TokenType).

    `modifiers` is the list of modifiers of regular expression. Please see also [perlre](https://metacpan.org/pod/perlre).

# SEE ALSO

- [perlre](https://metacpan.org/pod/perlre)
- [perlrebackslash](https://metacpan.org/pod/perlrebackslash)
- [Regexp::Lexer::TokenType](https://metacpan.org/pod/Regexp::Lexer::TokenType)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
