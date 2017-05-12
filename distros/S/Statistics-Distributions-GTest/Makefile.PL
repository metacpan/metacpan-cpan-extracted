use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::Distributions::GTest',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/Distributions/GTest.pm',
    ABSTRACT_FROM       => 'lib/Statistics/Distributions/GTest.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
		'Statistics::Distributions' => '1.02',
		'Math::Cephes'              => '0.47', 
		'Carp'                      => '1.08', 
		'Contextual::Return'        => '0.2.1',
		'List::Util'                => '1.19', 
		'Text::SimpleTable'         => '2.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-Distributions-GTest-*' },
);
