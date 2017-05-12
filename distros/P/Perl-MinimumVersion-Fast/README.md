# NAME

Perl::MinimumVersion::Fast - Find a minimum required version of perl for Perl code

# SYNOPSIS

    use Perl::MinimumVersion::Fast;

    my $p = Perl::MinimumVersion::Fast->new($filename);
    print $p->minimum_version, "\n";

# DESCRIPTION

"Perl::MinimumVersion::Fast" takes Perl source code and calculates the minimum
version of perl required to be able to run it. Because it is based on goccy's [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer),
it can do this without having to actually load the code.

Perl::MinimumVersion::Fast is an alternative fast & lightweight implementation of Perl::MinimumVersion.

This module supports only Perl 5.8.1+.
If you want to support **Perl 5.6**, use [Perl::MinimumVersion](https://metacpan.org/pod/Perl::MinimumVersion) instead.

In 2013, you don't need to support Perl 5.6 in most of case.

# METHODS

- `my $p = Perl::MinimumVersion::Fast->new($filename);`
- `my $p = Perl::MinimumVersion::Fast->new(\$src);`

    Create new instance. You can create object from `$filename` and `\$src` in string.

- `$p->minimum_version();`

    Get a minimum perl version the code required.

- `$p->minimum_explicit_version()`

    The `minimum_explicit_version` method checks through Perl code for the
    use of explicit version dependencies such as.

        use 5.006;
        require 5.005_03;

    Although there is almost always only one of these in a file, if more than
    one are found, the highest version dependency will be returned.

    Returns a [version](https://metacpan.org/pod/version) object, `undef` if no dependencies could be found.

- `$p->minimum_syntax_version()`

    The `minimum_syntax_version` method will explicitly test only the
    Document's syntax to determine it's minimum version, to the extent
    that this is possible.

    Returns a [version](https://metacpan.org/pod/version) object, `undef` if no dependencies could be found.

- version\_markers

    This method returns a list of pairs in the form:

        ($version, \@markers)

    Each pair represents all the markers that could be found indicating that the
    version was the minimum needed version.  `@markers` is an array of strings.
    Currently, these strings are not as clear as they might be, but this may be
    changed in the future.  In other words: don't rely on them as specific
    identifiers.

# BENCHMARK

Perl::MinimumVersion::Fast is faster than Perl::MinimumVersion.
Because Perl::MinimumVersion::Fast uses [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer), that is a Perl5 lexer implemented in C++.
And Perl::MinimumVersion::Fast omits some features implemented in Perl::MinimumVersion.

But, but, [Perl::MinimumVersion::Fast](https://metacpan.org/pod/Perl::MinimumVersion::Fast) is really fast.

                                Rate Perl::MinimumVersion Perl::MinimumVersion::Fast
    Perl::MinimumVersion       5.26/s                   --                       -97%
    Perl::MinimumVersion::Fast  182/s                3365%                         --

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# THANKS TO

Most of documents are taken from [Perl::MinimumVersion](https://metacpan.org/pod/Perl::MinimumVersion).

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

This module using [Compiler::Lexer](https://metacpan.org/pod/Compiler::Lexer) as a lexer for Perl5 code.

This module is inspired from [Perl::MinimumVersion](https://metacpan.org/pod/Perl::MinimumVersion).
