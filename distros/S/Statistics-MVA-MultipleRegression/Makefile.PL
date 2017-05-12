use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::MVA::MultipleRegression',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/MVA/MultipleRegression.pm',
    ABSTRACT_FROM       => 'lib/Statistics/MVA/MultipleRegression.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp' => '1.08', 
        'Statistics::MVA' => '0.0.1',
        'List::Util' => '1.19',
        'Math::MatrixReal' => '2.05', 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-MVA-MultipleRegression-*' },
);
