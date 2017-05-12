#!/usr/bin/perl
#
#   Perl Makefile for Perlbal
#   $Id$
#
#   Invoke with 'perl Makefile.PL'
#
#   See ExtUtils::MakeMaker (3) for more information on how to influence
#    the contents of the Makefile that is written
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                    => 'Sys::Syscall',
    VERSION_FROM            => 'lib/Sys/Syscall.pm',
    AUTHOR                  => 'Brad Fitzpatrick <brad@danga.com>',
    ABSTRACT                => 'Invoke system calls that are otherwise difficult to do from Perl.',

    PREREQ_PM               => {
        'POSIX' => 0,
        'Test::More' => 0,
    },
    dist                    => {
#        CI                      => "cvs commit",
#        RCS_LABEL               => 'cvs tag RELEASE_$(VERSION_SYM)',
        SUFFIX                  => ".gz",
        DIST_DEFAULT            => 'all tardist',
        COMPRESS                => "gzip",
    },
);


