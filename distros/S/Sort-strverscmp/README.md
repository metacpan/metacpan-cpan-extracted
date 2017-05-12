[![Build Status](https://travis-ci.org/nnutter/perl-sort-strverscmp.svg?branch=master)](https://travis-ci.org/nnutter/perl-sort-strverscmp)
# NAME

Sort::strverscmp -- Compare strings while treating digits characters numerically.

# SYNOPSIS

    use Sort::strverscmp;
    my @version = qw(a A beta9 alpha9 alpha10 alpha010 1.0.5 1.05);
    my @sorted  = sort strverscmp @list;
    say join("\n", @sorted);

    if (strverscmp($min_version, $this_version) <= 0) {
      say 'this version satisfies minimum version';
    }

# DESCRIPTION

Perl equivalents to GNU `strverscmp` and `versionsort`.

# METHODS

## strverscmp

    strverscmp('1.0.5', '1.0.50'); # -1

Returns -1, 0, or 1 depending on whether the left version string is less than,
equal to, or greater than the right version string.

## versionsort

    versionsort('1.0.5', '1.0.50'); # -1

Returns a sorted list of version strings.

# AUTHOR

Nathaniel Nutter `nnutter@cpan.org`

# COPYRIGHT AND DISCLAIMER

Copyright 2013, The Genome Institute at Washington University
`nnutter@cpan.org`, all rights reserved.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for a
particular purpose.
