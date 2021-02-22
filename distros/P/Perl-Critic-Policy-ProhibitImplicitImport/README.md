# NAME

Perl::Critic::Policy::ProhibitImplicitImport - Prefer symbol imports to be explicit

# VERSION

version 0.000001

# DESCRIPTION

Some Perl modules can implicitly import many symbols if no imports are
specified. To avoid this, and to assist in finding where symbols have been
imported from, specify the symbols you want to import explicitly in the `use`
statement.  Alternatively, specify an empty import list with `use Foo ()` to
avoid importing any symbols at all, and fully qualify the functions or
constants, such as `Foo::strftime`.

    use POSIX;                                                         # not ok
    use POSIX ();                                                      # ok
    use POSIX qw(fcntl);                                               # ok
    use POSIX qw(O_APPEND O_CREAT O_EXCL O_RDONLY O_RDWR O_WRONLY);    # ok

For modules which inherit from [Test::Builder::Module](https://metacpan.org/pod/Test%3A%3ABuilder%3A%3AModule), you may need to use a
different import syntax.

    use Test::JSON;                          # not ok
    use Test::JSON import => ['is_json'];    # ok

# CONFIGURATION

By default, this policy ignores many modules (like [Moo](https://metacpan.org/pod/Moo) and [Moose](https://metacpan.org/pod/Moose)) for
which implicit imports provide the expected behaviour. See the source of this
module for a complete list. If you would like to ignore additional modules,
this can be done via configuration:

    [ProhibitImplicitImport]
    ignored_modules = Git::Sub Regexp::Common

# ACKNOWLEDGEMENTS

Much of this code and even some documentation has been inspired by and borrowed
directly from [Perl::Critic::Policy::Freenode::POSIXImports](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AFreenode%3A%3APOSIXImports) and
[Perl::Critic::Policy::TooMuchCode](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3ATooMuchCode).

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
