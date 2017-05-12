# Preproc-Tiny

Minimal stand-alone preprocessor for code generation using perl

This preprocessor originated from the need to generate C++ code
in a flexible way and without having to adapt to limitations of
the several mini-languages of other templating engines available
in CPAN. The template language used is just perl.

Being a Tiny module, it has no external dependencies and can be
used by just copying the pp.pl file to any executable directory.

# Installation

To install this module type the following:

    perl Makefile.PL  
    make  
    make test  
    make install

# Dependencies

None non-core for running. There are dependendencies for running the tests.

# Copyright and Licence

Copyright (C) 2016 by Paulo Custodio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.1 or,
at your option, any later version of Perl 5 you may have available.
