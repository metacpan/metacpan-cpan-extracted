use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::FactorAnalysis',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/FactorAnalysis.pm',
    requires => {
        'Test::More'                =>  0,
        'version'                   =>  0,
        'Carp'                      =>  '1.08',
        'Moose'                     =>  '0.93',
        'MooseX::NonMoose'          =>  '0.07',
        'Statistics::PCA'           =>  '0.0.1',
        'Statistics::PCA::Varimax'  =>  '0.0.2',
        'Math::GSL::Linalg::SVD'    =>  '0.0.2', 
        'List::Util'                =>  '1.22',
    },
    add_to_cleanup      => [ 'Statistics-FactorAnalysis-*' ],
);

$builder->create_build_script();
