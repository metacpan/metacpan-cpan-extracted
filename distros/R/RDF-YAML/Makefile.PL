#!/usr/bin/env perl
# $File: //member/autrijus/RDF-YAML/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 8523 $ $DateTime: 2003/10/22 04:14:34 $

use inc::Module::Install;

build_requires ('Test::More', 0);

WriteMakefile (
    AUTHOR	    => 'Autrijus Tang (autrijus@autrijus.org)',
    NAME	    => 'RDF::YAML',
    ABSTRACT	    => 'RDF YAML parser and dumper',
    VERSION_FROM    => 'lib/RDF/YAML.pm',
    SIGN	    => 1,
    PREREQ_PM       => {
	'Class::MethodMaker'	=> '1.00',
        'RDF::Simple'		=> '0.04',
	'YAML'			=> '0.30',
    },
);

