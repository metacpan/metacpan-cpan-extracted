use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Distributions::Bartlett',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/Distributions/Bartlett.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Distributions/Bartlett.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::Distributions' => '1.02', 
        'Carp' => '1.08', 'Perl6::Form' => '0.04',
        'List::Util' => '1.19',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Distributions-Bartlett-*' },
);
