use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::PCA',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/PCA.pm',
    ABSTRACT_FROM       => 'lib/Statistics/PCA.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp' => '1.08', 
        'Math::Cephes::Matrix' => '0.47', 
        'Math::Cephes' => '0.47', 
        'List::Util' => '1.19', 
        'Math::MatrixReal' => '2.05', 
        'Text::SimpleTable' => '2.0', 
        'Contextual::Return' => '0.2.1',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-PCA-*' },
);
