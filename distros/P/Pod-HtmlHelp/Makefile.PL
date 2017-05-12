#!/usr/bin/perl
# $File: //member/autrijus/Pod-HtmlHelp/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 672 $ $DateTime: 2002/08/16 18:51:54 $

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Interface with Microsoft\'s HtmlHelp system',
    NAME		=> 'Pod::HtmlHelp',
    VERSION_FROM	=> 'HtmlHelp.pm', 
    DISTNAME		=> 'Pod-HtmlHelp',
    BINARY_LOCATION	=> 'x86/Pod-HtmlHelp.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

