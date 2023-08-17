# Statocles::Plugin::Highlight::Kamelon

A plugin for the static website generator Statocles that adds an alternative
syntax highlighter.  Source code and configuration examples in Markdown files
are highlighted with Syntax::Kamelon.

    %= highlight Perl => begin
    print "hello, world\n"
    %end

    %= highlight Perl => include -raw => 'hello.pl'

## DEPENDENCIES

Requires Perl 5.16 and the modules Statocles and Syntax::Kamelon from CPAN.

## INSTALLATION

Run the following commands to install the software:

    perl Makefile.PL
    make
    make test
    make install

Type the following command to see the module usage information:

    perldoc Statocles::Plugin::Highlight::Kamelon

## LICENSE AND COPYRIGHT

Copyright (C) 2023 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
