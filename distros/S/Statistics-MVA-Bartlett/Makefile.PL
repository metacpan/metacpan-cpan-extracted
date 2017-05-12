use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::MVA::Bartlett',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/MVA/Bartlett.pm',
    ABSTRACT_FROM       => 'lib/Statistics/MVA/Bartlett.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::MVA' => '0.0.1',
        'Carp' => '1.08',
        'Math::Cephes' => '0.47',
        'Statistics::Distributions' => '1.02',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-MVA-Bartlett-*' },
);
