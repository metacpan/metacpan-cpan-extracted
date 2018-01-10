# NAME

Pod::ProjectDocs - generates CPAN like project documents from pod.

# SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Pod::ProjectDocs;

    my $pd = Pod::ProjectDocs->new(
        libroot => '/your/project/lib/root',
        outroot => '/output/directory',
        title   => 'ProjectName',
    );
    $pd->gen();

    # or use pod2projdocs on your shell
    pod2projdocs -out /output/directory -lib /your/project/lib/root

# DESCRIPTION

This module allows you to generates CPAN like pod pages from your modules
for your projects. It also creates an optional index page.

# OPTIONS

- `outroot`

    output directory for the generated documentation.

- `libroot`

    your library's (source code) root directory.

    You can set single path by string, or multiple by arrayref.

        my $pd = Pod::ProjectDocs->new(
            outroot => '/path/to/output/directory',
            libroot => '/path/to/lib'
        );

    or

        my $pd = Pod::ProjectDocs->new(
            outroot => '/path/to/output/directory',
            libroot => ['/path/to/lib1', '/path/to/lib2'],
        );

- `title`

    your project's name.

- `desc`

    description for your project.

- `index`

    whether you want to create an index for all generated pages (0 or 1).

- `lang`

    set this language as xml:lang (default 'en')

- `forcegen`

    whether you want to generate HTML document even if source files are not updated (default is 0).

- `nosourcecode`

    whether to suppress inclusion of the original source code in the generated output (default is 0).

- `except`

    the files matches this regex won't be parsed.

        Pod::ProjectDocs->new(
          except => qr/^specific_dir\//,
          ...other parameters
        );

        Pod::ProjectDocs->new(
          except => [qr/^specific_dir1\//, qr/^specific_dir2\//],
          ...other parameters
        );

# pod2projdocs

You can use the command line script [pod2projdocs](https://metacpan.org/pod/pod2projdocs) to generate your documentation
without creating a custom perl script.

    pod2projdocs -help

# SEE ALSO

[Pod::Simple::XHTML](https://metacpan.org/pod/Pod::Simple::XHTML)

# AUTHORS

- Lyo Kato <lyo.kato@gmail.com>
- [Martin Gruner](https://github.com/mgruner) (current maintainer)

# COPYRIGHT AND LICENSE

- © 2005 by Lyo Kato
- © 2018 by Martin Gruner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
