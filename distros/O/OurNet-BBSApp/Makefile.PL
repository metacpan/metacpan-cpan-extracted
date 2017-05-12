#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT        => 'BBS Application Interface',
    NAME            => 'OurNet::BBSApp',
    VERSION_FROM    => 'BBSApp.pm',
    DISTNAME        => 'OurNet-BBSApp',
    BINARY_LOCATION => 'x86/OurNet-BBSApp.tar.gz',

    PREREQ_PM       => {
	'OurNet::BBS'           => '1.5',
        'HTML::FromText'        => '1.005',      # BBSApp::Templator
        'XML::Simple'           => '1.04',       # XML::Simple
    },
	
    EXE_FILES       => [ <bin/*> ],

    dist            => {
	COMPRESS    => 'gzip',
	SUFFIX      => '.gz',
    }
);

