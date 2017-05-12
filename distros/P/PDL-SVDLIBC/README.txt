    README for PDL::SVDLIBC

ABSTRACT
    PDL::SVDLIBC - PDL interface to Doug Rohde's SVD C Library

REQUIREMENTS
    PDL Tested versions 2.4.2, 2.4.3, 2.4.7_001, 2.4.9, 2.4.9_015.

    SVDLIBC
        By Dough Rohde, based on the SVDPACKC library, which was written by
        Michael Berry, Theresa Do, Gavin O'Brien, Vijay Krishna and Sowmini
        Varadhan. Tested version 1.33.

        Available from http://tedlab.mit.edu/~dr/SVDLIBC/svdlibc.tgz

DESCRIPTION
    PDL::SVDLIBC provides a PDL interface to the SVDLIBC routines for
    singular value decomposition of large sparse matrices.

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

    During the build process, you may be prompted for the locations of
    required libraries, header files, etc.

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT AND LICENSE
    Copyright (c) 2005-2015, Bryan Jurish. All rights reserved.

    This package is free software, and entirely without warranty. You may
    redistribute it and/or modify it under the same terms as Perl itself,
    either 5.20.2 or any newer version of Perl 5 you have available.

    The SVDLIBC sources included in this distribution are themselves
    released under a BSD-like license. See the file
    SVDLIBC/Manual/license.html in the PDL-SVDLIBC source distribution for
    details.

