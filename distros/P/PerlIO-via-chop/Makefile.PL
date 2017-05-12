#!/usr/bin/env perl
# $File: //member/autrijus/PerlIO-via-chop/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 1248 $ $DateTime: 2002/10/07 14:07:23 $

require 5.007002;
use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'PerlIO layer to chop the last byte outputted',
    NAME		=> 'PerlIO::via::chop',
    VERSION_FROM	=> 'chop.pm',
    DISTNAME		=> 'PerlIO-via-chop',
    BINARY_LOCATION	=> 'x86/PerlI-via-chop.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

