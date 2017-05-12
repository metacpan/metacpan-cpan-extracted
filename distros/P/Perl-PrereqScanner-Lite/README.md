[![Build Status](https://travis-ci.org/moznion/Perl-PrereqScanner-Lite.svg?branch=master)](https://travis-ci.org/moznion/Perl-PrereqScanner-Lite) [![Coverage Status](https://img.shields.io/coveralls/moznion/Perl-PrereqScanner-Lite/master.svg)](https://coveralls.io/r/moznion/Perl-PrereqScanner-Lite?branch=master)
# NAME

Perl::PrereqScanner::Lite - Lightweight Prereqs Scanner for Perl

# SYNOPSIS

    use Perl::PrereqScanner::Lite;

    my $scanner = Perl::PrereqScanner::Lite->new;
    $scanner->add_extra_scanner('Moose'); # add extra scanner for moose style
    my $modules = $scanner->scan_file('path/to/file');

# DESCRIPTION

Perl::PrereqScanner::Lite is the lightweight prereqs scanner for perl.
This scanner uses [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer) as tokenizer, therefore processing speed is really fast.

# METHODS

## new($opt)

Create a scanner instance.

`$opt` must be hash reference. It accepts following keys of hash:

- extra\_scanners

    It specifies extra scanners. This item must be array reference.

    e.g.

        my $scanner = Perl::PrereqScanner::Lite->new(
            extra_scanners => [qw/Moose Version/]
        );

    See also ["add\_extra\_scanner($scanner\_name)"](#add_extra_scanner-scanner_name).

- no\_prereq

    It specifies to use `## no prereq` or not. Please see also ["ADDITIONAL NOTATION"](#additional-notation).

## scan\_file($file\_path)

Scan and figure out prereqs which is instance of `CPAN::Meta::Requirements` by file path.

## scan\_string($string)

Scan and figure out prereqs which is instance of `CPAN::Meta::Requirements` by source code string written in perl.

e.g.

    open my $fh, '<', __FILE__;
    my $string = do { local $/; <$fh> };
    my $modules = $scanner->scan_string($string);

## scan\_module($module\_name)

Scan and figure out prereqs which is instance of `CPAN::Meta::Requirements` by module name.

e.g.

    my $modules = $scanner->scan_module('Perl::PrereqScanner::Lite');

## scan\_tokens($tokens)

Scan and figure out prereqs which is instance of `CPAN::Meta::Requirements` by tokens of [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer).

e.g.

    open my $fh, '<', __FILE__;
    my $string = do { local $/; <$fh> };
    my $tokens = Compiler::Lexer->new->tokenize($string);
    my $modules = $scanner->scan_tokens($tokens);

## add\_extra\_scanner($scanner\_name)

Add extra scanner to scan and figure out prereqs. This module loads extra scanner such as `Perl::PrereqScanner::Lite::Scanner::$scanner_name` if specifying scanner name through this method.

If you want to specify an extra scanner from external package without `Perl::PrereqScanner::Lite::` prefix, you can prepend `+` to `$scanner_name`. Like so `+Your::Awesome::Scanner`.

Extra scanners that are default supported are followings;

- [Perl::PrereqScanner::Lite::Scanner::Moose](https://metacpan.org/pod/Perl::PrereqScanner::Lite::Scanner::Moose)
- [Perl::PrereqScanner::Lite::Scanner::Version](https://metacpan.org/pod/Perl::PrereqScanner::Lite::Scanner::Version)

# ADDITIONAL NOTATION

If `no_prereq` is enabled by `new()` (like so: `Perl::PrereqScanner::Lite->new({no_prereq => 1})`),
this module recognize `## no prereq` optional comment. The requiring declaration with this comment on the same line will be ignored as prereq.

For example

    use Foo;
    use Bar; ## no prereq

In this case `Foo` is the prereq, however `Bar` is ignored.

# SPEED COMPARISON

## Plain

                                Rate   Perl::PrereqScanner Perl::PrereqScanner::Lite
    Perl::PrereqScanner       8.57/s                    --                      -97%
    Perl::PrereqScanner::Lite  246/s                 2770%                        --

## With Moose scanner

                                Rate   Perl::PrereqScanner Perl::PrereqScanner::Lite
    Perl::PrereqScanner       9.00/s                    --                      -94%
    Perl::PrereqScanner::Lite  152/s                 1587%                        --

# NOTES

This is a quotation from [https://github.com/moznion/Perl-PrereqScanner-Lite/issues/13](https://github.com/moznion/Perl-PrereqScanner-Lite/issues/13).

Yes, it's true. This design is so ugly and not smart.
So I have to redesign and reimplement this module, and I have some plans.

If you have a mind to expand this module by implementing external scanner,
please be careful.
Every `scan_*` calls must not affect to any others through the
singleton of this module (called it `$c` in [https://github.com/moznion/Perl-PrereqScanner-Lite/blob/c03638b2e2a39d92f4d7df360af5a6be65dc417a/lib/Perl/PrereqScanner/Lite/Scanner/Moose.pm#L8](https://github.com/moznion/Perl-PrereqScanner-Lite/blob/c03638b2e2a39d92f4d7df360af5a6be65dc417a/lib/Perl/PrereqScanner/Lite/Scanner/Moose.pm#L8)).

# SEE ALSO

[Perl::PrereqScanner](https://metacpan.org/pod/Perl::PrereqScanner), [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
