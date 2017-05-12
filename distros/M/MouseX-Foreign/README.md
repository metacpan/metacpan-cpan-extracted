# NAME

MouseX::Foreign - Extends non-Mouse classes as well as Mouse classes

# VERSION

This document describes MouseX::Foreign version 1.000.

# SYNOPSIS

    package MyInt;
    use Mouse;
    use MouseX::Foreign qw(Math::BigInt);

    has name => (
        is  => 'ro',
        isa => 'Str',
    );

# DESCRIPTION



MouseX::Foreign provides an ability for Mouse classes to extend any classes,
including non-Mouse classes, including Moose classes.

    

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# ACKNOWLEDGEMENT

This is a Mouse port of MooseX::NonMoose, although the name is different.

# SEE ALSO

[Mouse](https://metacpan.org/pod/Mouse)

[Moose](https://metacpan.org/pod/Moose)

[MooseX::NonMoose](https://metacpan.org/pod/MooseX::NonMoose)

[MooseX::Alien](https://metacpan.org/pod/MooseX::Alien)

# AUTHOR

Fuji, Goro (gfx) <gfuji(at)cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2010, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
