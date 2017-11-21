pod2github - Make pretty GitHub readmes from your POD

## Synopsis

```
$ pod2github lib/Foo/Bar.pm > README.md
```

## Description

This program converts your POD into Markdown, with GitHub-specific formatting
of source code. Because your project's README.md probably diverges from your
POD, `pod2github` offers various other functions:

- Improve formatting: syntax-highlight Perl sections, and render command-line
options, methods and functions as code. Title-case allcaps headers.
- Hide or inline arbitrary sections
- Optionally add a header or footer

## Options

- `--exclude HEADER,HEADER...`

    Exclude one or more sections from the output. For this and below
    sections, header matching is case-sensitive and matches headers at
    any level.

- `--include HEADER,HEADER...`

    Include _only_ the listed sections in the output.

- `--inline HEADER,HEADER...`

    When these sections are encountered, remove the header but keep the
    section body. Useful to remove the 'Name' header from the top of
    your readme.

- `--header header-string`, `--header-file file`

    Output the specified header text or the contents of the specified file
    before outputting the converted input.

- `--footer footer-string`, `--footer-file file`

    Output the specified footer text or the contents of the specified file
    after outputting the converted input.

- `--title-case`, `--no-title-case` (default: on)

    Convert section headings to title case.

- `--syntax-highlight`, `--no-syntax-highlight` (default: on)

    Convert verbatim code blocks to Github Flavored Markdown blocks, with
    Perl syntax highlighting.

- `--shift-headings OFFSET` (default: 1)

    Shift POD headings by _offset_ to yield a smaller Markdown heading.
    The default of 1 maps `=head1` to a level-2 heading (i.e. `##`)
    which is nicer than the overly large level-1 headings. Set to _0_
    to disable.

- `--input FILENAME`

    Set input filename, instead of STDIN/command line argument.

- `--output FILENAME`

    Set output filename, instead of STDOUT.

- `--config-file FILENAME`

    Load configuration from `FILENAME` (see below)

- `--help`

    Show this POD and exit.

- `--man`, `--perldoc`

    Show this POD in your `man` pager, and exit.

- `--version`

    Output version and exit.

- `--usage`

    Output the synopsis section only and exit.

## Yaml Configuration

Instead of passing command line arguments, configuration can be loaded
from a file named `pod2gitub.yaml` (or .yml; optionally preceded with
a single dot). Or from any other file via the `--config-file` option.

The YAML document should contain a top-level dictionary mapping keys
to values. Keys may use either underscores or dashes. For binary options,
use a value of 0/1.

An example configuration:

```
input: lib/Pod/Github.pm
output: README.md
inline: NAME
```

## Author

Richard Harris <richardharris@gmail.com>

However the hard work is done by [Pod::Markdown](https://metacpan.org/pod/Pod::Markdown) by Randy Stauner.

## Copyright and License

This software is copyright (c) 2017 Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
