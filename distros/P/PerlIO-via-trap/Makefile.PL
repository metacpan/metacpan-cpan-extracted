#!/usr/bin/env perl

require 5.007002;
use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR		=> 'Chia-liang Kao (clkao@clkao.org)',
    ABSTRACT		=> 'PerlIO layer to trap write',
    NAME		=> 'PerlIO::via::trap',
    VERSION_FROM	=> 'trap.pm',
    DISTNAME		=> 'PerlIO-via-trap',
    BINARY_LOCATION	=> 'x86/PerlI-via-trap.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

