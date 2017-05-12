    README for PDL::VectorValued

ABSTRACT
    PDL::VectorValued - Assorted PDL utilities treating vectors as values

REQUIREMENTS
    *   PDL

        Tested versions 2.4.3, 2.4.7_001, 2.4.9, 2.4.9_015.

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

    *   Code for vv_qsortvec() copied nearly verbatim from the builtin PDL
        functions in $PDL_SRC_ROOT/Basic/Ufunc/ufunc.pd, with Chris
        Marshall's "uniqsortvec" patch. Code for vv_qsortveci() based on the
        same.

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT
    *   Code for qsortvec() copyright (C) Tuomas J. Lukka 1997.
        Contributions by Christian Soeller (c.soeller@auckland.ac.nz) and
        Karl Glazebrook (kgb@aaoepp.aao.gov.au). All rights reserved. There
        is no warranty. You are allowed to redistribute this software /
        documentation under certain conditions. For details, see the file
        COPYING in the PDL distribution. If this file is separated from the
        PDL distribution, the copyright notice should be included in the
        file.

    *   All other parts copyright (c) 2007-2011, Bryan Jurish. All rights
        reserved.

        This package is free software, and entirely without warranty. You
        may redistribute it and/or modify it under the same terms as Perl
        itself.

