use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::MVA::HotellingTwoSample',
    license             => 'perl',
    dist_author         => 'Daniel S. T. Hughes <dsth@cantab.net>',
    dist_version_from   => 'lib/Statistics/MVA/HotellingTwoSample.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Statistics::MVA' => '0.0.1',
        'Carp' => '1.08',
        'Statistics::Distributions' => '1.02',
    },
    add_to_cleanup      => [ 'Statistics-MVA-HotellingTwoSample-*' ],
);

$builder->create_build_script();
