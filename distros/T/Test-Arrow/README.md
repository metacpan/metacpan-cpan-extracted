# Test::Arrow

This is Perl module `Test::Arrow`. It's Object-Oriented testing library.

<a href="https://github.com/bayashi/Test-Arrow/blob/main/README.md"><img src="https://img.shields.io/badge/Version-0.22-green?style=flat"></a> <a href="https://github.com/bayashi/Test-Arrow/blob/main/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Test-Arrow/actions"><img src="https://github.com/bayashi/Test-Arrow/workflows/main/badge.svg?_t=1691663069"/></a> <a href="https://coveralls.io/r/bayashi/Test-Arrow"><img src="https://coveralls.io/repos/bayashi/Test-Arrow/badge.png?_t=1691663069&branch=main"/></a>

## SYNOPSIS

    use Test::Arrow;

    my $arr = Test::Arrow->new;

    $arr->got(1)->ok;

    $arr->expect(uc 'foo')->to_be('FOO');

    $arr->name('Test Name')
        ->expected('FOO')
        ->got(uc 'foo')
        ->is;

    $arr->expected(6)
        ->got(2 * 3)
        ->is_num;

    $arr->expected(qr/^ab/)
        ->got('abc')
        ->like;

    $arr->warnings(sub { warn 'Bar' })->catch(qr/^Ba/);
    $arr->throw(sub { die 'Baz' })->catch(qr/^Ba/);

    done;

The function `t` is exported as a shortcut for constructor. It initializes an instance for each.

    use Test::Arrow;

    t->got(1)->ok;

    t->expect(uc 'foo')->to_be('FOO');

    done;


## INSTALLATION

`Test::Arrow` installation is straightforward. If your CPAN shell is set up,
you should just be able to do

    % cpan Test::Arrow

Download it, unpack it, then build it as per the usual:

    % perl Makefile.PL
    % make && make test

Then install it:

    % make install


## DOCUMENTATION

`Test::Arrow` documentation is available as in POD. So you can do:

    % perldoc Test::Arrow


## REPOSITORY

`Test::Arrow` is hosted on github: <http://github.com/bayashi/Test-Arrow>


## LICENSE

`Test::Arrow` is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.


## AUTHOR

Dai Okabayashi &lt;bayashi@cpan.org&gt;
