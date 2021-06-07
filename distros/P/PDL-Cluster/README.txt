    README for PDL::Cluster

ABSTRACT
    PDL::Cluster - PDL wrappers for the C clustering library by Michiel de
    Hoon

REQUIREMENTS
    *   PDL

        Tested versions 2.017, 2.019

DESCRIPTION
    PDL::Cluster provides PDL wrappers for the open source C clustering
    library by Michiel de Hoon.

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

    *   C clustering library for cDNA microarray data copyright (C)
        2002-2005 Michiel Jan Laurens de Hoon.

AUTHOR
    Bryan Jurish <moocow@cpan.org> wrote and maintains the PDL::Cluster
    distribution.

    Michiel de Hoon wrote the underlying C clustering library for cDNA
    microarray data.

COPYRIGHT
    PDL::Cluster is a set of wrappers around the C Clustering library for
    cDNA microarray data.

    *   The C clustering library for cDNA microarray data. Copyright (C)
        2002-2005 Michiel Jan Laurens de Hoon.

        This library was written at the Laboratory of DNA Information
        Analysis, Human Genome Center, Institute of Medical Science,
        University of Tokyo, 4-6-1 Shirokanedai, Minato-ku, Tokyo 108-8639,
        Japan. Contact: michiel.dehoon 'AT' riken.jp

        See the files README.cluster, ccluster.c, and ccluster.h in the
        PDL::Cluster distribution for details.

    *   PDL::Cluster wrappers (c) 2005-2021, Bryan Jurish. All rights
        reserved. This package is free software, and entirely without
        warranty. You may redistribute it and/or modify it under the same
        terms as Perl itself.

