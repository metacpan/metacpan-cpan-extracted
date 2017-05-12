# NAME

Symbol::Move - Move or rename symbols at compile time.

# DESCRIPTION

This package allows you to make move symbols in the current package, between
the current package and other packages, or between any arbitrary packages.

# SYNOPSYS

    use Symbol::Move(
        'foo'        => 'bar',    # Move the sub foo in the current package to the name bar.
        '%A::B::foo' => 'bar',    # Move the %A::B::foo hash to the %bar symbol in the current package.
        '@foo' => 'A::B::bar',    # Move the @foo array in the current package to the @A::B::bar symbol.
    );

# USAGE

    use Symbol::Move $SYMBOL => $NEW_NAME, ...;

`$SYMBOL` must be a string identifying the symbol. The symbol string must
include the sigil unless it is a subroutine. You can provide a fully qualified
symbol name, or it will be assumed the symbol is in `$PACKAGE`.

`$NEW_NAME` must be a string identifying the symbol. The string may include a
symbol, or the sigil from the `$SYMBOL` string will be used. The string can be
a fully qualified symbol name, or it will be assumed that the new name is in
`$PACKAGE`.

# USEFUL FOR RENAMING IMPORTS

    package Foo;

    {
        package Foo::Scratch;
        use Some::Exporter qw/xyz/;
    }
    use Symbol::Move '&Foo::Scratch::xyz' => 'my_xyz';

    my_xyz(' => 'my_xyz';

    my_xyz(...);

# SEE ALSO

- Symbol::Alias

    [Symbol::Alias](https://metacpan.org/pod/Symbol::Alias) Allows you to set up aliases within a package at compile-time.

- Symbol::Delete

    [Symbol::Delete](https://metacpan.org/pod/Symbol::Delete) Allows you to remove symbols from a package at compile time.

- Symbol::Extract

    [Symbol::Extract](https://metacpan.org/pod/Symbol::Extract) Allows you to extract symbols from packages and into
    variables at compile time.

- Symbol::Methods

    [Symbol::Methods](https://metacpan.org/pod/Symbol::Methods) introduces several package methods for managing symbols.

# SOURCE

The source code repository for symbol can be found at
`http://github.com/exodist/Symbol-Move`.

# MAINTAINERS

- Chad Granum &lt;exodist@cpan.org>

# AUTHORS

- Chad Granum &lt;exodist@cpan.org>

# COPYRIGHT

Copyright 2015 Chad Granum &lt;exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
