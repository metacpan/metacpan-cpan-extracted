# Sys::Export

This module helps you export a subset of an installed Unix system, such as for
use in containers, or an initrd, or just packaging an application with all of
its dependencies.  You start by specifying a list of the specific files you
want, and this module attempts to automatically find all of the dependencies.

# INSTALLATION

You can install the latest release from CPAN:

    cpanm Sys::Export

or if you have a release tarball,

    cpanm Sys-Export-001.tar.gz

or manually build it with

    tar -xf Sys-Export-001.tar.gz
    cd Sys-Export-001
    perl Makefile.PL
    make
    make test
    make install

# DEVELOPMENT

Download or checkout the source code, then:

    dzil --authordeps | cpanm
    dzil test

To build and install a trial version, use

    V=0.001_01 dzil build
    cpanm Sys-Export-001_01.tar.gz
