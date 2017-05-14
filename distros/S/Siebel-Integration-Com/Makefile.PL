use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Siebel::Integration::Com',
    AUTHOR           => q{Kyle Mathers <kyle.perl@mathersit.com>},
    VERSION			     => 0.02,
    ABSTRACT_FROM    => 'lib/Siebel/Integration/Com.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
				'Moose' => 2,
				'namespace::autoclean' => 0,
				'Win32::OLE' => 0.1,
				'Win32::OLE::Variant' => 1,
				'Carp' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Siebel-Integration-Com-*' },
);



