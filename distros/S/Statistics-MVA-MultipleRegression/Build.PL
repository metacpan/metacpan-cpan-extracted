use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::MVA::MultipleRegression',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/MVA/MultipleRegression.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Carp' => '1.08', 
        'Statistics::MVA' => '0.0.1',
        'List::Util' => '1.19',
        'Math::MatrixReal' => '2.05', 
    },
    add_to_cleanup      => [ 'Statistics-MVA-MultipleRegression-*' ],
);

$builder->create_build_script();
