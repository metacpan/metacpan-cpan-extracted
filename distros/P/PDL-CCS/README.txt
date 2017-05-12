    README for PDL::CCS

ABSTRACT
    PDL::CCS - Sparse N-dimensional PDLs with Harwell-Boeing compressed
    column storage

REQUIREMENTS
    *   PDL >= v2.4.2

        Tested version(s) 2.4.2, 2.4.3, 2.4.7_001, 2.4.9_015.

    *   PDL::VectorValued >= v0.07001

DESCRIPTION
    PDL::CCS is a set of perl modules for representation and manipulation of
    large sparse n-dimensional numeric arrays using PDL. It includes a perl
    class implementing a subset of the PDL API for memory-efficient storage
    and operations on large sparse arrays, as well as utilities for
    extracting Harwell-Boeing compressed column- and/or row-storage
    "pointers" from/to indexND() vector lists.

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

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT
    Copyright (c) 2005-2013 by Bryan Jurish. All rights reserved.

    This package is free software, and entirely without warranty. You may
    redistribute it and/or modify it under the same terms as Perl itself.

