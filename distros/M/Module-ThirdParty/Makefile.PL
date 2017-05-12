use strict;
use ExtUtils::MakeMaker;
eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    NAME                => 'Module::ThirdParty',
    LICENSE             => 'perl',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Module/ThirdParty.pm',
    ABSTRACT_FROM       => 'lib/Module/ThirdParty.pm',
    EXE_FILES           => [ 'bin/is3rdparty' ], 
    PREREQ_PM => {
        'Test::More' => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Module-ThirdParty-*' },
);
