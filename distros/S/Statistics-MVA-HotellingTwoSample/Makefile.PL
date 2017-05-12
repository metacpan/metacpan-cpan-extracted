use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::MVA::HotellingTwoSample',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/MVA/HotellingTwoSample.pm',
    ABSTRACT_FROM       => 'lib/Statistics/MVA/HotellingTwoSample.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::MVA' => '0.0.1',
        'Carp' => '1.08',
        'Statistics::Distributions' => '1.02',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-MVA-HotellingTwoSample-*' },
);
