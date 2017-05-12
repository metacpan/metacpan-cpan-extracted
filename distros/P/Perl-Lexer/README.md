# NAME

Perl::Lexer - Use Perl5 lexer as a library.

# SYNOPSIS

    use v5.18.0;
    use Perl::Lexer;

    my $lexer = Perl::Lexer->new();
    my @tokens = @{$lexer->scan_string('1+2')};
    for (@tokens) {
        say $_->inspect;
    }

Output is:

    <Token: THING opval 1>
    <Token: ADDOP opnum 63>
    <Token: THING opval 2>

# DESCRIPTION

**THIS LIBRARY IS WRITTEN FOR RESEARCHING PERL5 LEXER API. THIS MODULE USES PERL5 INTERNAL API. DO NOT USE THIS.**

Perl::Lexer is a really hackish library for using Perl5 lexer as a library.

# MOTIVATION

The programming language provides lexer library for itself is pretty nice.
I want to tokenize perl5 code by perl5.

Of course, this module uses Perl5's private APIs. I hope these APIs turn into public.

If we can use lexer, we can write a source code analysis related things like Test::MinimumVersion, and other things.

# WHAT API IS NEEDED FOR WRITING MODULES LIKE THIS.

- Open the token informations for XS hackers.

    Now, token name, type, and arguments informations are hidden at toke.c and perly.h.

    I need to define \`PERL\_CORE\` for use it... It's too bad.

    And, I take token\_type and debug\_tokens from toke.c.

# METHODS

- my $lexer = Perl::Lexer->new();

    Create new Perl::Lexer object.

- $lexer->scan\_string($code: Str) : ArrayRef\[Str\]

    Tokenize perl5 code. This method returns arrayref of Perl::Lexer::Token.

# LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>
