use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Temperature::Windchill',
    license             => 'perl',
    dist_author         => 'John Trammell <johntrammell@gmail.com>',
    dist_version_from   => 'lib/Temperature/Windchill.pm',
    requires => {
        'Exporter' => 0,
        'perl'     => 5.005_000,
    },
    build_requires => {
        'Test::More'          => 0,
#       'Pod::Coverage'       => 0,
#       'Test::Pod'           => 0,
#       'Test::Pod::Coverage' => 0,
    },
    add_to_cleanup => [ 'Temperature-Windchill-*', '*.bak' ],
);

$builder->create_build_script;

