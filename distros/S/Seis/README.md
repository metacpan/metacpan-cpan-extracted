# NAME

Seis - Perl6ish syntax on Perl5

# SYNOPSIS

    for 1..100 { .say }

# DESCRIPTION

Seis compiles Perl6 syntax into Perl5.

It's only emulate perl6's syntax. Not semantics.

But it's useful because perl6's syntax is sane.

So, there is a lot of Perl6::\* stuff, that ports a part of Perl6 stuff.
But this module's concept is port most Perl6 stuff to Perl5 using XS stuff :P

# PROJECT GOALS

We want to use some Perl6 stuff in Perl 5 environment.

We want to show more perl6 features can feedback to perl5 core.

# PROJECT PLANS

## Version 1.0 - Maybe production ready release

- Support basic Perl6 OOP features
- Support basic Perl6 regexp

# TODO

    Implement builtin methods
    multi methods
    perl6 regexp
    perl6 rules
    perl6 junctions
    perl6 open
    perl6 slurp
    pass the 200+ roast cases
    care the pairs
    my own virtual machine?

## Issues in PVIP

c<<end (1,2,3)>> and `<end(1,2,3)`\> is a different thing.
But PVIP handles these things are same.

# WHY SEIS REQUIRES Perl 5.18+?

- Lexical subs

    Perl6 supports lexical subs.

# WHY SEIS REQUIRES Perl 5.10+?

- //p flag

    //p flag was introduced at 5.10. It's needed by regexp operation.

# WHY SEIS REQUIRES Perl 5.16?

- fc()

    Perl6 provides ` String#fc ` method. Perl5 supports fc()  5.16 or later.

# KNOWN ISSUES

There is some known issues. Seis do in the forcible way.
And Seis placed great importance on performance.
Then, seis giving ups some features on Perl 6.

If you have any ideas to support these things without performance issue, patches welcome(I guess most of features can fix if you are XS hacker).

# Compiling regular expression is slow.

It can be optimizable.

# 1..\* was not supported.

You can implement this by dankogai's hack.

http://blog.livedoor.jp/dankogai/archives/50839189.html

## Compilation speed is optimizable

You can rewrite code generator to generate B tree directly.

I know it's the best way, but I don't have enough knowledge to do.
Please help us.

## Automatic literal conversion is not available

Perl6 has some more string literals perl5 does not have.

For example, I can't generate fast code from following code:

    say 'ok ', '0b1010' + 1;
    say 'ok ', '0o6' * '0b10';

Note. There is a idea... You can support this feature in fast code with XS magic. You can replace PP code in XS world...

Another option, you can send a patch for support perl6 style literals to p5p.

## No stringification available about refs

Following code does not works well. I need overloading stuff in autobox.pm.

    ~<a b>

This issue can solve with PP\_check hack.

## `eqv` operator is not compatible.

Not yet implemented.

## Method name contains '-'

Perl5 can't handles method name contains '-'.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
