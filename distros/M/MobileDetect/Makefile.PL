use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MobileDetect',
    AUTHOR           => q{Sebastian Enger <sebastian.enger@gmail.com>},
    VERSION_FROM     => 'lib/MobileDetect.pm',
    ABSTRACT_FROM    => 'lib/MobileDetect.pm',
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
        'JSON' 					=> 1.0,
		'LWP::Protocol::https'	=> 1.0,
		'LWP::Protocol'			=> 1.0,
		'Storable'				=> 1.0,
		
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MobileDetect*' },
);
