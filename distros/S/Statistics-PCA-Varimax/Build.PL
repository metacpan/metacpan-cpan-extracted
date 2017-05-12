use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::PCA::Varimax',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/PCA/Varimax.pm',
    requires => {
        'Test::More'                =>  '0',
        'version'                   =>  '0',
        'Carp'                      =>  '1.08',
        'Math::GSL::Linalg::SVD'    =>  '0.0.2',
        'Math::MatrixReal'          =>  '2.05',
        'List::Util'                =>  '1.22',
    },
    add_to_cleanup      => [ 'Statistics-PCA-Varimax-*' ],
);

$builder->create_build_script();
