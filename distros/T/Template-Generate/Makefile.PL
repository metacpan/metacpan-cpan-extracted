#!/usr/bin/env perl
# $File: //member/autrijus/Template-Generate/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 8137 $ $DateTime: 2003/09/14 20:18:55 $

use 5.006001;
use inc::Module::Install;

WriteMakefile (
    AUTHOR	    => 'Autrijus Tang (autrijus@autrijus.org)',
    NAME	    => 'Template::Generate',
    ABSTRACT	    => 'Generate TT2 templates from data and documents',
    VERSION_FROM    => 'lib/Template/Generate.pm',
);

