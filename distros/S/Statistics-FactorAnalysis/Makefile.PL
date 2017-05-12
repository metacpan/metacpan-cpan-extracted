use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Statistics::FactorAnalysis',
    AUTHOR              => 'Daniel S. T. Hughes <dsth@cantab.net>',
    VERSION_FROM        => 'lib/Statistics/FactorAnalysis.pm',
    ABSTRACT_FROM       => 'lib/Statistics/FactorAnalysis.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                =>  0,
        'version'                   =>  0,
        'Carp'                      =>  '1.08',
        'Moose'                     =>  '0.93',
        'MooseX::NonMoose'          =>  '0.07',
        'Statistics::PCA::Varimax'  =>  '0.0.2',
        'Statistics::PCA'           =>  '0.0.1',
        'Math::GSL::Linalg::SVD'    =>  '0.0.2', 
        'List::Util'                =>  '1.22',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Statistics-FactorAnalysis-*' },
);
