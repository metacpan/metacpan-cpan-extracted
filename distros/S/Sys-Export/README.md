# Sys::Export

This module helps you export a subset of an installed Unix system, such as for
use in containers, or an initrd, or just packaging an application with all of
its dependencies.  You start by specifying a list of the specific files you
want, and this module attempts to automatically find all of the dependencies.
It provides ways to rewrite user and group ownership, and can attempt to
rewrite paths of existing binaries and libraries as it exports them.

## SYNOPSIS

    use Sys::Export -src => '/', -dst => [ CPIO => "initrd.cpio" ];
    
    rewrite_path '/sbin'     => '/bin';
    rewrite_path '/usr/sbin' => '/bin';
    rewrite_path '/usr/bin'  => '/bin';
    
    # Add files and their dependencies
    add '/bin/busybox';
    add qw( bin/sh bin/date bin/cat bin/mount );
    
    # tell 'add' to ignore specific files
    skip 'usr/share/zoneinfo/tzdata.zi';
    
    # recurse and filter directories with 'find'
    add find 'usr/share/zoneinfo', sub { ! /(leapseconds|\.tab|\.list)$/ };
    
    # For Linux, generate minimal /etc/passwd /etc/group /etc/shadow according
    # to UID/GID which were exported so far.
    exporter->add_passwd;
    
    finish;

## INSTALLATION

You can install the latest release from CPAN:

    cpanm Sys::Export

or if you have a release tarball,

    cpanm Sys-Export-002.tar.gz

or manually build it with

    tar -xf Sys-Export-003.tar.gz
    cd Sys-Export-002
    perl Makefile.PL
    make
    make test
    make install

## DEVELOPMENT

Download or checkout the source code, then:

    dzil --authordeps | cpanm
    dzil test

To build and install a trial version, use

    V=0.003_01 dzil build
    cpanm Sys-Export-002_01.tar.gz
