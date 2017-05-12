use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PDL::Dims',
    AUTHOR           => q{Ingo Schmid <ingosch@gmx.at>},
    VERSION_FROM     => 'lib/PDL/Dims.pm',
    ABSTRACT_FROM    => 'lib/PDL/Dims.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Simple' => 0,
    },
    PREREQ_PM => {
    	'PDL'	=> 0,
    	'PDL::NiceSlice'	=> 0,
	'Scalar::Util' =>0,
	'Exporter', =>0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PDL-Dims-*' },
);
