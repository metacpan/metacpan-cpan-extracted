# NAME

Mojolicious::Command::Author::generate::cpanfile - cpanfile generator command

# SYNOPSIS

    Usage: APPLICATION generate cpanfile [OPTIONS]

      mojo generate cpanfile

    Options:
      -h, --help   Show this summary of available options

# DESCRIPTION

[Mojolicious::Command::Author::generate::cpanfile](https://metacpan.org/pod/Mojolicious%3A%3ACommand%3A%3AAuthor%3A%3Agenerate%3A%3Acpanfile) generates `cpanfile` files
for applications.

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
