# NAME

Mojolicious::Command::bulkget - Perform bulk get requests

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/Mojolicious-Command-bulkget.svg?branch=master)](https://travis-ci.org/mohawk2/Mojolicious-Command-bulkget) |

[![CPAN version](https://badge.fury.io/pl/Mojolicious-Command-bulkget.svg)](https://metacpan.org/pod/Mojolicious::Command::bulkget)

# SYNOPSIS

    Usage: APPLICATION bulkget urlbase outdir suffixesfile

      # suffixes contains lines with 1, 2, 3
      # fetches /pets/1, /pets/2, ...
      # stores results in outputdir/1, outputdir/2, ...
      mojo bulkget http://example.com/pets/ outputdir suffixes

    Options:
      -v, --verbose                        Print progress information

# DESCRIPTION

[Mojolicious::Command::bulkget](https://metacpan.org/pod/Mojolicious::Command::bulkget) is a command line interface for
bulk-fetching URLs.

Each line of the "suffixes" file is a suffix.  It gets appended to the URL
"base", then a non-blocking request is made. Only 20 requests will be
active at the same time. When ready, the result is stored in the output
directory with the suffix as the filename.

This command uses the relatively new Mojolicious feature, Promises. The
code may be considered worth examining for lessons on what to do, and/or
what not to do.

# ATTRIBUTES

## description

    $str = $self->description;

## usage

    $str = $self->usage;

# METHODS

## run

    $get->run(@ARGV);

Run this command.

# AUTHOR

Ed J

Based heavily on [Mojolicious::Command::openapi](https://metacpan.org/pod/Mojolicious::Command::openapi).

# COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
