use strict;
use warnings;

use 5.006002;

use ExtUtils::MakeMaker;

WriteMakefile(
    DISTNAME          => 'POE-Filter-PPPHDLC',
    NAME              => 'POE::Filter::PPPHDLC',
    VERSION_FROM      => 'lib/POE/Filter/PPPHDLC.pm',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
    PREREQ_PM         => {
        strict => 0,
	warnings => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'  => 0.47,
    },
    ABSTRACT_FROM     => 'lib/POE/Filter/PPPHDLC.pm',
    AUTHOR            => 'Benjamin Smith <bsmith@cabbage.org.uk>',
    MIN_PERL_VERSION  => '5.006002',
    LICENSE           => 'perl',
    META_ADD        => {
	dynamic_config => 0,
        resources => {
            homepage => "https://github.com/bsmith/POE-Filter-PPPHDLC",
            repository => {
                type => "git",
                url => "https://github.com/bsmith/POE-Filter-PPPHDLC.git",
                web => "https://github.com/bsmith/POE-Filter-PPPHDLC",
            },
	},
    },
);
