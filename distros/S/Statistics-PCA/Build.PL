use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::PCA',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/PCA.pm',
    dist_abstract       => 'Module to perfrom PCA analysis',
    requires => {
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
    add_to_cleanup      => [ 'Statistics-PCA-*' ],
);

$builder->create_build_script();
