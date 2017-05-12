use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::MVA::BayesianDiscrimination',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/MVA/BayesianDiscrimination.pm',
    ABSTRACT_FROM       => 'lib/Statistics/MVA/BayesianDiscrimination.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::MVA' => '0.0.1',
        'Carp' => '1.08', 
        'Math::Cephes' => '0.47', 
        'List::Util' => '1.19',
        'Text::SimpleTable' => '2.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-MVA-BayesianDiscrimination-*' },
);
