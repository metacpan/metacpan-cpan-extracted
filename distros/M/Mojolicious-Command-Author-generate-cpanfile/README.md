# NAME

Mojolicious::Command::Author::generate::cpanfile - cpanfile generator command

# SYNOPSIS

    Usage: APPLICATION generate cpanfile [OPTIONS]

      mojo generate cpanfile
      mojo generate cpanfile -r Mojolicious::Plugin::OpenAPI
      mojo generate cpanfile -l lib -l src -t t -t xt

    Options:
      -h, --help      Show this summary of available options
      -l, --lib       Overwrite module directories in which to look for
                      dependencies.  Can be used multiple times.
                      Defaults to 'lib' if no -l option is used.
      -r, --requires  Add module to dependencies that can't be found by
                      scanner.  Can be used multiple times.
      -t              Overwrite test directories in which to look for
                      test dependencies.  Can be used multiple times.
                      Defaults to 't' if no -t option is used.

# DESCRIPTION

[Mojolicious::Command::Author::generate::cpanfile](https://metacpan.org/pod/Mojolicious%3A%3ACommand%3A%3AAuthor%3A%3Agenerate%3A%3Acpanfile) generates a `cpanfile` file
by analyzing the application source code. It scans the `*.pm` files in the
directories under `./lib` (or whatever is given by the `-l` option) for
regular module dependencies and `*.t` files in `./t` (or whatever is given by
the `-t` option) for test dependencies.

# ATTRIBUTES

[Mojolicious::Command::Author::generate::cpanfile](https://metacpan.org/pod/Mojolicious%3A%3ACommand%3A%3AAuthor%3A%3Agenerate%3A%3Acpanfile) inherits all attributes from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious%3A%3ACommand) and implements the following new ones.

## description

    my $description = $cpanfile->description;
    $cpanfile       = $cpanfile->description('Foo');

Short description of this command, used for the command list.

## usage

    my $usage = $cpanfile->usage;
    $cpanfile = $cpanfile->usage('Foo');

Usage information for this command, used for the help screen.

# METHODS

[Mojolicious::Command::Author::generate::cpanfile](https://metacpan.org/pod/Mojolicious%3A%3ACommand%3A%3AAuthor%3A%3Agenerate%3A%3Acpanfile) inherits all methods from
[Mojolicious::Command](https://metacpan.org/pod/Mojolicious%3A%3ACommand) and implements the following new ones.

## run

    $cpanfile->run(@ARGV);

Run this command.

# LICENSE

Copyright (C) Bernhard Graf.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Bernhard Graf <augensalat@gmail.com>

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious%3A%3AGuides), [https://mojolicious.org](https://mojolicious.org).
