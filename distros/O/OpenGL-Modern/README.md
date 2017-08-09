# OpenGL-Modern 0.03_01


## STATUS

[![Build Status](https://travis-ci.org/devel-chm/OpenGL-Modern.svg?branch=master)](https://travis-ci.org/devel-chm/OpenGL-Modern)

## DESCRIPTION

This is the first official release of OpenGL::Modern
supporting OpenGL API bindings for OpenGL versions up to
version 4.5.

Bindings have been generated for all API routines but
any pointer value arguments or return values are
implemented as passing and returning raw pointers to
data or string buffers.  These "raw" functions are
named by starting with the base name of the C OpenGL
routine and appending `_c` (representing the C pointer)
usage.

See documentation and the perl source to
OpenGL::Modern::Helpers for examples for calling
those routines (i.e. perldoc -m OpenGL::Modern::Helpers).
As this is a new module, the handling for those pointer
arguments *will* be evolving.  These changes will be
documented in OpenGL::Modern::Helpers until final.

All releases for OpenGL::Modern *should* be considered
*alpha* until the API is fully implemented and stable.

We're happy for user feedback and questions.  See #pogl
on irc.perl.org for chatting and the Perl OpenGL users
lists at the sf.net site.  They are members only but
you can use the Subscribe link to join:

https://sourceforge.net/p/pogl/mailman/?source=navbar

## INSTALLATION

To install this module type the following:

```
   perl Makefile.PL
   make
   make test
   make install
```

or cpan or cpanm.



## DEPENDENCIES

This module requires these other modules and libraries:

    Carp                          => 0,
    Capture::Tiny                 => 0,
    Data::Dumper                  => 0,
    Devel::CheckOS                => 0,
    Devel::CheckLib               => 0,
    ExtUtils::Constant            => 0,
    ExtUtils::MakeMaker           => 6.17,
    ExtUtils::MakeMaker::CPANfile => 0,
    IO::All                       => 0,
    Test::InDistDir               => 0,
    Test::More                    => 0.88,

not *required* but needed for currently unimplemented features:

    OpenGL 0.70  (for unimplemented functions)

## COPYRIGHT AND LICENCE

Copyright (C) 2017 by Chris Marshall
Copyright (C) 2016 by Max Maischein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.
