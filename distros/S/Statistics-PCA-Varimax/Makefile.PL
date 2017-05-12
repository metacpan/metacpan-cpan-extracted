use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::PCA::Varimax',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/PCA/Varimax.pm',
    ABSTRACT_FROM       => 'lib/Statistics/PCA/Varimax.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                =>  '0',
        'version'                   =>  '0',
        'Carp'                      =>  '1.08',
        'Math::GSL::Linalg::SVD'    =>  '0.0.2',
        'Math::MatrixReal'          =>  '2.05',
        'List::Util'                =>  '1.22',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-PCA-Varimax-*' },
);
