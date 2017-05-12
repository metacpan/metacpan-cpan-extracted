use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::MVA::BayesianDiscrimination',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/MVA/BayesianDiscrimination.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::MVA' => '0.0.1',
        'Carp' => '1.08', 
        'Math::Cephes' => '0.47', 
        'List::Util' => '1.19',
        'Text::SimpleTable' => '2.0',
    },
    add_to_cleanup      => [ 'Statistics-MVA-BayesianDiscrimination-*' ],
);

$builder->create_build_script();
