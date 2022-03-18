    README for PDL::VectorValued

ABSTRACT
    PDL::VectorValued - Assorted PDL utilities treating vectors as values

REQUIREMENTS
    *   PDL

        Tested version(s) 2.4.2, 2.4.3, 2.4.7_001, 2.4.9_015, 2.4.10, 2.019,
        2.039

DESCRIPTION
    PDL::VectorValued provides some generalizations of builtin PDL functions
    to higher order PDLs which treat vectors in the source PDLs as "data
    values".

BUILDING
    Build this module as you would any perl module, by doing something akin
    to the following:

     gzip -dc distname-XX.YY.tar.gz | tar -xof -
     cd distname-XX.YY/
     perl Makefile.PL
     make
     make test                                     # optional
     make install

    See perlmodinstall(1) for details.

ACKNOWLEDGEMENTS
    *   Perl by Larry Wall

    *   PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and
        others.

    *   Code for rlevec() and rldvec() derived from the PDL builtin
        functions rle() and rld() in $PDL_SRC_ROOT/Basic/Slices/slices.pd

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT
    Copyright (c) 2007-2022, Bryan Jurish. All rights reserved.

    This package is free software, and entirely without warranty. You may
    redistribute it and/or modify it under the same terms as Perl itself.

