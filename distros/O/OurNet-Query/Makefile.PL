#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Scriptable queries with template extraction',
    NAME            => 'OurNet::Query',
    VERSION_FROM    => 'Query.pm',
    DISTNAME        => 'OurNet-Query',
    BINARY_LOCATION => 'x86/OurNet-Query.tar.gz',

    PREREQ_PM       => {
	'HTTP::Request::Common' => '1.16',       # Query
        'LWP::Parallel'         => '2.49',       # Query
        'Template'              => '2.00',       # Template, Site
    },
	
    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);
