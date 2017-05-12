use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDL::IO::Nifti',
    AUTHOR           => q{Ingo Schmid <ingosch@gmx.at>},
    VERSION_FROM     => 'lib/PDL/IO/Nifti.pm',
    ABSTRACT_FROM    => 'lib/PDL/IO/Nifti.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Simple' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
	'PDL'=> 0, #2.004,
	'ExtUtils::F77'	=> '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDL-IO-Nifti-*' },
);
