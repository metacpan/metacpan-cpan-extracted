    README for PDL::SVDSLEPc

ABSTRACT
    PDL::SVDLIBC - PDL interface to SLEPc sparse singular value
    decomposition

REQUIREMENTS
    PDL Tested version 2.015.

    SLEPc
        "Scalable Library for Eigenvalue Problem Computations". Tested
        version 3.4.2, debian packages libslepc3.4.2, libslepc3.4.2-dev.

        Available from <http://slepc.upv.es/>.

    PETSc
        "Portable, Extensible Toolkit for Scientific Computation", required
        by SLEPc. Tested version 3.4.2, debian packages petsc3.4.2,
        petsc3.4.2-dev.

        Available from <http://www.mcs.anl.gov/petsc/>.

DESCRIPTION
    PDL::SVDSLEPc provides a PDL interface to the SLEPc routines for
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

KNOWN BUGS
  OpenMPI errors "mca: base: component find: unable to open ..."
    You might see OpenMPI errors such as the following when trying to use
    this module:

     mca: base: component find: unable to open /usr/lib/openmpi/lib/openmpi/mca_paffinity_hwloc: perhaps a missing symbol, or compiled for a different version of Open MPI? (ignored)

    If you do, you probably need to configure your runtime linker to
    pre-load the OpenMPI libraries, e.g. with

     export LD_PRELOAD=/usr/lib/libmpi.so

    or similar. An alternative is to build OpenMPI with the
    "--disable-dlopen" option. See
    <http://www.open-mpi.org/faq/?category=troubleshooting#missing-symbols>
    for details.

  OpenMPI warnings "... unable to find any relevant network interfaces ... (openib)"
    This OpenMPI warning has been observed on Ubuntu 14.04; it can be
    suppressed by setting the OpenMPI MCA "btl" ("byte transfer layer")
    parameter to exclude the "openib" module. This can be accomplished in
    various ways, e.g.:

    via command-line parameters to "mpiexec":
        Call your program as:

         $ mpiexec --mca btl ^openib PROGRAM...

    via environment variables
        You can set the OpenMPI MCA paramters via environment variables,
        e.g.:

         $ export OMPI_MCA_btl="^openib"
         $ PROGRAM...

    via configuration files
        You can set OpenMPI MCA parameters via
        $HOME/.openmpi/mac-params.conf:

         ##-- suppress annoying warnings about missing openib
         btl = ^openib

    See <http://www.open-mpi.de/faq/?category=tuning#setting-mca-params> for
    more details.

AUTHOR
    Bryan Jurish <moocow@cpan.org>

COPYRIGHT AND LICENSE
    Copyright (c) 2015, Bryan Jurish. All rights reserved.

    This package is free software, and entirely without warranty. You may
    redistribute it and/or modify it under the same terms as Perl itself,
    either 5.20.2 or any newer version of Perl 5 you have available.

