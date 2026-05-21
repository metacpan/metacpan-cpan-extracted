# NAME

Qhull - Interface to the Qhull convex hull, Delauny triangulation, Voronoi diagram software suite

# VERSION

version 0.08

# SYNOPSIS

    use Qhull 'qhull';

    # generate a convex hull and return the ordered
    # indices of the points in the convex hull
    my \@indices = qhull( $x, $y );

# DESCRIPTION

This is an **alpha** quality interface to the [qhull](https://qhull.org) library and executables.

At present this module punts to [Qhull::PP](https://metacpan.org/pod/Qhull%3A%3APP), which is a wrapper
around **qhull** executable, not the library.

At present see [Qhull::PP](https://metacpan.org/pod/Qhull%3A%3APP) for a discussion of the arguments to [qhull](https://metacpan.org/pod/qhull).

## Future API

**qhull** has an interesting manner of setting up options, used by both
the executable and the library entry point.  It may be impossible to
get this to look Perlish, especially as the **qhull** manual page is
required to properly use its facilities.

The final interface, which will be the same for the library and the
executable wrapper is still in flux.

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-qhull@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull](https://rt.cpan.org/Public/Dist/Display.html?Name=Qhull)

## Source

Source is available at

    https://gitlab.com/djerius/p5-qhull

and may be cloned from

    https://gitlab.com/djerius/p5-qhull.git

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
