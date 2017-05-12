use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::MVA',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/MVA.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp' => '1.08',
        'Math::MatrixReal' => '2.05',
    },
    add_to_cleanup      => [ 'Statistics-MVA-*' ],
);

$builder->create_build_script();
