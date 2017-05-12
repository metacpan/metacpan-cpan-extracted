#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'Scriptable telnet-based virtual users',
    NAME            => 'OurNet::Site',
    VERSION_FROM    => 'Site.pm',
    DISTNAME        => 'OurNet-Site',
    BINARY_LOCATION => 'x86/OurNet-Site.tar.gz',

    PREREQ_PM       => {
	'HTTP::Request::Common' => '1.16',       # Query
        'LWP::Parallel'         => '2.49',       # Query
        'Template'              => '2.00',       # Template, WebBuilder
    },
	
    EXE_FILES       => [ <bin/*> ],

    dist            => {
        COMPRESS    => 'gzip',
        SUFFIX      => '.gz',
    }
);
