use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Distributions::GTest',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/Distributions/GTest.pm',
    dist_abstract       => 'Module to perform log-likelihood ratio test (G-test) of independence',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::Distributions' => '1.02',
        'Math::Cephes'              => '0.47', 
        'Carp'                      => '1.08', 
        'Contextual::Return'        => '0.2.1',
        'List::Util'                => '1.19', 
        'Text::SimpleTable'         => '2.0',
    },
    add_to_cleanup      => [ 'Statistics-Distributions-GTest-*' ],
);

$builder->create_build_script();
